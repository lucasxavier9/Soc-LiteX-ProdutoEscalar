module produto_escalar_pipeline_com_medicao (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        iniciar,
    input  logic signed [31:0] a0, a1, a2, a3, a4, a5, a6, a7,
    input  logic signed [31:0] b0, b1, b2, b3, b4, b5, b6, b7,
    output logic signed [63:0] resultado,
    output logic        concluido,
    
    output logic [31:0] latency_cycles,
    output logic [31:0] total_operations,
    output logic        measurement_valid
);

    // ========== PIPELINE REGISTRADO ==========
    
    logic iniciar_prev;
    always_ff @(posedge clk_i) begin
        if (rst_i) iniciar_prev <= 1'b0;
        else iniciar_prev <= iniciar;
    end
    wire iniciar_pulse = iniciar && !iniciar_prev;

    // === ESTÁGIO 1: Registro + Multiplicações ===
    logic signed [31:0] a_reg [0:7];
    logic signed [31:0] b_reg [0:7];
    logic signed [63:0] produtos [0:7];
    logic estagio1_valido;
    
    // Multiplicações e registro dos operandos
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            estagio1_valido <= 1'b0;
            for (int i = 0; i < 8; i++) begin
                a_reg[i] <= '0;
                b_reg[i] <= '0;
                produtos[i] <= '0;
            end
        end else if (iniciar_pulse) begin
            estagio1_valido <= 1'b1;

            a_reg[0] <= a0; b_reg[0] <= b0; produtos[0] <= a0 * b0;
            a_reg[1] <= a1; b_reg[1] <= b1; produtos[1] <= a1 * b1;
            a_reg[2] <= a2; b_reg[2] <= b2; produtos[2] <= a2 * b2;
            a_reg[3] <= a3; b_reg[3] <= b3; produtos[3] <= a3 * b3;
            a_reg[4] <= a4; b_reg[4] <= b4; produtos[4] <= a4 * b4;
            a_reg[5] <= a5; b_reg[5] <= b5; produtos[5] <= a5 * b5;
            a_reg[6] <= a6; b_reg[6] <= b6; produtos[6] <= a6 * b6;
            a_reg[7] <= a7; b_reg[7] <= b7; produtos[7] <= a7 * b7;
        end else begin
            estagio1_valido <= 1'b0;
        end
    end

    // === ESTÁGIO 2: Primeiro nível de somas ===
    logic signed [63:0] soma_nivel1 [0:3];
    logic estagio2_valido;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            estagio2_valido <= 1'b0;
            for (int i = 0; i < 4; i++) begin
                soma_nivel1[i] <= '0;
            end
        end else begin
            estagio2_valido <= estagio1_valido;
            if (estagio1_valido) begin
                soma_nivel1[0] <= produtos[0] + produtos[1];
                soma_nivel1[1] <= produtos[2] + produtos[3];
                soma_nivel1[2] <= produtos[4] + produtos[5];
                soma_nivel1[3] <= produtos[6] + produtos[7];
            end
        end
    end

    // === ESTÁGIO 3: Segundo nível de somas ===
    logic signed [63:0] soma_nivel2 [0:1];
    logic estagio3_valido;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            estagio3_valido <= 1'b0;
            for (int i = 0; i < 2; i++) begin
                soma_nivel2[i] <= '0;
            end
        end else begin
            estagio3_valido <= estagio2_valido;
            if (estagio2_valido) begin
                soma_nivel2[0] <= soma_nivel1[0] + soma_nivel1[1];
                soma_nivel2[1] <= soma_nivel1[2] + soma_nivel1[3];
            end
        end
    end

    // === ESTÁGIO 4: Soma final ===
    logic estagio4_valido;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            estagio4_valido <= 1'b0;
            resultado <= '0;
            concluido <= 1'b0;
        end else begin
            estagio4_valido <= estagio3_valido;
            if (estagio3_valido) begin
                resultado <= soma_nivel2[0] + soma_nivel2[1];
                concluido <= 1'b1;
            end else begin
                concluido <= 1'b0;
            end
        end
    end

    // ========== MEDIÇÃO ==========
    logic [31:0] contador_ciclos;
    logic [31:0] contador_operacoes;
    logic        medindo;
    logic        concluido_anterior;
    logic        medicao_valida_reg;
    
    always_ff @(posedge clk_i) begin
        if (rst_i) concluido_anterior <= 1'b0;
        else        concluido_anterior <= concluido;
    end

    wire concluido_pulse = concluido && !concluido_anterior;
    
    // Lógica de medição
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            contador_ciclos      <= 32'd0;
            contador_operacoes   <= 32'd0;
            medindo              <= 1'b0;
            latency_cycles       <= 32'd0;
            total_operations     <= 32'd0;
            medicao_valida_reg   <= 1'b0;

        end else begin
            
            if (iniciar_pulse && !medindo)
                medicao_valida_reg <= 1'b0;

            if (iniciar_pulse && !medindo) begin
                medindo            <= 1'b1;
                contador_ciclos    <= 32'd1;
                contador_operacoes <= 32'd8;

            end else if (medindo) begin
                contador_ciclos <= contador_ciclos + 32'd1;

                if (concluido_pulse) begin
                    latency_cycles     <= contador_ciclos;
                    total_operations   <= contador_operacoes;
                    medicao_valida_reg <= 1'b1;
                    medindo            <= 1'b0;
                end
            end
        end
    end

    assign measurement_valid = medicao_valida_reg;

endmodule
