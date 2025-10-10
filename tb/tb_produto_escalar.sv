`timescale 1ns/1ps

module tb_produto_escalar;

    // Clock
    logic clk = 0;
    always #5 clk = ~clk; // 100 MHz

    // Reset ativo alto
    logic rst_i;

    // Sinais do DUT
    logic iniciar;
    logic concluido;
    logic [63:0] resultado;

    logic [31:0] a0, a1, a2, a3, a4, a5, a6, a7;
    logic [31:0] b0, b1, b2, b3, b4, b5, b6, b7;

    // Instancia o DUT
    produto_escalar dut (
        .clk_i(clk),
        .rst_i(rst_i),
        .iniciar(iniciar),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3), .a4(a4), .a5(a5), .a6(a6), .a7(a7),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3), .b4(b4), .b5(b5), .b6(b6), .b7(b7),
        .concluido(concluido),
        .resultado(resultado)
    );

    // VCD dump
    initial begin
        $dumpfile("produto_escalar.vcd");
        $dumpvars(0, tb_produto_escalar);
    end

    // Simulação
    initial begin
        // Inicialização
        rst_i = 1;  // reset ativo
        iniciar = 0;
        a0=0; a1=0; a2=0; a3=0; a4=0; a5=0; a6=0; a7=0;
        b0=0; b1=0; b2=0; b3=0; b4=0; b5=0; b6=0; b7=0;
        #20; 
        rst_i = 0;  // desativa reset
        #10;

        // --- Teste 1: Positivos ---
        a0=1; a1=2; a2=3; a3=4; a4=5; a5=6; a6=7; a7=8;
        b0=1; b1=2; b2=3; b3=4; b4=5; b5=6; b6=7; b7=8;
        iniciar = 1; @(posedge clk); iniciar = 0;
        wait(concluido); @(posedge clk);
        $display("\n=== Teste 1 - Positivos ===");
        $display("Resultado: %0d | Esperado: %0d", $signed(resultado), 204);

        // --- Teste 2: Negativos ---
        rst_i = 1; @(posedge clk); @(posedge clk); rst_i = 0; @(posedge clk);
        a0=-1; a1=-2; a2=-3; a3=-4; a4=-5; a5=-6; a6=-7; a7=-8;
        b0=-1; b1=-2; b2=-3; b3=-4; b4=-5; b5=-6; b6=-7; b7=-8;
        iniciar = 1; @(posedge clk); iniciar = 0;
        wait(concluido); @(posedge clk);
        $display("\n=== Teste 2 - Negativos ===");
        $display("Resultado: %0d | Esperado: %0d", $signed(resultado), 204);

        // --- Teste 3: Opostos ---
        rst_i = 1; @(posedge clk); @(posedge clk); rst_i = 0; @(posedge clk);
        a0=1; a1=2; a2=3; a3=4; a4=5; a5=6; a6=7; a7=8;
        b0=-1; b1=-2; b2=-3; b3=-4; b4=-5; b5=-6; b6=-7; b7=-8;
        iniciar = 1; @(posedge clk); iniciar = 0;
        wait(concluido); @(posedge clk);
        $display("\n=== Teste 3 - Opostos ===");
        $display("Resultado: %0d | Esperado: %0d", $signed(resultado), -204);

        #50;
        $display("\n=== Simulação Concluída ===");
        $finish;
    end

endmodule

