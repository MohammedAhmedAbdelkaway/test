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
#ARGV[4] KERNAL_SIZE 2
#ARGV[5] NO._OF_UNITS 1
#ARGV[6] STRIDE 2
#ARGV[7] ARITH_TYPE
#ARGV[8] POOL_TYPE (1 => avg) , (0 => max)
#ARGV[9] POOL NUMBER
#ARGV[10]


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
my $pool_type = "POOL_TYPE";

my $full_path = "../../../$ARGV[10]/";
#######################################################################################
my $i = 0;
my $j = 0;
my $jj = 0;
my $file_name;
my $module_name;




$module_name = "poola_dp$ARGV[9]_S$ARGV[6]";

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
	$kernal_size              = $ARGV[4],
	ARITH_TYPE 				  = $ARGV[7],
	$pool_type				  = $ARGV[8]
)(
	$i_p 							clk,
	$i_p 							reset,
	
	$i_p 							fifo_enable,
	$i_p							pool_enable,
DONATE

if($ARGV[6] == 2){
		print $fh <<"DONATE";
	$i_p [$data_width-1:0] data_in_A,
	$i_p [$data_width-1:0] data_in_B,
DONATE
	
}
else{
		print $fh <<"DONATE";
	$i_p [$data_width-1:0] data_in_A,
DONATE
	
}

	print $fh <<"DONATE";
	output [DATA_WIDTH-1:0] data_out
    );
////////////////////////Signal declaration/////////////////
	
DONATE

for($i=1; $i<= $ARGV[4] * $ARGV[4]; $i = $i + 1){
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] signal_if$i;
DONATE
}



my $num_outputs_of_fifo = $ARGV[4] * $ARGV[4];
my $fifo_regs_of_fifo = (($ARGV[4] - 1) * $ARGV[1] + $ARGV[4]);
my $module_name_of_fifo;
my $module_name_of_pool;


$module_name_of_fifo = "FIFO_$num_outputs_of_fifo$under_Score$ARGV[6]$under_Score$fifo_regs_of_fifo";


chdir "./Modules";
system("perl fifo.pl  $ARGV[6] $ARGV[0] $ARGV[1] $ARGV[2] $ARGV[4] $ARGV[10]");


print $fh <<"DONATE";

	$module_name_of_fifo #(.$data_width($data_width), .$ifm_width($ifm_width),.$ifm_height($ifm_height), .$kernal_size($kernal_size))
	FIFO1 (
	.clk(clk),
	.reset(reset),
	.fifo_enable(fifo_enable),
	.fifo_data_in(data_in_A),
	
DONATE

if($ARGV[6] == 2){
print $fh <<"DONATE";
	.fifo_data_in_2(data_in_B),
DONATE
}

for($i = 1; $i < $num_outputs_of_fifo; $i = $i + 1){
print $fh <<"DONATE";
	.fifo_data_out_$i(signal_if$i),
DONATE
}

print $fh <<"DONATE";
	.fifo_data_out_$i(signal_if$i)
	);
	
DONATE


system("perl pool.pl  ${\($ARGV[4]*$ARGV[4])} $ARGV[7] $ARGV[0] $ARGV[8] $ARGV[10]");


if($ARGV[8]==1){
	$module_name_of_pool = "average_pooling_S${\($ARGV[4]*$ARGV[4])}";
}
else{
	$module_name_of_pool = "max_pooling_S${\($ARGV[4]*$ARGV[4])}";
}

print $fh <<"DONATE";
	$module_name_of_pool #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE))
	pool_1 (
	.clk(clk),
    .reset(reset),
    .pool_enable(pool_enable),

DONATE

for($i = 1; $i <= $num_outputs_of_fifo; $i = $i + 1){
print $fh <<"DONATE";
	.pool_data_in_$i(signal_if$i),
DONATE
}

print $fh <<"DONATE";
	.pool_data_out_reg(data_out)
	);
		
endmodule
DONATE

close $fh or die "Couldn't Close File : $!";