// rtl/produto_escalar_pipeline.sv
module produto_escalar_pipeline (
    input  clk_i,
    input  rst_i,
    input  iniciar,
    input  [31:0] a0, a1, a2, a3, a4, a5, a6, a7,
    input  [31:0] b0, b1, b2, b3, b4, b5, b6, b7,
    output reg [63:0] resultado,
    output reg concluido
);

// Estágio 0: Registro das entradas
reg signed [31:0] a_registrado [0:7];
reg signed [31:0] b_registrado [0:7];
reg iniciar_estagio0;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        iniciar_estagio0 <= 0;
        for (int i = 0; i < 8; i++) begin
            a_registrado[i] <= 0;
            b_registrado[i] <= 0;
        end
    end else begin
        a_registrado[0] <= a0; b_registrado[0] <= b0;
        a_registrado[1] <= a1; b_registrado[1] <= b1;
        a_registrado[2] <= a2; b_registrado[2] <= b2;
        a_registrado[3] <= a3; b_registrado[3] <= b3;
        a_registrado[4] <= a4; b_registrado[4] <= b4;
        a_registrado[5] <= a5; b_registrado[5] <= b5;
        a_registrado[6] <= a6; b_registrado[6] <= b6;
        a_registrado[7] <= a7; b_registrado[7] <= b7;
        iniciar_estagio0 <= iniciar;
    end
end

// Estágio 1: Multiplicações (registradas)
reg signed [63:0] produto_registrado [0:7];
reg iniciar_estagio1;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        iniciar_estagio1 <= 0;
        for (int i = 0; i < 8; i++) begin
            produto_registrado[i] <= 0;
        end
    end else begin
        for (int i = 0; i < 8; i++) begin
            produto_registrado[i] <= a_registrado[i] * b_registrado[i];
        end
        iniciar_estagio1 <= iniciar_estagio0;
    end
end

// Estágio 2: Primeiro nível de soma (registrado)
reg signed [63:0] soma_estagio2 [0:3];
reg iniciar_estagio2;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        iniciar_estagio2 <= 0;
        for (int i = 0; i < 4; i++) begin
            soma_estagio2[i] <= 0;
        end
    end else begin
        soma_estagio2[0] <= produto_registrado[0] + produto_registrado[1];
        soma_estagio2[1] <= produto_registrado[2] + produto_registrado[3];
        soma_estagio2[2] <= produto_registrado[4] + produto_registrado[5];
        soma_estagio2[3] <= produto_registrado[6] + produto_registrado[7];
        iniciar_estagio2 <= iniciar_estagio1;
    end
end

// Estágio 3: Segundo nível de soma (registrado)
reg signed [63:0] soma_estagio3 [0:1];
reg iniciar_estagio3;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        iniciar_estagio3 <= 0;
        for (int i = 0; i < 2; i++) begin
            soma_estagio3[i] <= 0;
        end
    end else begin
        soma_estagio3[0] <= soma_estagio2[0] + soma_estagio2[1];
        soma_estagio3[1] <= soma_estagio2[2] + soma_estagio2[3];
        iniciar_estagio3 <= iniciar_estagio2;
    end
end

// Estágio 4: Controle com timing correto
reg [3:0] atraso_pipeline;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        resultado <= 0;
        atraso_pipeline <= 0;
    end else begin
        // Calcula o resultado
        resultado <= soma_estagio3[0] + soma_estagio3[1];
        
        // Controle de delay do pipeline
        if (iniciar) begin
            atraso_pipeline <= 4'b0001;  // Inicia contagem
        end else if (atraso_pipeline != 0) begin
            atraso_pipeline <= {atraso_pipeline[2:0], 1'b0};  // Desloca
        end
    end
end

// Isso garante que o resultado já está registrado
reg atraso_pipeline_anterior;
always @(posedge clk_i) begin
    atraso_pipeline_anterior <= atraso_pipeline[3];
end

assign concluido = !atraso_pipeline[3] && atraso_pipeline_anterior;

// Debug: Monitoramento do pipeline
always @(posedge clk_i) begin
    if (iniciar_estagio0) begin
        $display("ESTAGIO0: Entradas registradas");
    end
    if (iniciar_estagio1) begin
        $display("ESTAGIO1: Multiplicações calculadas");
        for (int i = 0; i < 8; i++) begin
            $display("  produto[%0d] = %0d", i, $signed(produto_registrado[i]));
        end
    end
    if (iniciar_estagio2) begin
        $display("ESTAGIO2: Somas parciais = [%0d, %0d, %0d, %0d]", 
                 $signed(soma_estagio2[0]), $signed(soma_estagio2[1]),
                 $signed(soma_estagio2[2]), $signed(soma_estagio2[3]));
    end
    if (iniciar_estagio3) begin
        $display("ESTAGIO3: Somas intermediárias = [%0d, %0d]",
                 $signed(soma_estagio3[0]), $signed(soma_estagio3[1]));
    end
    if (concluido) begin
        $display(">>> RESULTADO FINAL: %0d (ciclo %0d) <<<", $signed(resultado), $time);
        $display("----------------------------------------");
    end
end

endmodule