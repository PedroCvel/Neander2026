`timescale 1ns/1ps
// ============================================================================
// Primitivas Básicas em Nível de Portas Lógicas (Gate-Level)
// Multiplexadores 1-bit, Latch SR e Flip-Flop D Mestre-Escravo com Reset/Preset
// ============================================================================

// Multiplexador 2:1 de 1 bit em nível de portas (AND, OR, NOT)
module mux2x1_1bit (
    input  wire d0,
    input  wire d1,
    input  wire sel,
    output wire y
);
    wire nsel, a0, a1;
    not u_not (nsel, sel);
    and u_and0 (a0, d0, nsel);
    and u_and1 (a1, d1, sel);
    or  u_or   (y, a0, a1);
endmodule

// Latch D com Enable e Preset/Clear assíncronos usando apenas portas NAND, AND e NOT
module latch_d_nand (
    input  wire d,
    input  wire en,
    input  wire pre_n, // Ativo em nível baixo (0 -> seta Q=1)
    input  wire clr_n, // Ativo em nível baixo (0 -> reseta Q=0)
    output wire q,
    output wire qn
);
    wire dn, en_g, s_n, r_n;
    not  u_not_d  (dn, d);
    // Desabilita a entrada D enquanto Preset ou Clear assíncrono estiver ativo
    and  u_en_g   (en_g, en, pre_n, clr_n);
    nand u_nand_s (s_n, d,  en_g);
    nand u_nand_r (r_n, dn, en_g);
    // Latch SR com Preset e Clear ativos em baixo
    nand #1 u_q  (q,  pre_n, s_n, qn);
    nand #1 u_qn (qn, clr_n, r_n, q);
endmodule

// Flip-Flop D Mestre-Escravo sensível à borda de subida do clock (posedge clk)
// Construído estritamente com portas NAND e NOT (via 2 Latches D em cascata)
module ffd_gate (
    input  wire clk,
    input  wire d,
    input  wire rst,    // Reset assíncrono (ativo em alto: Q -> 0)
    input  wire preset, // Preset assíncrono (ativo em alto: Q -> 1)
    output wire q,
    output wire qn
);
    wire nclk, pre_n, clr_n;
    wire qm, qmn;

    not u_not_clk (nclk, clk);
    not u_not_pre (pre_n, preset);
    not u_not_clr (clr_n, rst);

    // Estágio Mestre: transparente quando clk = 0 (nclk = 1)
    latch_d_nand u_mestre (
        .d     (d),
        .en    (nclk),
        .pre_n (pre_n),
        .clr_n (clr_n),
        .q     (qm),
        .qn    (qmn)
    );

    // Estágio Escravo: atualiza na subida do clock (clk = 1)
    latch_d_nand u_escravo (
        .d     (qm),
        .en    (clk),
        .pre_n (pre_n),
        .clr_n (clr_n),
        .q     (q),
        .qn    (qn)
    );
endmodule

// Flip-Flop D com sinal de Carga Paralela (Enable) e Inicialização por Reset
module ffd_carga (
    input  wire clk,
    input  wire rst,
    input  wire init_bit, // Valor carregado durante o Reset (0 ou 1)
    input  wire carga,
    input  wire d,
    output wire q
);
    wire d_mux, qn;
    wire rst_clr, rst_pre, n_init;

    // Se init_bit == 1, um pulso em rst aciona preset; se init_bit == 0, aciona clear
    not u_not_init (n_init, init_bit);
    and u_and_clr  (rst_clr, rst, n_init);
    and u_and_pre  (rst_pre, rst, init_bit);

    // Mux 2:1 na entrada D: se carga=1 seleciona 'd', se carga=0 mantém 'q'
    mux2x1_1bit u_mux (
        .d0  (q),
        .d1  (d),
        .sel (carga),
        .y   (d_mux)
    );

    ffd_gate u_ffd (
        .clk    (clk),
        .d      (d_mux),
        .rst    (rst_clr),
        .preset (rst_pre),
        .q      (q),
        .qn     (qn)
    );
endmodule
