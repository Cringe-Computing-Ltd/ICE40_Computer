module ice_pll(input clk_in, output clk_out);
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0100),
        .DIVF(7'b1010000),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b001),
    ) SB_PLL40_CORE_inst (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PLLOUTCORE(clk_out),
        .REFERENCECLK(clk_in)
   );
endmodule