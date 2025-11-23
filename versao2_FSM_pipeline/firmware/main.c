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
static void relatorio_completo(void);
static void debug_csr(void);

// === VARIÁVEIS GLOBAIS ===
static int32_t vetor_a_global[8] = {0, 0, 0, 0, 0, 0, 0, 0};
static int32_t vetor_b_global[8] = {0, 0, 0, 0, 0, 0, 0, 0};
static int vetores_definidos = 0;

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
    puts("|  relatorio_completo              - Relatório completo  |");
    puts("=========================================================");
}

static void reboot(void)
{
    ctrl_reset_write(1);
}

// FUNÇÃO CÁLCULO PRODUTO ESCALAR
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
        vetor_a_global[i] = a[i];
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
        vetor_b_global[i] = b[i];
    }

    vetores_definidos = 1;

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
    
    // LEITURA E CONVERSÃO 
    uint32_t resultado_raw = produto_escalar_resultado_read();
    int32_t resultado_signed = (int32_t)resultado_raw;  // Conversão para signed
    
    printf("Resultado Hardware: %ld (0x%08lx)\n", 
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
        printf("SUCESSO! Hardware e software coincidem!");
    } else {
        printf("ERRO! Resultados diferentes!");
        printf("   Hardware: %ld, Software: %ld\n", (long)resultado_signed, (long)verif);
    }
    
    printf("\n");
}

// FUNÇÃO RELATÓRIO COMPLETO
static void relatorio_completo(void) {
    printf("\n");
    printf("=========================================================\n");
    printf("|              RELATÓRIO COMPLETO - VERSÃO 2            |\n");
    printf("=========================================================\n");
    printf("|              ARQUITETURA: PIPELINE BÁSICO             |\n");
    printf("=========================================================\n");
    
    if (!vetores_definidos) {
        printf("\n AVISO: Execute 'produto_escalar' primeiro para definir os vetores!\n");
        printf("Relatório não pode ser gerado sem dados de entrada.\n");
        printf("\n=========================================================\n");
        printf("|               RELATÓRIO CANCELADO                     |\n");
        printf("=========================================================\n");
        return;
    }
    
    // EXECUTA O PRODUTO ESCALAR COM OS VETORES GLOBAIS
    printf("\n--- EXECUÇÃO DO PRODUTO ESCALAR ---\n");
    
    printf("Vetor A: ");
    for(int i = 0; i < 8; i++) printf("%ld ", (long)vetor_a_global[i]);
    printf("\nVetor B: ");
    for(int i = 0; i < 8; i++) printf("%ld ", (long)vetor_b_global[i]);
    printf("\n");
    
    // Escreve vetores nos registradores
    produto_escalar_vetor_a0_write(vetor_a_global[0]);
    produto_escalar_vetor_a1_write(vetor_a_global[1]);
    produto_escalar_vetor_a2_write(vetor_a_global[2]);
    produto_escalar_vetor_a3_write(vetor_a_global[3]);
    produto_escalar_vetor_a4_write(vetor_a_global[4]);
    produto_escalar_vetor_a5_write(vetor_a_global[5]);
    produto_escalar_vetor_a6_write(vetor_a_global[6]);
    produto_escalar_vetor_a7_write(vetor_a_global[7]);

    produto_escalar_vetor_b0_write(vetor_b_global[0]);
    produto_escalar_vetor_b1_write(vetor_b_global[1]);
    produto_escalar_vetor_b2_write(vetor_b_global[2]);
    produto_escalar_vetor_b3_write(vetor_b_global[3]);
    produto_escalar_vetor_b4_write(vetor_b_global[4]);
    produto_escalar_vetor_b5_write(vetor_b_global[5]);
    produto_escalar_vetor_b6_write(vetor_b_global[6]);
    produto_escalar_vetor_b7_write(vetor_b_global[7]);
    
    // Reseta medições anteriores
    produto_escalar_iniciar_write(0);
    for(volatile int d = 0; d < 1000; d++);
    
    // Lê valores ANTES da execução
    uint32_t latency_before = produto_escalar_latency_cycles_read();
    uint32_t total_ops_before = produto_escalar_total_operations_read();
    
    printf("Estado antes: latency=%ld, ops=%ld\n", 
           (long)latency_before, (long)total_ops_before);
    
    // Executa operação
    produto_escalar_iniciar_write(1);
    for(volatile int d = 0; d < 100; d++);
    produto_escalar_iniciar_write(0);
    
    // Aguarda processamento
    printf("Processando");
    uint32_t timeout = 0;
    int concluido_flag = 0;
    
    for(int i = 0; i < 20; i++) {
        for(volatile int d = 0; d < 50000; d++);
        
        if (produto_escalar_concluido_read()) {
            concluido_flag = 1;
            break;
        }
        printf(".");
    }
    
    if (concluido_flag) {
        printf(" Concluído!\n");
    } else {
        printf(" TIMEOUT! Continuando...\n");
    }
    
    // Pequena pausa para garantir medição
    for(volatile int d = 0; d < 10000; d++);
    
    // Lê resultados APÓS execução
    uint32_t resultado_hw = produto_escalar_resultado_read();
    uint32_t latency_after = produto_escalar_latency_cycles_read();
    uint32_t total_ops_after = produto_escalar_total_operations_read();
    uint32_t measurement_valid = produto_escalar_measurement_valid_read();
    
    // MEDIÇÕES DE PERFORMANCE 
    printf("\n--- MEDIÇÕES DE PERFORMANCE ---\n");
    
    uint32_t clock_freq = 60; 
    
    printf("Resultado: %ld\n", (long)resultado_hw);
    printf("Latência medida: %ld ciclos\n", (long)latency_after);
    printf("Operações totais: %ld\n", (long)total_ops_after);
    printf("Medição válida: %s\n", measurement_valid ? "SIM" : "NÃO");
    
    // SÓ CALCULA SE MEDIÇÃO FOR VÁLIDA
    if (measurement_valid && latency_after > 0 && total_ops_after > 0) {
        uint32_t throughput_mops = (total_ops_after * clock_freq) / latency_after;
        uint32_t time_total = (latency_after * 1000) / clock_freq;

        uint32_t time_per_op_x10 = (latency_after * 10000) / (clock_freq * total_ops_after);
        uint32_t time_per_op_int = time_per_op_x10 / 10;
        uint32_t time_per_op_frac = time_per_op_x10 % 10;
        
        uint32_t efficiency_x100 = (throughput_mops * 100) / clock_freq;
        
        printf("Throughput medido: %ld MOPS\n", (long)throughput_mops);
        printf("Eficiência: %ld.%02ld MOPS/MHz\n", 
               efficiency_x100 / 100, efficiency_x100 % 100);
        printf("Tempo total: %ld ns\n", (long)time_total);
        printf("Tempo por operação: %ld.%ld ns\n", (long)time_per_op_int, (long)time_per_op_frac);
        
    } else {
        printf(" DADOS DE MEDIÇÃO INVÁLIDOS - RELATÓRIO INCOMPLETO\n");
        return;
    }
    
    // VERIFICAÇÃO
    printf("\n--- VERIFICAÇÃO ---\n");
        
    int32_t verif = 0;
    for(int i = 0; i < 8; i++) {
        verif += vetor_a_global[i] * vetor_b_global[i];
    }
    
    printf("Resultado esperado: %ld\n", (long)verif);
    printf("Resultado obtido: %ld\n", (long)resultado_hw);
    printf("Status: %s\n", (resultado_hw == verif) ? "CORRETO" : "ERRO");
    
    // RESUMO PARA TCC - MESMO FORMATO SIMPLES
    printf("\n--- RESUMO PARA TCC ---\n");
    printf("Arquitetura: Pipeline Básico (Versão 2)\n");
    printf("Clock: %ld MHz\n", (long)clock_freq);
    printf("Latência medida: %ld ciclos\n", (long)latency_after);
    
    uint32_t real_operations = 8; // 8 multiplicações para produto escalar
    uint32_t throughput_mops = (real_operations * clock_freq) / latency_after;
    uint32_t efficiency_x100 = (throughput_mops * 100) / clock_freq;
    
    printf("Throughput real: %ld MOPS\n", (long)throughput_mops);
    printf("Eficiência real: %ld.%02ld MOPS/MHz\n", 
           efficiency_x100 / 100, efficiency_x100 % 100);
    
    uint32_t ideal_throughput = clock_freq;
    uint32_t performance_percent = (throughput_mops * 100) / ideal_throughput;
    printf("Throughput ideal: %ld MOPS (1 op/ciclo)\n", (long)ideal_throughput);
    printf("Performance: %ld%% do throughput ideal\n", (long)performance_percent);
    
    printf("\n=========================================================\n");
    printf("|               RELATÓRIO CONCLUÍDO                     |\n");
    printf("=========================================================\n");
}

static void debug_csr(void) {
    printf("=== DEBUG CSR ===\n");
    
    // Verifica quais CSRs existem
#ifdef CSR_PRODUTO_ESCALAR_LATENCY_CYCLES_ADDR
    printf("LATENCY_CYCLES_ADDR definido: 0x%08lx\n", (unsigned long)CSR_PRODUTO_ESCALAR_LATENCY_CYCLES_ADDR);
#else
    printf("LATENCY_CYCLES_ADDR NÃO definido\n");
#endif

#ifdef CSR_PRODUTO_ESCALAR_TOTAL_OPERATIONS_ADDR
    printf("TOTAL_OPERATIONS_ADDR definido: 0x%08lx\n", (unsigned long)CSR_PRODUTO_ESCALAR_TOTAL_OPERATIONS_ADDR);
#else
    printf("TOTAL_OPERATIONS_ADDR NÃO definido\n");
#endif

#ifdef CSR_PRODUTO_ESCALAR_MEASUREMENT_VALID_ADDR
    printf("MEASUREMENT_VALID_ADDR definido: 0x%08lx\n", (unsigned long)CSR_PRODUTO_ESCALAR_MEASUREMENT_VALID_ADDR);
#else
    printf("MEASUREMENT_VALID_ADDR NÃO definido\n");
#endif

    // Testa leitura múltipla
    printf("Teste leitura múltipla:\n");
    for(int i = 0; i < 4; i++) {
        uint32_t val = produto_escalar_resultado_read();
        printf("  Leitura %d: 0x%08lx (%lu)\n", i, (unsigned long)val, (unsigned long)val);
    }
    
    // Testa leitura das CSRs de medição
    printf("Leitura CSRs de medição:\n");
    printf("  latency_cycles: 0x%08lx\n", (unsigned long)produto_escalar_latency_cycles_read());
    printf("  total_operations: 0x%08lx\n", (unsigned long)produto_escalar_total_operations_read());
    printf("  measurement_valid: 0x%08lx\n", (unsigned long)produto_escalar_measurement_valid_read());
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
    else if(strcmp(token, "relatorio_completo") == 0)
        relatorio_completo();   
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
    printf("=========================================================\n");
    printf("|              ARQUITETURA: PIPELINE BÁSICO             |\n");
    printf("=========================================================\n");
    
    help();
    prompt();

    while(1) {
        console_service();
    }

    return 0;
}