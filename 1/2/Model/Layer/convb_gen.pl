use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";

use POSIX;
#argumets 
#ARGV[0] no of the conv 2
#ARGV[1] Mul number 25
#ARGV[2] ARITH_TYPE 0
#ARGV[3] DATA_WIDTH 32
#ARGV[4] ADDRESS_BITS 15
#ARGV[5] IFM_WIDTH  32
#ARGV[6] IFM_HEIGHT  32
#ARGV[7] IFM_DEPTH 3
#ARGV[8] KERNAL_SIZE 5  
#ARGV[9] NUMBER_OF_FILTERS 6 filter_num
#ARGV[10] NUMBER_OF_UNITS  3  layer_units
#ARGV[11] STRIDE 1
#ARGV[12] PADDING_EXIST
#ARGV[13] $relative_path
#

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

my $ifm_width = "IFM_WIDTH";    
my $ifm_height = "IFM_HEIGHT";                                             
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
my $adder_name;
my $mul_name;
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
$module_name = "top_convb$ARGV[0]";

# Variable to hold padding state #
my $padding_exist = $ARGV[12];


$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  
  print $fh <<"DONATE";
$module $module_name $parameter
///////////advanced parameters//////////
	ARITH_TYPE				= $ARGV[2],
	DATA_WIDTH 			    = $ARGV[3],
	ADDRESS_BITS 		    = $ARGV[4],
	/////////////////////////////////////
	IFM_WIDTH               = $ARGV[5], 
    IFM_HEIGHT              = $ARGV[6],                                               
	IFM_DEPTH               = $ARGV[7],
	KERNAL_SIZE             = $ARGV[8],
	NUMBER_OF_FILTERS       = $ARGV[9],
	NUMBER_OF_UNITS         = $ARGV[10],
	//////////////////////////////////////	
DONATE

if($padding_exist == 1){
	print $fh <<"DONATE";
	IFM_WIDTH_NEXT          = IFM_WIDTH,
	IFM_HEIGHT_NEXT         = IFM_HEIGHT,
DONATE
}
else{
	print $fh <<"DONATE";
	IFM_WIDTH_NEXT          = IFM_WIDTH - KERNAL_SIZE + 1,
	IFM_HEIGHT_NEXT         = IFM_HEIGHT - KERNAL_SIZE + 1,
DONATE
}

print $fh <<"DONATE";
    ADDRESS_SIZE_IFM        = $clog2(IFM_WIDTH*IFM_HEIGHT),
    ADDRESS_SIZE_NEXT_IFM   = $clog2(IFM_WIDTH_NEXT * IFM_HEIGHT_NEXT),
    ADDRESS_SIZE_WM         = $clog2( KERNAL_SIZE*KERNAL_SIZE*NUMBER_OF_FILTERS*(${\(ceil($ARGV[7]/$ARGV[10]))}) ),    
	NUMBER_OF_IFM           = IFM_DEPTH
	
)(
	$i_p 							clk,
	$i_p 							reset,
	
	input [DATA_WIDTH-1:0]  riscv_data,
	input [ADDRESS_BITS-1:0] riscv_address,
	input [NUMBER_OF_UNITS-1:0] wm_enable_write,
	input [$number_of_units-1:0] bm_enable_write,

	input start_from_previous,
	
DONATE

if($ARGV[11] == 1){
                print $fh <<"DONATE";
    input  [DATA_WIDTH-1:0]       data_in_A_from_previous1,
    output                        ifm_enable_read_A_current,
	output [ADDRESS_SIZE_IFM-1:0] ifm_address_read_A_current,
DONATE
    }
    else
    {
                print $fh <<"DONATE";
    input  [DATA_WIDTH-1:0]       data_in_A_from_previous1,
    input  [DATA_WIDTH-1:0]       data_in_B_from_previous1,
    output                        ifm_enable_read_A_current,
	output [ADDRESS_SIZE_IFM-1:0] ifm_address_read_A_current,
    output                        ifm_enable_read_B_current,
	output [ADDRESS_SIZE_IFM-1:0] ifm_address_read_B_current,

DONATE

            }

print $fh <<"DONATE";
	
	output                        end_to_previous,
	
	input                        conv_ready, 
	input  end_from_next,
DONATE

for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
	print $fh <<"DONATE";
	input  [DATA_WIDTH-1:0] data_in_from_next$i,
DONATE
}	

for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
	print $fh <<"DONATE";
	output  [DATA_WIDTH-1:0] data_out_for_next$i,
DONATE
}	
	
print $fh <<"DONATE";
	output ifm_enable_read_next,
	output ifm_enable_write_next,
    output [ADDRESS_SIZE_NEXT_IFM-1:0] ifm_address_read_next,
    output [ADDRESS_SIZE_NEXT_IFM-1:0] ifm_address_write_next,
	output start_to_next,
	
	output [$clog2(${\(ceil($ARGV[9]/$ARGV[10]))})-1:0] ifm_sel_next
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
system("perl CU_gen_B.pl $ARGV[0] $ARGV[1] $ARGV[5] $ARGV[6] $ARGV[7] $ARGV[8] $ARGV[9] $ARGV[10] $ARGV[13] $ARGV[11] $ARGV[12]");

$cu_name = "convb$ARGV[0]_CU";
print $fh <<"DONATE";

	$cu_name 
    #(
        .IFM_WIDTH(IFM_WIDTH), 
        .IFM_HEIGHT(IFM_HEIGHT), 
        .IFM_DEPTH(IFM_DEPTH), 
        .KERNAL_SIZE(KERNAL_SIZE), 
        .NUMBER_OF_FILTERS(NUMBER_OF_FILTERS)
        )
    CU_B$ARGV[0]
    (
        .clk(clk),
        .reset(reset),
        .end_from_next(end_from_next),
        .start_from_previous(start_from_previous),
        .end_to_previous(end_to_previous),
        .conv_ready(conv_ready),
        //this stride not real dont use stride = 2
        .ifm_sel_next(ifm_sel_next),
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
        .start_to_next(start_to_next)
    );    
     
DONATE


system("perl DP_gen_B.pl $ARGV[0] $ARGV[2] $ARGV[3] $ARGV[4] $ARGV[5] $ARGV[6] $ARGV[7] $ARGV[8] $ARGV[9] $ARGV[10] $ARGV[11] $ARGV[13] $ARGV[12]");

$dp_name = "convb$ARGV[0]_DP";
print $fh <<"DONATE";

	$dp_name 
    #(
        .ARITH_TYPE(ARITH_TYPE), 
        .DATA_WIDTH(DATA_WIDTH), 
        .ADDRESS_BITS(ADDRESS_BITS), 
        .IFM_WIDTH(IFM_WIDTH), 
        .IFM_HEIGHT(IFM_HEIGHT), 
        .IFM_DEPTH(IFM_DEPTH), 
        .KERNAL_SIZE(KERNAL_SIZE), 
        .NUMBER_OF_FILTERS(NUMBER_OF_FILTERS), 
        .NUMBER_OF_UNITS(NUMBER_OF_UNITS)
    )
    DP_B$ARGV[0]
	(
        .clk(clk),
        .reset(reset),
        .riscv_data(riscv_data),
        .riscv_address(riscv_address),
	//////////////////////////////////////////////
	    .data_in_A_from_previous(data_in_A_from_previous1),
DONATE
if($ARGV[11] == 2){
	print $fh <<"DONATE";
        .data_in_B_from_previous(data_in_B_from_previous1),
DONATE
}
print $fh <<"DONATE";
        .fifo_enable(fifo_enable),
        .conv_enable(conv_enable),
        .accu_enable(accu_enable),
        .relu_enable(relu_enable),
	
DONATE
for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
	print $fh <<"DONATE";
	    .data_in_from_next$i(data_in_from_next$i),
DONATE
    print $fh <<"DONATE";
	    .data_out_for_next$i(data_out_for_next$i),
DONATE
}

if($padding_exist == 1){
print $fh <<"DONATE";
	    .zeros_sel(zeros_sel),
DONATE
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
        .bm_address_read_current(bm_address_read_current)
	//////////////////////////////////////////////

    );
	
	
endmodule	
DONATE


close $fh or die "Couldn't Close File : $!";
