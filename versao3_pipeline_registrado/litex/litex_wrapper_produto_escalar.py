# litex_wrapper_produto_escalar.py (ATUALIZADO COM MEDIÇÃO)
from migen import *
from litex.gen import *
from litex.soc.interconnect.csr import *

class ProdutoEscalar(Module, AutoCSR):
    def __init__(self, platform):
        # Importa o módulo SystemVerilog com medição
        platform.add_source("rtl/produto_escalar_pipeline_com_medicao.sv")

        # CSR de controle (pulso de start)
        self.iniciar = CSRStorage(fields=[
            CSRField("iniciar", size=1, offset=0, pulse=True)
        ])

        # CSRs para vetores A0..A7
        self.vetor_a0 = CSRStorage(32, name="vetor_a0")
        self.vetor_a1 = CSRStorage(32, name="vetor_a1")
        self.vetor_a2 = CSRStorage(32, name="vetor_a2")
        self.vetor_a3 = CSRStorage(32, name="vetor_a3")
        self.vetor_a4 = CSRStorage(32, name="vetor_a4")
        self.vetor_a5 = CSRStorage(32, name="vetor_a5")
        self.vetor_a6 = CSRStorage(32, name="vetor_a6")
        self.vetor_a7 = CSRStorage(32, name="vetor_a7")

        # CSRs para vetores B0..B7  
        self.vetor_b0 = CSRStorage(32, name="vetor_b0")
        self.vetor_b1 = CSRStorage(32, name="vetor_b1")
        self.vetor_b2 = CSRStorage(32, name="vetor_b2")
        self.vetor_b3 = CSRStorage(32, name="vetor_b3")
        self.vetor_b4 = CSRStorage(32, name="vetor_b4")
        self.vetor_b5 = CSRStorage(32, name="vetor_b5")
        self.vetor_b6 = CSRStorage(32, name="vetor_b6")
        self.vetor_b7 = CSRStorage(32, name="vetor_b7")

        # CSRs: saídas principais
        self.concluido = CSRStatus(1, name="concluido")
        self.resultado = CSRStatus(64, name="resultado")
        
        # NOVOS CSRs: medição de performance
        self.latency_cycles = CSRStatus(32, name="latency_cycles")
        self.total_operations = CSRStatus(32, name="total_operations")
        self.measurement_valid = CSRStatus(1, name="measurement_valid")

        # Sinais internos
        iniciar_sig = Signal()
        concluido_sig = Signal()
        resultado_sig = Signal(64)
        latency_sig = Signal(32)
        total_ops_sig = Signal(32)
        measurement_valid_sig = Signal()
        
        # Sinais para os vetores A e B
        a_sigs = [Signal(32) for _ in range(8)]
        b_sigs = [Signal(32) for _ in range(8)]

        # Conexão dos sinais
        self.comb += [
            iniciar_sig.eq(self.iniciar.fields.iniciar),
            self.concluido.status.eq(concluido_sig),
            self.resultado.status.eq(resultado_sig),
            self.latency_cycles.status.eq(latency_sig),
            self.total_operations.status.eq(total_ops_sig),
            self.measurement_valid.status.eq(measurement_valid_sig)
        ]
        
        # Conexão dos vetores A
        self.comb += [
            a_sigs[0].eq(self.vetor_a0.storage),
            a_sigs[1].eq(self.vetor_a1.storage),
            a_sigs[2].eq(self.vetor_a2.storage),
            a_sigs[3].eq(self.vetor_a3.storage),
            a_sigs[4].eq(self.vetor_a4.storage),
            a_sigs[5].eq(self.vetor_a5.storage),
            a_sigs[6].eq(self.vetor_a6.storage),
            a_sigs[7].eq(self.vetor_a7.storage),
        ]
        
        # Conexão dos vetores B
        self.comb += [
            b_sigs[0].eq(self.vetor_b0.storage),
            b_sigs[1].eq(self.vetor_b1.storage),
            b_sigs[2].eq(self.vetor_b2.storage),
            b_sigs[3].eq(self.vetor_b3.storage),
            b_sigs[4].eq(self.vetor_b4.storage),
            b_sigs[5].eq(self.vetor_b5.storage),
            b_sigs[6].eq(self.vetor_b6.storage),
            b_sigs[7].eq(self.vetor_b7.storage),
        ]

        # Instância do módulo SystemVerilog com medição
        self.specials += Instance("produto_escalar_pipeline_com_medicao",
            i_clk_i     = ClockSignal(),
            i_rst_i     = ResetSignal(),
            i_iniciar   = iniciar_sig,
            o_concluido = concluido_sig,
            o_resultado = resultado_sig,
            o_latency_cycles = latency_sig,
            o_total_operations = total_ops_sig,
            o_measurement_valid = measurement_valid_sig,
            i_a0 = a_sigs[0], i_a1 = a_sigs[1], i_a2 = a_sigs[2], i_a3 = a_sigs[3],
            i_a4 = a_sigs[4], i_a5 = a_sigs[5], i_a6 = a_sigs[6], i_a7 = a_sigs[7],
            i_b0 = b_sigs[0], i_b1 = b_sigs[1], i_b2 = b_sigs[2], i_b3 = b_sigs[3],
            i_b4 = b_sigs[4], i_b5 = b_sigs[5], i_b6 = b_sigs[6], i_b7 = b_sigs[7]
        )