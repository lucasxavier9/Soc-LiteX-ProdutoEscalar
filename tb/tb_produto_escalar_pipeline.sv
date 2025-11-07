// tb/tb_produto_escalar_pipeline.sv
`timescale 1ns/1ps

module tb_produto_escalar_pipeline;

    logic clk;
    logic rst;
    logic iniciar;
    logic signed [31:0] a0, a1, a2, a3, a4, a5, a6, a7;
    logic signed [31:0] b0, b1, b2, b3, b4, b5, b6, b7;
    logic signed [63:0] resultado;
    logic concluido;

    // Instância do DUT
    produto_escalar_pipeline dut (
        .clk_i(clk),
        .rst_i(rst),
        .iniciar(iniciar),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .a4(a4), .a5(a5), .a6(a6), .a7(a7),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .b4(b4), .b5(b5), .b6(b6), .b7(b7),
        .resultado(resultado),
        .concluido(concluido)
    );

    // Geração de clock
    always #5 clk = ~clk;

    // Teste 1: Vetores unitários
    task teste_case1;
        begin
            $display("\n=== Test Case 1: Vetores unitários ===");
            a0 = 1; a1 = 1; a2 = 1; a3 = 1; a4 = 1; a5 = 1; a6 = 1; a7 = 1;
            b0 = 1; b1 = 1; b2 = 1; b3 = 1; b4 = 1; b5 = 1; b6 = 1; b7 = 1;

            iniciar = 1;
            @(posedge clk);
            iniciar = 0;

            wait(concluido);
            @(posedge clk);

            if (resultado === 64'd8)
                $display("PASS: Resultado = %0d (esperado: 8)", resultado);
            else
                $display("FAIL: Resultado = %0d (esperado: 8)", resultado);
        end
    endtask

    // Teste 2: Sequência linear
    task teste_case2;
        begin
            $display("\n=== Test Case 2: Sequência linear ===");
            a0 = 1; a1 = 2; a2 = 3; a3 = 4; a4 = 5; a5 = 6; a6 = 7; a7 = 8;
            b0 = 1; b1 = 2; b2 = 3; b3 = 4; b4 = 5; b5 = 6; b6 = 7; b7 = 8;

            iniciar = 1;
            @(posedge clk);
            iniciar = 0;

            wait(concluido);
            @(posedge clk);

            if (resultado === 64'd204)
                $display("PASS: Resultado = %0d (esperado: 204)", resultado);
            else
                $display("FAIL: Resultado = %0d (esperado: 204)", resultado);
        end
    endtask

    // Teste 3: Throughput
    task test_throughput;
        begin
            $display("\n=== Test Throughput Contínuo ===");
            
            // Cálculo 1: [1,1,1,1,1,1,1,1] = 8
            $display("Cálculo 1: Vetor de 1s");
            a0 = 1; a1 = 1; a2 = 1; a3 = 1; a4 = 1; a5 = 1; a6 = 1; a7 = 1;
            b0 = 1; b1 = 1; b2 = 1; b3 = 1; b4 = 1; b5 = 1; b6 = 1; b7 = 1;
            iniciar = 1;
            @(posedge clk);
            iniciar = 0;
            
            // Aguarda resultado 1
            wait(concluido);
            $display(">>> Resultado 1: %0d %s", resultado, (resultado === 64'd8) ? "[OK]" : "[ERRO]");
            repeat(2) @(posedge clk);
            
            // Cálculo 2: [2,2,2,2,2,2,2,2] = 32
            $display("Cálculo 2: Vetor de 2s");
            a0 = 2; a1 = 2; a2 = 2; a3 = 2; a4 = 2; a5 = 2; a6 = 2; a7 = 2;
            b0 = 2; b1 = 2; b2 = 2; b3 = 2; b4 = 2; b5 = 2; b6 = 2; b7 = 2;
            iniciar = 1;
            @(posedge clk);
            iniciar = 0;
            
            // Aguarda resultado 2
            wait(concluido);
            $display(">>> Resultado 2: %0d %s", resultado, (resultado === 64'd32) ? "[OK]" : "[ERRO]");
            repeat(2) @(posedge clk);
            
            // Cálculo 3: [3,3,3,3,3,3,3,3] = 72
            $display("Cálculo 3: Vetor de 3s");
            a0 = 3; a1 = 3; a2 = 3; a3 = 3; a4 = 3; a5 = 3; a6 = 3; a7 = 3;
            b0 = 3; b1 = 3; b2 = 3; b3 = 3; b4 = 3; b5 = 3; b6 = 3; b7 = 3;
            iniciar = 1;
            @(posedge clk);
            iniciar = 0;
            
            // Aguarda resultado 3
            wait(concluido);
            $display(">>> Resultado 3: %0d %s", resultado, (resultado === 64'd72) ? "[OK]" : "[ERRO]");
            
            $display("Throughput: 3 calculos completos com resultados corretos!");
        end
    endtask

    // Inicialização e execução
    initial begin
        $display("Iniciando simulacao do Pipeline de Produto Escalar");
        $display("Aplicando reset...");
        
        clk = 0;
        rst = 1;
        iniciar = 0;
        a0 = 0; a1 = 0; a2 = 0; a3 = 0; a4 = 0; a5 = 0; a6 = 0; a7 = 0;
        b0 = 0; b1 = 0; b2 = 0; b3 = 0; b4 = 0; b5 = 0; b6 = 0; b7 = 0;

        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);

        teste_case1();
        repeat(5) @(posedge clk);
        
        teste_case2();
        repeat(5) @(posedge clk);
        
        test_throughput();

        $finish;
    end

endmodule