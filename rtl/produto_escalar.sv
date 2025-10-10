// rtl/produto_escalar.sv
// Produto escalar 8x32bit -> 64bit
module produto_escalar (
    input  logic         clk_i,
    input  logic         rst_i,      
    input  logic         iniciar,      
    input  logic [31:0]  a0, a1, a2, a3, a4, a5, a6, a7,
    input  logic [31:0]  b0, b1, b2, b3, b4, b5, b6, b7,
    output logic [63:0]  resultado,
    output logic         concluido
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
        resultado_proximo   = resultado; // mantém valor

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

    // Registradores
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
            concluido   <= (estado_proximo == ESTADO_CONCLUIDO);
        end
    end

endmodule
