# Acelerador de Produto Escalar para SoC LiteX na FPGA

Este projeto é um System-on-Chip (SoC) para a FPGA Colorlight i5, construído com o framework LiteX. O SoC contém um processador RISC-V e um acelerador de hardware para cálculo de produto escalar, com o qual a CPU se comunica via barramento CSR (Control and Status Register).

O repositório cobre o fluxo completo: o design do acelerador em SystemVerilog, sua integração ao SoC usando Python/Migen, e um firmware em C que valida o hardware e compara seu desempenho com uma versão em software.

---

## Toolchain
A toolchain utilizada é a [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build), que integra binários de todas as etapas necessárias:
- Simulação: [Verilator](https://www.veripool.org/verilator/) ou [Icarus Verilog](https://steveicarus.github.io/iverilog/);
- Visualização de waveforms: [GTKWave](https://gtkwave.sourceforge.net/);
- Síntese RTL: [Yosys](https://github.com/YosysHQ/yosys);
- Place and Route: [nextpnr](https://github.com/YosysHQ/nextpnr) e [Project Trellis](https://github.com/YosysHQ/prjtrellis);
- Gravação da FPGA: [ECPDAP](https://github.com/adamgreig/ecpdap) ou [openFPGALoader](https://github.com/trabucayre/openFPGALoader)

Além disso, há exemplos utilizando o [LiteX](https://github.com/enjoy-digital/litex), descritos mais abaixo.

---

## Visão Geral

O acelerador calcula o **produto escalar** de dois vetores de 8 elementos de 32 bits com sinal:


resultado = A[0]*B[0] + A[1]*B[1] + ... + A[7]*B[7]

O resultado é um inteiro de **64 bits com sinal**, computado inteiramente em hardware em apenas **8 ciclos de clock**. A CPU carrega os vetores via CSRs, dispara o cálculo com um pulso de `iniciar`, aguarda o sinal `concluido`, e lê o resultado — tudo via mapeamento de memória.

O firmware inclui **validação cruzada automática**: após o cálculo em hardware, ele repete a operação em software e compara os resultados, garantindo correção funcional.

---

