module ice_spram(
    input           clk,
    input   [7:0]   addr,
    input   [15:0]  in,
    output  [15:0]  out,
    input           we,
);

SB_SPRAM256KA spram (
    .ADDRESS(addr),
    .DATAIN(in),
    .MASKWREN({we, we, we, we}),
    .WREN(we),
    .CHIPSELECT(1'b1),
    .CLOCK(clk),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(out)
);
    
endmodule