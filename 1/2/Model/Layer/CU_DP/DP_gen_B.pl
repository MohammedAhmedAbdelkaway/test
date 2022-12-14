#*COMMENTED*#

use strict;
use warnings;
use diagnostics;
use POSIX;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";

#######################################################
############    ARGUMENTS DISCRIPTION    ##############
####################################################### 

#ARGV[0] no of the conv 2
#ARGV[1] ARITH_TYPE 0 | Mul & Add type which (decimal, fixed, float)
#ARGV[2] DATA_WIDTH 32
#ARGV[3] ADDRESS_BITS 15
#ARGV[4] IFM_WIDTH  32
#ARGV[5] IFM_HEIGHT  32
#ARGV[6] IFM_DEPTH 3
#ARGV[7] KERNAL_SIZE  5
#ARGV[8] NUMBER_OF_FILTERS 6
#ARGV[9] NUMBER_OF_UNITS 3
#ARGV[10] STRIDE 1
#ARGV[11]
#ARGV[12] PADDING_EXIST

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
my $full_path = "../../../$ARGV[11]/";
##########################################################

my $i = 0;
my $j = 0;
my $jj = 0;
my $file_name;
my $module_name;
my $adder_name;
my $mul_name;
my $odd_flag;
my $dummy_level;
my @levels;
my $levels_number;

my $single_port_name = "single_port_memory";
my $unit_name ;
my $Relu_name = "relu";
my $accumulator_name = "accumulator"; 
$module_name = "convb$ARGV[0]_DP";

my $unitB_ifm_width;
my $unitB_ifm_height;

# Variable to hold padding state #
my $padding_exist = $ARGV[12];
my $stride = $ARGV[10];

# input Width and height with padding value added #
my $pad_value  = ($ARGV[7] - 1) ;


if($padding_exist == 1 && ($stride == 2)){
    $unitB_ifm_width = $ARGV[4] + $pad_value -1;
    $unitB_ifm_height = $ARGV[5] + $pad_value -1;
}
elsif($padding_exist == 1 && ($stride == 1)){
    $unitB_ifm_width = $ARGV[4] + $pad_value ;
    $unitB_ifm_height = $ARGV[5] + $pad_value ;
}
else{
    $unitB_ifm_width = $ARGV[4];
    $unitB_ifm_height = $ARGV[5];
}

=begin
$odd_flag = 0;
$dummy_level = $ARGV[8]; 
 while($dummy_level  > 0)
{
	push @levels , $dummy_level;
	if($dummy_level % 2 == 1){
		if($odd_flag == 1){
			$dummy_level = int($dummy_level / 2) + 1;
			$odd_flag = 0;
		}
		else{
			$dummy_level = int ($dummy_level / 2);
			$odd_flag = 1;
		}
	}
	else{	
		$dummy_level = $dummy_level / 2;
	}
}

$levels_number = @levels;
=cut 


my $ceil_NUMBER_OF_FILTERS_over_NUMBER_OF_UNITS = ceil($ARGV[8]/$ARGV[9]);  
my $num_outputs = $ARGV[7] * $ARGV[7];
my $fifo_regs;

if($padding_exist == 1){
	$fifo_regs = (($ARGV[7] - 1)*$unitB_ifm_width + $ARGV[7]);	}
else{
	$fifo_regs = (($ARGV[7] - 1)*$ARGV[4] + $ARGV[7]);	}

my $fifo_name = "FIFO_$num_outputs$under_Score$stride$under_Score$fifo_regs";


####################################################
#############     GENERATING FILE    ###############
####################################################

$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  

print $fh <<"DONATE";
$module $module_name $parameter
///////////advanced parameters//////////
	ARITH_TYPE				= $ARGV[1],
	DATA_WIDTH				= $ARGV[2],
	ADDRESS_BITS    		= $ARGV[3],
	/////////////////////////////////////
	IFM_WIDTH	            = $ARGV[4],
	IFM_HEIGHT	            = $ARGV[5],                                                  
	IFM_DEPTH	            = $ARGV[6],
	KERNAL_SIZE		        = $ARGV[7],
	NUMBER_OF_FILTERS	    = $ARGV[8],
	NUMBER_OF_UNITS	        = $ARGV[9],
	STRIDE       			= $stride,
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
	ADDRESS_SIZE_WM         = $clog2(KERNAL_SIZE*KERNAL_SIZE*IFM_DEPTH*${\(ceil($ARGV[8]/$ARGV[9]))})                             
)(
	// General Signals
	input clk,
	input reset,

	// Signals from RISC-V
	input [DATA_WIDTH-1:0] riscv_data,
	input [ADDRESS_BITS-1:0] riscv_address,
	
	// Signals from IFM Memory (Read)
	input [DATA_WIDTH-1:0] data_in_A_from_previous,
DONATE

if($stride == 2){
	print $fh <<"DONATE";
    input [DATA_WIDTH-1:0] data_in_B_from_previous,
DONATE
}

print $fh <<"DONATE";

	// Internal control signals
	input fifo_enable,
	input conv_enable,
	input accu_enable,
	input relu_enable,
    
	// Weight Memory signals
    input                       wm_addr_sel,
    input                       wm_enable_read,
    input [NUMBER_OF_UNITS-1:0] wm_enable_write,
    input [ADDRESS_SIZE_WM-1:0] wm_address_read_current,
    input                       wm_fifo_enable,
    
	// Bias Memory signals
    input                                 bm_addr_sel,
    input                                 bm_enable_read,
    input                     [$ARGV[9]-1:0]     bm_enable_write,
    input [$clog2(NUMBER_OF_FILTERS)-1:0] bm_address_read_current,
	
DONATE

if($padding_exist == 1){
    if($stride == 2){
    print $fh <<"DONATE";

    // Padding Mux Selection
	input zeros_sel_A,
    input zeros_sel_B,

	// Signal to OFM Memory
DONATE
    }
    else{
    print $fh <<"DONATE";

    // Padding Mux Selection
	input zeros_sel,

	// Signal to OFM Memory
DONATE
    }
}

for ($i = 1; $i <= $ARGV[9]; $i = $i + 1){
	print $fh <<"DONATE";
	input  [DATA_WIDTH-1:0] data_in_from_next$i,
DONATE
}


for ($i = 1; $i < $ARGV[9]; $i = $i + 1){
	print $fh <<"DONATE";
	output [DATA_WIDTH-1:0] data_out_for_next$i,
DONATE
}

print $fh <<"DONATE";
	output [DATA_WIDTH-1:0] data_out_for_next$i
	);

///////////////////////////////////////////////////////
////////////////  Signal declaration  /////////////////
///////////////////////////////////////////////////////

DONATE

 for ($i = 1; $i <= $ARGV[7]*$ARGV[7]; $i = $i + 1){
	print $fh <<"DONATE";
	wire [DATA_WIDTH - 1 : 0] signal_if$i;
DONATE
}

for ($i = 1; $i <= $ARGV[9]; $i = $i + 1){
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] unit${\($i)}_data_out;
DONATE
}

print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] accu_data_out;
	wire [DATA_WIDTH-1:0] relu_data_out;
DONATE

for ($i = 1; $i <= $ARGV[9]; $i = $i + 1){
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] data_bias_$i;
DONATE
}

if($padding_exist == 1){
	if($stride == 2){
		print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] input_data_A; 
	wire [DATA_WIDTH-1:0] input_data_B; 
DONATE
	}
	else{
		print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] input_data; 
DONATE
	}
}

 print $fh <<"DONATE";
	    
	wire [ADDRESS_SIZE_WM-1:0] wm_address;
	wire [$clog2((${\(ceil($ARGV[8]/$ARGV[9]))}))-1:0] bm_address;
	
	// Mux to switch addresses between writing parameters from RISC-V or Reading parameters in normal operation
	assign wm_address = wm_addr_sel ? wm_address_read_current : riscv_address[ADDRESS_SIZE_WM-1:0];
	assign bm_address = bm_addr_sel ? bm_address_read_current : riscv_address[$clog2((${\(ceil($ARGV[8]/$ARGV[9]))}))-1:0];
	
DONATE

if($padding_exist == 1){
	if($stride == 2){
		print $fh <<"DONATE";
	// Padding MUX, Enters zeros in case of reading a position in padding frame and enters the acutal IFM data otherwise
	assign input_data_A = (zeros_sel_A) ? {DATA_WIDTH{1'b0}} : data_in_A_from_previous;
	assign input_data_B = (zeros_sel_B) ? {DATA_WIDTH{1'b0}} : data_in_B_from_previous; 
DONATE
	}
	else{
		print $fh <<"DONATE";
	// Padding MUX, Enters zeros in case of reading a position in padding frame and enters the acutal IFM data otherwise
	assign input_data = (zeros_sel) ? {DATA_WIDTH{1'b0}} : data_in_A_from_previous; 
DONATE
	}
}	


print $fh <<"DONATE";

	///////////////////////////////////////////////////////////
	///////////////// BIAS MERMORY INSTANSIATION //////////////
	///////////////////////////////////////////////////////////
DONATE

for ($i = 1; $i <= $ARGV[9]; $i = $i + 1){
	print $fh <<"DONATE";
	single_port_memory #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE ($ceil_NUMBER_OF_FILTERS_over_NUMBER_OF_UNITS) )
	bm$i (
		.clk(clk),	
		.Enable_Write(bm_enable_write[${\($i-1)}]),
		.Enable_Read(bm_enable_read),	
		.Address(bm_address),
		.Data_Input(riscv_data),	
		.Data_Output(data_bias_$i)
	);
   
DONATE
}

chdir "./Modules";
system("perl fifo.pl  $stride $ARGV[2] $unitB_ifm_width $unitA_ifm_height $ARGV[7] $ARGV[11]");


if($padding_exist == 1){
	print $fh <<"DONATE";
	///////////////////////////////////////////////////////////
	////////////////// INPUT FIFO INSTANSIATION ///////////////
	///////////////////////////////////////////////////////////
	$fifo_name #(.DATA_WIDTH(DATA_WIDTH), .$ifm_width(IFM_WIDTH_PAD), .$kernal_size($kernal_size) ) 
DONATE
}
else{
	print $fh <<"DONATE";
	///////////////////////////////////////////////////////////
	////////////////// INPUT FIFO INSTANSIATION ///////////////
	///////////////////////////////////////////////////////////
	$fifo_name #(.DATA_WIDTH(DATA_WIDTH), .$ifm_width($ifm_width), .$kernal_size($kernal_size) )
DONATE
}


print $fh <<"DONATE";
	FIFO1 (
		.clk(clk),
		.reset(reset),
		.fifo_enable(fifo_enable),
DONATE

if($padding_exist == 1){
	if($stride == 2){
		print $fh <<"DONATE";
		.fifo_data_in(input_data_A),
		.fifo_data_in_2(input_data_B), 
DONATE
	}
	else{
		print $fh <<"DONATE";
		.fifo_data_in(input_data), 
DONATE
	}
}
else{
	if($stride == 2){
		print $fh <<"DONATE";
		.fifo_data_in(data_in_A_from_previous),
		.fifo_data_in_2(data_in_B_from_previous),  
DONATE
	}
	else{
		print $fh <<"DONATE";
		.fifo_data_in(data_in_A_from_previous), 
DONATE
	}
}
	

for ($i = 1; $i < $ARGV[7]*$ARGV[7]; $i = $i + 1){
	print $fh <<"DONATE";
	 	.fifo_data_out_$i(signal_if$i),  
DONATE
}

print $fh <<"DONATE";
	 	.fifo_data_out_$i(signal_if$i)
	);
	

	///////////////////////////////////////////////////////////
	///////////////// CONVB UNITS INSTANSIATION ///////////////
	///////////////////////////////////////////////////////////
DONATE


chdir "../";
system("perl UnitB.pl  $ARGV[2] $ARGV[6] $ARGV[7] $ARGV[8] $ARGV[9] $ARGV[1] $stride $ARGV[11]");

$unit_name = "unitB";

for ($i = 1; $i <= $ARGV[9]; $i = $i + 1){
print $fh <<"DONATE";
	$unit_name 
	#(
		.ARITH_TYPE(ARITH_TYPE),
		.DATA_WIDTH(DATA_WIDTH), 
		.$ifm_depth($ifm_depth), 
		.$kernal_size($kernal_size), 
		.$number_of_filters($number_of_filters), 
		.$number_of_units($number_of_units)
	)
	convB_unit_$i
	(
		.clk(clk),                                 
		.reset(reset),  
		.riscv_data(riscv_data),
		.data_in_from_next(data_in_from_next$i),
		.data_bias(data_bias_$i), 
DONATE

for ($j = 1; $j <= $ARGV[7]*$ARGV[7]; $j = $j + 1){
	print $fh <<"DONATE";
		.signal_if$j(signal_if$j),
DONATE
}

print $fh <<"DONATE";
		.conv_enable(conv_enable),
		.accu_enable(accu_enable),
		.relu_enable(relu_enable),
		.wm_enable_read(wm_enable_read),
		.wm_enable_write(wm_enable_write[${\($i-1)}]), 
		.wm_address(wm_address),
		.wm_fifo_enable(wm_fifo_enable),          
		.unit_data_out(unit${\($i)}_data_out)   
    );
	

// Results from convolution to OFM Memory	
DONATE
}

for ($i = 1; $i <= $ARGV[9]; $i = $i + 1){
print $fh <<"DONATE";
assign data_out_for_next$i = unit${\($i)}_data_out;
DONATE
}

print $fh <<"DONATE";


endmodule
DONATE