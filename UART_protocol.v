`timescale 1ns / 1ps

module UART_protocol(
input clk,
input start,
input [7:0] txin,
output reg tx,
input rx,
output [7:0] rxout,
output  rxdone,
output  txdone
    );
    parameter clk_value = 100_000;
    parameter baud = 9600;
    parameter wait_count = clk_value / baud;
    integer count = 0;
    reg bitdone = 0;
    parameter idle = 0,send = 1, check = 2;
    reg [1:0] state = idle;
    always@(posedge clk) begin
    if(state == idle)
    begin
    count <= 0;
    end
    else begin
    if(count == wait_count)
     begin
    bitdone <=1'b1;
    count <= 0;
    end
    else 
    begin
    count <= count + 1;
    bitdone <= 1'b0;
    end
    end
    end
    reg [9:0] txdata;//stop and statr data include
    integer bitindex = 0;
    reg [9:0] shifttx = 0;
    always@(posedge clk)
    begin
    case(state)
    idle: 
        begin
    tx    <= 1'b1;
    txdata   <= 0;
    bitindex <= 0;
    shifttx  <= 0;
    if(start == 1'b1)
    begin
    txdata <= {1'b1,txin,1'b0};//{start,data,stop}
    state  <= send;
        end
        else begin
        state <= idle;
        end
    end
    send: begin
    tx <= txdata[bitindex];
    state <= check;
    shifttx <= {txdata[bitindex],shifttx[9:1]};
    end
     check:
     begin
     if (bitindex <= 9)//0-9=10
        begin
     if (bitdone == 1'b1)
     begin
     state <= send;
     bitindex <= bitindex + 1;
     end
     else   begin
     state <= idle ;
     bitindex <= 0;
            end
     end
     end
     default: state <= idle;
     endcase
     end
     assign txdone = (bitindex == 9 && bitdone == 1'b1) ? 1'b1 : 1'b0;
     ///RXlogic
     integer rcount = 0;
     integer rindex = 0;
     parameter ridle = 0, rwait = 1, recv = 2, rcheck = 3;
     reg [1:0] rstate;
     reg [9:0] rxdata;
     always@(posedge clk)
      begin
     case(rstate) 
     idle: begin
     rxdata <= 0;
     rstate <= 0;
     rcount <= 0;
     if(rx == 1'b1)
     begin
     state <= rwait;
     end
     else begin
     rstate <= ridle;
     end
     end
     rwait: 
     begin
     if (rcount < wait_count / 2)
     begin
     rcount <= rcount + 1;
     rstate <= rwait;
     end
     else begin
     rcount <= 0;
     state  <= recv;
     rxdata <= {rx,rxdata[9:1]};
     end
     end
     recv : 
     begin
     if (rindex <= 9)
     begin
     if(bitdone == 1'b1)
     begin
     rindex <= rindex + 1;
     rstate <= rwait;
     end
     end
     else begin
     rstate <= ridle;
     rindex <= 0;
     end
     end
     default : 
     rstate <= ridle;
     endcase
     end
     assign rxout = rxdata [8:1]; 
     assign rxdone = (rindex == 9 && bitdone == 1'b1)? 1'b1 : 1'b0;
endmodule
