module ice_spram(
    input           ram_clk,
    input   [13:0]  ram_addr,
    input   [15:0]  ram_data_in,
    output  [15:0]  ram_data_out,
    input           ram_we,
);

SB_SPRAM256KA spram (
    .ADDRESS(ram_addr),
    .DATAIN(ram_data_in),
    .MASKWREN({ram_we, ram_we, ram_we, ram_we}),
    .WREN(ram_we),
    .CHIPSELECT(1'b1),
    .CLOCK(ram_clk),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(ram_data_out)
);
    
endmodule