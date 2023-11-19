 `timescale 1ns / 1ps
module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
    parameter IDLE = 5'd0,
    parameter coeff_INPUT_1 = 5'd1,
    parameter coeff_INPUT_2 = 5'd2,
    parameter coeff_check_1 = 5'd3,
    parameter coeff_check_2 = 5'd4,
    parameter coeff_check_3 = 5'd5,
    parameter coeff_check_4 = 5'd6,
    parameter coeff_check_5 = 5'd7,
    parameter AP_START = 5'd8,
    parameter DATA_INPUT_0 = 5'd9,
    parameter DATA_INPUT_1 = 5'd10,
    parameter coeff_0 = 5'd11,
    parameter coeff_1 = 5'd12,
    parameter coeff_2 = 5'd13,
    parameter coeff_3 = 5'd14,
    parameter coeff_4 = 5'd15,
    parameter coeff_5 = 5'd16,
    parameter coeff_6 = 5'd17,
    parameter coeff_7 = 5'd18,
    parameter coeff_8 = 5'd19,
    parameter coeff_9 = 5'd20,
    parameter coeff_10 = 5'd21,
    parameter OUTPUT = 5'd22,
    parameter WAIT = 5'd23,
    parameter WAIT_1 = 5'd24
)
(
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,    
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);
begin

    // write your code here!

    //ram
    reg [4:0] state;
    reg [4:0] next_state;
    reg signed [31:0] tap_Di_buffer, data_Di_buffer, rdata_buffer, sm_tdata_buffer, acc, multi_buffer;
    reg [11:0] data_A_buffer, tap_A_buffer;
    reg [3:0] data_WE_buffer, tap_WE_buffer;
    reg [31:0] count, ap_signal, length;
    reg data_EN_buffer, tap_EN_buffer, sm_tlast_buffer, sm_tvalid_buffer, ss_tready_buffer, rvalid_buffer, arready_buffer, wready_buffer, awready_buffer;
    reg [3:0] ap_start, ap_done, ap_idle;

    assign tap_Di = tap_Di_buffer;
    assign data_Di = data_Di_buffer;
    assign rdata = rdata_buffer;
    assign sm_tdata = sm_tdata_buffer;
    assign data_A = data_A_buffer;
    assign tap_A = tap_A_buffer;
    assign data_WE = data_WE_buffer;
    assign tap_WE = tap_WE_buffer;
    assign data_EN = data_EN_buffer;
    assign tap_EN = tap_EN_buffer;
    assign sm_tlast = sm_tlast_buffer;
    assign sm_tvalid = sm_tvalid_buffer;
    assign ss_tready = ss_tready_buffer;
    assign rvalid = rvalid_buffer;
    assign arready = arready_buffer;
    assign wready = wready_buffer;
    assign awready = awready_buffer;
    // assign ap_start = ap_signal[0];
    // assign ap_done = ap_signal[1];
    // assign ap_idle = ap_signal[2];



    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            state <= IDLE;
            tap_Di_buffer <= 0;
            data_Di_buffer <= 0;
            rdata_buffer <= 0;
            sm_tdata_buffer <= 0;
            data_A_buffer <= 12'h00;
            tap_A_buffer <= 0;
            data_WE_buffer <= 0;
            tap_WE_buffer <= 0;
            data_EN_buffer <= 0;
            tap_EN_buffer <= 0;
            sm_tlast_buffer <= 0;
            sm_tvalid_buffer <= 0;
            ss_tready_buffer <= 0;
            rvalid_buffer <= 0;
            arready_buffer <= 0;
            wready_buffer <= 0;
            awready_buffer <= 0;
            ap_signal[0] <= 0;
            ap_signal[1] <= 0;
            ap_signal[2] <= 1;
            length <= 32'h00;
        end
        else begin
            state <= next_state;
            if (state == IDLE) begin
                tap_WE_buffer <= 4'b0000;
                rvalid_buffer <= 0;
                wready_buffer <= 0;
                data_EN_buffer <= 0;
                // ap_signal[0] <= 0;
                // ap_signal[1] <= 0;
                // ap_signal[2] <= 1;
            end
            else if (state == coeff_INPUT_1) begin
                ap_signal[0] <= 0;
                ap_signal[1] <= 0;
                ap_signal[2] <= 1;
                //input coeff
                tap_EN_buffer <= 1;
                tap_WE_buffer <= 4'b1111;
                if (awaddr == 12'h10) begin
                    tap_A_buffer <= awaddr;
                    length <= wdata;
                end
                else begin
                    tap_A_buffer <= awaddr - 12'h20;
                    data_A_buffer <= awaddr - 12'h20;
                end
                tap_Di_buffer <= wdata;
                wready_buffer <= 1;
                awready_buffer <= 1;
                
                //reset data ram
                data_EN_buffer <= 1;
                data_WE_buffer <= 4'b1111;
                data_Di_buffer <= 0;
            end
            else if (state == coeff_INPUT_2) begin
                //coeff
                tap_WE_buffer <= 4'b0000;
                wready_buffer <= 0;
                awready_buffer <= 0;
                //data
                data_WE_buffer <= 4'b0000;
            end
            else if (state == coeff_check_1) begin
                
            end
            else if (state == coeff_check_2) begin
                tap_A_buffer <= araddr - 12'h20;
            //    $display ("123");
            end
            else if (state == coeff_check_3) begin
                
            end
            else if (state == coeff_check_4) begin
                rdata_buffer <= tap_Do;
                rvalid_buffer <= 1;
            end
            else if (state == AP_START) begin
                wready_buffer <=1;
                ap_signal <= wdata;
                tap_EN_buffer <= 0;
                //$display ("%d", wdata);
            end
            else if (state == DATA_INPUT_0) begin
                //reset ap_start
                ap_signal[0] <= 0;
                ap_signal[2] <= 0;
                //data write
                data_EN_buffer <= 1;
                data_WE_buffer <= 4'b1111;
                data_Di_buffer <= ss_tdata;
                data_A_buffer <= 12'h00;
                ss_tready_buffer <= 1;
                //coeff read
                tap_A_buffer <= 12'h00;
                tap_EN_buffer <= 1;
                tap_WE_buffer <= 0;
                acc <= 32'd0;
                multi_buffer <= tap_Do * ss_tdata;
                count <= 32'd0;
            end
            else if (state == DATA_INPUT_1) begin
                sm_tvalid_buffer <= 0;
                rvalid_buffer <= 1;
                //data write
                data_EN_buffer <= 1;
                data_WE_buffer <= 4'b1111;
                data_Di_buffer <= ss_tdata;
                ss_tready_buffer <= 1;
                //coeff read
                tap_A_buffer <= 12'h00;
                tap_EN_buffer <= 1;
                tap_WE_buffer <= 0;
                acc <= 0;
                multi_buffer <= tap_Do * ss_tdata;
            end
            else if (state == coeff_0) begin
                data_WE_buffer <= 4'b0000;
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=1
                ss_tready_buffer <= 0;
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_1) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=2
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_2) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=3
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_3) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=4
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_4) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=5
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_5) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=6
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_6) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=7
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_7) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=8
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_8) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=9
                if (data_A_buffer == 12'h00) 
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_9) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                tap_A_buffer <= tap_A_buffer + 12'h04; //addr=10
                if (data_A_buffer == 12'h00)
                    data_A_buffer <= 12'h28;
                else    data_A_buffer <= data_A_buffer - 12'h04;
            end
            else if (state == coeff_10) begin
                acc <= acc + multi_buffer;
                multi_buffer <= tap_Do * data_Do;
                //sm_tvalid_buffer <= 1;
            end
            if (state == OUTPUT) begin
                sm_tvalid_buffer <= 1;
                sm_tdata_buffer <= acc + multi_buffer;
                count <= count + 32'd1;
            end
            if (state == WAIT) begin
                sm_tvalid_buffer <= 0;
                rvalid_buffer <= 1;
            end
            if (state == WAIT_1) begin
                sm_tvalid_buffer <= 0;
                rvalid_buffer <= 1;
                rdata_buffer[1] <= 1;
                rdata_buffer[2] <= 1;
                ap_signal[1] <= 1;
                ap_signal[2] <= 1;
            end


        end
    end

    always @ (*) begin
        ap_start = ap_signal[0];
        ap_done = ap_signal[1];
        ap_idle = ap_signal[2];
        next_state = 5'dx;
        case (state)
            IDLE: 
                if(awvalid == 1 & awaddr >= 12'h10) begin
                        next_state = coeff_INPUT_1;
                end
                else if(arvalid == 1)  begin
                    next_state = coeff_check_1;
                //    $display ("12345");
                end
                else if(awaddr == 12'h00 & wvalid == 1) begin
                    next_state = AP_START;
                    //$display ("123");
                end
                else if(ap_signal[0] == 1) begin
                    next_state = DATA_INPUT_0;
                end
                else begin
                    next_state = IDLE;
                end
            coeff_INPUT_1: next_state = coeff_INPUT_2;
            coeff_INPUT_2: next_state = IDLE;
            coeff_check_1: next_state = coeff_check_2;
            coeff_check_2: next_state = coeff_check_3;
            coeff_check_3: next_state = coeff_check_4;
            coeff_check_4: next_state = IDLE;
            AP_START: next_state = IDLE;
            DATA_INPUT_0: next_state = coeff_0;
            DATA_INPUT_1: next_state = coeff_0;
                /*if(count == 32'd599) begin
                    next_state = OUTPUT_1;
                end
                else begin            
                    next_state = coeff_0;
                end*/
            coeff_0: next_state = coeff_1;
            coeff_1: next_state = coeff_2;
            coeff_2: next_state = coeff_3;
            coeff_3: next_state = coeff_4;
            coeff_4: next_state = coeff_5;
            coeff_5: next_state = coeff_6;
            coeff_6: next_state = coeff_7;
            coeff_7: next_state = coeff_8;
            coeff_8: next_state = coeff_9;
            coeff_9: next_state = coeff_10;
            coeff_10: next_state = OUTPUT;
                /*if(count == 32'd599) begin
                    next_state = OUTPUT_1;
                end
                else begin
                    next_state = OUTPUT;
                end*/
            OUTPUT: 
                if(count == 32'd599) begin
                    next_state = WAIT;
                end
                else begin
                    next_state = DATA_INPUT_1;
                end
            WAIT: next_state = WAIT_1;
            WAIT_1:
                if(ss_tlast == 1) begin
                    next_state = DATA_INPUT_1;
                end
                else begin
                    next_state = WAIT_1;
                end
        endcase
    end

    
end
endmodule