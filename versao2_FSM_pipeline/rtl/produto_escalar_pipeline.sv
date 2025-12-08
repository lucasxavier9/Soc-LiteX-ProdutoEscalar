// rtl/produto_escalar_pipeline_v2.sv
module produto_escalar_pipeline(
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        iniciar,
    input  logic signed [31:0] a0, a1, a2, a3, a4, a5, a6, a7,
    input  logic signed [31:0] b0, b1, b2, b3, b4, b5, b6, b7,
    output logic signed [63:0] resultado,
    output logic        concluido,
    
    // Sinais de medição de performance
    output logic [31:0] latency_cycles,
    output logic [31:0] total_operations,
    output logic        measurement_valid
);

    // Estados da FSM 
    typedef enum logic [1:0] {
        PARADO     = 2'b00,
        CALCULANDO = 2'b01,
        CONCLUIDO  = 2'b10
    } estado_t;

    estado_t estado_atual;

    // Detector de borda de subida do iniciar
    logic iniciar_ant;
    always_ff @(posedge clk_i) begin
        if (rst_i) iniciar_ant <= 1'b0;
        else iniciar_ant <= iniciar;
    end
    wire iniciar_pulse = iniciar && !iniciar_ant;

    // === PIPELINE ===
    
    // Estágio 1
    logic signed [31:0] a_reg [0:7];
    logic signed [31:0] b_reg [0:7];
    logic estagio1_valido;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (int i = 0; i < 8; i++) begin
                a_reg[i] <= '0;
                b_reg[i] <= '0;
            end
            estagio1_valido <= 1'b0;
        end else if (iniciar_pulse) begin 
            a_reg[0] <= a0; a_reg[1] <= a1; a_reg[2] <= a2; a_reg[3] <= a3;
            a_reg[4] <= a4; a_reg[5] <= a5; a_reg[6] <= a6; a_reg[7] <= a7;

            b_reg[0] <= b0; b_reg[1] <= b1; b_reg[2] <= b2; b_reg[3] <= b3;
            b_reg[4] <= b4; b_reg[5] <= b5; b_reg[6] <= b6; b_reg[7] <= b7;

            estagio1_valido <= 1'b1;
        end else begin
            estagio1_valido <= 1'b0; 
        end
    end

    // Estágio 2
    logic signed [63:0] produtos_reg [0:7];
    logic estagio2_valido;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (int i = 0; i < 8; i++)
                produtos_reg[i] <= '0;
            estagio2_valido <= 1'b0;
        end else begin
            estagio2_valido <= estagio1_valido;
            if (estagio1_valido) begin
                for (int i = 0; i < 8; i++)
                    produtos_reg[i] <= a_reg[i] * b_reg[i];
            end
        end
    end

    // Estágio 3
    logic signed [63:0] somas_parciais [0:3];
    logic estagio3_valido;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (int i = 0; i < 4; i++)
                somas_parciais[i] <= '0;
            estagio3_valido <= 1'b0;
        end else begin
            estagio3_valido <= estagio2_valido;
            if (estagio2_valido) begin
                somas_parciais[0] <= produtos_reg[0] + produtos_reg[1];
                somas_parciais[1] <= produtos_reg[2] + produtos_reg[3];
                somas_parciais[2] <= produtos_reg[4] + produtos_reg[5];
                somas_parciais[3] <= produtos_reg[6] + produtos_reg[7];
            end
        end
    end

    // Estágio 4
    logic signed [63:0] soma_total;
    logic estagio4_valido;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            soma_total <= '0;
            estagio4_valido <= 1'b0;
        end else begin
            estagio4_valido <= estagio3_valido;
            if (estagio3_valido)
                soma_total <= somas_parciais[0] + somas_parciais[1] +
                              somas_parciais[2] + somas_parciais[3];
        end
    end

    // === FSM ===
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
                    if (iniciar_pulse)
                        estado_atual <= CALCULANDO;
                end

                CALCULANDO: begin
                    contador_ciclos <= contador_ciclos + 1;

                    if (estagio4_valido) begin
                        resultado     <= soma_total;
                        estado_atual  <= CONCLUIDO;
                        concluido     <= 1'b1;
                    end else if (contador_ciclos > 4'd10) begin 
                        estado_atual  <= CONCLUIDO;
                        concluido     <= 1'b1;
                    end
                end

                CONCLUIDO: begin
                    concluido <= 1'b1;
                    if (iniciar_pulse) begin
                        estado_atual    <= CALCULANDO;
                        contador_ciclos <= 4'd0;
                        concluido       <= 1'b0;
                    end
                end

                default: estado_atual <= PARADO;
            endcase
        end
    end

    // === MEDIÇÃO DE PERFORMANCE ===
    logic [31:0] contador_ciclos_med;
    logic [31:0] contador_ops;
    logic        measuring;
    logic        concluido_prev;
    logic        medicao_valida_reg;
    
    // Detector de borda de subida do concluido
    always_ff @(posedge clk_i) begin
        if (rst_i) concluido_prev <= 1'b0;
        else concluido_prev <= concluido;
    end
    
    wire concluido_pulse = concluido && !concluido_prev;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            contador_ciclos_med <= 32'd0;
            contador_ops        <= 32'd0;
            measuring           <= 1'b0;
            latency_cycles      <= 32'd0;
            total_operations    <= 32'd0;
            medicao_valida_reg  <= 1'b0;
        end else begin
            if (iniciar_pulse && !measuring) begin
                medicao_valida_reg <= 1'b0;
            end
            
            if (iniciar_pulse && !measuring) begin
                measuring            <= 1'b1;
                contador_ciclos_med  <= 32'd1;
                contador_ops         <= 32'd0;
            end 
            else if (measuring) begin
                contador_ciclos_med <= contador_ciclos_med + 32'd1;

            if (estagio2_valido) begin
                contador_ops <= contador_ops + $size(produtos_reg);
            end
            
                if (concluido_pulse) begin
                    latency_cycles     <= contador_ciclos_med;
                    total_operations   <= contador_ops; 
                    medicao_valida_reg <= 1'b1;
                    measuring          <= 1'b0;
                end
            end
        end
    end

    assign measurement_valid = medicao_valida_reg;

endmodule
