// tb/tb_produto_escalar_pipeline_com_medicao.sv
`timescale 1ns/1ps

module tb_produto_escalar_pipeline_com_medicao;

    logic clk;
    logic rst;
    logic iniciar;
    logic signed [31:0] a0, a1, a2, a3, a4, a5, a6, a7;
    logic signed [31:0] b0, b1, b2, b3, b4, b5, b6, b7;
    logic signed [63:0] resultado;
    logic concluido;
    
    // Sinais de medição
    logic [31:0] latency_cycles;
    logic [31:0] total_operations;
    logic measurement_valid;

    // Instância do DUT com medição
    produto_escalar_pipeline_com_medicao dut (
        .clk_i(clk),
        .rst_i(rst),
        .iniciar(iniciar),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .a4(a4), .a5(a5), .a6(a6), .a7(a7),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .b4(b4), .b5(b5), .b6(b6), .b7(b7),
        .resultado(resultado),
        .concluido(concluido),
        .latency_cycles(latency_cycles),
        .total_operations(total_operations),
        .measurement_valid(measurement_valid)
    );

    // Geração de clock
    always #5 clk = ~clk;  // 100MHz para teste

    // Variáveis de medição
    real total_time_ns = 0;
    int total_ops = 0;
    real clock_period_ns = 10.0;  // 100MHz = 10ns período

    task report_performance;
        input string test_name;
        input int measured_latency;
        begin
            real throughput_mops;
            real efficiency;
            
            throughput_mops = (total_ops * 1000.0) / total_time_ns;  // MOPS
            efficiency = throughput_mops / (clock_period_ns * 0.1);   // MOPS/MHz
            
            $display("\n[%s] RELATORIO DE PERFORMANCE:", test_name);
            $display("   Latencia medida: %0d ciclos", measured_latency);
            $display("   Throughput: %.2f MOPS", throughput_mops);
            $display("   Eficiencia: %.2f MOPS/MHz", efficiency);
            $display("   Tempo total: %.2f ns", total_time_ns);
            $display("   Operacoes completas: %0d", total_ops);
        end
    endtask

    // Teste com medição de latência
    task teste_com_medicao;
        input string test_name;
        input int expected_result;
        begin
            int start_time, end_time;
            int measured_latency;
            
            $display("\n=== %s ===", test_name);
            
            // Configura vetores de teste
            if (test_name == "Vetores Unitarios") begin
                a0 = 1; a1 = 1; a2 = 1; a3 = 1; a4 = 1; a5 = 1; a6 = 1; a7 = 1;
                b0 = 1; b1 = 1; b2 = 1; b3 = 1; b4 = 1; b5 = 1; b6 = 1; b7 = 1;
            end else if (test_name == "Sequencia Linear") begin
                a0 = 1; a1 = 2; a2 = 3; a3 = 4; a4 = 5; a5 = 6; a6 = 7; a7 = 8;
                b0 = 1; b1 = 2; b2 = 3; b3 = 4; b4 = 5; b5 = 6; b6 = 7; b7 = 8;
            end
            
            start_time = $time;
            iniciar = 1;
            @(posedge clk);
            iniciar = 0;

            // Aguarda medição
            wait(measurement_valid);
            end_time = $time;
            
            measured_latency = latency_cycles;
            total_time_ns = (end_time - start_time);
            total_ops = total_operations;
            
            // Verifica resultado
            if (resultado === expected_result)
                $display("PASS: Resultado = %0d", resultado);
            else
                $display("FAIL: Resultado = %0d (esperado: %0d)", resultado, expected_result);
            
            report_performance(test_name, measured_latency);
        end
    endtask

    // Inicialização e execução
    initial begin
        $display("Iniciando simulacao com medicao de performance");
        $display("Periodo de clock: %.1f ns (%.0f MHz)", clock_period_ns, 1000.0/clock_period_ns);
        
        // Inicialização
        clk = 0;
        rst = 1;
        iniciar = 0;
        a0 = 0; a1 = 0; a2 = 0; a3 = 0; a4 = 0; a5 = 0; a6 = 0; a7 = 0;
        b0 = 0; b1 = 0; b2 = 0; b3 = 0; b4 = 0; b5 = 0; b6 = 0; b7 = 0;

        // Reset
        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Testes individuais com medição
        teste_com_medicao("Vetores Unitarios", 8);
        repeat(5) @(posedge clk);
        
        teste_com_medicao("Sequencia Linear", 204);
        repeat(5) @(posedge clk);

        $display("\nSimulacao concluida com sucesso!");
        $finish;
    end

    // Monitor de eventos
    initial begin
        forever begin
            @(posedge measurement_valid);
            $display("[MEDICAO] Latencia=%0d ciclos, Ops=%0d", 
                     latency_cycles, total_operations);
        end
    end

endmodule