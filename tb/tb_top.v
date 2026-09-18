`timescale 1ns/1ps
module tb_top;
    reg [2:0] i_ALU_OP;
    reg [31:0] i_register_RS_1, i_register_RS_2, I_pc_output, i_immediate;
    reg i_B_sel, i_A_Sel;
    wire [31:0] o_Q;
    reg [31:0] a, b, expected;
    integer errors, checks, op, sel_a, sel_b, test_case;

    top dut (
        .i_ALU_OP(i_ALU_OP), .i_register_RS_1(i_register_RS_1),
        .i_register_RS_2(i_register_RS_2), .I_pc_output(I_pc_output),
        .i_immediate(i_immediate), .i_B_sel(i_B_sel),
        .i_A_Sel(i_A_Sel), .o_Q(o_Q)
    );

    task check;
        begin
            a = i_A_Sel ? I_pc_output : i_register_RS_1;
            b = i_B_sel ? i_immediate : i_register_RS_2;
            case (i_ALU_OP)
                3'b001: expected = a - b;
                3'b010: expected = a & b;
                3'b011: expected = a | b;
                3'b100: expected = a ^ b;
                default: expected = a + b;
            endcase
            #1;
            checks = checks + 1;
            if (o_Q !== expected) begin
                errors = errors + 1;
                $display("FAIL op=%b A_sel=%b B_sel=%b a=%h b=%h got=%h expected=%h",
                         i_ALU_OP, i_A_Sel, i_B_sel, a, b, o_Q, expected);
            end
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;
        for (test_case = 0; test_case < 4; test_case = test_case + 1) begin
            case (test_case)
                0: begin
                    i_register_RS_1 = 32'd15; i_register_RS_2 = 32'd7;
                    I_pc_output = 32'h0040_0000; i_immediate = 32'd4;
                end
                1: begin
                    i_register_RS_1 = 32'hFFFF_FFFF; i_register_RS_2 = 32'd1;
                    I_pc_output = 32'h8000_0000; i_immediate = 32'hFFFF_FFFE;
                end
                2: begin
                    i_register_RS_1 = 32'h8000_0000; i_register_RS_2 = 32'h7FFF_FFFF;
                    I_pc_output = 32'h1234_5678; i_immediate = 32'hAAAA_5555;
                end
                3: begin
                    i_register_RS_1 = 32'd0; i_register_RS_2 = 32'd0;
                    I_pc_output = 32'hFFFF_FFFC; i_immediate = 32'h0000_0004;
                end
            endcase
            for (sel_a = 0; sel_a < 2; sel_a = sel_a + 1)
                for (sel_b = 0; sel_b < 2; sel_b = sel_b + 1)
                    for (op = 0; op < 8; op = op + 1) begin
                        i_A_Sel = sel_a;
                        i_B_sel = sel_b;
                        i_ALU_OP = op;
                        check();
                    end
        end
        if (errors == 0) $display("PASS: %0d checks", checks);
        else $display("FAIL: %0d errors in %0d checks", errors, checks);
        if (errors != 0) $fatal(1, "ALU verification failed");
        $finish;
    end
endmodule
