
`timescale 1ns/1ps

// Multiplexador 2:1 de 1 bit 
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

// ============================================================================
// PASSO 1: Projeto dos Circuitos Combinacionais em Nível de Portas Lógicas
// A) Multiplexador 2:1 de 8 bits
// B) Unidade Aritmética e Lógica (UAL) de 8 bits com flags N (Negativo) e Z (Zero)
// C) Decodificador de Instruções 4x16 (para o registrador de instrução RI)
// ============================================================================

// A) Multiplexador 2:1 de largura de 8 bits (seleciona entre PC quando sel=0 e RDM quando sel=1)
module mux2x1_8bits (
    input  wire [7:0] d0,
    input  wire [7:0] d1,
    input  wire       sel,
    output wire [7:0] y
);
    mux2x1_1bit b0 (.d0(d0[0]), .d1(d1[0]), .sel(sel), .y(y[0]));
    mux2x1_1bit b1 (.d0(d0[1]), .d1(d1[1]), .sel(sel), .y(y[1]));
    mux2x1_1bit b2 (.d0(d0[2]), .d1(d1[2]), .sel(sel), .y(y[2]));
    mux2x1_1bit b3 (.d0(d0[3]), .d1(d1[3]), .sel(sel), .y(y[3]));
    mux2x1_1bit b4 (.d0(d0[4]), .d1(d1[4]), .sel(sel), .y(y[4]));
    mux2x1_1bit b5 (.d0(d0[5]), .d1(d1[5]), .sel(sel), .y(y[5]));
    mux2x1_1bit b6 (.d0(d0[6]), .d1(d1[6]), .sel(sel), .y(y[6]));
    mux2x1_1bit b7 (.d0(d0[7]), .d1(d1[7]), .sel(sel), .y(y[7]));
endmodule

// Somador Completo de 1 bit em nível de portas lógicas
module somador_completo_1bit (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire s,
    output wire cout
);
    wire axb, ab, axb_cin;
    xor u_xor1 (axb, a, b);
    xor u_xor2 (s, axb, cin);
    and u_and1 (ab, a, b);
    and u_and2 (axb_cin, axb, cin);
    or  u_or1  (cout, ab, axb_cin);
endmodule

// Somador de 8 bits em cascata (Ripple-Carry Adder)
module somador_8bits (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] s,
    output wire       cout
);
    wire c1, c2, c3, c4, c5, c6, c7;
    somador_completo_1bit fa0 (.a(a[0]), .b(b[0]), .cin(cin), .s(s[0]), .cout(c1));
    somador_completo_1bit fa1 (.a(a[1]), .b(b[1]), .cin(c1),  .s(s[1]), .cout(c2));
    somador_completo_1bit fa2 (.a(a[2]), .b(b[2]), .cin(c2),  .s(s[2]), .cout(c3));
    somador_completo_1bit fa3 (.a(a[3]), .b(b[3]), .cin(c3),  .s(s[3]), .cout(c4));
    somador_completo_1bit fa4 (.a(a[4]), .b(b[4]), .cin(c4),  .s(s[4]), .cout(c5));
    somador_completo_1bit fa5 (.a(a[5]), .b(b[5]), .cin(c5),  .s(s[5]), .cout(c6));
    somador_completo_1bit fa6 (.a(a[6]), .b(b[6]), .cin(c6),  .s(s[6]), .cout(c7));
    somador_completo_1bit fa7 (.a(a[7]), .b(b[7]), .cin(c7),  .s(s[7]), .cout(cout));
endmodule

// Seletor 5:1 (via decodificação de 3 bits selUAL) de 1 bit para a UAL
module mux5x1_1bit (
    input  wire       d0, // 000: ADD
    input  wire       d1, // 001: AND
    input  wire       d2, // 010: OR
    input  wire       d3, // 011: NOT X
    input  wire       d4, // 100: Y
    input  wire [2:0] sel,
    output wire       y
);
    wire ns0, ns1, ns2;
    wire m0, m1, m2, m3, m4;

    not u_ns0 (ns0, sel[0]);
    not u_ns1 (ns1, sel[1]);
    not u_ns2 (ns2, sel[2]);

    and u_m0 (m0, d0, ns2, ns1, ns0); // 000
    and u_m1 (m1, d1, ns2, ns1, sel[0]); // 001
    and u_m2 (m2, d2, ns2, sel[1], ns0); // 010
    and u_m3 (m3, d3, ns2, sel[1], sel[0]); // 011
    and u_m4 (m4, d4, sel[2], ns1, ns0); // 100

    or u_or (y, m0, m1, m2, m3, m4);
endmodule

// B) Unidade Aritmética e Lógica (UAL) de 8 bits
// Operações conforme tabela do projeto:
//   selUAL = 000 -> X + Y
//   selUAL = 001 -> X and Y
//   selUAL = 010 -> X or Y
//   selUAL = 011 -> Not X
//   selUAL = 100 -> Y
module ual_8bits (
    input  wire [7:0] X,
    input  wire [7:0] Y,
    input  wire [2:0] selUAL,
    output wire [7:0] S,
    output wire       N,
    output wire       Z
);
    wire [7:0] res_add;
    wire [7:0] res_and;
    wire [7:0] res_or;
    wire [7:0] res_not;
    wire       cout_unused;

    // 000: X + Y
    somador_8bits u_add (
        .a    (X),
        .b    (Y),
        .cin  (1'b0),
        .s    (res_add),
        .cout (cout_unused)
    );

    // 001: X and Y
    and u_and0 (res_and[0], X[0], Y[0]);
    and u_and1 (res_and[1], X[1], Y[1]);
    and u_and2 (res_and[2], X[2], Y[2]);
    and u_and3 (res_and[3], X[3], Y[3]);
    and u_and4 (res_and[4], X[4], Y[4]);
    and u_and5 (res_and[5], X[5], Y[5]);
    and u_and6 (res_and[6], X[6], Y[6]);
    and u_and7 (res_and[7], X[7], Y[7]);

    // 010: X or Y
    or u_or0 (res_or[0], X[0], Y[0]);
    or u_or1 (res_or[1], X[1], Y[1]);
    or u_or2 (res_or[2], X[2], Y[2]);
    or u_or3 (res_or[3], X[3], Y[3]);
    or u_or4 (res_or[4], X[4], Y[4]);
    or u_or5 (res_or[5], X[5], Y[5]);
    or u_or6 (res_or[6], X[6], Y[6]);
    or u_or7 (res_or[7], X[7], Y[7]);

    // 011: Not X
    not u_not0 (res_not[0], X[0]);
    not u_not1 (res_not[1], X[1]);
    not u_not2 (res_not[2], X[2]);
    not u_not3 (res_not[3], X[3]);
    not u_not4 (res_not[4], X[4]);
    not u_not5 (res_not[5], X[5]);
    not u_not6 (res_not[6], X[6]);
    not u_not7 (res_not[7], X[7]);

    // Seleção do resultado de 8 bits conforme selUAL[2:0]
    mux5x1_1bit mux_b0 (.d0(res_add[0]), .d1(res_and[0]), .d2(res_or[0]), .d3(res_not[0]), .d4(Y[0]), .sel(selUAL), .y(S[0]));
    mux5x1_1bit mux_b1 (.d0(res_add[1]), .d1(res_and[1]), .d2(res_or[1]), .d3(res_not[1]), .d4(Y[1]), .sel(selUAL), .y(S[1]));
    mux5x1_1bit mux_b2 (.d0(res_add[2]), .d1(res_and[2]), .d2(res_or[2]), .d3(res_not[2]), .d4(Y[2]), .sel(selUAL), .y(S[2]));
    mux5x1_1bit mux_b3 (.d0(res_add[3]), .d1(res_and[3]), .d2(res_or[3]), .d3(res_not[3]), .d4(Y[3]), .sel(selUAL), .y(S[3]));
    mux5x1_1bit mux_b4 (.d0(res_add[4]), .d1(res_and[4]), .d2(res_or[4]), .d3(res_not[4]), .d4(Y[4]), .sel(selUAL), .y(S[4]));
    mux5x1_1bit mux_b5 (.d0(res_add[5]), .d1(res_and[5]), .d2(res_or[5]), .d3(res_not[5]), .d4(Y[5]), .sel(selUAL), .y(S[5]));
    mux5x1_1bit mux_b6 (.d0(res_add[6]), .d1(res_and[6]), .d2(res_or[6]), .d3(res_not[6]), .d4(Y[6]), .sel(selUAL), .y(S[6]));
    mux5x1_1bit mux_b7 (.d0(res_add[7]), .d1(res_and[7]), .d2(res_or[7]), .d3(res_not[7]), .d4(Y[7]), .sel(selUAL), .y(S[7]));

    // Flag N (Negativo em complemento de 2 = bit mais significativo S[7])
    buf u_buf_n (N, S[7]);

    // Flag Z (Zero = NOR de todos os 8 bits da saída S)
    nor u_nor_z (Z, S[7], S[6], S[5], S[4], S[3], S[2], S[1], S[0]);
endmodule

// Decodificador de Instrução 4x16 (decodifica os 4 bits de opcode RI[7:4])
module decodificador_4x16 (
    input  wire [3:0] op,
    output wire       NOP,    // 0000
    output wire       STA,    // 0001
    output wire       LDA,    // 0010
    output wire       ADD,    // 0011
    output wire       OR_op,  // 0100
    output wire       AND_op, // 0101
    output wire       NOT_op, // 0110
    output wire       JMP,    // 1000
    output wire       JN,     // 1001
    output wire       JZ,     // 1010
    output wire       HLT     // 1111
);
    wire nop0, nop1, nop2, nop3;
    not u_n0 (nop0, op[0]);
    not u_n1 (nop1, op[1]);
    not u_n2 (nop2, op[2]);
    not u_n3 (nop3, op[3]);

    and u_nop (NOP,    nop3,  nop2,  nop1,  nop0);  // 0000
    and u_sta (STA,    nop3,  nop2,  nop1,  op[0]); // 0001
    and u_lda (LDA,    nop3,  nop2,  op[1], nop0);  // 0010
    and u_add (ADD,    nop3,  nop2,  op[1], op[0]); // 0011
    and u_or  (OR_op,  nop3,  op[2], nop1,  nop0);  // 0100
    and u_and (AND_op, nop3,  op[2], nop1,  op[0]); // 0101
    and u_not (NOT_op, nop3,  op[2], op[1], nop0);  // 0110
    and u_jmp (JMP,    op[3], nop2,  nop1,  nop0);  // 1000
    and u_jn  (JN,     op[3], nop2,  nop1,  op[0]); // 1001
    and u_jz  (JZ,     op[3], nop2,  op[1], nop0);  // 1010
    and u_hlt (HLT,    op[3], op[2], op[1], op[0]); // 1111
endmodule

// ============================================================================
// PASSO 2: Projeto dos Circuitos Sequenciais em Nível de Portas Lógicas
// A) Registradores de 8 bits (AC, REM, RDM, RI) e Registrador NZ de 2 bits
// B) Contador de Programa (PC) de 8 bits com Carga Paralela e Incremento
// C) Memória RAM de 16 endereços x 8 bits (Matriz 4x4 com Decodificadores X e Y)
// ============================================================================

// Registrador de 8 bits com Carga Paralela e Valor Inicial de Reset configurável
module registrador_8bits_init (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] init_val,
    input  wire       carga,
    input  wire [7:0] d,
    output wire [7:0] q
);
    ffd_carga ff0 (.clk(clk), .rst(rst), .init_bit(init_val[0]), .carga(carga), .d(d[0]), .q(q[0]));
    ffd_carga ff1 (.clk(clk), .rst(rst), .init_bit(init_val[1]), .carga(carga), .d(d[1]), .q(q[1]));
    ffd_carga ff2 (.clk(clk), .rst(rst), .init_bit(init_val[2]), .carga(carga), .d(d[2]), .q(q[2]));
    ffd_carga ff3 (.clk(clk), .rst(rst), .init_bit(init_val[3]), .carga(carga), .d(d[3]), .q(q[3]));
    ffd_carga ff4 (.clk(clk), .rst(rst), .init_bit(init_val[4]), .carga(carga), .d(d[4]), .q(q[4]));
    ffd_carga ff5 (.clk(clk), .rst(rst), .init_bit(init_val[5]), .carga(carga), .d(d[5]), .q(q[5]));
    ffd_carga ff6 (.clk(clk), .rst(rst), .init_bit(init_val[6]), .carga(carga), .d(d[6]), .q(q[6]));
    ffd_carga ff7 (.clk(clk), .rst(rst), .init_bit(init_val[7]), .carga(carga), .d(d[7]), .q(q[7]));
endmodule

// A.1) Registrador padrão de 8 bits com Carga Paralela (usado para AC, REM, RDM e RI)
module registrador_8bits (
    input  wire       clk,
    input  wire       rst,
    input  wire       carga,
    input  wire [7:0] d,
    output wire [7:0] q
);
    registrador_8bits_init u_reg (
        .clk      (clk),
        .rst      (rst),
        .init_val (8'b0000_0000),
        .carga    (carga),
        .d        (d),
        .q        (q)
    );
endmodule

// A.2) Registrador de Estado NZ de 2 bits com Carga Paralela
module registrador_nz (
    input  wire clk,
    input  wire rst,
    input  wire cargaNZ,
    input  wire n_in,
    input  wire z_in,
    output wire n_out,
    output wire z_out
);
    // No reset: N = 0, Z = 1 (acumulador inicia em zero)
    ffd_carga ff_n (.clk(clk), .rst(rst), .init_bit(1'b0), .carga(cargaNZ), .d(n_in), .q(n_out));
    ffd_carga ff_z (.clk(clk), .rst(rst), .init_bit(1'b1), .carga(cargaNZ), .d(z_in), .q(z_out));
endmodule

// B) Contador de 8 bits PC com Carga Paralela (cargaPC) e Incremento (incrementaPC)
module contador_pc_8bits (
    input  wire       clk,
    input  wire       rst,
    input  wire       cargaPC,
    input  wire       incrementaPC,
    input  wire [7:0] d_in,
    output wire [7:0] pc_out
);
    wire [7:0] pc_mais_1;
    wire [7:0] prox_pc;
    wire       cout_unused;
    wire       en_pc;

    // Incrementador em nível de portas: pc_mais_1 = pc_out + 1
    somador_8bits u_inc (
        .a    (pc_out),
        .b    (8'b0000_0001),
        .cin  (1'b0),
        .s    (pc_mais_1),
        .cout (cout_unused)
    );

    // Se cargaPC=1, carrega d_in (endereço de salto vindo do RDM); senão, seleciona pc_mais_1
    mux2x1_8bits u_mux_pc (
        .d0  (pc_mais_1),
        .d1  (d_in),
        .sel (cargaPC),
        .y   (prox_pc)
    );

    // Habilita atualização do registrador PC quando cargaPC=1 OU incrementaPC=1
    or u_or_en (en_pc, cargaPC, incrementaPC);

    registrador_8bits u_reg_pc (
        .clk   (clk),
        .rst   (rst),
        .carga (en_pc),
        .d     (prox_pc),
        .q     (pc_out)
    );
endmodule

// Decodificador 2x4 em nível de portas (usado para DECOD. X e DECOD. Y da Memória RAM)
module decodificador_2x4 (
    input  wire [1:0] a,
    output wire [3:0] s
);
    wire na0, na1;
    not u_n0 (na0, a[0]);
    not u_n1 (na1, a[1]);

    and u_s0 (s[0], na1,  na0);  // 00
    and u_s1 (s[1], na1,  a[0]); // 01
    and u_s2 (s[2], a[1], na0);  // 10
    and u_s3 (s[3], a[1], a[0]); // 11
endmodule

// Célula de Memória de 8 bits (1 linha da matriz 4x4 conforme diagrama da Página 3)
// Possui entradas DI (8b), W (write), SX, SY e saída DO (8b controlada pela seleção SX e SY)
module celula_ram_8bits (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] init_val,
    input  wire [7:0] di,
    input  wire       w,
    input  wire       sx,
    input  wire       sy,
    output wire [7:0] do_bus,
    output wire [7:0] q_debug
);
    wire sel_xy, carga_celula;
    wire [7:0] q_reg;

    and u_sel   (sel_xy, sx, sy);
    and u_carga (carga_celula, sel_xy, w);

    registrador_8bits_init u_reg (
        .clk      (clk),
        .rst      (rst),
        .init_val (init_val),
        .carga    (carga_celula),
        .d        (di),
        .q        (q_reg)
    );

    // Saída DO habilitada por SX e SY
    and u_do0 (do_bus[0], q_reg[0], sel_xy);
    and u_do1 (do_bus[1], q_reg[1], sel_xy);
    and u_do2 (do_bus[2], q_reg[2], sel_xy);
    and u_do3 (do_bus[3], q_reg[3], sel_xy);
    and u_do4 (do_bus[4], q_reg[4], sel_xy);
    and u_do5 (do_bus[5], q_reg[5], sel_xy);
    and u_do6 (do_bus[6], q_reg[6], sel_xy);
    and u_do7 (do_bus[7], q_reg[7], sel_xy);

    buf u_b0 (q_debug[0], q_reg[0]);
    buf u_b1 (q_debug[1], q_reg[1]);
    buf u_b2 (q_debug[2], q_reg[2]);
    buf u_b3 (q_debug[3], q_reg[3]);
    buf u_b4 (q_debug[4], q_reg[4]);
    buf u_b5 (q_debug[5], q_reg[5]);
    buf u_b6 (q_debug[6], q_reg[6]);
    buf u_b7 (q_debug[7], q_reg[7]);
endmodule

// C) Memória RAM de 16 endereços x 8 bits (Matriz 4x4 com DECOD. X e DECOD. Y)
// Inicializada no sinal de RESET com o programa de 10 instruções (0000 a 1001)
// e 6 endereços de dados (1010 a 1111) conforme Passo 4.
module memoria_ram_16x8 (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] addr,     // A3, A2, A1, A0 (vindos do REM[3:0])
    input  wire [7:0] data_in,  // DADO A GRAVAR (RDM)
    input  wire       read,     // Sinal READ
    input  wire       write,    // Sinal WRITE
    output wire [7:0] data_out, // DADO LIDO (para RDM)
    output wire [7:0] mem10_dbg,
    output wire [7:0] mem11_dbg,
    output wire [7:0] mem12_dbg
);
    wire [3:0] sx; // Saídas do DECOD. X (A1, A0)
    wire [3:0] sy; // Saídas do DECOD. Y (A3, A2)

    decodificador_2x4 u_decod_x (.a(addr[1:0]), .s(sx));
    decodificador_2x4 u_decod_y (.a(addr[3:2]), .s(sy));

    wire [7:0] do_c [0:15];
    wire [7:0] q_dbg [0:15];

    // ========================================================================
    // PASSO 4: Programa Inicial (Endereços 0000 a 1001) + Dados (1010 a 1111)
    // ========================================================================
    // O programa realiza um laço de contagem/acumulação usando complemento de 2,
    // executando exatamente 10 instruções dinâmicas até parar em HLT:
    //   End 0,1 (0000,0001): LDA 10  (0x20, 0x0A) -> AC <- MEM[10] (-3 = 0xFD)
    //   End 2,3 (0010,0011): ADD 11  (0x30, 0x0B) -> AC <- AC + MEM[11] (+1)
    //   End 4,5 (0100,0101): JN  2   (0x90, 0x02) -> Se N=1 (AC < 0), volta p/ End 2
    //   End 6,7 (0110,0111): STA 12  (0x10, 0x0C) -> MEM[12] <- AC (grava 0x00)
    //   End 8   (1000)     : NOT     (0x60)       -> AC <- NOT(AC) (0xFF = -1)
    //   End 9   (1001)     : HLT     (0xF0)       -> Termina execução (10ª instrução!)
    // Dados (Endereços 1010 a 1111):
    //   End 10  (1010)     : 0xFD (-3 em complemento de 2: valor inicial)
    //   End 11  (1011)     : 0x01 (+1: passo de incremento)
    //   End 12  (1100)     : 0xAA (variável de saída, recebe 0x00 pelo STA 12)
    //   End 13  (1101)     : 0x0F (constante auxiliar 15)
    //   End 14  (1110)     : 0xF0 (constante auxiliar -16)
    //   End 15  (1111)     : 0x55 (constante auxiliar 85)
    // ========================================================================

    // Linha Y=0 (Endereços 0, 1, 2, 3)
    celula_ram_8bits c0  (.clk(clk), .rst(rst), .init_val(8'h20), .di(data_in), .w(write), .sx(sx[0]), .sy(sy[0]), .do_bus(do_c[0]),  .q_debug(q_dbg[0]));
    celula_ram_8bits c1  (.clk(clk), .rst(rst), .init_val(8'h0A), .di(data_in), .w(write), .sx(sx[1]), .sy(sy[0]), .do_bus(do_c[1]),  .q_debug(q_dbg[1]));
    celula_ram_8bits c2  (.clk(clk), .rst(rst), .init_val(8'h30), .di(data_in), .w(write), .sx(sx[2]), .sy(sy[0]), .do_bus(do_c[2]),  .q_debug(q_dbg[2]));
    celula_ram_8bits c3  (.clk(clk), .rst(rst), .init_val(8'h0B), .di(data_in), .w(write), .sx(sx[3]), .sy(sy[0]), .do_bus(do_c[3]),  .q_debug(q_dbg[3]));

    // Linha Y=1 (Endereços 4, 5, 6, 7)
    celula_ram_8bits c4  (.clk(clk), .rst(rst), .init_val(8'h90), .di(data_in), .w(write), .sx(sx[0]), .sy(sy[1]), .do_bus(do_c[4]),  .q_debug(q_dbg[4]));
    celula_ram_8bits c5  (.clk(clk), .rst(rst), .init_val(8'h02), .di(data_in), .w(write), .sx(sx[1]), .sy(sy[1]), .do_bus(do_c[5]),  .q_debug(q_dbg[5]));
    celula_ram_8bits c6  (.clk(clk), .rst(rst), .init_val(8'h10), .di(data_in), .w(write), .sx(sx[2]), .sy(sy[1]), .do_bus(do_c[6]),  .q_debug(q_dbg[6]));
    celula_ram_8bits c7  (.clk(clk), .rst(rst), .init_val(8'h0C), .di(data_in), .w(write), .sx(sx[3]), .sy(sy[1]), .do_bus(do_c[7]),  .q_debug(q_dbg[7]));

    // Linha Y=2 (Endereços 8, 9, 10, 11)
    celula_ram_8bits c8  (.clk(clk), .rst(rst), .init_val(8'h60), .di(data_in), .w(write), .sx(sx[0]), .sy(sy[2]), .do_bus(do_c[8]),  .q_debug(q_dbg[8]));
    celula_ram_8bits c9  (.clk(clk), .rst(rst), .init_val(8'hF0), .di(data_in), .w(write), .sx(sx[1]), .sy(sy[2]), .do_bus(do_c[9]),  .q_debug(q_dbg[9]));
    celula_ram_8bits c10 (.clk(clk), .rst(rst), .init_val(8'hFD), .di(data_in), .w(write), .sx(sx[2]), .sy(sy[2]), .do_bus(do_c[10]), .q_debug(q_dbg[10]));
    celula_ram_8bits c11 (.clk(clk), .rst(rst), .init_val(8'h01), .di(data_in), .w(write), .sx(sx[3]), .sy(sy[2]), .do_bus(do_c[11]), .q_debug(q_dbg[11]));

    // Linha Y=3 (Endereços 12, 13, 14, 15)
    celula_ram_8bits c12 (.clk(clk), .rst(rst), .init_val(8'hAA), .di(data_in), .w(write), .sx(sx[0]), .sy(sy[3]), .do_bus(do_c[12]), .q_debug(q_dbg[12]));
    celula_ram_8bits c13 (.clk(clk), .rst(rst), .init_val(8'h0F), .di(data_in), .w(write), .sx(sx[1]), .sy(sy[3]), .do_bus(do_c[13]), .q_debug(q_dbg[13]));
    celula_ram_8bits c14 (.clk(clk), .rst(rst), .init_val(8'hF0), .di(data_in), .w(write), .sx(sx[2]), .sy(sy[3]), .do_bus(do_c[14]), .q_debug(q_dbg[14]));
    celula_ram_8bits c15 (.clk(clk), .rst(rst), .init_val(8'h55), .di(data_in), .w(write), .sx(sx[3]), .sy(sy[3]), .do_bus(do_c[15]), .q_debug(q_dbg[15]));

    // Portas OR reunindo as 16 células e porta AND com o sinal READ (conforme Página 3)
    wire [7:0] bus_or;
    genvar b;
    generate
        for (b = 0; b < 8; b = b + 1) begin : gen_read_bus
            or u_or_bus (
                bus_or[b],
                do_c[0][b],  do_c[1][b],  do_c[2][b],  do_c[3][b],
                do_c[4][b],  do_c[5][b],  do_c[6][b],  do_c[7][b],
                do_c[8][b],  do_c[9][b],  do_c[10][b], do_c[11][b],
                do_c[12][b], do_c[13][b], do_c[14][b], do_c[15][b]
            );
            and u_and_read (data_out[b], bus_or[b], read);
        end
    endgenerate

    assign mem10_dbg = q_dbg[10];
    assign mem11_dbg = q_dbg[11];
    assign mem12_dbg = q_dbg[12];
endmodule

// ============================================================================
// PASSO 3: Projeto da Unidade de Controle (FSM) em Nível de Portas Lógicas
// - Contador de Temporização de 3 bits + Decodificador 3x8 (gera t0 a t7)
// - Lógica Combinacional dos Sinais de Controle conforme Organização Neander
// ============================================================================

// Decodificador 3x8 em nível de portas (gera os pulsos de tempo t0 a t7)
module decodificador_3x8 (
    input  wire [2:0] c,
    output wire [7:0] t
);
    wire nc0, nc1, nc2;
    not u_n0 (nc0, c[0]);
    not u_n1 (nc1, c[1]);
    not u_n2 (nc2, c[2]);

    and u_t0 (t[0], nc2,  nc1,  nc0);  // 000
    and u_t1 (t[1], nc2,  nc1,  c[0]); // 001
    and u_t2 (t[2], nc2,  c[1], nc0);  // 010
    and u_t3 (t[3], nc2,  c[1], c[0]); // 011
    and u_t4 (t[4], c[2], nc1,  nc0);  // 100
    and u_t5 (t[5], c[2], nc1,  c[0]); // 101
    and u_t6 (t[6], c[2], c[1], nc0);  // 110
    and u_t7 (t[7], c[2], c[1], c[0]); // 111
endmodule

// Gerador dos sinais de temporização (t0..t7) com goto_t0 e parada em HLT
module gerador_temporizacao (
    input  wire       clk,
    input  wire       rst,
    input  wire       goto_t0,
    input  wire       halt_ativo,
    output wire [2:0] estado_cnt,
    output wire [7:0] t
);
    wire [2:0] inc_cnt;
    wire [2:0] prox_cnt;
    wire       c1_and_c0, n_goto_t0, en_cnt;

    // Lógica de incremento de 3 bits (cnt + 1) em nível de portas
    not u_inc0 (inc_cnt[0], estado_cnt[0]);
    xor u_inc1 (inc_cnt[1], estado_cnt[1], estado_cnt[0]);
    and u_c1c0 (c1_and_c0,  estado_cnt[1], estado_cnt[0]);
    xor u_inc2 (inc_cnt[2], estado_cnt[2], c1_and_c0);

    // Se goto_t0 = 1, o próximo estado do contador volta para 000 (t0)
    not u_ngoto (n_goto_t0, goto_t0);
    and u_p0    (prox_cnt[0], inc_cnt[0], n_goto_t0);
    and u_p1    (prox_cnt[1], inc_cnt[1], n_goto_t0);
    and u_p2    (prox_cnt[2], inc_cnt[2], n_goto_t0);

    // Se halt_ativo = 1, congela o contador de tempo
    not u_nhalt (en_cnt, halt_ativo);

    // 3 Flip-Flops D para armazenar o estado atual do ciclo de busca/execução
    ffd_carga ff_t0 (.clk(clk), .rst(rst), .init_bit(1'b0), .carga(en_cnt), .d(prox_cnt[0]), .q(estado_cnt[0]));
    ffd_carga ff_t1 (.clk(clk), .rst(rst), .init_bit(1'b0), .carga(en_cnt), .d(prox_cnt[1]), .q(estado_cnt[1]));
    ffd_carga ff_t2 (.clk(clk), .rst(rst), .init_bit(1'b0), .carga(en_cnt), .d(prox_cnt[2]), .q(estado_cnt[2]));

    decodificador_3x8 u_dec_t (
        .c (estado_cnt),
        .t (t)
    );
endmodule

// Unidade de Controle completa do Processador Neander em nível de portas lógicas
module unidade_controle (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] opcode,       // RI[7:4]
    input  wire       N,            // Flag Negativo
    input  wire       Z,            // Flag Zero
    output wire       sel,          // Seletor do MUX do REM (0=PC, 1=RDM)
    output wire       cargaREM,     // Carga do REM
    output wire       cargaRDM,     // Carga do RDM a partir do AC (para STA)
    output wire       cargaRI,      // Carga do RI
    output wire       cargaAC,      // Carga do Acumulador (AC)
    output wire       cargaNZ,      // Carga do Registrador de Estado (NZ)
    output wire       cargaPC,      // Carga paralela do PC (Saltos)
    output wire       incrementaPC, // Incremento do PC (PC <- PC + 1)
    output wire [2:0] selUAL,       // Seleção de operação da UAL
    output wire       read,         // Leitura da Memória RAM
    output wire       write,        // Escrita na Memória RAM
    output wire       halt_out,     // Indica processador parado em HLT
    output wire [2:0] tempo_cnt,    // Contador de tempo (0..7) para depuração
    output wire [7:0] t_out         // Sinais t0..t7 para depuração
);
    // Sinais decodificados da instrução atual
    wire NOP, STA, LDA, ADD, OR_op, AND_op, NOT_op, JMP, JN, JZ, HLT;

    decodificador_4x16 u_decod_inst (
        .op     (opcode),
        .NOP    (NOP),
        .STA    (STA),
        .LDA    (LDA),
        .ADD    (ADD),
        .OR_op  (OR_op),
        .AND_op (AND_op),
        .NOT_op (NOT_op),
        .JMP    (JMP),
        .JN     (JN),
        .JZ     (JZ),
        .HLT    (HLT)
    );

    wire [7:0] t;
    wire       goto_t0;

    gerador_temporizacao u_temp (
        .clk        (clk),
        .rst        (rst),
        .goto_t0    (goto_t0),
        .halt_ativo (halt_out),
        .estado_cnt (tempo_cnt),
        .t          (t)
    );

    assign t_out = t;

    // Sinais auxiliares das condições de salto (JN e JZ)
    wire nN, nZ;
    wire jn_sim, jn_nao, jz_sim, jz_nao;
    not u_not_n  (nN, N);
    not u_not_z  (nZ, Z);
    and u_jn_sim (jn_sim, JN, N);
    and u_jn_nao (jn_nao, JN, nN);
    and u_jz_sim (jz_sim, JZ, Z);
    and u_jz_nao (jz_nao, JZ, nZ);

    // Agrupamentos de instruções conforme equações booleanas do Neander
    wire grp_mem5;      // STA + LDA + ADD + OR + AND
    wire grp_alu4;      // LDA + ADD + OR + AND
    wire grp_salto_sim; // JMP + JN.N + JZ.Z
    wire grp_salto_nao; // JN.N' + JZ.Z'
    wire grp_t3_rem;    // STA + LDA + ADD + OR + AND + JMP + JN.N + JZ.Z

    or u_g_mem5      (grp_mem5,      STA, LDA, ADD, OR_op, AND_op);
    or u_g_alu4      (grp_alu4,      LDA, ADD, OR_op, AND_op);
    or u_g_salto_sim (grp_salto_sim, JMP, jn_sim, jz_sim);
    or u_g_salto_nao (grp_salto_nao, jn_nao, jz_nao);
    or u_g_t3_rem    (grp_t3_rem,    grp_mem5, grp_salto_sim);

    // 1) cargaREM = t0 + t3.(STA+LDA+ADD+OR+AND+JMP+JN.N+JZ.Z) + t5.(STA+LDA+ADD+OR+AND)
    wire crem_t3, crem_t5;
    and u_crem_t3 (crem_t3, t[3], grp_t3_rem);
    and u_crem_t5 (crem_t5, t[5], grp_mem5);
    or  u_crem    (cargaREM, t[0], crem_t3, crem_t5);

    // 2) incrementaPC = t1 + t4.(STA+LDA+ADD+OR+AND) + t3.(JN.N' + JZ.Z')
    wire inc_t4, inc_t3;
    and u_inc_t4 (inc_t4, t[4], grp_mem5);
    and u_inc_t3 (inc_t3, t[3], grp_salto_nao);
    or  u_inc_pc (incrementaPC, t[1], inc_t4, inc_t3);

    // 3) cargaRI = t2
    buf u_cri (cargaRI, t[2]);

    // 4) sel = t5.(STA+LDA+ADD+OR+AND)
    and u_sel (sel, t[5], grp_mem5);

    // 5) cargaRDM = t6.STA
    and u_crdm (cargaRDM, t[6], STA);

    // 6) Read = t1 + t4.(STA+LDA+ADD+OR+AND+JMP+JN.N+JZ.Z) + t6.(LDA+ADD+OR+AND)
    wire rd_t4, rd_t6;
    and u_rd_t4 (rd_t4, t[4], grp_t3_rem);
    and u_rd_t6 (rd_t6, t[6], grp_alu4);
    or  u_read  (read,  t[1], rd_t4, rd_t6);

    // 7) Write = t7.STA
    and u_write (write, t[7], STA);

    // 8) Sinais de operação da UAL:
    //    UAL(ADD) = t7.ADD  -> selUAL = 000
    //    UAL(AND) = t7.AND  -> selUAL = 001
    //    UAL(OR)  = t7.OR   -> selUAL = 010
    //    UAL(NOT) = t3.NOT  -> selUAL = 011
    //    UAL(Y)   = t7.LDA  -> selUAL = 100
    wire ual_y, ual_add, ual_or, ual_and, ual_not;
    and u_uy   (ual_y,   t[7], LDA);
    and u_uadd (ual_add, t[7], ADD);
    and u_uor  (ual_or,  t[7], OR_op);
    and u_uand (ual_and, t[7], AND_op);
    and u_unot (ual_not, t[3], NOT_op);

    or  u_sel_ual0 (selUAL[0], ual_and, ual_not);
    or  u_sel_ual1 (selUAL[1], ual_or,  ual_not);
    buf u_sel_ual2 (selUAL[2], ual_y);

    // 9) cargaAC = t7.(LDA+ADD+OR+AND) + t3.NOT
    // 10) cargaNZ = cargaAC
    wire cac_t7;
    and u_cac_t7 (cac_t7,  t[7], grp_alu4);
    or  u_cac    (cargaAC, cac_t7, ual_not);
    buf u_cnz    (cargaNZ, cargaAC);

    // 11) cargaPC = t5.(JMP+JN.N+JZ.Z)
    and u_cpc (cargaPC, t[5], grp_salto_sim);

    // 12) goto_t0 = t7.(STA+LDA+ADD+OR+AND) + t3.(NOP+NOT+JN.N'+JZ.Z') + t5.(JMP+JN.N+JZ.Z)
    wire grp_t3_fim, gt0_t7, gt0_t3, gt0_t5;
    or  u_g_t3_fim (grp_t3_fim, NOP, NOT_op, grp_salto_nao);
    and u_gt0_t7   (gt0_t7, t[7], grp_mem5);
    and u_gt0_t3   (gt0_t3, t[3], grp_t3_fim);
    and u_gt0_t5   (gt0_t5, t[5], grp_salto_sim);
    or  u_gt0      (goto_t0, gt0_t7, gt0_t3, gt0_t5);

    // 13) Halt = t3.HLT
    and u_halt (halt_out, t[3], HLT);
endmodule

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
