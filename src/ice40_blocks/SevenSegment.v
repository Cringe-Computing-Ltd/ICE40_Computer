module SevenSegment(
    input   wire    [3:0]   inp,
    output  reg     [6:0]   outp
);

always @(inp) begin
    case (inp)
        4'h0 : outp = 7'b0111111;
        4'h1 : outp = 7'b0000110;
        4'h2 : outp = 7'b1011011;
        4'h3 : outp = 7'b1001111;
        4'h4 : outp = 7'b1100110;
        4'h5 : outp = 7'b1101101;
        4'h6 : outp = 7'b1111101;
        4'h7 : outp = 7'b0000111;
        4'h8 : outp = 7'b1111111;
        4'h9 : outp = 7'b1101111;
        4'hA : outp = 7'b1110111;
        4'hB : outp = 7'b1111100;
        4'hC : outp = 7'b0111001;
        4'hD : outp = 7'b1011110;
        4'hE : outp = 7'b1111001;
        4'hF : outp = 7'b1110001;
    endcase
end

endmodule