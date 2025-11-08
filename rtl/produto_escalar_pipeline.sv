// rtl/produto_escalar_pipeline_registrado.sv
module produto_escalar_pipeline (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        iniciar,
    input  logic signed [31:0] a0, a1, a2, a3, a4, a5, a6, a7,
    input  logic signed [31:0] b0, b1, b2, b3, b4, b5, b6, b7,
    output logic signed [63:0] resultado,
    output logic        concluido
);

    // ESTÁGIO 0 — Registro das entradas
    logic signed [31:0] a_registrado [0:7];
    logic signed [31:0] b_registrado [0:7];
    logic iniciar_estagio0;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            iniciar_estagio0 <= 1'b0;
            for (int i = 0; i < 8; i++) begin
                a_registrado[i] <= '0;
                b_registrado[i] <= '0;
            end
        end else begin
            iniciar_estagio0 <= iniciar;
            a_registrado[0] <= a0; b_registrado[0] <= b0;
            a_registrado[1] <= a1; b_registrado[1] <= b1;
            a_registrado[2] <= a2; b_registrado[2] <= b2;
            a_registrado[3] <= a3; b_registrado[3] <= b3;
            a_registrado[4] <= a4; b_registrado[4] <= b4;
            a_registrado[5] <= a5; b_registrado[5] <= b5;
            a_registrado[6] <= a6; b_registrado[6] <= b6;
            a_registrado[7] <= a7; b_registrado[7] <= b7;
        end
    end

    // ESTÁGIO 1 — Multiplicações
    logic signed [63:0] produto_registrado [0:7];
    logic iniciar_estagio1;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            iniciar_estagio1 <= 1'b0;
            for (int i = 0; i < 8; i++) begin
                produto_registrado[i] <= '0;
            end
        end else begin
            iniciar_estagio1 <= iniciar_estagio0;
            for (int i = 0; i < 8; i++) begin
                produto_registrado[i] <= a_registrado[i] * b_registrado[i];
            end
        end
    end

    // ESTÁGIO 2 — Primeiro nível de soma
    logic signed [63:0] soma_estagio2 [0:3];
    logic iniciar_estagio2;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            iniciar_estagio2 <= 1'b0;
            for (int i = 0; i < 4; i++) begin
                soma_estagio2[i] <= '0;
            end
        end else begin
            iniciar_estagio2 <= iniciar_estagio1;
            soma_estagio2[0] <= produto_registrado[0] + produto_registrado[1];
            soma_estagio2[1] <= produto_registrado[2] + produto_registrado[3];
            soma_estagio2[2] <= produto_registrado[4] + produto_registrado[5];
            soma_estagio2[3] <= produto_registrado[6] + produto_registrado[7];
        end
    end

    // ESTÁGIO 3 — Segundo nível de soma
    logic signed [63:0] soma_estagio3 [0:1];
    logic iniciar_estagio3;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            iniciar_estagio3 <= 1'b0;
            for (int i = 0; i < 2; i++) begin
                soma_estagio3[i] <= '0;
            end
        end else begin
            iniciar_estagio3 <= iniciar_estagio2;
            soma_estagio3[0] <= soma_estagio2[0] + soma_estagio2[1];
            soma_estagio3[1] <= soma_estagio2[2] + soma_estagio2[3];
        end
    end

    // ESTÁGIO 4 — Soma final e controle de pipeline
    logic [3:0] atraso_pipeline;
    logic atraso_pipeline_anterior;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            resultado <= '0;
            atraso_pipeline <= '0;
            atraso_pipeline_anterior <= 1'b0;
        end else begin
            resultado <= soma_estagio3[0] + soma_estagio3[1];

            // Controle do pipeline
            if (iniciar)
                atraso_pipeline <= 4'b0001;
            else if (atraso_pipeline != 4'b0000)
                atraso_pipeline <= {atraso_pipeline[2:0], 1'b0};

            atraso_pipeline_anterior <= atraso_pipeline[3];
        end
    end

    assign concluido = (!atraso_pipeline[3] && atraso_pipeline_anterior);

endmodule
