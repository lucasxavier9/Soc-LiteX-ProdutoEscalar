// rtl/produto_escalar.sv
// Produto escalar 8x32bit -> 64bit
module produto_escalar (
    input  logic         clk_i,
    input  logic         rst_n,   // ativo baixo
    // entradas (32-bit cada)
    input  logic [31:0]  a0, a1, a2, a3, a4, a5, a6, a7,
    input  logic [31:0]  b0, b1, b2, b3, b4, b5, b6, b7,
    input  logic         iniciar,
    // saídas
    output logic         concluido,
    output logic [63:0]  resultado
);

    typedef enum logic [1:0] {
        PARADO = 2'd0, 
        CALCULANDO = 2'd1, 
        FEITO = 2'd2 } estado_t;
    
    estado_t estado, proximo_estado;

    // registradores
    logic [63:0] acumulador, acumulador_prox;
    logic [3:0]  indice, indice_prox;
    logic        concluido_prox;

    // multiplicandos pipeline (registrados para evitar caminhos combinacionais longos)
    logic signed [31:0] aa [0:7];
    logic signed [31:0] bb [0:7];
    logic signed [63:0] produto;

    // desempacotar entradas em arrays (combinacional)
    always_comb begin
        aa[0] = a0; aa[1] = a1; aa[2] = a2; aa[3] = a3;
        aa[4] = a4; aa[5] = a5; aa[6] = a6; aa[7] = a7;
        bb[0] = b0; bb[1] = b1; bb[2] = b2; bb[3] = b3;
        bb[4] = b4; bb[5] = b5; bb[6] = b6; bb[7] = b7;
    end

    // lógica sequencial-registradores
    always_ff @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            estado <= PARADO;
            acumulador <= 64'd0;
            indice   <= 4'd0;
            concluido  <= 1'b0;
        end else begin
            estado <= proximo_estado;
            acumulador <= acumulador_prox;
            indice   <= indice_prox;
            concluido  <= concluido_prox;
        end
    end

    // logica combinacional
    always_comb begin
        proximo_estado = estado;
        acumulador_prox = acumulador;
        indice_prox   = indice;
        concluido_prox  = concluido;
        produto = 64'd0;

        case (estado)
            PARADO: begin
                concluido_prox = 1'b0;
                acumulador_prox = 64'sd0;
                indice_prox = 4'd0;
                if (iniciar) begin
                    proximo_estado = CALCULANDO;
                end
            end

            CALCULANDO: begin
                // multiplicação com extensão de sinal para 64 bits
                produto = $signed(aa[indice]) * $signed(bb[indice]);
                acumulador_prox = acumulador + produto;
                indice_prox = indice + 4'd1;
                
                if (indice == 4'd7) begin
                    proximo_estado = FEITO;
                    concluido_prox = 1'b1;
                end
            end

            FEITO: begin
                // aguarda iniciar ser baixado para voltar ao inicio
                if (!iniciar) begin
                    proximo_estado = PARADO;
                    concluido_prox = 1'b0;
                end
            end

            default: begin
                proximo_estado = PARADO;
            end
        endcase
    end

    assign resultado = acumulador;

endmodule
