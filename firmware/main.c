#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>

// DECLARAÇÕES DAS FUNÇÕES
static void calc_produto_escalar(void);
static void reboot(void);
static void help(void);
static void prompt(void);
static void debug_csr(void);


#ifdef CSR_PRODUTO_ESCALAR_VETOR_A0_ADDR
#define PRODUTO_ESCALAR_AVAILABLE 1
#else
#define PRODUTO_ESCALAR_AVAILABLE 0
#endif

static char *readstr(void)
{
    char c[2];
    static char s[64];
    static int ptr = 0;

    if(readchar_nonblock()) {
        c[0] = readchar();
        c[1] = 0;
        switch(c[0]) {
            case 0x7f:
            case 0x08:
                if(ptr > 0) {
                    ptr--;
                    putsnonl("\x08 \x08");
                }
                break;
            case 0x07:
                break;
            case '\r':
            case '\n':
                s[ptr] = 0x00;
                putsnonl("\n");
                ptr = 0;
                return s;
            default:
                if(ptr >= (sizeof(s) - 1))
                    break;
                putsnonl(c);
                s[ptr] = c[0];
                ptr++;
                break;
        }
    }
    return NULL;
}

static char *get_token(char **str)
{
    char *c, *d;

    c = (char *)strchr(*str, ' ');
    if(c == NULL) {
        d = *str;
        *str = *str+strlen(*str);
        return d;
    }
    *c = 0;
    d = *str;
    *str = c+1;
    return d;
}

static void prompt(void)
{
    printf("\nRUNTIME> ");
}

static void help(void)
{
    puts("=========================================================");
    puts("|              Comandos disponíveis:                     |");
    puts("|  help                            - Mostra commands     |");
    puts("|  reboot                          - Reboot CPU          |");
    puts("|  produto_escalar                 - Faz produto_escalar |");
    puts("|  debug_csr                       - Debug registradores |");
    puts("=========================================================");
}

static void reboot(void)
{
    ctrl_reset_write(1);
}

static void calc_produto_escalar(void)
{
#if !PRODUTO_ESCALAR_AVAILABLE
    printf("ERRO: Módulo produto_escalar não encontrado no SoC!\n");
    printf("Execute 'debug_csr' para verificar os módulos disponíveis.\n");
    return;
#endif

    int32_t a[8], b[8];
    char *str, *token;

    printf("Digite 8 valores de A (separados por espaco): ");
    while((str = readstr()) == NULL);
    for(int i = 0; i < 8; i++) {
        token = get_token(&str);
        if(token == NULL) {
            printf("Faltaram valores em A!\n");
            return;
        }
        a[i] = atoi(token);
    }

    printf("Digite 8 valores de B (separados por espaco): ");
    while((str = readstr()) == NULL);
    for(int i = 0; i < 8; i++) {
        token = get_token(&str);
        if(token == NULL) {
            printf("Faltaram valores em B!\n");
            return;
        }
        b[i] = atoi(token);
    }

    printf("\nCÁLCULO PRODUTO ESCALAR: \n");
    
    printf("Vetor A: ");
    for(int i = 0; i < 8; i++) printf("%ld ", (long)a[i]);
    printf("\nVetor B: ");
    for(int i = 0; i < 8; i++) printf("%ld ", (long)b[i]);
    printf("\n\n");
    
    // Escreve vetores no hardware
    produto_escalar_vetor_a0_write(a[0]);
    produto_escalar_vetor_a1_write(a[1]);
    produto_escalar_vetor_a2_write(a[2]);
    produto_escalar_vetor_a3_write(a[3]);
    produto_escalar_vetor_a4_write(a[4]);
    produto_escalar_vetor_a5_write(a[5]);
    produto_escalar_vetor_a6_write(a[6]);
    produto_escalar_vetor_a7_write(a[7]);

    produto_escalar_vetor_b0_write(b[0]);
    produto_escalar_vetor_b1_write(b[1]);
    produto_escalar_vetor_b2_write(b[2]);
    produto_escalar_vetor_b3_write(b[3]);
    produto_escalar_vetor_b4_write(b[4]);
    produto_escalar_vetor_b5_write(b[5]);
    produto_escalar_vetor_b6_write(b[6]);
    produto_escalar_vetor_b7_write(b[7]);

    printf("Iniciando cálculo...\n");
    
    // Reset
    produto_escalar_iniciar_write(0);
    for(volatile int d = 0; d < 1000; d++);
    
    // Pulso de iniciar
    produto_escalar_iniciar_write(1);
    for(volatile int d = 0; d < 1000; d++);
    produto_escalar_iniciar_write(0);
    
    // Espera fixa para pipeline
    printf("Processando");
    for(volatile int d = 0; d < 10000; d++) {
        if (d % 2000 == 0) printf(".");
    }
    printf(" Concluído!\n\n");
    
    // Lê o resultado do hardware
    uint32_t resultado_hw = produto_escalar_resultado_read();
    
    printf("Resultado Hardware: %ld (0x%08lx)\n", 
           (long)(int32_t)resultado_hw, (unsigned long)resultado_hw);

    // LEITURA E CONVERSÃO CORRETA
    uint32_t resultado_raw = produto_escalar_resultado_read();
    int32_t resultado_signed = (int32_t)resultado_raw;  // Conversão para signed
    
    // Verificação por software
    int32_t verif = 0;
    printf("Verificação (software): ");
    for(int i = 0; i < 8; i++) {
        int32_t prod = a[i] * b[i];
        verif += prod;
        printf("%ld*%ld", (long)a[i], (long)b[i]);
        if(i < 7) printf(" + ");
        else printf(" = %ld\n", (long)verif);
    }

    if(verif == resultado_signed) {
        printf("SUCESSO! Hardware e software coincidem!");
    } else {
        printf("ERRO! Resultados diferentes!\n");
        printf("   Hardware: %ld, Software: %ld\n", (long)resultado_signed, (long)verif);
    }
    
    printf("\n");
}

static void debug_csr(void) {
    printf("=== DEBUG CSR ===\n");
    
#if PRODUTO_ESCALAR_AVAILABLE
    printf("Módulo produto_escalar encontrado!\n\n");
    
    // Lê e mostra os valores dos registradores
    printf("Entradas do vetor A:\n");
    printf("  a0: %ld\n", (long)produto_escalar_vetor_a0_read());
    printf("  a1: %ld\n", (long)produto_escalar_vetor_a1_read());
    printf("  a2: %ld\n", (long)produto_escalar_vetor_a2_read());
    printf("  a3: %ld\n", (long)produto_escalar_vetor_a3_read());
    
    printf("\nStatus do hardware:\n");
    printf("  iniciar: %ld\n", (long)produto_escalar_iniciar_read());
    printf("  concluido: %ld\n", (long)produto_escalar_concluido_read());
    printf("  resultado: %ld\n", (long)produto_escalar_resultado_read());
    
    // Testa se consegue escrever e ler um registrador
    printf("\nTeste de comunicação:\n");
    produto_escalar_vetor_a0_write(0x12345678);
    uint32_t valor_lido = produto_escalar_vetor_a0_read();
    printf("  Escrito: 0x12345678, Lido: 0x%08lx\n", (unsigned long)valor_lido);
    
#else
    printf("Módulo produto_escalar NÃO encontrado!\n");
    printf("Verifique a configuração do hardware.\n");
#endif
}

static void console_service(void) {
    char *str;
    char *token;

    str = readstr();
    if(str == NULL) return;
    token = get_token(&str);
    if(strcmp(token, "help") == 0)
        help();
    else if(strcmp(token, "reboot") == 0)
        reboot();
    else if(strcmp(token, "produto_escalar") == 0)
        calc_produto_escalar();
    else if(strcmp(token, "debug_csr") == 0)
        debug_csr();
    else
        printf("Comando desconhecido: %s\n", token);
    prompt();
}

int main(void) {
#ifdef CONFIG_CPU_HAS_INTERRUPT
    irq_setmask(0);
    irq_setie(1);
#endif
    uart_init();

    printf("\n");
    printf("=========================================================\n");
    printf("|               RISC-V com Produto Escalar               |\n");
//#if PRODUTO_ESCALAR_AVAILABLE
//    printf("|                   HARDWARE DETECTADO                    |\n");
//#else
//    printf("|                 HARDWARE NÃO DETECTADO                |\n");
//#endif
    printf("=========================================================\n");
    
    help();
    prompt();

    while(1) {
        console_service();
    }

    return 0;
}