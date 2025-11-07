// tb/tb_produto_escalar_pipeline.sv
`timescale 1ns/1ps

module tb_produto_escalar;

    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_i, iniciar, concluido;
    reg [63:0] resultado;
    reg [31:0] a0,a1,a2,a3,a4,a5,a6,a7;
    reg [31:0] b0,b1,b2,b3,b4,b5,b6,b7;

    produto_escalar_pipeline dut (
        .clk_i(clk),
        .rst_i(rst_i),
        .iniciar(iniciar),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .a4(a4), .a5(a5), .a6(a6), .a7(a7),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .b4(b4), .b5(b5), .b6(b6), .b7(b7),
        .resultado(resultado),
        .concluido(concluido)
    );

    initial begin
        $dumpfile("produto_escalar_pipeline.vcd");
        $dumpvars(0, tb_produto_escalar);
    end

    task testar;
        input [31:0] a0_in, a1_in, a2_in, a3_in, a4_in, a5_in, a6_in, a7_in;
        input [31:0] b0_in, b1_in, b2_in, b3_in, b4_in, b5_in, b6_in, b7_in;
        input integer esperado;
        input [80:0] nome;
        
        integer ciclo;
        begin
            // Aplica vetores
            a0 = a0_in; a1 = a1_in; a2 = a2_in; a3 = a3_in;
            a4 = a4_in; a5 = a5_in; a6 = a6_in; a7 = a7_in;
            b0 = b0_in; b1 = b1_in; b2 = b2_in; b3 = b3_in;
            b4 = b4_in; b5 = b5_in; b6 = b6_in; b7 = b7_in;

            @(posedge clk);
            
            $display("=== INICIANDO TESTE: %s ===", nome);
            $display("Aplicando sinal de iniciar...");
            
            // Pulso de iniciar
            iniciar = 1;
            @(posedge clk);
            iniciar = 0;

            ciclo = 1;
            while (!concluido && ciclo < 10) begin
                @(posedge clk);
                ciclo = ciclo + 1;
            end

            @(posedge clk);
            $display("=== RESULTADO %s ===", nome);
            $display("Ciclos totais: %0d", ciclo);
            $display("Resultado (HW): %0d | Esperado (SW): %0d", $signed(resultado), esperado);
            if ($signed(resultado) == esperado) 
                $display("TESTE PASSOU!");
            else 
                $display("TESTE FALHOU! Diferença: %0d", $signed(resultado) - esperado);
            $display("");
        end
    endtask

initial begin
        // Inicialização
        rst_i = 1; 
        iniciar = 0;
        a0=0; a1=0; a2=0; a3=0; a4=0; a5=0; a6=0; a7=0;
        b0=0; b1=0; b2=0; b3=0; b4=0; b5=0; b6=0; b7=0;
        
        $display("Fase 1: Reset ativo");
        repeat(3) @(posedge clk);
        rst_i = 0;
        repeat(2) @(posedge clk);
        $display("Fase 2: Reset liberado");

        // Teste 1: Positivos
        testar(1,2,3,4,5,6,7,8, 1,2,3,4,5,6,7,8, 204, "Teste 1 - Positivos");

        // Reset entre testes
        rst_i = 1; @(posedge clk); rst_i = 0; @(posedge clk);

        // Teste 2: Zeros
        testar(0,0,0,0,0,0,0,0, 1,2,3,4,5,6,7,8, 0, "Teste 2 - Zeros");

        // Reset entre testes
        rst_i = 1; @(posedge clk); rst_i = 0; @(posedge clk);

        // Teste 3: Negativos
        testar(-1,-2,-3,-4,-5,-6,-7,-8, -1,-2,-3,-4,-5,-6,-7,-8, 204, "Teste 3 - Negativos");

        // Reset entre testes
        rst_i = 1; @(posedge clk); rst_i = 0; @(posedge clk);

        // Teste 4: Opostos
        testar(1,2,3,4,5,6,7,8, -1,-2,-3,-4,-5,-6,-7,-8, -204, "Teste 4 - Opostos");

        $finish;
    end

  

endmodule