#*COMMENTED*#

use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";

use POSIX;

#######################################################
############    ARGUMENTS DISCRIPTION    ##############
#######################################################

#ARGV[0] no of the conv 
#ARGV[1] Mul number//
#ARGV[2] ARITH_TYPE
#ARGV[3] DATA_WIDTH
#ARGV[4] ADDRESS_BITS
#ARGV[5] IFM_WIDTH
#ARGV[6] IFM_HEIGHT  
#ARGV[7] IFM_DEPTH 
#ARGV[8] KERNAL_SIZE  
#ARGV[9] NUMBER_OF_FILTERS
#ARGV[10] NUMBER_OF_UNITS
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
###########################################################

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
my $accumulator_name = "accumulator"; 
$module_name = "conva$ARGV[0]_DP";



my $unitA_ifm_width;
my $unitA_ifm_height;

# Variable to hold padding state #
my $padding_exist  = $ARGV[12];
my $stride = $ARGV[11];

# input Width and height with padding value added #
my $pad_value  = ($ARGV[8] - 1) ;

if($padding_exist == 1 && ($stride == 2)){
    $unitA_ifm_width = $ARGV[5] + $pad_value -1;
    $unitA_ifm_height = $ARGV[6] + $pad_value -1;
}
elsif($padding_exist == 1 && ($stride == 1)){
    $unitA_ifm_width = $ARGV[5] + $pad_value ;
    $unitA_ifm_height = $ARGV[6] + $pad_value ;
}
else{
    $unitA_ifm_width = $ARGV[5];
    $unitA_ifm_height = $ARGV[6];
}

# Calculating number of adders levels needed to add the results from all units 
$odd_flag = 0;
$dummy_level = $ARGV[10]; 
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



####################################################
#############     GENERATING FILE    ###############
####################################################

$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  
  print $fh <<"DONATE";
$module $module_name $parameter
///////////advanced parameters//////////
	DATA_WIDTH 	   		   = $ARGV[3],
	ADDRESS_BITS 		   = $ARGV[4],
	/////////////////////////////////////
	IFM_WIDTH              = $ARGV[5],
	IFM_HEIGHT       	   = $ARGV[6],                                                
	IFM_DEPTH              = $ARGV[7],
	KERNAL_SIZE            = $ARGV[8],
	NUMBER_OF_FILTERS      = $ARGV[9],
	NUMBER_OF_UNITS        = $ARGV[10],
	ARITH_TYPE 			   = $ARGV[2],
	STRIDE				   = $stride,
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
	ADDRESS_SIZE_WM         = $clog2( KERNAL_SIZE*KERNAL_SIZE*NUMBER_OF_FILTERS*(${\(ceil($ARGV[7]/$ARGV[10]))}) ),    
	FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH + KERNAL_SIZE,
	NUMBER_OF_IFM           = IFM_DEPTH,
	NUMBER_OF_IFM_NEXT      = NUMBER_OF_FILTERS,
	NUMBER_OF_WM            = KERNAL_SIZE*KERNAL_SIZE,                              
	NUMBER_OF_BITS_SEL_IFM_NEXT = $clog2(NUMBER_OF_IFM_NEXT)
)(
	// General Signals
	input clk,
	input reset,

	// Signals from RISC-V
	input [DATA_WIDTH-1:0] 	riscv_data,
	input [ADDRESS_BITS-1:0] riscv_address,
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
    input                                 bm_enable_write,
    input [$clog2(NUMBER_OF_FILTERS)-1:0] bm_address_read_current,
    
	// Signals from IFM Memory (Read)
DONATE


for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){

	print $fh <<"DONATE";
	input [DATA_WIDTH-1:0] data_in_A_from_previous$i,
DONATE
	if($stride == 2){
		print $fh <<"DONATE";
	input [DATA_WIDTH-1:0] data_in_B_from_previous$i,
DONATE
	}
}

print $fh <<"DONATE";
	// Signal to OFM Memory
	input  [DATA_WIDTH-1:0] data_in_from_next,
    output [DATA_WIDTH-1:0] data_out_for_next
    );

///////////////////////////////////////////////////////
////////////////  Signal declaration  /////////////////
///////////////////////////////////////////////////////

DONATE
 
 
 for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
	print $fh <<"DONATE";
	wire [DATA_WIDTH-1:0] unit${\($i)}_data_out;
DONATE
}


 print $fh <<"DONATE";
 
	wire [DATA_WIDTH-1:0] accu_data_out;
	wire [DATA_WIDTH-1:0] relu_data_out;
	
	wire [DATA_WIDTH-1:0] data_bias;
	

	wire [ADDRESS_SIZE_WM-1:0] wm_address;
	wire [$clog2(NUMBER_OF_FILTERS)-1:0] bm_address;
	
DONATE
 

	
$odd_flag = 0;
for ($i = 1; $i < $levels_number; $i = $i + 1){
	$odd_flag = $odd_flag + ($levels[$i-1] % 2);
	for($j = 1; $j <= $levels[$i] + ($odd_flag % 2);$j = $j + 1){
		print $fh "\twire\t[DATA_WIDTH - 1 : 0]	adder_out_$i$under_Score$j;\n";
	}
	print $fh "\n";
}
 
 

 $odd_flag = 0;
for ($i = 1; $i < $levels_number; $i = $i + 1){
	$odd_flag = $odd_flag + ($levels[$i-1] % 2);
	for($j = 1; $j <= $levels[$i] + ($odd_flag % 2);$j = $j + 1){
		print $fh "\treg \t[DATA_WIDTH - 1 : 0]	reg_adder_out_$i$under_Score$j;\n";
	}
	print $fh "\n";
}


print $fh <<"DONATE";   

	// Mux to switch between writing parameters from RISC-V or Reading parameters in normal operation
	assign wm_address = wm_addr_sel ? wm_address_read_current : riscv_address[ADDRESS_SIZE_WM-1:0];
	assign bm_address = bm_addr_sel ? bm_address_read_current : riscv_address[$clog2(NUMBER_OF_FILTERS)-1:0];


DONATE

print $fh <<"DONATE"; 
    ///////////////////////////////////////////////////////////
	///////////////// BIAS MERMORY INSTANSIATION //////////////
	///////////////////////////////////////////////////////////
	$single_port_name #(.MEM_SIZE (NUMBER_OF_FILTERS), .DATA_WIDTH(DATA_WIDTH)) bm 
	(
		.clk(clk),	
		.Enable_Write(bm_enable_write),
		.Enable_Read(bm_enable_read),	
		.Address(bm_address),
		.Data_Input(riscv_data),	
		.Data_Output(data_bias)
	);
	 

DONATE

# Generation of Convolution Units
system("perl UnitA.pl $ARGV[3] $unitA_ifm_width $unitA_ifm_height $ARGV[8] $stride $ARGV[2] $ARGV[7] $ARGV[9] $ARGV[10] $ARGV[12] $ARGV[13]");
$unit_name = "unitA_$unitA_ifm_width";

print $fh <<"DONATE";
    ///////////////////////////////////////////////////////////
	///////////////// CONVA UNITS INSTANSIATION ///////////////
	///////////////////////////////////////////////////////////

DONATE

for ($i = 1; $i <= $ARGV[10]; $i = $i + 1){
		print $fh <<"DONATE"; 
	$unit_name 
	#(
		.DATA_WIDTH(DATA_WIDTH), 
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
		.IFM_DEPTH(IFM_DEPTH), 
		.NUMBER_OF_UNITS(NUMBER_OF_UNITS),
		.KERNAL_SIZE(KERNAL_SIZE), 
		.NUMBER_OF_FILTERS(NUMBER_OF_FILTERS),
		.ARITH_TYPE(ARITH_TYPE))
    unit_$i
    (
		.clk(clk),                                 
		.reset(reset),  
		.riscv_data(riscv_data),                             
		.unit_data_in_A(data_in_A_from_previous$i),
DONATE

	if($stride == 2){
		print $fh <<"DONATE";
    	.unit_data_in_B(data_in_A_from_previous$i),
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
		.wm_enable_write(wm_enable_write[${\($i-1)}]),          
		.wm_address(wm_address), 
		.wm_fifo_enable(wm_fifo_enable),         
		.unit_data_out(unit${\($i)}_data_out)   
    );
DONATE
}


if($ARGV[10] == 1){
	print $fh <<"DONATE";  
		$accumulator_name #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE))
		accu
		(
			.clk(clk),
			.accu_enable(accu_enable),
			.data_in_from_conv(unit1_data_out),
			.data_bias(data_bias),
			.data_in_from_next(data_in_from_next),
			.accu_data_out(accu_data_out)
		);
DONATE
	
}
else{
	print $fh <<"DONATE";

    
    always @(posedge clk)
    begin
		
DONATE


	$odd_flag = 0;
	for ($i = 1; $i < $levels_number; $i = $i + 1){
		$odd_flag = $odd_flag + ($levels[$i-1] % 2);
		for($j = 1; $j <= $levels[$i] + ($odd_flag % 2);$j = $j + 1){
			print $fh "\t\t\treg_adder_out_$i$under_Score$j <= adder_out_$i$under_Score$j;\n";
		}
		print $fh "\n";
	}


	print $fh <<"DONATE";   
	end

	// Adding results from all units
DONATE
	$i = 1;
		$odd_flag = $odd_flag + ($levels[$i-1] % 2);
		$jj = 1;
		for($j = 1; $j <= $levels[$i] ;$j = $j + 1){
			
			print $fh "\t$adder_name #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE))\t\tadr_$i$under_Score$j\t(.in1(unit${\($jj)}_data_out), .in2(unit${\($jj+1)}_data_out), .out(adder_out_$i$under_Score$j));\n";
			$jj = $jj + 2;
		}
		if($odd_flag % 2){
			print $fh "\n\tassign adder_out_$i$under_Score$j = unit${\($jj)}_data_out;\n";
		}
		print $fh "\n";


	for ($i = 2; $i < $levels_number; $i = $i + 1){
		$odd_flag = $odd_flag + ($levels[$i-1] % 2);
		$jj = 1;
		for($j = 1; $j <= $levels[$i] ;$j = $j + 1){
			print $fh "\t$adder_name #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE))\t\tadr_$i$under_Score$j\t(.in1(reg_adder_out_${\($i-1)}$under_Score$jj), .in2(reg_adder_out_${\($i-1)}$under_Score${\($jj+1)}), .out(adder_out_$i$under_Score$j));\n";
			$jj = $jj + 2;
		}
		if($odd_flag % 2){
			print $fh "\n\tassign adder_out_$i$under_Score$j = reg_adder_out_${\($i-1)}$under_Score$jj;\n";
		}
		print $fh "\n";
	}


	print $fh <<"DONATE"; 
		// Upload Bias in first cycle at every new channel, then accumlate partial sums until get final sums  
		$accumulator_name #(.DATA_WIDTH(DATA_WIDTH), .ARITH_TYPE(ARITH_TYPE))
		accu
		(
			.clk(clk),
			.accu_enable(accu_enable),
			.data_in_from_conv(reg_adder_out_${\($i-1)}$under_Score${\($jj-2)}),
			.data_bias(data_bias),
			.data_in_from_next(data_in_from_next),
			.accu_data_out(accu_data_out)
		);
DONATE

}
print $fh <<"DONATE";   
	// RelU Activation Function
	$Relu_name #(.DATA_WIDTH(DATA_WIDTH)) Active1 (.in(accu_data_out), .out (relu_data_out), .relu_enable(relu_enable));
	
	// Result from convolution to OFM Memory
    assign data_out_for_next = relu_data_out;	   	 
	
endmodule

DONATE
close $fh or die "Couldn't Close File : $!";
