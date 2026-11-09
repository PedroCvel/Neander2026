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
