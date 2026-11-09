// ============================================================================
// TOP-LEVEL: Processador Neander Completo (Datapath + Memória RAM + Controle)
// Implementado estritamente em Nível de Portas Lógicas (Gate-Level Verilog)
// ============================================================================

module neander_top (
    input  wire       clk,
    input  wire       rst,
    output wire [7:0] pc_out,
    output wire [7:0] ac_out,
    output wire [7:0] ri_out,
    output wire [7:0] rem_out,
    output wire [7:0] rdm_out,
    output wire       n_out,
    output wire       z_out,
    output wire       halt_out,
    output wire [2:0] tempo_out,
    output wire [7:0] mem10_dbg,
    output wire [7:0] mem11_dbg,
    output wire [7:0] mem12_dbg
);
    // Sinais de controle gerados pela Unidade de Controle
    wire       sel;
    wire       cargaREM;
    wire       cargaRDM;
    wire       cargaRI;
    wire       cargaAC;
    wire       cargaNZ;
    wire       cargaPC;
    wire       incrementaPC;
    wire [2:0] selUAL;
    wire       read;
    wire       write;
    wire [7:0] t_pulsos;

    // Barramentos internos do Datapath
    wire [7:0] mux_rem_out;
    wire [7:0] mem_data_out;
    wire [7:0] rdm_in;
    wire       en_rdm;
    wire [7:0] ual_s;
    wire       ual_n;
    wire       ual_z;

    // 1. Contador de Programa (PC) de 8 bits
    contador_pc_8bits u_pc (
        .clk          (clk),
        .rst          (rst),
        .cargaPC      (cargaPC),
        .incrementaPC (incrementaPC),
        .d_in         (rdm_out),
        .pc_out       (pc_out)
    );

    // 2. Multiplexador 2:1 de 8 bits (seleciona PC quando sel=0, RDM quando sel=1)
    mux2x1_8bits u_mux_rem (
        .d0  (pc_out),
        .d1  (rdm_out),
        .sel (sel),
        .y   (mux_rem_out)
    );

    // 3. Registrador de Endereço de Memória (REM) de 8 bits
    registrador_8bits u_rem (
        .clk   (clk),
        .rst   (rst),
        .carga (cargaREM),
        .d     (mux_rem_out),
        .q     (rem_out)
    );

    // 4. Memória RAM de 16 endereços x 8 bits (usa A3..A0 = REM[3:0])
    memoria_ram_16x8 u_mem (
        .clk       (clk),
        .rst       (rst),
        .addr      (rem_out[3:0]),
        .data_in   (rdm_out),
        .read      (read),
        .write     (write),
        .data_out  (mem_data_out),
        .mem10_dbg (mem10_dbg),
        .mem11_dbg (mem11_dbg),
        .mem12_dbg (mem12_dbg)
    );

    // 5. Registrador de Dados de Memória (RDM) de 8 bits
    // Recebe dado da Memória quando read=1, ou do Acumulador (AC) quando cargaRDM=1 (STA)
    mux2x1_8bits u_mux_rdm (
        .d0  (mem_data_out),
        .d1  (ac_out),
        .sel (cargaRDM),
        .y   (rdm_in)
    );

    or u_or_en_rdm (en_rdm, read, cargaRDM);

    registrador_8bits u_rdm (
        .clk   (clk),
        .rst   (rst),
        .carga (en_rdm),
        .d     (rdm_in),
        .q     (rdm_out)
    );

    // 6. Registrador de Instrução (RI / INST) de 8 bits
    registrador_8bits u_ri (
        .clk   (clk),
        .rst   (rst),
        .carga (cargaRI),
        .d     (rdm_out),
        .q     (ri_out)
    );

    // 7. Acumulador (AC) de 8 bits
    registrador_8bits u_ac (
        .clk   (clk),
        .rst   (rst),
        .carga (cargaAC),
        .d     (ual_s),
        .q     (ac_out)
    );

    // 8. Unidade Aritmética e Lógica (UAL) de 8 bits
    ual_8bits u_ual (
        .X      (ac_out),
        .Y      (rdm_out),
        .selUAL (selUAL),
        .S      (ual_s),
        .N      (ual_n),
        .Z      (ual_z)
    );

    // 9. Registrador de Estado (NZ) de 2 bits
    registrador_nz u_nz (
        .clk     (clk),
        .rst     (rst),
        .cargaNZ (cargaNZ),
        .n_in    (ual_n),
        .z_in    (ual_z),
        .n_out   (n_out),
        .z_out   (z_out)
    );

    // 10. Unidade de Controle (FSM)
    unidade_controle u_uc (
        .clk          (clk),
        .rst          (rst),
        .opcode       (ri_out[7:4]),
        .N            (n_out),
        .Z            (z_out),
        .sel          (sel),
        .cargaREM      (cargaREM),
        .cargaRDM      (cargaRDM),
        .cargaRI       (cargaRI),
        .cargaAC       (cargaAC),
        .cargaNZ       (cargaNZ),
        .cargaPC       (cargaPC),
        .incrementaPC (incrementaPC),
        .selUAL       (selUAL),
        .read         (read),
        .write        (write),
        .halt_out     (halt_out),
        .tempo_cnt    (tempo_out),
        .t_out        (t_pulsos)
    );
endmodule
