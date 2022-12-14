use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";

use POSIX;

#argumets 
#ARGV[0] no of the conv 
#ARGV[1] Mul number
#ARGV[2] ARITH_TYPE
#ARGV[3] DATA_WIDTH
#ARGV[4] ADDRESS_BITS
#ARGV[5] IFM_WIDTH
#ARGV[6] IFM_HEIGHT  
#ARGV[7] IFM_DEPTH 
#ARGV[8] KERNAL_SIZE  
#ARGV[9] NUMBER_OF_FILTERS  filter_num
#ARGV[10] NUMBER_OF_UNITS    layer_units
#ARGV[11] stride
#ARGV[12] PADDING_EXIST
#ARGV[13] $relative_path



######################################### CONSTANTS ###################################
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

#############################################################                                               
my $ifm_width = "IFM_WIDTH";                                               
my $ifm_height = "IFM_HEIGHT";                                               
###########################################################

my $ifm_depth = "IFM_DEPTH";
my $kernal_size = "KERNAL_SIZE";
my $number_of_filters = "NUMBER_OF_FILTERS";
my $number_of_units = "NUMBER_OF_UNITS";
my $full_path = "../../$ARGV[13]/";
#######################################################################################
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

my $single_port_name = "single_port_memory";
my $unit_name = "unitA";
my $Relu_name = "relu";
my $cu_name;
my $dp_name;
my $accumulator_name = "accumulator"; 
$module_name = "top_conva$ARGV[0]";

# Variable to hold padding state #
my $padding_exist = $ARGV[12];

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
	IFM_HEIGHT			    = $ARGV[6],                                                
	IFM_DEPTH               = $ARGV[7],
	KERNAL_SIZE             = $ARGV[8],
	NUMBER_OF_FILTERS       = $ARGV[9],
	NUMBER_OF_UNITS         = $ARGV[10],
	ARITH_TYPE 			    = $ARGV[2],
	//////////////////////////////////////
	IFM_WIDTH_NEXT          = IFM_WIDTH - KERNAL_SIZE + 1,
	IFM_HEIGHT_NEXT         = IFM_HEIGHT - KERNAL_SIZE + 1,
	ADDRESS_SIZE_IFM        = $clog2(IFM_WIDTH*IFM_HEIGHT),
DONATE

if($padding_exist == 1){
	print $fh <<"DONATE";
	ADDRESS_SIZE_NEXT_IFM   = $clog2(IFM_WIDTH * IFM_HEIGHT),
DONATE
}
else{
	print $fh <<"DONATE";
	ADDRESS_SIZE_NEXT_IFM   = $clog2(IFM_WIDTH_NEXT*IFM_HEIGHT_NEXT),
DONATE
}

print $fh <<"DONATE";
	ADDRESS_SIZE_WM         = $clog2( KERNAL_SIZE*KERNAL_SIZE*NUMBER_OF_FILTERS*(${\(ceil($ARGV[7]/$ARGV[10]))}) ),    
	FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH + KERNAL_SIZE,
	NUMBER_OF_IFM           = IFM_DEPTH,
	NUMBER_OF_IFM_NEXT      = NUMBER_OF_FILTERS,
	NUMBER_OF_WM            = KERNAL_SIZE*KERNAL_SIZE
)(
	$i_p 							clk,
	$i_p 							reset,
	
	input [DATA_WIDTH-1:0]  riscv_data,
	input [ADDRESS_BITS-1:0] riscv_address,
	input [NUMBER_OF_UNITS-1:0] wm_enable_write,
	input bm_enable_write,

	input start_from_previous,
	
DONATE


for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
	print $fh <<"DONATE";
	input [DATA_WIDTH-1:0] data_in_A_from_previous$i,
DONATE

}
if($ARGV[11]  == 2){
	for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
		print $fh <<"DONATE";
	input [DATA_WIDTH-1:0] data_in_B_from_previous$i,
DONATE

	}
}

if($ARGV[11] == 1){
	print $fh <<"DONATE";
	output                        ifm_enable_read_A_current,
	output [ADDRESS_SIZE_IFM-1:0] ifm_address_read_A_current,
DONATE
}
else{
print $fh <<"DONATE";
	output                        ifm_enable_read_A_current,
	output [ADDRESS_SIZE_IFM-1:0] ifm_address_read_A_current,
	output                        ifm_enable_read_B_current,
	output [ADDRESS_SIZE_IFM-1:0] ifm_address_read_B_current,
DONATE
}

print $fh <<"DONATE";

	output                        end_to_previous,
	
	output                        ready, 
	input  				    end_from_next,
	
	input  [DATA_WIDTH-1:0] data_in_from_next,
	
	output [DATA_WIDTH-1:0] data_out_for_next1,
	
	output 							   ifm_enable_read_next,
	output 							   ifm_enable_write_next,
    output [ADDRESS_SIZE_NEXT_IFM-1:0] ifm_address_read_next,
    output [ADDRESS_SIZE_NEXT_IFM-1:0] ifm_address_write_next,
	output 							   start_to_next,
	
	output [$clog2((${\(ceil($ARGV[7]/$ARGV[10]))}))-1:0] ifm_sel_previous,
	output                                               ifm_sel_next
    );
	
	wire fifo_enable;
    wire conv_enable;
    wire accu_enable;
    wire relu_enable;
    
    
    wire wm_addr_sel;
    wire wm_enable_read;
    wire [ADDRESS_SIZE_WM-1:0] wm_address_read_current;
    wire wm_fifo_enable;
    
    wire bm_addr_sel;
    wire bm_enable_read;
    wire [$clog2(NUMBER_OF_FILTERS)-1:0] bm_address_read_current ;

DONATE

if($padding_exist == 1){
	print $fh <<"DONATE";
	/* Signal to select whether to input zeros or the actual input data  */
	wire zeros_sel;
DONATE
}
chdir "./CU_DP";


system("perl CU_gen_A.pl $ARGV[0] $ARGV[1] $ARGV[3] $ARGV[5] $ARGV[6] $ARGV[7] $ARGV[8] $ARGV[9] $ARGV[10] $ARGV[13] $ARGV[11] $ARGV[12]");

$cu_name = "conva$ARGV[0]_CU";
print $fh <<"DONATE";

	$cu_name 
	#(
		.DATA_WIDTH(DATA_WIDTH), 
		.IFM_WIDTH(IFM_WIDTH),
		.IFM_HEIGHT(IFM_HEIGHT), 
		.IFM_DEPTH(IFM_DEPTH), 
		.KERNAL_SIZE(KERNAL_SIZE), 
		.NUMBER_OF_FILTERS(NUMBER_OF_FILTERS)
	)
    CU_A$ARGV[0]
    (
		.clk(clk),
		.reset(reset),
		.end_from_next(end_from_next),
		.start_from_previous(start_from_previous),
		.end_to_previous(end_to_previous),
		.ready(ready),
		
		.ifm_sel_previous(ifm_sel_previous),
		
		.ifm_enable_read_A_current(ifm_enable_read_A_current),
		.ifm_address_read_A_current(ifm_address_read_A_current),
DONATE

if($ARGV[11] == 2){
		print $fh <<"DONATE";
		.ifm_enable_read_B_current(ifm_enable_read_B_current),
		.ifm_address_read_B_current(ifm_address_read_B_current),
DONATE
	}
	print $fh <<"DONATE";
		.wm_addr_sel(wm_addr_sel),
		.wm_enable_read(wm_enable_read),
		.wm_address_read_current(wm_address_read_current),
		.wm_fifo_enable(wm_fifo_enable),
		
		.bm_addr_sel(bm_addr_sel),                                            
		.bm_enable_read(bm_enable_read),                                         
		.bm_address_read_current(bm_address_read_current),
DONATE

if($padding_exist == 1){
print $fh <<"DONATE";
		.zeros_sel(zeros_sel),
DONATE
}

print $fh <<"DONATE"; 		
		.fifo_enable(fifo_enable),
		.conv_enable(conv_enable),
		.accu_enable(accu_enable),
		.relu_enable(relu_enable),
		.ifm_enable_read_next(ifm_enable_read_next),
		.ifm_enable_write_next(ifm_enable_write_next),
		.ifm_address_read_next(ifm_address_read_next), 
		.ifm_address_write_next(ifm_address_write_next),
		.ifm_sel_next(ifm_sel_next),
		.start_to_next(start_to_next)
    );    
     
DONATE


system("perl DP_gen_A.pl $ARGV[0] $ARGV[1] $ARGV[2] $ARGV[3] $ARGV[4] $ARGV[5] $ARGV[6] $ARGV[7] $ARGV[8] $ARGV[9] $ARGV[10] $ARGV[11] $ARGV[12] $ARGV[13]");

$dp_name = "conva$ARGV[0]_DP";
print $fh <<"DONATE";

	$dp_name 
	#(
		.DATA_WIDTH(DATA_WIDTH), 
		.IFM_WIDTH(IFM_WIDTH),
		.IFM_HEIGHT(IFM_HEIGHT), 
		.IFM_DEPTH(IFM_DEPTH), 
		.KERNAL_SIZE(KERNAL_SIZE), 
		.ARITH_TYPE(ARITH_TYPE),
		.NUMBER_OF_FILTERS(NUMBER_OF_FILTERS)
	)
    DP_A$ARGV[0]
	(
		.clk(clk),
		.reset(reset),
		.riscv_data(riscv_data),
		.riscv_address(riscv_address),
	//////////////////////////////////////////////
		.fifo_enable(fifo_enable),
		.conv_enable(conv_enable),
		.accu_enable(accu_enable),
		.relu_enable(relu_enable),
	
DONATE
for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
	print $fh <<"DONATE";
		.data_in_A_from_previous$i(data_in_A_from_previous$i),
DONATE
	if($ARGV[11] == 2){
		print $fh <<"DONATE";
		.data_in_B_from_previous$i(data_in_B_from_previous$i),
DONATE
	}
}

print $fh <<"DONATE";

	
		.wm_addr_sel(wm_addr_sel),
		.wm_enable_read(wm_enable_read),
		.wm_enable_write(wm_enable_write),
		.wm_address_read_current(wm_address_read_current),
		.wm_fifo_enable(wm_fifo_enable),
		
		.bm_addr_sel(bm_addr_sel),                                            
		.bm_enable_read(bm_enable_read),
		.bm_enable_write(bm_enable_write),
		.bm_address_read_current(bm_address_read_current),
DONATE

if($padding_exist == 1){
print $fh <<"DONATE";
		.zeros_sel(zeros_sel),
DONATE
}

print $fh <<"DONATE"; 		
		//////////////////////////////////////////////
		.data_in_from_next(data_in_from_next),
		.data_out_for_next(data_out_for_next1)
    );
	
	
endmodule	
DONATE


close $fh or die "Couldn't Close File : $!";
