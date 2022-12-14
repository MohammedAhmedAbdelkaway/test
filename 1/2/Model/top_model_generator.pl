use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";
use POSIX;

#argumets
#ARGV[0]   LAYERS_NAMES DELIMITED BY COMAS ex: conva1,convb,conva2,fc1,fc2
#ARGV[1]   NUMBER OF UNITS DELIMITED BY COMAS ex: 3,3,3,84,10
#ARGV[2]   KERNAL_SIZE DELIMITED BY COMAS
#ARGV[3]   NUMBER_OF_FILTERS DELIMITED BY COMAS | was OUTPUT CHANNELS |
#ARGV[4]   IFM_WIDTH DELIMITED BY COMAS | was INPUT SIZE |
#ARGV[5]   IFM_HEIGHT DELIMITED BY COMAS | was INPUT SIZE |
#ARGV[6]   IFM_DEPTH DELIMITED BY COMAS | was INPUT CHANNELS |
#ARGV[7]   DATA_WIDTH
#ARGV[8]   ADDRESS_BUS
#ARGV[9]   ADDRESS_BITS
#ARGV[10]   RGB FLAG
#ARGV[11]  STRIDES  DELIMITED BY COMAS
#ARGV[12]  ARITH_TYPE
#ARGV[13]  PADDING_EXIST
#ARGV[14]  CONV_TYPE
#ARGV[15]  $relative_path

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
my $full_path = "../$ARGV[15]/";
#######################################################################################
my $i = 0;
my $j = 0;
my $k = 0;
my $pool_type;
my $pool_num = 0;
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
$module_name = "top_module";


$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  
  
  
  
print $fh <<"DONATE";
$module $module_name $parameter
		///////////advanced parameters//////////
        $data_width                 = $ARGV[7],
        ADDRESS_BUS                 = $ARGV[8],
        ADDRESS_BITS                = $ARGV[9],
        ARITH_TYPE                  = $ARGV[12],
		/////////////////////////////////////
DONATE

my @layers_names = split(',', $ARGV[0]);
my $layers_count = @layers_names;

my @layer_units  = split(',', $ARGV[1]);

my @kernal_size  = split(',', $ARGV[2]);

my @filter_num   = split(',', $ARGV[3]);

my @ifm_width    = split(',', $ARGV[4]);

my @ifm_height   = split(',', $ARGV[5]);

my @ifm_depth    = split(',', $ARGV[6]);

my @stride       = split(',', $ARGV[11]);

my @padding_state       = split(',', $ARGV[13]);
###########################################
#this part generate the parameters        #
###########################################
for($i = 0; $i < $layers_count; $i = $i + 1){
    if($layers_names[$i] =~ /conv/){
        print $fh <<"DONATE";
		// ${\($i+1)}.$layers_names[$i]
        ${\(uc $layers_names[$i])}_KERNAL_SIZE             = $kernal_size[$i],
        ${\(uc $layers_names[$i])}_NUMBER_OF_FILTERS       = $filter_num[$i],
        ${\(uc $layers_names[$i])}_IFM_WIDTH               = $ifm_width[$i],
        ${\(uc $layers_names[$i])}_IFM_HEIGHT              = $ifm_height[$i],
        ${\(uc $layers_names[$i])}_IFM_DEPTH               = $ifm_depth[$i],
        ${\(uc $layers_names[$i])}_NUMBER_OF_UNITS         = $layer_units[$i],
        ${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM        = $clog2(${\(uc $layers_names[$i])}_IFM_WIDTH * ${\(uc $layers_names[$i])}_IFM_HEIGHT),
		
DONATE
    }
    if($layers_names[$i] =~ /pool/){
        print $fh <<"DONATE";
		// ${\($i+1)}.$layers_names[$i]
        ${\(uc $layers_names[$i])}_KERNAL_SIZE             = $kernal_size[$i],
        ${\(uc $layers_names[$i])}_IFM_WIDTH               = $ifm_width[$i],
        ${\(uc $layers_names[$i])}_IFM_HEIGHT              = $ifm_height[$i],
        ${\(uc $layers_names[$i])}_IFM_DEPTH               = $ifm_depth[$i],
        ${\(uc $layers_names[$i])}_NUMBER_OF_UNITS         = $layer_units[$i],
        ${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM        = $clog2(${\(uc $layers_names[$i])}_IFM_WIDTH * ${\(uc $layers_names[$i])}_IFM_HEIGHT),
		
DONATE
    }
    if($layers_names[$i] =~ /fc/){
        print $fh <<"DONATE";
		// ${\($i+1)}.$layers_names[$i]
        ${\(uc $layers_names[$i])}_NUMBER_OF_FILTERS         = $filter_num[$i],
        ${\(uc $layers_names[$i])}_IFM_DEPTH                = $ifm_depth[$i],
        ${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM         = 0,
		
DONATE
    }
}
#############################################
#this part generate the inpusts and outputs #
#############################################
print $fh <<"DONATE";


        ENABLE_BITS              = ADDRESS_BUS - ADDRESS_BITS
    )(
    input                               clk                        ,
    input                               reset                      ,
    input              [DATA_WIDTH-1:0] riscv_data_bus             ,
    input              [ADDRESS_BUS-1:0]riscv_address_bus          ,
    input                               initialization_done        ,
	
DONATE

for($i = 1; $i <= $filter_num[$layers_count-1]; $i = $i + 1){
    print $fh <<"DONATE";
    output             [DATA_WIDTH-1:0] Data_out_${\($i)}_final    ,
DONATE

}

print $fh <<"DONATE";
    output                              ready                      ,
    output                              testSignal                 ,
    output                              output_ready             
    );
	
	wire	memControl_conva1_start    ;
DONATE

if($ARGV[10] == 0){
    print $fh <<"DONATE";
	//1 indicates the input img is grayscale
	wire	[1-1:0] memControl_conva1_ifm_enable_write;
	
DONATE
}
else{
    print $fh <<"DONATE";
	//3 indicates the input img is RGB
	wire	[3-1:0] memControl_conva1_ifm_enable_write;
	
DONATE
}

for($i = 0; $i <$layers_count; $i = $i + 1){
    if (index($layers_names[$i], "pool") == -1) {
        print $fh <<"DONATE";
	wire	[$layer_units[$i]-1:0] memControl_$layers_names[$i]_wm_enable_write           ;
DONATE
    }
}

print $fh <<"DONATE";

	wire	[DATA_WIDTH-1:0] memControl_riscv_data      ;
	wire	[ADDRESS_BITS-1:0]memControl_riscv_address   ;
	
DONATE

for($i = 0; $i <$layers_count; $i = $i + 1){
    if (index($layers_names[$i], "pool") == -1) {
        if (index($layers_names[$i], "convb") == -1) {
            print $fh <<"DONATE";
	wire	memControl_$layers_names[$i]_bm_enable_write;
	
DONATE
        }
        else{
            print $fh <<"DONATE";
	wire	[$layer_units[$i]-1:0] memControl_$layers_names[$i]_bm_enable_write;
	
DONATE
        }
    }
}

#######################################################################
#this loop generate the wires for layers and mem array WIRE WIRE WIRE #
#######################################################################

my $ab_flag = 0;#false, 0 is a/ true, 1 is b
my $is_itConvB = 0;
my $unit_counter;
my $is_itPool = 0;
my $is_itFCfirst = 0;

for($i = 0; $i < $layers_count; $i = $i + 1){
    if($layers_names[$i] =~ /conv/){
        $is_itPool = 0;
        if($i == 0){
            print $fh <<"DONATE";
			
	// Outputs of layer Conv $i
	wire    [DATA_WIDTH-1:0]  ${\($layers_names[$i])}_data_out_for_next1       ;
	wire    [${\(uc $layers_names[$i+1])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_write_next  ;
	wire    ${\($layers_names[$i])}_ifm_enable_write_next;	
	wire    ${\($layers_names[$i])}_start_to_next;
	wire    ${\($layers_names[$i])}_ifm_sel_next;
	
DONATE
            $ab_flag = $ab_flag + 1;
            $is_itConvB = 1;
        }
        else{
            $ab_flag = $ab_flag + 1;
            if($ab_flag % 2){
                print $fh <<"DONATE";
			
	// Outputs of layer Conv $i
	wire    ${\($layers_names[$i])}_end_to_previous;
	wire    ${\($layers_names[$i])}_ready;

DONATE
                if($stride[$i] == 2){
                    print $fh <<"DONATE";
    wire	${\($layers_names[$i])}_ifm_enable_read_A_current;
    wire	${\($layers_names[$i])}_ifm_enable_read_B_current;
    wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_A_current;
    wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_B_current;

DONATE
                }
                else{
                    print $fh <<"DONATE";
    
    wire	${\($layers_names[$i])}_ifm_enable_read_A_current;
    wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_A_current;

DONATE
                }
              

                print $fh <<"DONATE";
    wire	[DATA_WIDTH-1:0] ${\($layers_names[$i])}_data_out_for_next1       ;
    wire	[${\(uc $layers_names[$i+1])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_next;
    wire	[${\(uc $layers_names[$i+1])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_write_next;
    wire	${\($layers_names[$i])}_ifm_enable_write_next;
    wire	${\($layers_names[$i])}_ifm_enable_read_next;
    wire	${\($layers_names[$i])}_start_to_next;
    wire	[$clog2(${\(ceil($ifm_depth[$i]/$layer_units[$i]))})-1:0] ${\($layers_names[$i])}_ifm_sel_previous;
    wire	${\($layers_names[$i])}_ifm_sel_next;
	
DONATE
                $is_itConvB = 1;
            }
            else{
                print $fh <<"DONATE";
			
	// Outputs of layer Conv $i
	wire	${\($layers_names[$i])}_end_to_previous;
DONATE
				if($stride[$i] == 2){
                    print $fh <<"DONATE";
    wire	${\($layers_names[$i])}_ifm_enable_read_A_current;
    wire	${\($layers_names[$i])}_ifm_enable_read_B_current;
    wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_A_current;
    wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_B_current;

DONATE
                }
                else{
                    print $fh <<"DONATE";
    
    wire	${\($layers_names[$i])}_ifm_enable_read_A_current;
    wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_A_current;


DONATE
                }
                print $fh <<"DONATE";
	wire	${\($layers_names[$i])}_ifm_enable_read_next;
	wire	${\($layers_names[$i])}_ifm_enable_write_next;
	wire	[${\(uc $layers_names[$i+1])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_next   ;
	wire	[${\(uc $layers_names[$i+1])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_write_next  ;
	
DONATE
                for($j = 1; $j <= $layer_units[$i]; $j = $j + 1){
                    print $fh "\twire [DATA_WIDTH-1:0] ${\($layers_names[$i])}_data_out_for_next$j;\n";
                }
                print $fh <<"DONATE";
	wire	${\($layers_names[$i])}_start_to_next;//all
	wire	[$clog2(${\(ceil($ifm_depth[$i+1]/$layer_units[$i]))})-1:0] ${\($layers_names[$i])}_ifm_sel_next;
				
DONATE
                $is_itConvB = 0;
            }
        }
    }
    if($layers_names[$i] =~ /pool/){
        $is_itPool = 1;
        if($ab_flag % 2){
            print $fh <<"DONATE";

	// Outputs of layer Pool $i
	wire	${\($layers_names[$i])}_ifm_enable_read_A_current;
	wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_A_current;
DONATE
				if($stride[$i] == 2){
					print $fh <<"DONATE";
	wire	${\($layers_names[$i])}_ifm_enable_read_B_current;
	wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_B_current;
DONATE
            }

            
            print $fh <<"DONATE";
    wire	${\($layers_names[$i])}_end_to_previous;
    wire	[DATA_WIDTH-1:0] ${\($layers_names[$i])}_data_out_for_next1                ;
    wire	[${\(uc $layers_names[$i+1])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_write_next  ;
    wire	${\($layers_names[$i])}_ifm_enable_write_next;
    wire	${\($layers_names[$i])}_start_to_next;
    wire	${\($layers_names[$i])}_ifm_sel_next;
DONATE
        }
        else{
            print $fh <<"DONATE";
			
	// Outputs of layer Pool $i		
	wire	${\($layers_names[$i])}_ifm_enable_read_A_current;
	wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_A_current;
DONATE
				if($stride[$i] == 2){
					print $fh <<"DONATE";
	wire	${\($layers_names[$i])}_ifm_enable_read_B_current;
	wire	[${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_read_B_current;
DONATE
            }
            for($j = 1; $j <= $unit_counter; $j = $j + 1){
                print $fh <<"DONATE";
    wire [DATA_WIDTH-1 : 0] ${\($layers_names[$i])}_data_out_for_next$j;
DONATE
            }
            print $fh <<"DONATE";
	wire	${\($layers_names[$i])}_end_to_previous;
	wire	[${\(uc $layers_names[$i+1])}_ADDRESS_SIZE_IFM-1:0] ${\($layers_names[$i])}_ifm_address_write_next  ;
	wire	${\($layers_names[$i])}_ifm_enable_write_next;
	wire	${\($layers_names[$i])}_start_to_next;
	wire	[$clog2(${\(ceil($ifm_depth[$i+1]/$layer_units[$i]))})-1:0]${\($layers_names[$i])}_ifm_sel_next;
DONATE
        }
    }
    if($layers_names[$i] =~ /fc/){
        $is_itPool = 0;
        $is_itFCfirst = $is_itFCfirst + 1;
        $ab_flag = $ab_flag + 1;
        if($is_itFCfirst == 1){
            print $fh <<"DONATE";

    //Outputs of Reg_array $is_itFCfirst
    wire [DATA_WIDTH-1:0]   mem_arr${\($i)}_data_A_out_for_previous1;
    wire [DATA_WIDTH-1:0]   reg_arr1_data_out_for_next;
 
    //Outputs of layer FC $is_itFCfirst
    wire ${\($layers_names[$i])}_enable_read_current;
    wire ${\($layers_names[$i])}_end_to_previous;

    wire ${\($layers_names[$i])}_bias_sel;    
    wire ${\($layers_names[$i])}_enable_write_next;
    wire ${\($layers_names[$i])}_start_to_next;

DONATE
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\twire [DATA_WIDTH-1:0] Data_out_FC_${\($is_itFCfirst)}_$j;\n";
            }
            print $fh "\n\n";
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\twire [DATA_WIDTH-1:0] data_bias_FC_${\($is_itFCfirst)}_$j;\n";
            }
            print $fh "\n\n";
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\twire [DATA_WIDTH-1:0] out_reg_acc${\($is_itFCfirst)}_$j;\n";
            }
            print $fh "\n\n";
        }
        else{
            print $fh <<"DONATE";
    // commented by the perl commity 
    wire ${\($layers_names[$i])}_end_to_previous;

    wire ${\($layers_names[$i])}_bias_sel;    
    wire ${\($layers_names[$i])}_enable_write_next;
    //wire ${\($layers_names[$i])}_start_to_next;

DONATE
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\twire [DATA_WIDTH-1:0] Data_out_FC_${\($is_itFCfirst)}_$j;\n";
            }
            print $fh "\n\n";
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\twire [DATA_WIDTH-1:0] data_bias_FC_${\($is_itFCfirst)}_$j;\n";
            }
            print $fh "\n\n";
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\twire [DATA_WIDTH-1:0] out_reg_acc${\($is_itFCfirst)}_$j;\n";
            }
            print $fh "\n\n";
        }
    }
    ###########################################
    #this part for mem_arr wire between layers#
    ###########################################

        
    if($i != ($layers_count-1)  && !($layers_names[$i+1] =~ /fc/) ){

        if ($is_itConvB){
            $unit_counter = 1;
        }
        else{
            $unit_counter = $layer_units[$i];
        }
        print $fh "\n\t// Outputs of Mem_Array ${\($i+1)} $layers_names[$i] - $layers_names[$i+1]\n";
        if(!$is_itPool && $i != 0){
            for($j = 1; $j <= $unit_counter; $j = $j + 1){
                print $fh "\twire [DATA_WIDTH-1:0] mem_arr${\($i+1)}_data_A_out_for_previous$j;\n";
                if($stride[$i] == 2){
                    print $fh "\twire [DATA_WIDTH-1:0] mem_arr${\($i+1)}_data_B_out_for_previous$j;\n";
                }
            }
        }
        if ($is_itConvB){
            $unit_counter = 1;
        }
        else{
            $unit_counter = $layer_units[$i+1];
        }
        for($j = 1; $j <= $unit_counter; $j = $j + 1){
            print $fh "\twire [DATA_WIDTH-1:0] mem_arr${\($i+1)}_data_A_out_for_next$j;\n";
            if($stride[$i+1] == 2){
                print $fh "\twire [DATA_WIDTH-1:0] mem_arr${\($i+1)}_data_B_out_for_next$j;\n";
            }
        }
    }
}

print $fh <<DONATE;

    assign testSignal = conva1_start_to_next;
DONATE

my $top_name;   
################################################################
#this part generate the instantiation for NENORY CONTROL       #
################################################################
system("perl memory_control.pl $ARGV[0]  $ARGV[1] $ARGV[7] $ARGV[8] $ARGV[9] ${\($ARGV[8] - $ARGV[9])} $ARGV[10] $ARGV[15]");
$top_name = "memory_control";
print $fh <<"DONATE";

	//memory controler
    $top_name #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_BUS(ADDRESS_BUS),
        .ADDRESS_BITS(ADDRESS_BITS)
    )
    MEM_Cont
    (
	
    .riscv_data_bus                    (riscv_data_bus            ),
    .riscv_address_bus                 (riscv_address_bus         ),
    .initialization_done               (initialization_done       ),
    .conva1_start                      (memControl_conva1_start   ),
    .conva1_ifm_enable_write           (memControl_conva1_ifm_enable_write),	
DONATE



for($i = 0; $i <$layers_count; $i = $i + 1){
    if (index($layers_names[$i], "pool") == -1) {
	print $fh <<"DONATE";
	.$layers_names[$i]_wm_enable_write(memControl_${\($layers_names[$i])}_wm_enable_write),
DONATE
    }
}

for($i = 0; $i <$layers_count; $i = $i + 1){
	if (index($layers_names[$i], "pool") == -1) {
                
     
	    print $fh <<"DONATE";
        //updated
	.$layers_names[$i]_bm_enable_write(memControl_${\($layers_names[$i])}_bm_enable_write),
DONATE
    }
}

	print $fh <<"DONATE";
	
    .riscv_data                        (memControl_riscv_data     ),
    .riscv_address                     (memControl_riscv_address  ) 
	);
DONATE
################################################################
#this part generate the instantiation for layers and mem array #
################################################################

chdir "./Layer";

my $mem_name;
my $units;
my $argv0;  
my $IFM_number;
$ab_flag = 0;#false, 0 is a/ true, 1 is b



#########################################################
###instantiation loop                                 ###
#########################################################
$is_itFCfirst = 0;
for($i = 0; $i < $layers_count; $i = $i + 1){
	
    if($layers_names[$i] =~ /conv/){
        if($i == 0){

            #########################################################
            ### inistantion for the first conv                    ###
            #########################################################

            $ab_flag = $ab_flag + 1;
            system("perl conva_first_gen.pl ${\($ab_flag)}  ${\($kernal_size[$i]*$kernal_size[$i])} $ARGV[12] $ARGV[7] $ARGV[9] $ifm_width[$i] $ifm_height[$i] $ifm_depth[$i] $kernal_size[$i] $filter_num[$i] $ARGV[10] $stride[$i] $padding_state[$i] $ARGV[15]");
            $top_name = "top_conva${\($ab_flag)}";
            print $fh <<"DONATE";

	/////////////////$i - $top_name////////////////		

    $top_name #(
    .DATA_WIDTH                        (DATA_WIDTH),
    .IFM_WIDTH                         (${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT                        (${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .IFM_DEPTH                         (${\(uc $layers_names[$i])}_IFM_DEPTH),
    .KERNAL_SIZE                       (${\(uc $layers_names[$i])}_KERNAL_SIZE),
    .NUMBER_OF_FILTERS                 (${\(uc $layers_names[$i])}_NUMBER_OF_FILTERS), 
    .ARITH_TYPE                        (ARITH_TYPE))
    ${\($top_name)}_inst
    (
    .clk                               (clk                       ),
    .reset                             (reset                     ),
    .riscv_data                        (memControl_riscv_data     ),
    .riscv_address                     (memControl_riscv_address  ),
    .wm_enable_write                   (memControl_${\($layers_names[$i])}_wm_enable_write),
    .bm_enable_write                   (memControl_${\($layers_names[$i])}_bm_enable_write),
	// previous
    .start_from_previous               (memControl_${\($layers_names[$i])}_start   ),
    .ifm_enable_write_previous         (memControl_${\($layers_names[$i])}_ifm_enable_write),
    // next
    .end_from_next                     (${\($layers_names[$i+1])}_end_to_previous     ),
    .data_out_for_next1                 (${\($layers_names[$i])}_data_out_for_next1  ),

    .ifm_address_write_next            (${\($layers_names[$i])}_ifm_address_write_next),
    .ifm_enable_write_next             (${\($layers_names[$i])}_ifm_enable_write_next),
    .start_to_next                     (${\($layers_names[$i])}_start_to_next      ),
    .ifm_sel_next                      (${\($layers_names[$i])}_ifm_sel_next       ),
    .ready                             (ready                     ) 
    );
DONATE




        }
        else{
            $ab_flag = $ab_flag + 1;
            if($ab_flag % 2){
                #########################################################
                ### inistantion for conv AAA mem array                ###
                #########################################################
                $argv0 = 2; #?????????????????
                system("perl mem_array.pl $argv0 $layer_units[$i] $ARGV[7] $ARGV[9] $ifm_height[$i] $ifm_width[$i] $ifm_depth[$i] $ARGV[15]");
				
                if($argv0 == 1){
                    $IFM_number = 2;
                    $units = 1;
                }
                else{
                    $IFM_number = $ifm_depth[$i];
                    $units = $layer_units[$i];
                }
                
                $top_name = "mem_array_U${\($units)}_D${\($IFM_number)}_H$ifm_height[$i]_W$ifm_width[$i]";
                print $fh <<"DONATE";

	/////////////////$i - $top_name////////////////		
    $top_name #(.DATA_WIDTH(DATA_WIDTH),
    .IFM_WIDTH                         (${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT                        (${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .NUMBER_OF_IFM                     (${\(uc $layers_names[$i-1])}_IFM_DEPTH                         ),
    .NUMBER_OF_UNITS                   (${\(uc $layers_names[$i])}_NUMBER_OF_UNITS  )) 
    ${\($top_name)}_inst_$i
    (
	.clk (clk),
	
    .ifm_sel                           (${\($layers_names[$i-1])}_ifm_sel_next|${\($layers_names[$i])}_ifm_sel_previous),
    .ifm_enable_write_previous         (${\($layers_names[$i-1])}_ifm_enable_write_next),
    .ifm_address_write_previous        (${\($layers_names[$i-1])}_ifm_address_write_next),

DONATE
            if($layers_names[$i-1] =~ /conv/){#conva not first
                print $fh <<"DONATE";
    .ifm_enable_read_previous          (${\($layers_names[$i-1])}_ifm_enable_read_next),
    .ifm_address_read_previous         (${\($layers_names[$i-1])}_ifm_address_read_next),
    
DONATE
                for($j = 1;$j <= $units; $j = $j + 1){
                    print $fh <<"DONATE";
	 .data_out_for_previous$j(mem_arr${\($i)}_data_A_out_for_previous$j),
DONATE
                }
            }
            else{#pool or conva first
                print $fh <<"DONATE";
    .ifm_enable_read_previous          (1'b0                      ),
    .ifm_address_read_previous         ({${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM{1'b0}}),
    
DONATE
                for($j = 1;$j <= $units; $j = $j + 1){
                    print $fh <<"DONATE";
	 .data_out_for_previous$j(),
DONATE
                }

            }





            for($j = 1;$j <= $units; $j = $j + 1){
                print $fh <<"DONATE";
	 .data_in_from_previous$j(${\($layers_names[$i-1])}_data_out_for_next$j),
DONATE
            }
		
            
			
            print $fh <<"DONATE";
    .ifm_enable_read_A_next            (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_enable_read_B_next            (1'b0),
    .ifm_address_read_A_next           (${\($layers_names[$i])}_ifm_address_read_A_current),
    .ifm_address_read_B_next           ({${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM{1'b0}}),
DONATE
            for($j = 1;$j < $units; $j = $j + 1){
                print $fh <<"DONATE";
	 .data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j),
DONATE
            }
            print $fh <<"DONATE";
	 .data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j)
     );
DONATE

            #########################################################
            ### inistantion for conv AAA layer                    ###
            #########################################################
            system("perl conva_gen.pl ${\($ab_flag)}  ${\($kernal_size[$i]*$kernal_size[$i])} $ARGV[12] $ARGV[7] $ARGV[9] $ifm_width[$i] $ifm_height[$i] $ifm_depth[$i] $kernal_size[$i] $filter_num[$i] $layer_units[$i] $stride[$i] $padding_state[$i] $ARGV[15]");
            $top_name = "top_conva${\($ab_flag)}";
				
            print $fh <<"DONATE";
				
	/////////////////$i - $top_name////////////////		
    $top_name #(
    .IFM_WIDTH(${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT(${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .ARITH_TYPE(ARITH_TYPE),
    .DATA_WIDTH(DATA_WIDTH),
    .IFM_DEPTH                         (${\(uc $layers_names[$i])}_IFM_DEPTH),
    .KERNAL_SIZE                       (${\(uc $layers_names[$i])}_KERNAL_SIZE),
    .NUMBER_OF_FILTERS                 (${\(uc $layers_names[$i])}_NUMBER_OF_FILTERS)) 
    ${\($top_name)}_inst
    (
    .clk                               (clk                       ),
    .reset                             (reset                     ),
	 
    .riscv_data                        (memControl_riscv_data     ),
    .riscv_address                     (memControl_riscv_address  ),	
    .wm_enable_write                   (memControl_${\($layers_names[$i])}_wm_enable_write),
    .bm_enable_write                   (memControl_${\($layers_names[$i])}_bm_enable_write),
    

    .ifm_sel_previous                  (${\($layers_names[$i])}_ifm_sel_previous),
    .ifm_sel_next                      (${\($layers_names[$i])}_ifm_sel_next),
    .ifm_enable_read_A_current         (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_address_read_A_current        (${\($layers_names[$i])}_ifm_address_read_A_current),
DONATE
                if($stride[$i] == 2){
                    print $fh <<"DONATE";
    .ifm_enable_read_B_current         (${\($layers_names[$i])}_ifm_enable_read_B_current),
    .ifm_address_read_B_current        (${\($layers_names[$i])}_ifm_address_read_B_current),
				
DONATE
                }
                
                for($j = 1; $j <= $layer_units[$i]; $j = $j + 1){
                    print $fh "\t .data_in_A_from_previous$j(mem_arr${\($i)}_data_A_out_for_next$j),\n";
                    if($stride[$i] == 2){
                        print $fh "\t .data_in_B_from_previous$j(mem_arr${\($i)}_data_B_out_for_next$j),\n";
                    }
                }
                print $fh <<"DONATE";
	 
    .start_from_previous               (${\($layers_names[$i-1])}_start_to_next),
    .end_to_previous                   (${\($layers_names[$i])}_end_to_previous),
    .ready                             (${\($layers_names[$i])}_ready),
    .end_from_next                     (${\($layers_names[$i+1])}_end_to_previous),
    .data_in_from_next                 (mem_arr${\($i+1)}_data_A_out_for_previous1),
    .data_out_for_next1                 (${\($layers_names[$i])}_data_out_for_next1),
    
    .ifm_address_read_next              (${\($layers_names[$i])}_ifm_address_read_next),
    .ifm_address_write_next             (${\($layers_names[$i])}_ifm_address_write_next),

    .ifm_enable_read_next              (${\($layers_names[$i])}_ifm_enable_read_next),
    .ifm_enable_write_next             (${\($layers_names[$i])}_ifm_enable_write_next),
    .start_to_next                     (${\($layers_names[$i])}_start_to_next) 
    );
	
DONATE
            }
            else{
				 $argv0 = 1;
			#########################################################
            ### inistantion for conv BBB mem array                ###
            #########################################################
			system("perl mem_array.pl $argv0 $layer_units[$i] $ARGV[7] $ARGV[9] $ifm_height[$i] $ifm_width[$i] $ifm_depth[$i] $ARGV[15]");
			
			if($argv0 == 1){
				$IFM_number = 2;
				$units = 1;
			}
			else{
				$IFM_number = $ifm_depth[$i];
				$units = $layer_units[$i];
			}
			$top_name = "mem_array_U${\($units)}_D${\($IFM_number)}_H$ifm_height[$i]_W$ifm_width[$i]";
			print $fh <<"DONATE";

	/////////////////$i - $top_name////////////////					
    $top_name #(
    .DATA_WIDTH                        (DATA_WIDTH                ),
    .IFM_WIDTH                          (${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT                          (${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .NUMBER_OF_IFM                     (2                         ),
    .NUMBER_OF_UNITS                   (${\(uc $layers_names[$i])}_NUMBER_OF_UNITS)          ) 
    ${\($top_name)}_inst_$i
    (
	.clk (clk),
	
    .ifm_sel                           (${\($layers_names[$i-1])}_ifm_sel_next),
    .ifm_enable_write_previous         (${\($layers_names[$i-1])}_ifm_enable_write_next),
    
    .ifm_address_write_previous        (${\($layers_names[$i-1])}_ifm_address_write_next),

DONATE
            if($layers_names[$i-1] =~ /conv/ && ($i-1) != 0){#conva not first
                print $fh <<"DONATE";
    .ifm_enable_read_previous          (${\($layers_names[$i-1])}_ifm_enable_read_next),
    .ifm_address_read_previous         (${\($layers_names[$i-1])}_ifm_address_read_next),
    .data_out_for_previous1		       (mem_arr${\($i)}_data_A_out_for_previous1),
DONATE
            }
            else{#pool or conva first
                print $fh <<"DONATE";
    .ifm_enable_read_previous          (1'b0                      ),
    .ifm_address_read_previous         ({${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM{1'b0}}),
    .data_out_for_previous1		       (),
DONATE


            }
            for($j = 1;$j <= $units; $j = $j + 1){
                    print $fh <<"DONATE";
	 .data_in_from_previous$j 		   (${\($layers_names[$i-1])}_data_out_for_next$j),
DONATE
            }

           
			
            print $fh <<"DONATE";
    .ifm_enable_read_A_next            (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_enable_read_B_next            (1'b0),
    .ifm_address_read_A_next           (${\($layers_names[$i])}_ifm_address_read_A_current),
    .ifm_address_read_B_next           ({${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM{1'b0}}),
DONATE
            for($j = 1;$j < $units; $j = $j + 1){
                print $fh <<"DONATE";
                //upd
	 .data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j),
DONATE
            }
            print $fh <<"DONATE";
	 .data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j)
     );
DONATE
			#########################################################
            ### inistantion for conv BBB layer                    ###
            #########################################################
            
            
            system("perl convb_gen.pl ${\($ab_flag)}  ${\($kernal_size[$i]*$kernal_size[$i])} $ARGV[12] $ARGV[7] $ARGV[9] $ifm_width[$i] $ifm_height[$i] $ifm_depth[$i] $kernal_size[$i] $filter_num[$i] $layer_units[$i] $stride[$i] $padding_state[$i] $ARGV[15]");
            $top_name = "top_convb${\($ab_flag)}";
            print $fh <<"DONATE";
    /////////////////$i - $top_name////////////////		
    $top_name #(
    .IFM_WIDTH(${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT(${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .IFM_DEPTH                         (${\(uc $layers_names[$i])}_IFM_DEPTH),
    .KERNAL_SIZE                       (${\(uc $layers_names[$i])}_KERNAL_SIZE),
    .DATA_WIDTH                        (DATA_WIDTH),
    .ARITH_TYPE                        (ARITH_TYPE),
    .NUMBER_OF_FILTERS                 (${\(uc $layers_names[$i])}_NUMBER_OF_FILTERS)) 
    ${\($top_name)}_inst
    (
    .clk                               (clk                       ),
    .reset                             (reset                     ),
	 ///////////////////////////////////////////////////////////////
	.riscv_data                        (memControl_riscv_data     ),
    .riscv_address                     (memControl_riscv_address  ),	
    .wm_enable_write                   (memControl_${\($layers_names[$i])}_wm_enable_write),
    .bm_enable_write                   (memControl_${\($layers_names[$i])}_bm_enable_write),
    ///////////////////////////////////////////////////
    .start_from_previous (${\($layers_names[$i-1])}_start_to_next), 
	.data_in_A_from_previous1 (mem_arr${\($i)}_data_A_out_for_next1),
    .end_to_previous (${\($layers_names[$i])}_end_to_previous),  
	.end_from_next (${\($layers_names[$i+1])}_end_to_previous),
     
DONATE
            if($layers_names[$i+1] =~ /conv/ ){#conva 
                print $fh <<"DONATE";
    .conv_ready(${\($layers_names[$i+1])}_ready ),
DONATE
            }
            else{#pool
                print $fh <<"DONATE";
    .conv_ready(1'b1),
DONATE
            }
            


            if($stride[$i] == 1){
                print $fh <<"DONATE";
    .ifm_enable_read_A_current(${\($layers_names[$i])}_ifm_enable_read_A_current),
	.ifm_address_read_A_current(${\($layers_names[$i])}_ifm_address_read_A_current),

DONATE
            }
            else
            {
                print $fh <<"DONATE";
    .ifm_enable_read_A_current(${\($layers_names[$i])}_ifm_enable_read_A_current),
	.ifm_address_read_A_current(${\($layers_names[$i])}_ifm_address_read_A_current),
    .ifm_enable_read_B_current(${\($layers_names[$i])}_ifm_enable_read_B_current),
	.ifm_address_read_B_current(${\($layers_names[$i])}_ifm_address_read_B_current),

DONATE

            }
                for($j = 1; $j <= $layer_units[$i]; $j = $j + 1){
                    print $fh <<"DONATE";
    .data_in_from_next$j                 (mem_arr${\($i+1)}_data_A_out_for_previous$j),
    .data_out_for_next$j                 (${\($layers_names[$i])}_data_out_for_next$j),

DONATE

                }
                print $fh <<"DONATE";
	.ifm_enable_read_next (${\($layers_names[$i])}_ifm_enable_read_next),
	.ifm_enable_write_next (${\($layers_names[$i])}_ifm_enable_write_next),
    .ifm_address_read_next (${\($layers_names[$i])}_ifm_address_read_next),
	.ifm_address_write_next (${\($layers_names[$i])}_ifm_address_write_next),
	 
    .start_to_next (${\($layers_names[$i])}_start_to_next),
	.ifm_sel_next  (${\($layers_names[$i])}_ifm_sel_next)
    );
	
DONATE

            }
        }
    }
    if($layers_names[$i] =~ /pool/){

        $pool_num = $pool_num + 1;

        if($ab_flag % 2){
				
                $argv0 = 1;
				#########################################################
                ### inistantion for Pool 111 AAA mem array            ###
                #########################################################
                system("perl mem_array.pl $argv0 $layer_units[$i] $ARGV[7] $ARGV[9] $ifm_height[$i] $ifm_width[$i] $ifm_depth[$i] $ARGV[15]");
				
                if($argv0 == 1){
                    $IFM_number = 2;
                    $units = 1;
                }
                else{
                    $IFM_number = $ifm_depth[$i];
                    $units = $layer_units[$i];
                }
                $top_name = "mem_array_U${\($units)}_D${\($IFM_number)}_H$ifm_height[$i]_W$ifm_width[$i]";
                print $fh <<"DONATE";

	/////////////////$i - $top_name////////////////					
    $top_name #(
    .DATA_WIDTH                        (DATA_WIDTH                ),
    .IFM_WIDTH                         (${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT                        (${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .NUMBER_OF_IFM                     (2                         ),
    .NUMBER_OF_UNITS                   (${\(uc $layers_names[$i])}_NUMBER_OF_UNITS)          ) 
    ${\($top_name)}_inst_$i
    (
	.clk (clk),
    
    .ifm_sel                           (${\($layers_names[$i-1])}_ifm_sel_next),
    .ifm_enable_write_previous         (${\($layers_names[$i-1])}_ifm_enable_write_next),
    .ifm_address_write_previous        (${\($layers_names[$i-1])}_ifm_address_write_next),

DONATE

            if($layers_names[$i-1] =~ /conv/ && ($i-1) != 0){#conva not first
                print $fh <<"DONATE";
    .ifm_enable_read_previous          (${\($layers_names[$i-1])}_ifm_enable_read_next),
    .ifm_address_read_previous         (${\($layers_names[$i-1])}_ifm_address_read_next),
    .data_out_for_previous1		       (mem_arr${\($i)}_data_A_out_for_previous1),
DONATE
            }
            else{#conva first
                print $fh <<"DONATE";
    .ifm_enable_read_previous          (1'b0                      ),
    .ifm_address_read_previous         ({${\(uc $layers_names[$i])}_ADDRESS_SIZE_IFM{1'b0}}),
    .data_out_for_previous1		       (),
DONATE


            }
						
                for($j = 1;$j <= $units; $j = $j + 1){
                print $fh <<"DONATE";
	.data_in_from_previous$j 		   (${\($layers_names[$i-1])}_data_out_for_next$j),
DONATE
            }

            print $fh <<"DONATE";
    .ifm_enable_read_A_next            (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_enable_read_B_next            (${\($layers_names[$i])}_ifm_enable_read_B_current),
    .ifm_address_read_A_next           (${\($layers_names[$i])}_ifm_address_read_A_current),
    .ifm_address_read_B_next           (${\($layers_names[$i])}_ifm_address_read_B_current),
DONATE
            for($j = 1;$j < $units; $j = $j + 1){
                print $fh <<"DONATE";
                //updated
	.data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j),
	.data_out_B_for_next$j(mem_arr${\($i)}_data_B_out_for_next$j),
DONATE
            }
            print $fh <<"DONATE";
	.data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j),
	.data_out_B_for_next$j(mem_arr${\($i)}_data_B_out_for_next$j)
     );
DONATE
			#########################################################
            ### inistantion for Pool 111 AAA layer                ###
            #########################################################

            if($layers_names[$i] =~ /avg/){
                $pool_type = 1;
            }
            else{
                $pool_type = 0;
            }

            system("perl top_poola.pl $ARGV[7]  $ifm_height[$i] $ifm_width[$i] $ifm_depth[$i] $kernal_size[$i] $layer_units[$i]  $stride[$i] $ARGV[12] $pool_type $pool_num $ARGV[15]");
            $top_name = "top_poola$pool_num"."_S$stride[$i]_K$kernal_size[$i]"; #S for stride
			
            print $fh <<"DONATE";

	/////////////////$i - $top_name////////////////					
    $top_name #(
    .DATA_WIDTH(DATA_WIDTH),
    .ARITH_TYPE(ARITH_TYPE),
    .IFM_WIDTH                         (${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT                        (${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .IFM_DEPTH                         (${\(uc $layers_names[$i])}_IFM_DEPTH),
    .KERNAL_SIZE                       (${\(uc $layers_names[$i])}_KERNAL_SIZE),
    .POOL_TYPE                         ()
    ) 
    ${\($top_name)}_inst
    (
    .clk                               (clk                       ),
    .reset                             (reset                     ),
	 
    .start_from_previous               (${\($layers_names[$i-1])}_start_to_next),
DONATE
            for($j = 1;$j <= $units; $j = $j + 1){
                if($stride[$i] == 2){
                    print $fh <<"DONATE";
    .data_in_A_from_previous1                         (mem_arr${\($i)}_data_A_out_for_next$j),
    .data_in_B_from_previous1                         (mem_arr${\($i)}_data_B_out_for_next$j),
DONATE



                }
                else{
                    print $fh <<"DONATE";
    .data_in_A_from_previous1                         (mem_arr${\($i)}_data_A_out_for_next$j),
DONATE

                }
            }
            if($stride[$i] == 2){
                print $fh <<"DONATE";
    .ifm_enable_read_A_current         (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_enable_read_B_current         (${\($layers_names[$i])}_ifm_enable_read_B_current),
    .ifm_address_read_A_current        (${\($layers_names[$i])}_ifm_address_read_A_current),
    .ifm_address_read_B_current        (${\($layers_names[$i])}_ifm_address_read_B_current),
DONATE

            }
            else{
                print $fh <<"DONATE";
    .ifm_enable_read_A_current         (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_address_read_A_current        (${\($layers_names[$i])}_ifm_address_read_A_current),
DONATE
            }
            print $fh <<"DONATE";
    .end_to_previous                   (${\($layers_names[$i])}_end_to_previous),

    .end_from_next                     (${\($layers_names[$i+1])}_end_to_previous),
    .data_out_for_next1                (${\($layers_names[$i])}_data_out_for_next1),
    .ifm_address_write_next            (${\($layers_names[$i])}_ifm_address_write_next),
    .ifm_enable_write_next             (${\($layers_names[$i])}_ifm_enable_write_next),
    .start_to_next                     (${\($layers_names[$i])}_start_to_next),
    .ifm_sel_next                      (${\($layers_names[$i])}_ifm_sel_next) 
    );

DONATE
		
        }
        else{

			 $argv0 = 2;
			#########################################################
            ### inistantion for Pool 222 BBB mem array            ###
            #########################################################
			system("perl mem_array.pl $argv0 $layer_units[$i] $ARGV[7] $ARGV[9] $ifm_height[$i] $ifm_width[$i] $ifm_depth[$i] $ARGV[15]");
			
			if($argv0 == 1){
				$IFM_number = 2;
				$units = 1;
			}
			else{
				$IFM_number = $ifm_depth[$i];
				$units = $layer_units[$i];
			}
			$top_name = "mem_array_U${\($units)}_D${\($IFM_number)}_H$ifm_height[$i]_W$ifm_width[$i]";
			print $fh <<"DONATE";

	/////////////////$i - $top_name////////////////					
    $top_name #(
    .DATA_WIDTH                        (DATA_WIDTH                ),
    .IFM_WIDTH                         (${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT                        (${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .NUMBER_OF_IFM                     (2                         ),
    .NUMBER_OF_UNITS                   (${\(uc $layers_names[$i])}_NUMBER_OF_UNITS)          ) 
    ${\($top_name)}_inst_$i
    (
	.clk (clk),
	
    .ifm_sel                           (${\($layers_names[$i-1])}_ifm_sel_next),
    .ifm_enable_write_previous         (${\($layers_names[$i-1])}_ifm_enable_write_next),
    .ifm_enable_read_previous          (${\($layers_names[$i-1])}_ifm_enable_read_next),
    .ifm_address_write_previous        (${\($layers_names[$i-1])}_ifm_address_write_next),
    .ifm_address_read_previous         (${\($layers_names[$i-1])}_ifm_address_read_next),

DONATE
						
                for($j = 1;$j <= $units; $j = $j + 1){
                print $fh <<"DONATE";
	 .data_in_from_previous$j 		   (${\($layers_names[$i-1])}_data_out_for_next$j),
DONATE
            }

            for($j = 1;$j <= $units; $j = $j + 1){
                print $fh <<"DONATE";
	 .data_out_for_previous$j		   (mem_arr${\($i)}_data_A_out_for_previous$j),
DONATE
            }
			
            print $fh <<"DONATE";
    .ifm_enable_read_A_next            (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_enable_read_B_next            (${\($layers_names[$i])}_ifm_enable_read_B_current),
    .ifm_address_read_A_next           (${\($layers_names[$i])}_ifm_address_read_A_current),
    .ifm_address_read_B_next           (${\($layers_names[$i])}_ifm_address_read_B_current),
DONATE
            for($j = 1;$j < $units; $j = $j + 1){
                print $fh <<"DONATE";
	 .data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j),
	 .data_out_B_for_next$j(mem_arr${\($i)}_data_B_out_for_next$j),
DONATE
            }
            print $fh <<"DONATE";
	 .data_out_A_for_next$j(mem_arr${\($i)}_data_A_out_for_next$j),
	 .data_out_B_for_next$j(mem_arr${\($i)}_data_B_out_for_next$j)
     );
DONATE
			#########################################################
            ### inistantion for Pool 222 BBB layer                ###
            #########################################################
            if($layers_names[$i] =~ /avg/){
                $pool_type = 1;
            }
            else{
                $pool_type = 0;
            }

            system("perl top_poolb.pl $ARGV[7]  $ifm_height[$i] $ifm_width[$i] $ifm_depth[$i] $kernal_size[$i] $layer_units[$i]  $stride[$i] $ARGV[12] $pool_type $pool_num $ARGV[15]");
            $top_name = "top_poolb$pool_num"."_U$layer_units[$i]_S$stride[$i]_K$kernal_size[$i]"; #U for units
			print $fh <<"DONATE";

				
	/////////////////$i - $top_name////////////////					
    $top_name #(
	.DATA_WIDTH						   (DATA_WIDTH),
    .ARITH_TYPE(ARITH_TYPE),
	.IFM_WIDTH    					   (${\(uc $layers_names[$i])}_IFM_WIDTH),
    .IFM_HEIGHT    					   (${\(uc $layers_names[$i])}_IFM_HEIGHT),
    .IFM_DEPTH                         (${\(uc $layers_names[$i])}_IFM_DEPTH           ),
    .KERNAL_SIZE                       (${\(uc $layers_names[$i])}_KERNAL_SIZE)        ) 
	${\($top_name)}_inst
	(
	.clk                               (clk                       ),
    .reset                             (reset                     ),
	 
    .start_from_previous               (${\($layers_names[$i-1])}_start_to_next       ),
DONATE
		
            if($stride[$i] == 2){
				print $fh <<"DONATE";
	.ifm_enable_read_A_current         (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_enable_read_B_current         (${\($layers_names[$i])}_ifm_enable_read_B_current),
    .ifm_address_read_A_current        (${\($layers_names[$i])}_ifm_address_read_A_current),
    .ifm_address_read_B_current        (${\($layers_names[$i])}_ifm_address_read_B_current),
DONATE

			}
			else{
				print $fh <<"DONATE";
	.ifm_enable_read_A_current         (${\($layers_names[$i])}_ifm_enable_read_A_current),
    .ifm_address_read_A_current        (${\($layers_names[$i])}_ifm_address_read_A_current),
DONATE
			}
			if($stride[$i] == 2){
    			for($j = 1;$j <= $layer_units[$i]; $j = $j + 1){
					print $fh <<"DONATE";
	.data_in_A_from_previous$j                    (mem_arr${\($i)}_data_A_out_for_next$j),
    .data_in_B_from_previous$j                    (mem_arr${\($i)}_data_B_out_for_next$j),
DONATE
				}
			}
			else{
    			for($j = 1;$j <= $layer_units[$i]; $j = $j + 1){
					print $fh <<"DONATE";
	.data_in_A_from_previous$j                    (mem_arr${\($i)}_data_A_out_for_next$j),
DONATE

				}
			}
			print $fh <<"DONATE";
    .end_to_previous                   (${\($layers_names[$i])}_end_to_previous     ),
     
    .end_from_next                     (${\($layers_names[$i+1])}_end_to_previous    ),
DONATE

			for($j = 1;$j <= $layer_units[$i]; $j = $j + 1){
				print $fh <<"DONATE";
	.data_out_for_next$j                        (${\($layers_names[$i])}_data_out_for_next$j          ),
DONATE

			}

            if($layers_names[$i+1] =~ /conv/ ){#conva 
                print $fh <<"DONATE";
    .conv_ready(${\($layers_names[$i+1])}_ready ), 
DONATE
            }
            else{#pool
                print $fh <<"DONATE";
    .conv_ready(1'b1),
DONATE


            }
            
			print $fh <<"DONATE";
	.ifm_address_write_next            (${\($layers_names[$i])}_ifm_address_write_next),
    .ifm_enable_write_next             (${\($layers_names[$i])}_ifm_enable_write_next),
    .start_to_next                     (${\($layers_names[$i])}_start_to_next       ),
    .ifm_sel_next                      (${\($layers_names[$i])}_ifm_sel_next        ) 
	);

DONATE
			            
		}
				
        
    }
	
    if($layers_names[$i] =~ /fc/){
        $ab_flag = $ab_flag + 1;
        $is_itFCfirst = $is_itFCfirst + 1;
        if($is_itFCfirst == 1){
            #########################################################
            ### inistantion for fc 111 lsa msh faker layer        ###
            #########################################################


            system("perl reg_array.pl $ARGV[7] $ARGV[15]");

            print $fh <<"DONATE";
    reg_array  #(.DATA_WIDTH(DATA_WIDTH)) reg_array_1
    (
    .clk(clk),
	.reset(reset),
    .data_in_from_previous(${\($layers_names[$i-1])}_data_out_for_next1),
    .data_out_for_previous(mem_arr${\($i)}_data_A_out_for_previous1),
    .enable_write_previous(${\($layers_names[$i-1])}_ifm_enable_write_next),
    .enable_read_previous(${\($layers_names[$i-1])}_ifm_enable_read_next),
    .ifm_sel(${\($layers_names[$i-1])}_ifm_sel_next),
    .enable_read_next(${\($layers_names[$i])}_enable_read_current),
    .data_out_for_next(reg_arr${\($is_itFCfirst)}_data_out_for_next)
    );


DONATE
#_NUMBER_OF_FILTERS
            system("perl top_fc1.pl $ARGV[7]  $ifm_width[$i] $ifm_height[$i] $ifm_depth[$i] $filter_num[$i] $ARGV[9] $ARGV[12] $is_itFCfirst 0 $ARGV[15]");
            $top_name = "top_fcA_$is_itFCfirst";
            print $fh <<"DONATE";

				
	/////////////////$i - $top_name////////////////					
    $top_name #(.DATA_WIDTH(DATA_WIDTH),
    .ARITH_TYPE(ARITH_TYPE),
    .IFM_DEPTH(${\(uc $layers_names[$i])}_IFM_DEPTH))
    ${\($top_name)}_inst
    (
        .clk(clk),
        .reset(reset),
        .riscv_data (memControl_riscv_data),
        .riscv_address (memControl_riscv_address),
        .wm_enable_write (memControl_${\($layers_names[$i])}_wm_enable_write),
        .bm_enable_write(memControl_${\($layers_names[$i])}_bm_enable_write), 
        // //////////////////////////////////////previous
        .data_in_from_previous(reg_arr${\($is_itFCfirst)}_data_out_for_next),
        .start_from_previous(${\($layers_names[$i-1])}_start_to_next),
        .end_to_previous(${\($layers_names[$i])}_end_to_previous),   
        .bias_sel(${\($layers_names[$i])}_bias_sel),
        .enable_write_next (${\($layers_names[$i])}_enable_write_next),
        .start_to_next (${\($layers_names[$i])}_start_to_next ),
        
        .enable_read_current (${\($layers_names[$i])}_enable_read_current),

DONATE
            if($i == ($layers_count - 1)){
                print $fh "        .end_from_next (1'b1),\n";

            }
            else{
                print $fh "        .end_from_next (${\($layers_names[$i+1])}_end_to_previous),\n";

            }

            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\t.reg_out_FC_$j ( Data_out_FC_${\($is_itFCfirst)}_$j),\n";
            }
            for($j = 1; $j < $filter_num[$i]; $j = $j + 1){
                print $fh "\t.data_bias_$j (data_bias_FC_${\($is_itFCfirst)}_$j),\n";
            }
            print $fh "\t.data_bias_$j (data_bias_FC_${\($is_itFCfirst)}_$j)\n);\n";

            system("perl reg_acc_array.pl $ARGV[7] $ARGV[12] $filter_num[$i] $ARGV[15]");

            $top_name = "reg_acc_$filter_num[$i]";

            print $fh <<"DONATE";

    $top_name #(
        . DATA_WIDTH (DATA_WIDTH), 
        .ARITH_TYPE(ARITH_TYPE) ) 
        ${\($top_name)}_inst_$is_itFCfirst
    (   
        .clk (clk),                                                     
        .reset (reset),                                                
        .bias_sel (${\($layers_names[$i])}_bias_sel),                                                   
        .enable_write (${\($layers_names[$i])}_enable_write_next),      
DONATE
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\t.Data_in_$j ( Data_out_FC_${\($is_itFCfirst)}_$j),\n";
            }
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\t.data_bias_$j (data_bias_FC_${\($is_itFCfirst)}_$j),\n";
            }
            for($j = 1; $j < $filter_num[$i]; $j = $j + 1){
                print $fh "\t.Data_out_FC_$j ( out_reg_acc${\($is_itFCfirst)}_$j),\n";
            }
            print $fh "\t.Data_out_FC_$j ( out_reg_acc${\($is_itFCfirst)}_$j)\n);\n";

        }
        else{
            
            #########################################################
            ### inistantion for fc 222 lsa msh faker layer        ###
            #########################################################
                #_NUMBER_OF_FILTERS
            system("perl top_fc2.pl $ARGV[7]  $ifm_width[$i] $ifm_height[$i] $ifm_depth[$i] $filter_num[$i] $ARGV[9] $ARGV[12] $is_itFCfirst  1 $ARGV[15]");
            $top_name = "top_fcB_$is_itFCfirst";
            print $fh <<"DONATE";

				
	/////////////////$i - $top_name////////////////					
    $top_name #(.DATA_WIDTH(DATA_WIDTH),
    .ARITH_TYPE(ARITH_TYPE),
    .IFM_DEPTH(${\(uc $layers_names[$i])}_IFM_DEPTH))
    ${\($top_name)}_inst
    (
        .clk(clk),
        .reset(reset),
        .riscv_data (memControl_riscv_data),
        .riscv_address (memControl_riscv_address),
        .wm_enable_write (memControl_${\($layers_names[$i])}_wm_enable_write),
        .bm_enable_write(memControl_${\($layers_names[$i])}_bm_enable_write), 
        // //////////////////////////////////////previous
        
        .start_from_previous (${\($layers_names[$i-1])}_start_to_next),
        .end_to_previous     (${\($layers_names[$i])}_end_to_previous),
        .bias_sel (${\($layers_names[$i])}_bias_sel),
        .enable_write_next (${\($layers_names[$i])}_enable_write_next),
        .output_ready (output_ready),
DONATE
            if($i == ($layers_count - 1)){
                print $fh "        .end_from_next (1'b1),\n";

            }
            else{
                print $fh "        .end_from_next (${\($layers_names[$i+1])}_end_to_previous),\n";

            }

            for($j = 1; $j <= $filter_num[$i-1]; $j = $j + 1){
                print $fh "\t.Data_in_$j ( out_reg_acc${\($is_itFCfirst - 1)}_$j),\n";
            }
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\t.data_bias_$j (data_bias_FC_${\($is_itFCfirst)}_$j),\n";
            }
            for($j = 1; $j < $filter_num[$i]; $j = $j + 1){
                print $fh "\t.reg_out_FC_$j (Data_out_FC_${\($is_itFCfirst)}_$j),\n";
            }
            print $fh "\t.reg_out_FC_$j (Data_out_FC_${\($is_itFCfirst)}_$j)\n);";

            system("perl reg_acc_array.pl $ARGV[7] $ARGV[12] $filter_num[$i] $ARGV[15]");

            $top_name = "reg_acc_$filter_num[$i]";

            print $fh <<"DONATE";

    $top_name #(
        . DATA_WIDTH (DATA_WIDTH), 
        .ARITH_TYPE(ARITH_TYPE) ) 
        ${\($top_name)}_inst_$is_itFCfirst
    (   
        .clk (clk),                                                     
        .reset (reset),                                                
        .bias_sel (${\($layers_names[$i])}_bias_sel),                                                   
        .enable_write (${\($layers_names[$i])}_enable_write_next),      
DONATE
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\t.Data_in_$j ( Data_out_FC_${\($is_itFCfirst)}_$j),\n";
            }
            for($j = 1; $j <= $filter_num[$i]; $j = $j + 1){
                print $fh "\t.data_bias_$j (data_bias_FC_${\($is_itFCfirst)}_$j),\n";
            }
            for($j = 1; $j < $filter_num[$i]; $j = $j + 1){
                print $fh "\t.Data_out_FC_$j ( out_reg_acc${\($is_itFCfirst)}_$j),\n";
            }
            print $fh "\t.Data_out_FC_$j ( out_reg_acc${\($is_itFCfirst)}_$j)\n);\n";

        }
    }

}

for($j = 1; $j <= $filter_num[$i-1]; $j = $j + 1){

    print $fh "\tassign Data_out_${\($j)}_final = out_reg_acc${\($is_itFCfirst)}_$j;\n";
}

print $fh "$end_module";

close $fh or die "Couldn't Close File : $!";
