use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";

# MAX Pooling editing finished

#argumets 
#ARGV[0] DATA_WIDTH 32
#ARGV[1] IFM_WIDTH 14
#ARGV[2] IFM_HEIGHT 14
#ARGV[3] IFM_DEPTH 3
#ARGV[4] STRIDE 2
#ARGV[5] NO._OF_UNITS 3
#ARGV[6] KERNAL_SIZE 2
#ARGV[7] ARITH_TYPE
#ARGV[8] POOL_TYPE
#ARGV[9] POOL NUMBER
#$ARGV[10]

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

my $ifm_size = "IFM_SIZE"; 
my $ifm_width = "IFM_WIDTH"; 
my $ifm_height = "IFM_HEIGHT"; 
my $ifm_depth = "IFM_DEPTH";
my $kernal_size = "KERNAL_SIZE";
my $number_of_filters = "NUMBER_OF_FILTERS";
my $number_of_units = "NUMBER_OF_UNITS";
my $pool_type = "POOL_TYPE";
my $full_path = "../../../$ARGV[10]/";

#######################################################################################
my $i = 0;
my $j = 0;
my $jj = 0; 
my $file_name;
my $module_name;
my $pool_unit_name = "poolb_unit_$ARGV[1]";
system("perl PoolB_unit.pl  $ARGV[0] $ARGV[2] $ARGV[1] $ARGV[6] $ARGV[4] $ARGV[7] $ARGV[8] $ARGV[10]");


$module_name = "poolb_dp$ARGV[9]_U$ARGV[5]";

$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  
  print $fh <<"DONATE";
  
$module $module_name $parameter
///////////advanced parameters//////////
	$data_width 			  = $ARGV[0],
	////////////////////////////////////
	$ifm_width                = $ARGV[1],  
	$ifm_height               = $ARGV[2],                                                
	$ifm_depth                = $ARGV[3],
	ARITH_TYPE 				  = $ARGV[7],
	$kernal_size              = $ARGV[6],
	$pool_type				  = $ARGV[8]
)(
	$i_p 							clk,
	$i_p 							reset,
	$i_p 							fifo_enable,
	$i_p							pool_enable,
DONATE

if($ARGV[4] == 2){
	for($i=1; $i<= $ARGV[5]; $i = $i + 1){
		print $fh <<"DONATE";
	$i_p [$data_width-1:0] data_in_A_unit$i,
	$i_p [$data_width-1:0] data_in_B_unit$i,
DONATE
	}
}
else{
	for($i=1; $i<= $ARGV[5]; $i = $i + 1){
		print $fh <<"DONATE";
	$i_p [$data_width-1:0] data_in_A_unit$i,
DONATE
	}
}

for($i=1; $i< $ARGV[5]; $i = $i + 1){
	print $fh <<"DONATE";
	$o_p [$data_width-1:0] data_out_$i,
DONATE
}

	print $fh <<"DONATE";
	$o_p [$data_width-1:0] data_out_$i
	);
DONATE

if($ARGV[4] == 2){
	for($i=1; $i<= $ARGV[5]; $i = $i + 1){

		print $fh <<"DONATE";
	$pool_unit_name 
	#(
		.$data_width($data_width), 
		.$ifm_height($ifm_height), 
		.$ifm_width($ifm_width), 
		.ARITH_TYPE(ARITH_TYPE),
		.$kernal_size($kernal_size),
		.POOL_TYPE(POOL_TYPE)
	)
    unit$i
	(
		.clk(clk),
		.reset(reset),
		.fifo_enable(fifo_enable),
		.pool_enable(pool_enable),
		.unit_data_in(data_in_A_unit$i),
		.unit_data_in_2(data_in_B_unit$i),
		.unit_data_out(data_out_$i)
    );
	
DONATE
	}
}
else{
	for($i=1; $i<= $ARGV[5]; $i = $i + 1){
	print $fh <<"DONATE";
	$pool_unit_name 
	#(
		.$data_width($data_width), 
		.$ifm_height($ifm_height), 
		.$ifm_width($ifm_width),  
		.ARITH_TYPE(ARITH_TYPE),
		.$kernal_size($kernal_size),
		.POOL_TYPE(POOL_TYPE)
	)
    unit$i
	(
		.clk(clk),
		.reset(reset),
		.fifo_enable(fifo_enable),
		.pool_enable(pool_enable),
		.unit_data_in(data_in_A_unit$i),
		.unit_data_out(data_out_$i)
    );
	
DONATE
	}
}

	print $fh <<"DONATE";
endmodule
	
DONATE

