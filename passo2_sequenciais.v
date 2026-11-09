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
