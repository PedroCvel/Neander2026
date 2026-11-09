`timescale 1ns/1ps

module tb_neander;
    reg        clk;
    reg        rst;
    wire [7:0] pc;
    wire [7:0] ac;
    wire [7:0] ri;
    wire [7:0] rem;
    wire [7:0] rdm;
    wire       N;
    wire       Z;
    wire       halt;
    wire [2:0] tempo;
    wire [7:0] mem10;
    wire [7:0] mem11;
    wire [7:0] mem12;

    integer instr_count;

    neander_top dut (
        .clk       (clk),
        .rst       (rst),
        .pc_out    (pc),
        .ac_out    (ac),
        .ri_out    (ri),
        .rem_out   (rem),
        .rdm_out   (rdm),
        .n_out     (N),
        .z_out     (Z),
        .halt_out  (halt),
        .tempo_out (tempo),
        .mem10_dbg (mem10),
        .mem11_dbg (mem11),
        .mem12_dbg (mem12)
    );

    // Geração de clock: período de 20ns (10ns baixo, 10ns alto)
    always #10 clk = ~clk;

    // Nome legível do opcode para exibição no terminal
    function [31:0] nome_inst;
        input [3:0] op;
        begin
            case (op)
                4'b0000: nome_inst = "NOP ";
                4'b0001: nome_inst = "STA ";
                4'b0010: nome_inst = "LDA ";
                4'b0011: nome_inst = "ADD ";
                4'b0100: nome_inst = "OR  ";
                4'b0101: nome_inst = "AND ";
                4'b0110: nome_inst = "NOT ";
                4'b1000: nome_inst = "JMP ";
                4'b1001: nome_inst = "JN  ";
                4'b1010: nome_inst = "JZ  ";
                4'b1111: nome_inst = "HLT ";
                default: nome_inst = "??? ";
            endcase
        end
    endfunction

    initial begin
        $dumpfile("neander.vcd");
        $dumpvars(0, tb_neander);

        clk = 0;
        rst = 1;
        instr_count = 0;

        $display("=========================================================================================");
        $display("  SIMULACAO DO PROCESSADOR NEANDER EM NIVEL DE PORTAS LOGICAS (VERILOG)                  ");
        $display("=========================================================================================");
        #25;
        rst = 0;
        $display("Reset liberado. Estado inicial: PC=%0d | AC=%02h (%0d) | N=%b Z=%b | MEM[10]=%02h (%0d) MEM[11]=%02h MEM[12]=%02h",
                 pc, ac, $signed(ac), N, Z, mem10, $signed(mem10), mem11, mem12);
        $display("-----------------------------------------------------------------------------------------");
    end

    // Monitora cada ciclo de clock
    always @(posedge clk) begin
        if (!rst) begin
            #3; // Aguarda propagação das portas lógicas após a borda de subida
            if (tempo == 3'd3) begin
                instr_count = instr_count + 1;
                $display("[Inst #%02d | t%0d] Decodificou %s (RI=%02h) | PC=%02d | AC=%02h (%4d) | N=%b Z=%b | MEM[12]=%02h",
                         instr_count, tempo, nome_inst(ri[7:4]), ri, pc, ac, $signed(ac), N, Z, mem12);
            end else if (tempo == 3'd0) begin
                $display("          [t0] Fim da instrucao -> Estado atualizado: PC=%02d | AC=%02h (%4d) | N=%b Z=%b | MEM[12]=%02h",
                         pc, ac, $signed(ac), N, Z, mem12);
            end

            if (halt) begin
                $display("-----------------------------------------------------------------------------------------");
                $display("PROCESSADOR PARADO EM HLT APOS %0d INSTRUCOES EXECUTADAS!", instr_count);
                $display("Estado Final: PC=%02d | AC=0x%02h (%0d) | N=%b | Z=%b | MEM[10]=0x%02h | MEM[11]=0x%02h | MEM[12]=0x%02h",
                         pc, ac, $signed(ac), N, Z, mem10, mem11, mem12);
                $display("=========================================================================================");
                #20;
                $finish;
            end
        end
    end

    // Timeout de segurança
    initial begin
        #3000;
        $display("Timeout atingido!");
        $finish;
    end
endmodule
