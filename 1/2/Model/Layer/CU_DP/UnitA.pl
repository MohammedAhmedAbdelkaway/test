use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";


use POSIX;
#argumets 
#ARGV[0] DATA_WIDTH
#ARGV[1] IFM_WIDTH
#ARGV[2] IFM_HEIGHT
#ARGV[3] KERNAL_SIZE
#ARGV[4] Stride
#ARGV[5] ARITH_TYPE
#ARGV[6] IFM_DEPTH
#ARGV[7] NUMBER_OF_FILTERS
#ARGV[8] NUMBER_OF_UNITS
#ARGV[9] PADDING_EXIST
#$ARGV[10] relative path

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
my $full_path = "../../../$ARGV[10]/";
#######################################################################################
my $i = 0;
my $j = 0;
my $jj = 0;
my $file_name;
my $module_name;
my $adder_name;
my $div_name;
my $odd_flag;
my $dummy_level;
my @levels;
my $levels_number;
my $divided_by;

# Variable to hold padding state #
my $padding_exist  = $ARGV[9];

my $single_port_name = "single_port_memory"; 
$module_name = "unitA_$ARGV[1]";

$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  
 print $fh <<"DONATE";
$module $module_name $parameter
///////////advanced parameters//////////
	DATA_WIDTH 		    	= $ARGV[0],
	/////////////////////////////////////
	IFM_WIDTH               = $ARGV[1],
	IFM_HEIGHT              = $ARGV[2],                                                
	IFM_DEPTH               = $ARGV[6],
	KERNAL_SIZE             = $ARGV[3],
	NUMBER_OF_FILTERS		= $ARGV[7],
	ARITH_TYPE				= $ARGV[5],
	NUMBER_OF_UNITS 		= $ARGV[8],
	STRIDE					= $ARGV[4],
	CEIL_DEPTH              = \$rtoi(\$ceil(IFM_DEPTH*1.0/NUMBER_OF_UNITS)),
DONATE

if ($ARGV[4] == 2){
print $fh <<"DONATE";
	FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH + KERNAL_SIZE +1,
DONATE
}
else{
	print $fh <<"DONATE";
	FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH + KERNAL_SIZE ,
DONATE
}
 
print $fh <<"DONATE";
	ADDRESS_SIZE_WM         = $clog2(KERNAL_SIZE*KERNAL_SIZE*NUMBER_OF_FILTERS*CEIL_DEPTH)      

	)(
	$i_p 							clk,
	$i_p 							reset,
	
	$i_p 	[$data_width-1:0]		riscv_data,
	$i_p 	[$data_width-1:0]		unit_data_in_A,
DONATE

if($ARGV[4] == 2){
	print $fh <<"DONATE";
    $i_p    [$data_width-1:0]       unit_data_in_B,
DONATE
}

print $fh <<"DONATE";	
	$i_p 							fifo_enable,
	$i_p 							conv_enable,
	
	$i_p 							wm_enable_read,
	$i_p 							wm_enable_write,
	$i_p 							wm_fifo_enable,
	
	$i_p	[ADDRESS_SIZE_WM-1:0]		wm_address,
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
	$o_p 	[$data_width-1:0]		unit_data_out
	);
////////////////////////Signal declaration/////////////////
	wire [$data_width-1:0] wm_data_out;
	
DONATE


for($i = 1; $i <= ($ARGV[3]*$ARGV[3]); $i = $i + 1){
	print $fh "\twire [$data_width-1:0]	signal_if$i,\tsignal_w$i;\n";
}

if($padding_exist == 1){
print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] input_data;

    assign input_data = (zeros_sel) ? {DATA_WIDTH{1'b0}} : unit_data_in_A;
DONATE
}
    
 print $fh <<"DONATE";

$single_port_name 
	#(
		.MEM_SIZE ($kernal_size * $kernal_size * $number_of_filters * CEIL_DEPTH ), 
		.DATA_WIDTH(DATA_WIDTH)
	) 
	WM 
	(
		.clk(clk),	
		.Enable_Write(wm_enable_write), 
		.Enable_Read(wm_enable_read), 
		.Address(wm_address), 
		.Data_Input(riscv_data),	
		.Data_Output(wm_data_out)
	 );    
    

DONATE



chdir "./Modules";
system("perl fc_fifo.pl  ${\($ARGV[3]*$ARGV[3])} $ARGV[0] $ARGV[10]");

my $num_outputs = $ARGV[3]*$ARGV[3];
my $fifo_regs = (($ARGV[3] - 1)*$ARGV[1] + $ARGV[3]);
my $fifo_name = "fo_fifo_${\($ARGV[3]*$ARGV[3])}";

print $fh <<"DONATE";

$fifo_name 
	#(
		.$data_width($data_width)
	)
	WM_FIFO (
		.clk(clk),
		.reset(reset),
		.fifo_enable(wm_fifo_enable),
		.fifo_data_in(wm_data_out),
DONATE

for($i = 1; $i < ($ARGV[3]*$ARGV[3]); $i = $i + 1){
	print $fh "\t\t.fifo_data_out_$i(signal_w$i),\n";
}
print $fh "\t\t.fifo_data_out_$i(signal_w$i)\n";


system("perl fifo.pl  $ARGV[4] $ARGV[0] $ARGV[1] $ARGV[2] $ARGV[3] $ARGV[10]");

$num_outputs = $ARGV[3]*$ARGV[3];

if($ARGV[4] == 2){
	$fifo_regs = (($ARGV[3] - 1)*$ARGV[1] + $ARGV[3]) + 1;
}
else{
	$fifo_regs = (($ARGV[3] - 1)*$ARGV[1] + $ARGV[3]);
}

$fifo_name = "FIFO_$num_outputs$under_Score$ARGV[4]$under_Score$fifo_regs";


 print $fh <<"DONATE";
);
$fifo_name 
	#(
		.$data_width($data_width),
		.$kernal_size($kernal_size), 
		.IFM_WIDTH(IFM_WIDTH),
		.FIFO_SIZE(FIFO_SIZE)
	)
	FIFO1 (
		.clk(clk),
		.reset(reset),
		.fifo_enable(fifo_enable),
DONATE

if($padding_exist == 1){
	print $fh <<"DONATE";
	 	.fifo_data_in(input_data),	
DONATE
}
else{
	print $fh <<"DONATE";
	 	.fifo_data_in(unit_data_in_A),	
DONATE
}

if($ARGV[4] == 2){
	
	print $fh <<"DONATE";
		.fifo_data_in_2(unit_data_in_B),	
DONATE
}

for($i = 1; $i < ($ARGV[3]*$ARGV[3]); $i = $i + 1){
	print $fh "\t\t.fifo_data_out_$i(signal_if$i),\n";
}
print $fh "\t\t.fifo_data_out_$i(signal_if$i)\n";


system("perl convolution.pl  ${\($ARGV[3]*$ARGV[3])} $ARGV[5] $ARGV[0] $ARGV[10]");

$fifo_name = "convolution_S${\($ARGV[3]*$ARGV[3])}";
 print $fh <<"DONATE";
);
$fifo_name 
	#(
		.$data_width($data_width), 
		.ARITH_TYPE(ARITH_TYPE))
	conv
	(
		.clk(clk),
		.reset(reset),
		.conv_enable(conv_enable),
		.conv_data_out(unit_data_out),
DONATE

for($i = 1; $i < ($ARGV[3]*$ARGV[3]); $i = $i + 1){
	print $fh "\t\t.w$i(signal_w$i),.if$i(signal_if$i),\n";
}
print $fh "\t\t.w$i(signal_w$i),.if$i(signal_if$i)\n";


 print $fh <<"DONATE";
 
);


$end_module
DONATE


