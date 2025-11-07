// Módulo: produto_escalar_pipeline 
module produto_escalar_pipeline (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        iniciar,
    input  logic signed [31:0] a0, a1, a2, a3, a4, a5, a6, a7,
    input  logic signed [31:0] b0, b1, b2, b3, b4, b5, b6, b7,
    output logic signed [63:0] resultado,
    output logic        concluido
);

    // Estados da FSM 
    typedef enum logic [1:0] {
        PARADO     = 2'b00,
        CALCULANDO = 2'b01,
        CONCLUIDO  = 2'b10
    } estado_t;

    estado_t estado_atual;

    // Estágio 1: Registrar Entradas
    logic signed [31:0] a_reg [0:7];
    logic signed [31:0] b_reg [0:7];

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (int i = 0; i < 8; i++) begin
                a_reg[i] <= '0;
                b_reg[i] <= '0;
            end
        end else if (estado_atual == CALCULANDO) begin
            a_reg[0] <= a0; a_reg[1] <= a1; a_reg[2] <= a2; a_reg[3] <= a3;
            a_reg[4] <= a4; a_reg[5] <= a5; a_reg[6] <= a6; a_reg[7] <= a7;

            b_reg[0] <= b0; b_reg[1] <= b1; b_reg[2] <= b2; b_reg[3] <= b3;
            b_reg[4] <= b4; b_reg[5] <= b5; b_reg[6] <= b6; b_reg[7] <= b7;
        end
    end

    // Estágio 2: Multiplicações Registradas (Pipeline)
    logic signed [63:0] produto_reg [0:7];

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (int i = 0; i < 8; i++)
                produto_reg[i] <= '0;
        end else if (estado_atual == CALCULANDO) begin
            for (int i = 0; i < 8; i++)
                produto_reg[i] <= a_reg[i] * b_reg[i];
        end
    end

    // Estágio 3: Soma Parcial Registrada
    logic signed [63:0] soma_parcial [0:3];

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (int i = 0; i < 4; i++)
                soma_parcial[i] <= '0;
        end else if (estado_atual == CALCULANDO) begin
            soma_parcial[0] <= produto_reg[0] + produto_reg[1];
            soma_parcial[1] <= produto_reg[2] + produto_reg[3];
            soma_parcial[2] <= produto_reg[4] + produto_reg[5];
            soma_parcial[3] <= produto_reg[6] + produto_reg[7];
        end
    end

    // Estágio 4: Soma Final Registrada
    logic signed [63:0] soma_final;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            soma_final <= '0;
        else if (estado_atual == CALCULANDO)
            soma_final <= soma_parcial[0] + soma_parcial[1] +
                          soma_parcial[2] + soma_parcial[3];
    end

    // FSM e Controle de Latência
    logic [3:0] contador_ciclos;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            estado_atual    <= PARADO;
            resultado       <= '0;
            concluido       <= 1'b0;
            contador_ciclos <= 4'd0;
        end else begin
            case (estado_atual)
                PARADO: begin
                    concluido       <= 1'b0;
                    contador_ciclos <= 4'd0;
                    if (iniciar)
                        estado_atual <= CALCULANDO;
                end

                CALCULANDO: begin
                    contador_ciclos <= contador_ciclos + 1;

                    // Latência total: 4 estágios de pipeline
                    if (contador_ciclos == 4'd4) begin
                        resultado     <= soma_final;
                        estado_atual  <= CONCLUIDO;
                        concluido     <= 1'b1;
                    end
                end

                CONCLUIDO: begin
                    concluido <= 1'b1;
                    if (iniciar) begin
                        estado_atual    <= CALCULANDO;
                        contador_ciclos <= 4'd0;
                        concluido       <= 1'b0;
                    end
                end

                default: estado_atual <= PARADO;
            endcase
        end
    end

endmodule
