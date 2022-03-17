module ice_bram(
    // Read port
    input           rclk,
    input   [7:0]   raddr,
    output  [15:0]  rdata,

    // Write port
    input           wclk,
    input           we,
    input   [7:0]   waddr,
    input   [15:0]  wdata,
);

    SB_RAM40_4K SB_RAM40_4K_inst(
        .RDATA(rdata), .RADDR(raddr), .WADDR(waddr), .MASK(16'h0000), .WDATA(wdata), .RCLKE(1), .RCLK(rclk), .RE(1), .WCLKE(1), .WCLK(wclk), .WE(we)
    );
endmodule