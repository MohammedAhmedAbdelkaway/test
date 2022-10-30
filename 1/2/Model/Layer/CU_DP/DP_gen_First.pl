#*COMMENTED*#

use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";

#######################################################
############    ARGUMENTS DISCRIPTION    ##############
#######################################################

#ARGV[0]  no of the conv 
#ARGV[1]  Mul number
#ARGV[2]  ARITH_TYPE
#ARGV[3]  DATA_WIDTH
#ARGV[4]  ADDRESS_BITS
#ARGV[5]  IFM_WIDTH 
#ARGV[6]  IFM_HEIGHT  
#ARGV[7]  IFM_DEPTH 
#ARGV[8]  KERNAL_SIZE  
#ARGV[9]  NUMBER_OF_FILTERS
#ARGV[10]  RGB 0gray 1 rgb
#ARGV[11] stride
#ARGV[12] PADDING_EXIST
#ARGV[13] relative path

#######################################################
##################    CONSTANTS    ####################
#######################################################
my $module = <<"DONATE";
`timescale 1ns / 1ps


module 
DONATE
my $parameter = "#(parameter";

my $always_clk = <<"DONATE";
always @ (posedge clk)
    begin 
DONATE
my $end = "end";
my $end_module = "endmodule";
my $i_p = "input";
my $o_p = "output";
my $under_Score = "_";
my $clog2 = "\$clog2";

my $data_width = "DATA_WIDTH";
my $address_bits = "ADDRESS_BITS";

my $ifm_width = "IFM_WIDTH";
my $ifm_height = "IFM_HEIGHT";                                                                                      
my $ifm_depth = "IFM_DEPTH";
my $kernal_size = "KERNAL_SIZE";
my $number_of_filters = "NUMBER_OF_FILTERS";
my $number_of_units = "NUMBER_OF_UNITS";
my $full_path = "../../../$ARGV[13]/";
#########################################################

my $i = 0;
my $j = 0;
my $jj = 0;
my $file_name;
my $module_name;
my $adder_name = "adder";
my $mul_name = "multiplier";
my $odd_flag;
my $dummy_level;
my @levels;
my $levels_number;
my $dual_port_name = "true_dual_port_memory";
my $single_port_name = "single_port_memory";
my $unit_name = "unitA";
my $Relu_name = "relu";
my $accumulator_name = "accumulator"; 
my $temp;



my $unitA_ifm_width;
my $unitA_ifm_height;

# Variable to hold padding state #
my $padding_exist  = $ARGV[12];
my $stride = $ARGV[11];
my $is_RGB = $ARGV[10];

# input Width and height with padding value added #
my $pad_value  = ($ARGV[8] - 1);;


if($padding_exist == 1 && ($stride == 2)){
    $unitA_ifm_width = $ARGV[5] + $pad_value -1;
    $unitA_ifm_height = $ARGV[6] + $pad_value -1;
}
elsif($padding_exist == 1 && ($stride == 1)){
    $unitA_ifm_width = $ARGV[5] + $pad_value; 
    $unitA_ifm_height = $ARGV[6] + $pad_value;
}
else{
    $unitA_ifm_width = $ARGV[5];
    $unitA_ifm_height = $ARGV[6];
}


$module_name = "conva$ARGV[0]_DP";

if($is_RGB == 1){
	$temp = 3;
}
else{	
	$temp = 1;
}


####################################################
#############     GENERATING FILE    ###############
####################################################

$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  

  print $fh <<"DONATE";
$module $module_name $parameter
///////////advanced parameters//////////
	DATA_WIDTH 		        = $ARGV[3],
	ADDRESS_BITS 		    = $ARGV[4],
	/////////////////////////////////////
	IFM_WIDTH               = $ARGV[5],
	IFM_HEIGHT 		        = $ARGV[6],                                                
	IFM_DEPTH               = $ARGV[7],
	KERNAL_SIZE	            = $ARGV[8],
	NUMBER_OF_FILTERS       = $ARGV[9],
	NUMBER_OF_UNITS         = $temp,
    ARITH_TYPE              = $ARGV[2],
    STRIDE                  = $stride,
	//////////////////////////////////////
DONATE

if($padding_exist == 1){
    
    if(($stride == 2)){
        print $fh "    PADDING_VALUE           = ${\($pad_value-1)},\n";
    }else{
        print $fh "    PADDING_VALUE           = $pad_value,\n";
    }

    print $fh <<"DONATE";    
    IFM_WIDTH_PAD           = IFM_WIDTH + PADDING_VALUE ,
	IFM_HEIGHT_PAD          = IFM_HEIGHT + PADDING_VALUE ,
DONATE
}

print $fh <<"DONATE";
	ADDRESS_SIZE_IFM        = $clog2(IFM_WIDTH * IFM_HEIGHT),
	ADDRESS_SIZE_WM         = $clog2( KERNAL_SIZE * KERNAL_SIZE * NUMBER_OF_FILTERS),    
	NUMBER_OF_IFM           = IFM_DEPTH
)(
    // General Signals
	input clk,
	input reset,

    // Signals from RISC-V
	input [DATA_WIDTH-1:0] riscv_data,
	input [ADDRESS_BITS-1:0] riscv_address,
	
    // Signals to IFM Memory (Read)
	input [NUMBER_OF_IFM-1:0]    ifm_enable_write_previous,            
	input [ADDRESS_SIZE_IFM-1:0] ifm_address_read_A_current,
    input                        ifm_enable_read_A_current,
DONATE

if($stride == 2){
	print $fh <<"DONATE";
    
    input [ADDRESS_SIZE_IFM-1:0] ifm_address_read_B_current,
    input                        ifm_enable_read_B_current,
DONATE
}
print $fh <<"DONATE";

    // Weight Memory signals
    input                       wm_addr_sel,
    input                       wm_enable_read,
    input [NUMBER_OF_UNITS-1:0] wm_enable_write,
    input [ADDRESS_SIZE_WM-1:0] wm_address_read_current,
    input                       wm_fifo_enable,

    // Bias Memory signals    
    input                                 bm_addr_sel,
    input                                 bm_enable_read,
    input                                 bm_enable_write,
    input [$clog2(NUMBER_OF_FILTERS)-1:0] bm_address_read_current,
DONATE

if($padding_exist == 1){
    if($stride == 2){
    print $fh <<"DONATE";

    // Padding Mux Selection
	input zeros_sel_A,
    input zeros_sel_B,
DONATE
    }
    else{
    print $fh <<"DONATE";

    // Padding Mux Selection
	input zeros_sel,
DONATE
    }
}

print $fh <<"DONATE";
    // Internal Control Signals
    input fifo_enable,
	input conv_enable,

    // Signal to OFM Memory
    output [DATA_WIDTH-1:0] data_out_for_next
    );
	
///////////////////////////////////////////////////////
////////////////  Signal declaration  /////////////////
///////////////////////////////////////////////////////

DONATE

if($is_RGB == 1){#rgb
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] data_read_A_for_unit1;
	wire [DATA_WIDTH-1:0] data_read_A_for_unit2;
	wire [DATA_WIDTH-1:0] data_read_A_for_unit3;

DONATE
    if($stride == 2){
	        print $fh <<"DONATE";
    wire [DATA_WIDTH-1:0] data_read_B_for_unit1;
	wire [DATA_WIDTH-1:0] data_read_B_for_unit2;
	wire [DATA_WIDTH-1:0] data_read_B_for_unit3;

DONATE
    }
}
else{#gray
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] data_read_A_for_unit1;

DONATE
    if($stride == 2){
	        print $fh <<"DONATE";
    wire [DATA_WIDTH-1:0] data_read_B_for_unit1;

DONATE
    }
}

if($is_RGB == 1){#rgb
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] unit1_data_out;
	wire [DATA_WIDTH-1:0] unit2_data_out;
	wire [DATA_WIDTH-1:0] unit3_data_out;
DONATE
}
else{#grays
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] unit1_data_out;
DONATE
}



if($is_RGB == 1){
	print $fh <<"DONATE";
 
	reg [DATA_WIDTH-1:0] partial_sum1_r;
	reg [DATA_WIDTH-1:0] partial_sum2_r;
    wire [DATA_WIDTH-1:0] partial_sum1;
	wire [DATA_WIDTH-1:0] partial_sum2;
	reg [DATA_WIDTH-1:0] full_sum_r;
	wire [DATA_WIDTH-1:0] full_sum;

DONATE
}
else{
    print $fh <<"DONATE";

	reg [DATA_WIDTH-1:0] full_sum_r;
	wire [DATA_WIDTH-1:0] full_sum;

DONATE

}


print $fh <<"DONATE";	
    wire [DATA_WIDTH-1:0] data_bias;
	wire [ADDRESS_SIZE_WM-1:0] wm_address;
	wire [$clog2(NUMBER_OF_FILTERS)-1:0] bm_address;
	
    // Mux to switch between writing parameters from RISC-V or Reading parameters in normal operation
	assign wm_address = wm_addr_sel ? wm_address_read_current : riscv_address[ADDRESS_SIZE_WM-1:0];
	assign bm_address = bm_addr_sel ? bm_address_read_current : riscv_address[$clog2(NUMBER_OF_FILTERS)-1:0];

DONATE

if($stride == 2){
	print $fh <<"DONATE";
    wire [ADDRESS_SIZE_IFM-1:0] ifm_address;
	assign ifm_address = wm_addr_sel ? ifm_address_read_B_current : riscv_address[ADDRESS_SIZE_IFM-1:0];
DONATE
}

print $fh <<"DONATE"; 
	
    ///////////////////////////////////////////////////////////
	///////////////// BIAS MERMORY INSTANSIATION //////////////
	///////////////////////////////////////////////////////////
    $single_port_name #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE (NUMBER_OF_FILTERS)) bm 
    (
        .clk(clk),	
        .Enable_Write(bm_enable_write),
        .Enable_Read(bm_enable_read),	
        .Address(bm_address),
        .Data_Input(riscv_data),	
        .Data_Output(data_bias)
    );

    ////////////////////////////////////////////////////////////////////
	///////////////// INPUT IMAGE MEMOIRES INSTANSIATION ///////////////
	//////////////////////////////////////////////////////////////////// 
	$dual_port_name #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(IFM_WIDTH*IFM_HEIGHT)) 
	convA1_IFM1 
    (
DONATE

    if($stride == 2){
		print $fh <<"DONATE";
        .clk(clk),
        
        .Data_Input_A(riscv_data),
        .Address_A(ifm_address),
        .Enable_Write_A(ifm_enable_write_previous[0]),
        .Enable_Read_A(ifm_enable_read_B_current), 
        .Data_Output_A(data_read_B_for_unit1),
        
        .Data_Input_B({DATA_WIDTH{1'b0}}),
        .Address_B(ifm_address_read_A_current),
        .Enable_Write_B(1'b0),
        .Enable_Read_B(ifm_enable_read_A_current), 
        .Data_Output_B(data_read_A_for_unit1)
    );
DONATE
	
}
else{
		print $fh <<"DONATE";
        .clk(clk),
        
        .Data_Input_A(riscv_data),
        .Address_A(riscv_address),
        .Enable_Write_A(ifm_enable_write_previous[0]),
        .Enable_Read_A(1'b0), 
        .Data_Output_A(),

        .Data_Input_B({DATA_WIDTH{1'b0}}),
        .Address_B(ifm_address_read_A_current),
        .Enable_Write_B(1'b0),
        .Enable_Read_B(ifm_enable_read_A_current), 
        .Data_Output_B(data_read_A_for_unit1)
    );
DONATE
	
}

# If it RGB add another 2 IFM Memories	
if($is_RGB == 1){
	
    if($stride == 2){
		print $fh <<"DONATE";


    $dual_port_name #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(IFM_WIDTH*IFM_HEIGHT)) 
	convA1_IFM2 
    (
        .clk(clk),
        
        .Data_Input_A(riscv_data),
        .Address_A(ifm_address),
        .Enable_Write_A(ifm_enable_write_previous[1]),
        .Enable_Read_A(ifm_enable_read_B_current), 
        .Data_Output_A(data_read_B_for_unit2),
        
        .Data_Input_B({DATA_WIDTH{1'b0}}),
        .Address_B(ifm_address_read_A_current),
        .Enable_Write_B(1'b0),
        .Enable_Read_B(ifm_enable_read_A_current), 
        .Data_Output_B(data_read_A_for_unit2)
    );

    $dual_port_name #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(IFM_WIDTH * IFM_HEIGHT)) 
	convA1_IFM3 
    (
        .clk(clk),
        
        .Data_Input_A(riscv_data),
        .Address_A(ifm_address),
        .Enable_Write_A(ifm_enable_write_previous[2]),
        .Enable_Read_A(ifm_enable_read_B_current), 
        .Data_Output_A(data_read_B_for_unit3),
        
        .Data_Input_B({DATA_WIDTH{1'b0}}),
        .Address_B(ifm_address_read_A_current),
        .Enable_Write_B(1'b0),
        .Enable_Read_B(ifm_enable_read_A_current), 
        .Data_Output_B(data_read_A_for_unit3)
    );

DONATE
        
    }
    else{
		print $fh <<"DONATE";


    $dual_port_name #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(IFM_WIDTH*IFM_HEIGHT)) 
	convA1_IFM2 
    (
        .clk(clk),
        
        .Data_Input_A(riscv_data),
        .Address_A(riscv_address),
        .Enable_Write_A(ifm_enable_write_previous[1]),
        .Enable_Read_A(1'b0), 
        .Data_Output_A(),

        .Data_Input_B({DATA_WIDTH{1'b0}}),
        .Address_B(ifm_address_read_A_current),
        .Enable_Write_B(1'b0),
        .Enable_Read_B(ifm_enable_read_A_current), 
        .Data_Output_B(data_read_A_for_unit2)
    );


    $dual_port_name #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(IFM_WIDTH*IFM_HEIGHT) 
	convA1_IFM3 
    (
        .clk(clk),

        .Data_Input_A(riscv_data),
        .Address_A(riscv_address),
        .Enable_Write_A(ifm_enable_write_previous[2]),
        .Enable_Read_A(1'b0), 
        .Data_Output_A(),

        .Data_Input_B({DATA_WIDTH{1'b0}}),
        .Address_B(ifm_address_read_A_current),
        .Enable_Write_B(1'b0),
        .Enable_Read_B(ifm_enable_read_A_current), 
        .Data_Output_B(data_read_A_for_unit3)
    );
DONATE
}

}

# Generation of Convolution units
system("perl UnitA.pl $ARGV[3] $unitA_ifm_width $unitA_ifm_height $ARGV[8] $stride $ARGV[2] $ARGV[7] $ARGV[9] $temp $ARGV[12] $ARGV[13]");

$unit_name = "unitA_$unitA_ifm_width";

print $fh <<"DONATE";

    ///////////////////////////////////////////////////////////
	///////////////// CONVA UNITS INSTANSIATION ///////////////
	///////////////////////////////////////////////////////////

    $unit_name 
    #(
        .ARITH_TYPE(ARITH_TYPE),
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
	    .$ifm_width(IFM_WIDTH_PAD),
        .$ifm_height(IFM_HEIGHT_PAD),
DONATE
}
else{
    print $fh <<"DONATE";
	    .$ifm_width($ifm_width),
        .$ifm_height($ifm_height),
DONATE
}

print $fh <<"DONATE";    
	    .DATA_WIDTH(DATA_WIDTH), 
	    .$ifm_depth($ifm_depth), 
	    .$kernal_size($kernal_size), 
	    .$number_of_filters($number_of_filters)
    )
    convA1_unit_1
    (
        .clk(clk),                                 
        .reset(reset),  
        .riscv_data(riscv_data),                             
        .unit_data_in_A(data_read_A_for_unit1),  
DONATE

    if($stride == 2){
	        print $fh <<"DONATE";
        .unit_data_in_B(data_read_B_for_unit1), 
DONATE
}

if($padding_exist == 1){
    if($stride == 2){
        print $fh <<"DONATE";
	    .zeros_sel_A(zeros_sel_A),
        .zeros_sel_B(zeros_sel_B),
DONATE
    }
    else{
        print $fh <<"DONATE";
	    .zeros_sel(zeros_sel),
DONATE
    }
}

print $fh <<"DONATE";     
        .fifo_enable(fifo_enable),                         
        .conv_enable(conv_enable),
        .wm_enable_read(wm_enable_read),          
        .wm_enable_write(wm_enable_write[0]),          
        .wm_address(wm_address),
        .wm_fifo_enable(wm_fifo_enable),
        .unit_data_out(unit1_data_out)   
    );
	
DONATE


if($is_RGB == 1){
	print $fh <<"DONATE";
	$unit_name #(
        .ARITH_TYPE(ARITH_TYPE),
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
	    .$ifm_width(IFM_WIDTH_PAD),
        .$ifm_height(IFM_HEIGHT_PAD),
DONATE
}
else{
    print $fh <<"DONATE";
	    .$ifm_width($ifm_width),
        .$ifm_height($ifm_height),
DONATE
}

print $fh <<"DONATE";
        .DATA_WIDTH(DATA_WIDTH), 
        .$ifm_depth($ifm_depth), 
        .$kernal_size($kernal_size), 
        .$number_of_filters($number_of_filters))
    convA1_unit_2
    (
        .clk(clk),                                 
        .reset(reset),  
        .riscv_data(riscv_data),                             
        .unit_data_in_A(data_read_A_for_unit2), 
DONATE

        if($stride == 2){
	        print $fh <<"DONATE";
        .unit_data_in_B(data_read_B_for_unit2), 
DONATE
}

if($padding_exist == 1){
if($stride == 2){
        print $fh <<"DONATE";
	    .zeros_sel_A(zeros_sel_A),
        .zeros_sel_B(zeros_sel_B),
DONATE
    }
    else{
        print $fh <<"DONATE";
	    .zeros_sel(zeros_sel),
DONATE
    }
}

print $fh <<"DONATE";      
        .fifo_enable(fifo_enable),                         
        .conv_enable(conv_enable),  
        .wm_enable_read(wm_enable_read),          
        .wm_enable_write(wm_enable_write[1]),          
        .wm_address(wm_address),
        .wm_fifo_enable(wm_fifo_enable),          
        .unit_data_out(unit2_data_out)   
    );
    
    $unit_name #(
        .ARITH_TYPE(ARITH_TYPE),
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
	    .$ifm_width(IFM_WIDTH_PAD),
        .$ifm_height(IFM_HEIGHT_PAD),
DONATE
}
else{
    print $fh <<"DONATE";
	    .$ifm_width($ifm_width),
        .$ifm_height($ifm_height),
DONATE
}

print $fh <<"DONATE";
	    .DATA_WIDTH(DATA_WIDTH), 
	    .$ifm_depth($ifm_depth), 
	    .$kernal_size($kernal_size), 
	    .$number_of_filters($number_of_filters))
    convA1_unit_3
    (
        .clk(clk),                                 
        .reset(reset),  
        .riscv_data(riscv_data),                             
        .unit_data_in_A(data_read_A_for_unit3), 
DONATE

        if($stride == 2){
	        print $fh <<"DONATE";
        .unit_data_in_B(data_read_B_for_unit3), 
DONATE
}

if($padding_exist == 1){
if($stride == 2){
        print $fh <<"DONATE";
	    .zeros_sel_A(zeros_sel_A),
        .zeros_sel_B(zeros_sel_B),
DONATE
    }
    else{
        print $fh <<"DONATE";
	    .zeros_sel(zeros_sel),
DONATE
    }
}

print $fh <<"DONATE";       
        .fifo_enable(fifo_enable),                         
        .conv_enable(conv_enable),    
        .wm_enable_read(wm_enable_read),          
        .wm_enable_write(wm_enable_write[2]),         
        .wm_address(wm_address),
        .wm_fifo_enable(wm_fifo_enable),          
        .unit_data_out(unit3_data_out)   
    );
	
	
DONATE
}


if($is_RGB == 1){
	print $fh <<"DONATE";
	
	always @(posedge clk)
	begin
	   partial_sum1_r <= partial_sum1;
	   partial_sum2_r <= partial_sum2;
	   full_sum_r     <= full_sum;
	end
	
DONATE

}	
else{
    print $fh <<"DONATE";
    always @(posedge clk)
	begin
	   full_sum_r     <= full_sum;
	end

DONATE
}

#RGB
if($is_RGB == 1){
	print $fh <<"DONATE";

    // Adding results from all units + bias
	adder #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE)) Add1 (.in1 (unit1_data_out), .in2 (unit2_data_out), .out (partial_sum1));
	adder #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE)) Add2 (.in1 (unit3_data_out), .in2 (data_bias),      .out (partial_sum2));

	adder #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE)) Add3 (.in1 (partial_sum1_r), .in2 (partial_sum2_r), .out (full_sum));
	
    // RelU Activation Function
    relu  #(.DATA_WIDTH(DATA_WIDTH)) Active1 (.in(full_sum_r),.out (data_out_for_next), .relu_enable(1'b1)); 
	
endmodule
DONATE
}

#Gray
else{

	print $fh <<"DONATE";  

    // Adding bias
	adder #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE)) Add (.in1 (unit1_data_out), .in2 (data_bias), .out (full_sum));
    
    // RelU Activation Function
	relu  #(.DATA_WIDTH(DATA_WIDTH)) Active1 (.in(full_sum_r),.out (data_out_for_next), .relu_enable(1'b1)); 
 	 
	
endmodule

DONATE
}

close $fh or die "Couldn't Close File : $!";
