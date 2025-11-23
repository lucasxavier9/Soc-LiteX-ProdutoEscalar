// rtl/produto_escalar_v1_com_medicao.sv
module produto_escalar(
    input  logic         clk_i,
    input  logic         rst_i,      
    input  logic         iniciar,      
    input  logic [31:0]  a0, a1, a2, a3, a4, a5, a6, a7,
    input  logic [31:0]  b0, b1, b2, b3, b4, b5, b6, b7,
    output logic [63:0]  resultado,
    output logic         concluido,

// Sinais de medição de performance 
    output logic [31:0] ciclos_latencia,
    output logic [31:0] total_operacoes,
    output logic        medicao_valida
);
   
    // FSM: Estados
    typedef enum logic [1:0] {
        ESTADO_PARADO     = 2'b00,
        ESTADO_CALCULANDO = 2'b01,
        ESTADO_CONCLUIDO  = 2'b10
    } estado_t;
    
    estado_t estado, estado_proximo;
    logic [2:0] contador, contador_proximo; 
    logic signed [63:0] acumulador, acumulador_proximo;
    logic [63:0] resultado_proximo;

    // Arrays para cálculo
    logic signed [31:0] a_signed [0:7];
    logic signed [31:0] b_signed [0:7];

    // Detector de borda de subida
    logic iniciar_prev;
    always_ff @(posedge clk_i) begin
        if (rst_i) iniciar_prev <= 1'b0;
        else iniciar_prev <= iniciar;
    end
    wire iniciar_pulse = iniciar && !iniciar_prev;

    // Desempacotar entradas para arrays
    always_comb begin
        a_signed[0] = a0; a_signed[1] = a1; a_signed[2] = a2; a_signed[3] = a3;
        a_signed[4] = a4; a_signed[5] = a5; a_signed[6] = a6; a_signed[7] = a7;

        b_signed[0] = b0; b_signed[1] = b1; b_signed[2] = b2; b_signed[3] = b3;
        b_signed[4] = b4; b_signed[5] = b5; b_signed[6] = b6; b_signed[7] = b7;
    end

    // FSM combinacional + cálculo
    always_comb begin
        estado_proximo      = estado;
        contador_proximo    = contador;
        acumulador_proximo  = acumulador;
        resultado_proximo   = resultado;

        case (estado)
            ESTADO_PARADO: begin
                if (iniciar_pulse) begin
                    estado_proximo     = ESTADO_CALCULANDO;
                    contador_proximo   = 3'd0;
                    acumulador_proximo = 64'sd0;
                end
            end

            ESTADO_CALCULANDO: begin
                // Cálculo do próximo acumulador
                acumulador_proximo = acumulador + (a_signed[contador] * b_signed[contador]);
                contador_proximo   = contador + 3'd1;
                
                if (contador == 3'd7) begin
                    estado_proximo    = ESTADO_CONCLUIDO;
                    resultado_proximo = acumulador_proximo; 
                end
            end

            ESTADO_CONCLUIDO: begin
                // Mantém resultado estável até próximo iniciar
                if (iniciar_pulse) begin
                    estado_proximo     = ESTADO_CALCULANDO;
                    contador_proximo   = 3'd0;
                    acumulador_proximo = 64'sd0;
                end
            end

            default: begin
                estado_proximo = ESTADO_PARADO;
            end
        endcase
    end

    // FSM sequencial
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            estado      <= ESTADO_PARADO;
            contador    <= 3'd0;
            acumulador  <= 64'sd0;
            resultado   <= 64'sd0;
            concluido   <= 1'b0;
        end else begin
            estado      <= estado_proximo;
            contador    <= contador_proximo;
            acumulador  <= acumulador_proximo;
            resultado   <= resultado_proximo;
            
            // Sinal de concluído
            if (estado_proximo == ESTADO_CONCLUIDO) begin
                concluido <= 1'b1;
            end else if (iniciar_pulse) begin
                concluido <= 1'b0;
            end
        end
    end

// ========== MÓDULO DE MEDIÇÃO DE PERFORMANCE ==========
    logic [31:0] contador_ciclos;
    logic [31:0] contador_operacoes;
    logic medindo;
    logic concluido_anterior;
    logic medicao_valida_reg;
    
    // Detector de borda de subida do concluido
    always_ff @(posedge clk_i) begin
        if (rst_i) concluido_anterior <= 1'b0;
        else concluido_anterior <= concluido;
    end
    
    wire pulso_concluido = concluido && !concluido_anterior;

// Lógica de medição
always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        contador_ciclos <= 32'd0;
        contador_operacoes <= 32'd0;
        medindo <= 1'b0;
        ciclos_latencia <= 32'd0;
        total_operacoes <= 32'd0;
        medicao_valida_reg <= 1'b0;
    end else begin
        // RESET do válido apenas quando iniciar nova medição
        if (iniciar && !medindo) begin
            medicao_valida_reg <= 1'b0;
        end
        
        if (iniciar && !medindo) begin
            // Inicia nova medição
            medindo <= 1'b1;
            contador_ciclos <= 32'd0;  
            contador_operacoes <= 32'd0; 
        end else if (medindo) begin
            contador_ciclos <= contador_ciclos + 32'd1;
            
            // Conta operações apenas no estado de cálculo
            if (estado == ESTADO_CALCULANDO) begin
                contador_operacoes <= contador_operacoes + 32'd1;
            end
            
            if (pulso_concluido) begin
                // Finaliza medição atual
                ciclos_latencia <= contador_ciclos;
                total_operacoes <= contador_operacoes; 
                medicao_valida_reg <= 1'b1;
                medindo <= 1'b0;
            end
        end
    end
end

    assign medicao_valida = medicao_valida_reg;

endmodule