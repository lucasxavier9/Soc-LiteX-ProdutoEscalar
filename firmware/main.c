#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>

// DECLARAÇÕES DAS FUNÇÕES
static void calc_produto_escalar(void);
static void toggle_led(void);
static void reboot(void);
static void help(void);
static void prompt(void);


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
    printf("RUNTIME>");
}

static void help(void)
{
    puts("Available commands:");
    puts("help                            - this command");
    puts("reboot                          - reboot CPU");
    puts("led                             - led test");
    puts("produto_escalar                 - test produto_escalar");
    puts("debug_csr                       - debug dos registradores");

}

static void reboot(void)
{
    ctrl_reset_write(1);
}

static void toggle_led(void)
{
    int i;
    printf("Invertendo LED...\n");
    i = leds_out_read();
    leds_out_write(!i);
}

static void calc_produto_escalar(void)
{
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

    printf("=== CÁLCULO PRODUTO ESCALAR ===\n");
    
    printf("Vetor A: ");
    for(int i = 0; i < 8; i++) printf("%ld ", (long)a[i]);
    printf("\nVetor B: ");
    for(int i = 0; i < 8; i++) printf("%ld ", (long)b[i]);
    printf("\n");
    
    // Escreve vetores
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

    // Reset e início
    produto_escalar_iniciar_write(0);
    for(volatile int d = 0; d < 10000; d++);
    
    produto_escalar_iniciar_write(1);
    for(volatile int d = 0; d < 1000; d++);
    produto_escalar_iniciar_write(0);

    // Aguarda conclusão
    printf("Calculando...");
    int timeout = 0;
    while(!produto_escalar_concluido_read()) {
        timeout++;
        if(timeout > 1000000) {
            printf("\nTimeout! Hardware não respondeu.\n");
            return;
        }
    }
    printf(" Concluído!\n");

    // ✅ CORREÇÃO: LEITURA E CONVERSÃO CORRETA
    uint32_t resultado_raw = produto_escalar_resultado_read();
    int32_t resultado_signed = (int32_t)resultado_raw;  // Conversão para signed
    
    printf("Resultado (hardware): %ld (0x%08lx)\n", 
           (long)resultado_signed, (unsigned long)resultado_raw);

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
        printf("SUCESSO! Hardware e software coincidem! \n");
    } else {
        printf("ERRO! Resultados diferentes! \n");
        printf("Hardware: %ld, Software: %ld\n", (long)resultado_signed, (long)verif);
    }
}

static void debug_csr(void) {
    printf("=== DEBUG CSR ===\n");
    
    // Verifica quais CSRs existem
#ifdef CSR_PRODUTO_ESCALAR_RESULTADO_HI_ADDR
    printf("RESULTADO_HI_ADDR definido: 0x%08lx\n", (unsigned long)CSR_PRODUTO_ESCALAR_RESULTADO_HI_ADDR);
#else
    printf("RESULTADO_HI_ADDR NÃO definido\n");
#endif

#ifdef CSR_PRODUTO_ESCALAR_RESULTADO_LO_ADDR
    printf("RESULTADO_LO_ADDR definido: 0x%08lx\n", (unsigned long)CSR_PRODUTO_ESCALAR_RESULTADO_LO_ADDR);
#else
    printf("RESULTADO_LO_ADDR NÃO definido\n");
#endif

#ifdef CSR_PRODUTO_ESCALAR_RESULTADO_ADDR
    printf("RESULTADO_ADDR definido: 0x%08lx\n", (unsigned long)CSR_PRODUTO_ESCALAR_RESULTADO_ADDR);
#else
    printf("RESULTADO_ADDR NÃO definido\n");
#endif

    // Testa leitura múltipla
    printf("Teste leitura múltipla:\n");
    for(int i = 0; i < 4; i++) {
        uint32_t val = produto_escalar_resultado_read();
        printf("  Leitura %d: 0x%08lx (%lu)\n", i, (unsigned long)val, (unsigned long)val);
    }
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
    else if(strcmp(token, "led") == 0)
        toggle_led();
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

    printf("\n=== Sistema LiteX com Produto Escalar ===\n");
    help();
    prompt();

    while(1) {
        console_service();
    }

    return 0;
}
