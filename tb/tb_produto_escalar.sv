// tb/tb_produto_escalar.sv
`timescale 1ns/1ps

module tb_produto_escalar;

    // sinais do DUT
    logic clk;
    logic rst_n;
    logic iniciar;
    logic [31:0] a0, a1, a2, a3, a4, a5, a6, a7;
    logic [31:0] b0, b1, b2, b3, b4, b5, b6, b7;
    logic concluido;
    logic [63:0] resultado;

    // instanciar DUT
    produto_escalar dut (
        .clk_i(clk),
        .rst_n(rst_n),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3), .a4(a4), .a5(a5), .a6(a6), .a7(a7),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3), .b4(b4), .b5(b5), .b6(b6), .b7(b7),
        .iniciar(iniciar),
        .concluido(concluido),
        .resultado(resultado)
    );

    // clock 
    initial clk = 0;
    always #5 clk = ~clk;

    // gerar VCD file
    initial begin
        $dumpfile("produto_escalar.vcd");
        $dumpvars(0, tb_produto_escalar);
    end

    // estímulos
    initial begin
        integer timeout;
        
        // reset
        rst_n = 0;
        iniciar = 0;
        {a0, a1, a2, a3, a4, a5, a6, a7} = '0;
        {b0, b1, b2, b3, b4, b5, b6, b7} = '0;
        #20;
        rst_n = 1;

        // Teste 1: vetores iguais [1,2,3,4,5,6,7,8]
        $display("=== Teste 1 ===");
        a0=32'd1; a1=32'd2; a2=32'd3; a3=32'd4;
        a4=32'd5; a5=32'd6; a6=32'd7; a7=32'd8;
        b0=32'd1; b1=32'd2; b2=32'd3; b3=32'd4;
        b4=32'd5; b5=32'd6; b6=32'd7; b7=32'd8;

        #10;
        iniciar = 1;
        #10;
        iniciar = 0;

        // Esperar com timeout
        timeout = 0;
        while (concluido == 0 && timeout < 100) begin
            #10;
            timeout = timeout + 1;
        end
        
        if (concluido == 0) begin
            $display("ERRO: Timeout no Teste 1!");
            $finish;
        end

        // Verificar resultado esperado: 1²+2²+3²+4²+5²+6²+7²+8² = 204
        $display("Resultado: %d, Esperado: 204", resultado);
        if (resultado !== 64'd204) begin
            $display("ERRO: Resultado incorreto no Teste 1!");
        end else begin
            $display("SUCESSO: Teste 1 passou!");
        end

        // Aguardar ciclo completo antes do próximo teste
        #30;

        // Teste 2: vetores com números positivos e negativos
        $display("\n=== Teste 2 ===");
        a0=32'd1; a1=-32'd1; a2=32'd2; a3=-32'd2;
        a4=32'd3; a5=-32'd3; a6=32'd4; a7=-32'd4;
        b0=32'd1; b1=32'd1; b2=32'd2; b3=32'd2;
        b4=32'd3; b5=32'd3; b6=32'd4; b7=32'd4;

        #10;
        iniciar = 1;
        #10;
        iniciar = 0;

        // Esperar com timeout
        timeout = 0;
        while (concluido == 0 && timeout < 100) begin
            #10;
            timeout = timeout + 1;
        end
        
        if (concluido == 0) begin
            $display("ERRO: Timeout no Teste 2!");
            $finish;
        end

        // Verificar resultado: (1*1) + (-1*1) + (2*2) + (-2*2) + (3*3) + (-3*3) + (4*4) + (-4*4) = 0
        $display("Resultado: %d, Esperado: 0", resultado);
        if (resultado !== 64'd0) begin
            $display("ERRO: Resultado incorreto no Teste 2!");
        end else begin
            $display("SUCESSO: Teste 2 passou!");
        end

        #50;
        $display("\n=== Simulação concluída ===");
        $finish;
    end

endmodule