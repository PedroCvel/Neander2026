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
