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
#ARGV[1] Mul number
#ARGV[2] DATA_WIDTH
#ARGV[3] IFM_WIDTH
#ARGV[4] IFM_HEIGHT 
#ARGV[5] IFM_DEPTH 
#ARGV[6] KERNAL_SIZE  
#ARGV[7] NUMBER_OF_FILTERS
#ARGV[8] NUMBER_OF_UNITS
#ARGV[9]
#ARGV[10] stride
#ARGV[11] PADDING_EXIST


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
my $full_path = "../../../$ARGV[9]/";
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
$module_name = "conva$ARGV[0]_CU";

my $psums_enable ;
my $actual_ifm_width ;
my $actual_ifm_height;

# Variable to hold padding state #
my $padding_exist = $ARGV[11];
my $stride = $ARGV[10];

# input Width and height with padding value added #
my $pad_value  = ($ARGV[6] - 1) ;

if($padding_exist == 1 && ($stride == 2)){
    $actual_ifm_width = $ARGV[3] + $pad_value -1;
    $actual_ifm_height = $ARGV[4] + $pad_value -1;
}
elsif($padding_exist == 1 && ($stride == 1)){
    $actual_ifm_width = $ARGV[3] + $pad_value ;
    $actual_ifm_height = $ARGV[4] + $pad_value ;
}
else{
    $actual_ifm_width = $ARGV[3];
    $actual_ifm_height = $ARGV[4];
}


if($padding_exist == 1){
    if($actual_ifm_width == $ARGV[6]){
     $psums_enable = "ifm_enable_write_next";
    }
    else{
     $psums_enable = "ifm_address_write_next_tick";
    } 
}
else{
    if($ARGV[3] == $ARGV[6]){
     $psums_enable = "ifm_enable_write_next";
    }
    else{
     $psums_enable = "ifm_address_write_next_tick";
    }     
}



my $added_value ;

if($stride == 1){
     $added_value = "1'b1";
}else{
     $added_value = "2'b10";

}

####################################################
#############     GENERATING FILE    ###############
####################################################

$file_name = $full_path . $module_name . ".v";
open my $fh, '>', $file_name
  or die "Can't open file : $!";
  
print $fh <<"DONATE";
$module $module_name $parameter
    ///////////advanced parameters///////
	DATA_WIDTH 	   		    = $ARGV[2],
	/////////////////////////////////////
	IFM_WIDTH               = $ARGV[3],
    IFM_HEIGHT              = $ARGV[4],                                                
	IFM_DEPTH               = $ARGV[5],
	KERNAL_SIZE             = $ARGV[6],
	NUMBER_OF_FILTERS       = $ARGV[7],
	NUMBER_OF_UNITS         = $ARGV[8],
    STRIDE                  = $stride,
	//////////////////////////////////////
DONATE

if($padding_exist == 1){

    if($stride == 2){
        print $fh "    PADDING_VALUE           = ${\($pad_value-1)}\n,"
    }
    else{
        print $fh "    PADDING_VALUE           = ${\($pad_value)},\n"
    }
    
    print $fh <<"DONATE";
	IFM_WIDTH_PAD           = IFM_WIDTH + PADDING_VALUE ,
	IFM_HEIGHT_PAD          = IFM_HEIGHT + PADDING_VALUE ,
	ADDRESS_SIZE_IFM_PAD    = $clog2(IFM_WIDTH_PAD*IFM_HEIGHT_PAD),
	ADDRESS_SIZE_KERNAL     = $clog2( KERNAL_SIZE*KERNAL_SIZE ),
DONATE
}
if ($padding_exist == 1 && $stride == 2){
    print $fh <<"DONATE";
	IFM_WIDTH_NEXT          = IFM_WIDTH / 2 ,
    IFM_HEIGHT_NEXT         = IFM_HEIGHT / 2,   
DONATE
}
elsif ($padding_exist == 1 && $stride == 1){
    print $fh <<"DONATE";
	IFM_WIDTH_NEXT          = IFM_WIDTH ,
    IFM_HEIGHT_NEXT         = IFM_HEIGHT,   
DONATE
}
else{
    print $fh <<"DONATE";
	IFM_WIDTH_NEXT          = (IFM_WIDTH - KERNAL_SIZE) / STRIDE + 1,
    IFM_HEIGHT_NEXT         = (IFM_HEIGHT - KERNAL_SIZE) / STRIDE + 1,
DONATE
}


if ($padding_exist == 1 && $stride == 1){
    print $fh "    FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH_PAD + KERNAL_SIZE,\n";
}

elsif ($padding_exist == 1 && $stride == 2){
    print $fh "    FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH_PAD + KERNAL_SIZE +1,\n";
}

elsif ($padding_exist == 0 && $stride == 1){
    print $fh "    FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH + KERNAL_SIZE,\n";
}

elsif ($padding_exist == 0 && $stride == 2){
    print $fh "    FIFO_SIZE               = (KERNAL_SIZE-1)*IFM_WIDTH + KERNAL_SIZE +1,\n";
}

print $fh <<"DONATE";
    ADDRESS_SIZE_IFM        = $clog2(IFM_WIDTH*IFM_HEIGHT),
    ADDRESS_SIZE_NEXT_IFM   = $clog2(IFM_WIDTH_NEXT*IFM_HEIGHT_NEXT),
	ADDRESS_SIZE_WM         = $clog2( KERNAL_SIZE*KERNAL_SIZE*NUMBER_OF_FILTERS*(${\(ceil($ARGV[5]/$ARGV[8]))}) ),
	ADDRESS_SIZE_BM         = $clog2(NUMBER_OF_FILTERS),
	NUMBER_OF_IFM           = IFM_DEPTH
)(
    // General Signals
	input  clk,
	input  reset,
	
    // Signals from next layer
	input  end_from_next,
    
    // Signals to next layer
    output reg  start_to_next,
    
    // Signals from previous layer
    input  start_from_previous,

    // Signals to previous layer
    output reg end_to_previous,
    output ready,

    // Signals to IFM memory
	output reg [$clog2(${\(ceil($ARGV[5]/$ARGV[8]))} )-1 : 0] ifm_sel_previous,
    output reg ifm_enable_read_A_current,
    output reg [ADDRESS_SIZE_IFM-1:0] ifm_address_read_A_current,
DONATE

if($stride == 2){
	print $fh <<"DONATE";
    output     ifm_enable_read_B_current,
    output     [ADDRESS_SIZE_IFM-1:0] ifm_address_read_B_current,
DONATE
}
print $fh <<"DONATE";

    // Signals to Weight memory
    output reg wm_addr_sel,
    output reg wm_enable_read,
    output reg [ADDRESS_SIZE_WM-1:0] wm_address_read_current,
    output reg wm_fifo_enable,

    // Signals to Bias memory
    output reg bm_addr_sel,
    output reg bm_enable_read,
    output reg [ADDRESS_SIZE_BM-1:0] bm_address_read_current,
DONATE

if($padding_exist == 1){
    if($stride == 2){
        print $fh <<"DONATE";
	output reg zeros_sel_A,
    output reg zeros_sel_B,
DONATE
    }
    else{
        print $fh <<"DONATE";
	output reg zeros_sel,
DONATE
    }
}

print $fh <<"DONATE";    

    // Internal Control Signals
    output reg fifo_enable,
    output conv_enable,
    output accu_enable,
    output relu_enable,
    
    // Signals to OFM memory
    output ifm_enable_read_next,
    output ifm_enable_write_next,
    output reg  [ADDRESS_SIZE_NEXT_IFM-1:0] ifm_address_read_next,
    output wire [ADDRESS_SIZE_NEXT_IFM-1:0] ifm_address_write_next,
    output reg  ifm_sel_next
    
);
	
/////////////////////////////////////////////////////
/////////////////// Signal declaration //////////////
/////////////////////////////////////////////////////

    reg  ifm_start_counter_read_address;
    wire ifm_address_read_current_tick;
    reg  ifm_address_read_current_tick_delayed;
    wire no_more_start_flag;
    
    reg  fifo_enable_sig1;
    
    reg  [$clog2(NUMBER_OF_FILTERS)-1 : 0] filters_counter;
    wire filters_counter_tick;

    reg  [$clog2( ${\(ceil($ARGV[5]/$ARGV[8]))} )-1 : 0] depth_counter;  // ceil IFM_DEPTH/ NUMBER_OF_UNITS
    wire depth_counter_tick;
    
    // Partial sums Counter 
    reg  [$clog2( ${\(ceil($ARGV[5]/$ARGV[8]))} )-1 : 0] psums_counter_next;
    wire psums_counter_next_tick;

    wire ifm_address_write_next_tick;
    
    // Start new reading cycle
    wire start_internal;
    wire start;

    // Flag indicates the availability of OFM memory 
    reg mem_empty;

    // Signal to hold the reading proccess in case of the OFM is not available
    wire signal_hold;
DONATE


if($padding_exist == 1 || $stride == 2){
    print $fh <<"DONATE";
	
    //Counter to input weights correctly in WM FIFO
    reg [ADDRESS_SIZE_KERNAL-1 : 0] wm_counter;

    //Flag indicates that full kernal channel is ready to use 
    wire wm_counter_tick;
DONATE
}

if($padding_exist == 1){
print $fh <<"DONATE";
	// Reading address of input memory with added pixels
    reg [ADDRESS_SIZE_IFM_PAD-1:0] ifm_address_with_padding;
    
    // Flag to indicate that memory has been fully read (Reading channel is finished)
    wire ifm_address_with_padding_tick;
    reg  ifm_address_with_padding_tick_delayed;

    // Counter to count the width of actual data in rows in each channel
    reg [$clog2(IFM_WIDTH)-1:0] width_counter;
    wire width_counter_tick;
    reg  width_counter_enable;

    // Counter to count the number of needed zeros to pad correctly
	reg [$clog2(PADDING_VALUE)-1:0] zero_counter;
	wire zero_counter_tick;
	reg  zero_counter_enable;

    // Flag to indicate that first row(s) of padding zeros has read correctly
    wire input_data_start;

    // Flag to indicate that last row(s) of padding zeros is in process
    wire input_data_end;
      
DONATE
}

print $fh <<"DONATE"; 
    assign start = start_from_previous | start_internal;


///////////////////////////////////////////////////////
///////////////////    READ FSM    ////////////////////
/////////////////////////////////////////////////////// 

    localparam [1:0]   IDLE   = 2'b00,
                       READ   = 2'b01,
                       FINISH = 2'b10,
					   HOLD   = 2'b11;
                      
    reg [1:0] state_reg, state_next;  
              
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            state_reg <= IDLE;       
        else
            state_reg <= state_next;
    end

    always @*
    begin 
        state_next                     = state_reg;
        
        case(state_reg)
         
        IDLE : 
        begin
        
        ifm_enable_read_A_current        = 1'b0;
        ifm_start_counter_read_address = 1'b0;
    
        wm_addr_sel                    = 1'b0;
        
        bm_addr_sel                    = 1'b0;
        bm_enable_read                 = 1'b0;
        
        fifo_enable_sig1               = 1'b0;
        
        end_to_previous                = 1'b1;
        
        if(start)
            state_next = READ;
      
        end                    
 
        READ : 
        begin // Read From Memory 
		
        ifm_enable_read_A_current        = 1'b1;
        ifm_start_counter_read_address = 1'b1;
        
        wm_addr_sel                    = 1'b1;
        
        bm_addr_sel                    = 1'b1;
        bm_enable_read                 = 1'b1;
      
        fifo_enable_sig1               = 1'b1;
		
		end_to_previous                = 1'b0;
        
        if( (signal_hold) &(~mem_empty) )
            state_next = HOLD;
        else if(filters_counter_tick)
            state_next = IDLE;        
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
        else if(ifm_address_with_padding_tick)
DONATE
}
else{
    print $fh <<"DONATE";
        else if(ifm_address_read_current_tick)
DONATE
}
	        
print $fh <<"DONATE";
            state_next = FINISH;
			
        end
                
        FINISH : 
        begin 

        ifm_enable_read_A_current        = 1'b0;
        ifm_start_counter_read_address = 1'b0;
    
        wm_addr_sel                    = 1'b1;
        
        bm_addr_sel                    = 1'b1;
        bm_enable_read                 = 1'b0;
      
        fifo_enable_sig1               = 1'b0;
        
        end_to_previous                = 1'b1;

	     if(start)
             state_next = READ;
        end
        
        HOLD :
        begin

        ifm_enable_read_A_current        = 1'b0;
        ifm_start_counter_read_address = 1'b0;
    
        wm_addr_sel                    = 1'b0;
        
        bm_addr_sel                    = 1'b0;
        bm_enable_read                 = 1'b0;
      
        fifo_enable_sig1               = 1'b0;
        
        end_to_previous                = 1'b0;

        if(mem_empty)
            state_next = READ;
        
        end
        
        endcase
    end       
DONATE


if($padding_exist == 1){
    print $fh <<"DONATE";
    
///////////////////////////////////////////////////////////////////////////
/////////////////////////////// Padding FSM ///////////////////////////////
///////////////////////////////////////////////////////////////////////////

    // Depth of pad pixels around IFM
    localparam TOP_PAD   = (PADDING_VALUE/2);
    localparam BOT_PAD   = PADDING_VALUE - (PADDING_VALUE/2);
    localparam LEFT_PAD  = (PADDING_VALUE/2);
    localparam RIGHT_PAD = PADDING_VALUE - (PADDING_VALUE/2);

    localparam [1:0]  HORIZONTAL_ZEROS          = 2'b00,
                      VERTICAL_ZEROS            = 2'b01,
                      DATA                      = 2'b11;

    reg [1:0] input_state_reg, input_state_next;

    always @(posedge clk, posedge reset)
    begin
        if(reset) begin
            input_state_reg <= HORIZONTAL_ZEROS;
        end
        else begin
            input_state_reg <= input_state_next;
        end    
    end
    
 always @* 
    begin
        input_state_next = input_state_reg;
        
        case(input_state_reg)
        
        HORIZONTAL_ZEROS: begin
        
        zeros_sel = 1'b1;
        width_counter_enable = 1'b0;
        zero_counter_enable = 1'b0;
        
        if(input_data_start)
            input_state_next = VERTICAL_ZEROS;
        end
                 
        VERTICAL_ZEROS: begin
        
        zeros_sel = 1'b1;
        width_counter_enable = 1'b0;
        zero_counter_enable = 1'b1;
        
        if(input_data_end)
            input_state_next = HORIZONTAL_ZEROS;
            
        else if(zero_counter_tick)
            input_state_next = DATA;
        end
        
        DATA: begin     
         
        zeros_sel = 1'b0;
        width_counter_enable = 1'b1;
        zero_counter_enable = 1'b0;
        
        if(width_counter_tick)
            input_state_next = VERTICAL_ZEROS;
        
        end
                           
        endcase
    end    
    
    // Counter to get the position of current pixel being read ( With New size after adding zero pixels IFM + PAD)
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            ifm_address_with_padding <= {ADDRESS_SIZE_IFM_PAD{1'b0}};
        else if(ifm_address_with_padding_tick)
            ifm_address_with_padding <= {ADDRESS_SIZE_IFM_PAD{1'b0}};
        else if(ifm_start_counter_read_address)
            ifm_address_with_padding <= ifm_address_with_padding + 1'b1;
    end
    assign ifm_address_with_padding_tick = (ifm_address_with_padding == (IFM_WIDTH_PAD * IFM_HEIGHT_PAD)-1);
    
    // Flag indicates the start position of real IFM
    assign input_data_start =  (ifm_address_with_padding == (IFM_WIDTH_PAD * TOP_PAD - RIGHT_PAD));
    
    // Flag indicates the end position of real IFM pixels
    assign input_data_end   =  (ifm_address_with_padding == (IFM_WIDTH_PAD * IFM_HEIGHT_PAD - IFM_WIDTH_PAD * BOT_PAD + LEFT_PAD));
    
    always @(posedge clk, posedge reset) begin
        if(reset)
            width_counter <= {$clog2(IFM_WIDTH){1'b0}};
        else if (width_counter_tick) 
            width_counter <= {$clog2(IFM_WIDTH){1'b0}};
        else if( width_counter_enable & ifm_start_counter_read_address)
            width_counter <= width_counter + 1'b1 ;
    end
    assign width_counter_tick = (width_counter == IFM_WIDTH -1 ) ; 
    
    always @(posedge clk, posedge reset) begin
        if(reset)
            zero_counter <= {$clog2(IFM_HEIGHT){1'b0}} ;
        else if (zero_counter_tick)
            zero_counter <= {$clog2(IFM_HEIGHT){1'b0}} ;
        else if( zero_counter_enable & ifm_start_counter_read_address)
            zero_counter <= zero_counter + 1'b1 ;
    end        
    assign zero_counter_tick = (zero_counter ==  PADDING_VALUE -1 ) ; 
        
DONATE
}

print $fh <<"DONATE";

    // Selection of previous IFM Memory unit
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            ifm_sel_previous <= 0;
        else if(ifm_sel_previous ==  ${\(ceil($ARGV[5]/$ARGV[8]))}  -1 & start)
            ifm_sel_previous <= 0;  
        else if(start)
            ifm_sel_previous <= ifm_sel_previous + 1'b1; 
    end 
	
    // Selection of next OFM Memory unit
	always @(posedge clk, posedge reset)
    begin
        if(reset)
            ifm_sel_next <= 1'b0;
        else if(start_to_next)
            ifm_sel_next <= ~ifm_sel_next;
    end

    // Address Read counter of current reading IFM channel
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            ifm_address_read_A_current <= {ADDRESS_SIZE_IFM{1'b0}};
        else if(ifm_address_read_A_current == IFM_WIDTH*IFM_HEIGHT-STRIDE)
            ifm_address_read_A_current <= {ADDRESS_SIZE_IFM{1'b0}} ;
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
        else if(ifm_start_counter_read_address & (input_state_next == DATA))
DONATE
}
else{
    print $fh <<"DONATE";
        else if(ifm_start_counter_read_address)
DONATE
}

print $fh <<"DONATE";
            ifm_address_read_A_current <= (ifm_address_read_A_current + $added_value );      
    end
DONATE

if($stride == 2){
    print $fh <<"DONATE";
    assign ifm_address_read_current_tick = (ifm_address_read_A_current == IFM_HEIGHT*IFM_WIDTH-STRIDE+1);     
DONATE
}
else{
    print $fh <<"DONATE";
    assign ifm_address_read_current_tick = (ifm_address_read_A_current == IFM_HEIGHT*IFM_WIDTH-STRIDE );     
DONATE
}

if($padding_exist == 1){
    print $fh <<"DONATE";
    assign signal_hold = ( ifm_address_with_padding == FIFO_SIZE-${\($stride*3)} );
DONATE
}
else{
    print $fh <<"DONATE";
    assign signal_hold = ( ifm_address_read_A_current == FIFO_SIZE-${\($stride*3)} );
DONATE
}

if($stride == 2){
	print $fh <<"DONATE";
    assign ifm_address_read_B_current = ifm_address_read_A_current + 1'b1;
    assign ifm_enable_read_B_current = ifm_enable_read_A_current;
DONATE
}

if($padding_exist == 1 || $stride == 2){
    print $fh <<"DONATE";

    // Counter to get the right Kernal window
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            wm_counter <= {ADDRESS_SIZE_KERNAL{1'b0}};
        else if(wm_counter_tick)
            wm_counter <= {ADDRESS_SIZE_KERNAL{1'b0}};
        else if( wm_enable_read )
            wm_counter <= wm_counter + 1'b1;
    end
    assign wm_counter_tick = (wm_counter == (KERNAL_SIZE*KERNAL_SIZE-1));
DONATE
}

print $fh <<"DONATE";    
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            wm_enable_read <= 1'b0;
        else if(start)
            wm_enable_read <= 1'b1;
DONATE

if($padding_exist == 1 || $stride == 2){
    print $fh <<"DONATE";
        else if( (wm_counter_tick ))
DONATE
}
else{
    print $fh <<"DONATE";
        else if( (ifm_address_read_A_current == KERNAL_SIZE*KERNAL_SIZE-1) | (state_reg==IDLE) )
DONATE
}

print $fh <<"DONATE";
            wm_enable_read <= 1'b0;
    end
    
    // Address Read counter of Weight Memory
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            wm_address_read_current <= {ADDRESS_SIZE_WM{1'b0}};
        else if(wm_enable_read)
            wm_address_read_current <= wm_address_read_current + 1'b1;
        else if(state_reg==IDLE) 
            wm_address_read_current <= {ADDRESS_SIZE_WM{1'b0}};      
    end

    // Address Read counter of Bias Memory      
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            bm_address_read_current <= {ADDRESS_SIZE_BM{1'b0}};
        else if(bm_address_read_current == (NUMBER_OF_FILTERS-1) & ifm_address_read_current_tick)
            bm_address_read_current <= {ADDRESS_SIZE_BM{1'b0}};
        else if(depth_counter_tick)
            bm_address_read_current <= bm_address_read_current + 1'b1;      
    end
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            depth_counter <= 0;
        else if(depth_counter == ( ${\(ceil($ARGV[5]/$ARGV[8]))}  -1) & ifm_address_with_padding_tick)
            depth_counter <= 0;  
        else if(ifm_address_with_padding_tick)
            depth_counter <= depth_counter + 1'b1; 
    end 
    
    assign depth_counter_tick = (depth_counter == ( ${\(ceil($ARGV[5]/$ARGV[8]))} -1) & ifm_address_with_padding_tick);

DONATE
}
else{
    print $fh <<"DONATE";
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            depth_counter <= 0;
        else if(depth_counter == ( ${\(ceil($ARGV[5]/$ARGV[8]))}  -1) & ifm_address_read_current_tick)
            depth_counter <= 0;  
        else if(ifm_address_read_current_tick)
            depth_counter <= depth_counter + 1'b1; 
    end 
    
    assign depth_counter_tick = (depth_counter == ( ${\(ceil($ARGV[5]/$ARGV[8]))} -1) & ifm_address_read_current_tick);

DONATE
}        

print $fh <<"DONATE";    
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            filters_counter <= 0;
        else if(filters_counter == (NUMBER_OF_FILTERS-1) & depth_counter_tick)
            filters_counter <= 0;
        else if(depth_counter_tick)
            filters_counter <= filters_counter + 1'b1;
    end
    
    assign filters_counter_tick = (filters_counter == (NUMBER_OF_FILTERS-1) & depth_counter_tick);
    
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            psums_counter_next <= 0;
        else if(psums_counter_next == ( ${\(ceil($ARGV[5]/$ARGV[8]))}  -1) & $psums_enable)
            psums_counter_next <= 0 ;
        else if($psums_enable)
            psums_counter_next <= psums_counter_next + 1'b1;      
    end
    assign psums_counter_next_tick = (psums_counter_next == ( ${\(ceil($ARGV[5]/$ARGV[8]))}  -1) & $psums_enable);
    
    assign accu_enable = ( psums_counter_next != 0 );
    assign relu_enable = ( psums_counter_next == ${\(ceil($ARGV[5]/$ARGV[8]))}  -1 );

    // First kernal has external start signal pulses (Start_from_previous) equals to kernal depth,
    // Rest of kernal has internal self start pulse generation, through next assigns
	assign no_more_start_flag = |filters_counter;
    assign ready = ~no_more_start_flag;
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
    assign start_internal = no_more_start_flag & ifm_address_with_padding_tick_delayed;
DONATE
}
else{
    print $fh <<"DONATE";
    assign start_internal = no_more_start_flag & ifm_address_read_current_tick_delayed;
DONATE
}
    
print $fh <<"DONATE";
    always @(posedge clk)
    begin
        fifo_enable <= fifo_enable_sig1;
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
        ifm_address_with_padding_tick_delayed <= ifm_address_with_padding_tick;
DONATE
}
else{
    print $fh <<"DONATE";
        ifm_address_read_current_tick_delayed <= ifm_address_read_current_tick;
DONATE
}
    
print $fh <<"DONATE";
        wm_fifo_enable <= wm_enable_read;
    end 
    
///////////////////////////////////////////
//////////////// FIFO FSM /////////////////
///////////////////////////////////////////
	localparam COUNTER_FIFO_SIZE      = $clog2( FIFO_SIZE/STRIDE );
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
    localparam COUNTER_READY_SIZE     = $clog2( (IFM_WIDTH_PAD-KERNAL_SIZE)/STRIDE + 1 );
	localparam COUNTER_NOT_READY_SIZE = $clog2( (STRIDE-1)*(IFM_WIDTH_PAD/STRIDE)+(KERNAL_SIZE/STRIDE-1));
DONATE
}
else{
    print $fh <<"DONATE";
    localparam COUNTER_READY_SIZE     = $clog2( (IFM_WIDTH-KERNAL_SIZE)/STRIDE + 1 );
	localparam COUNTER_NOT_READY_SIZE = $clog2( (STRIDE-1)*(IFM_WIDTH/STRIDE)+(KERNAL_SIZE/STRIDE-1));
DONATE
}
	
print $fh <<"DONATE"; 
	
    reg start_counter_fifo;
    reg [COUNTER_FIFO_SIZE-1:0] counter_fifo;
    wire counter_fifo_tick;

    reg start_counter_ready;
    reg [COUNTER_READY_SIZE-1:0] counter_ready;
    wire counter_ready_tick;

    reg start_counter_not_ready;
    reg [COUNTER_NOT_READY_SIZE-1:0] counter_not_ready;
    wire counter_not_ready_tick;

    reg fifo_output_ready;
    
    localparam [1:0] FIFO_IDLE      = 2'b00,
                     FIFO_READY     = 2'b01,
                     FIFO_NOT_READY = 2'b10;
                     
    
    reg [1:0] fifo_state_reg, fifo_state_next;
     
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            fifo_state_reg <= FIFO_IDLE;       
        else
            fifo_state_reg <= fifo_state_next;
    end
    
    always @*
    begin 
        fifo_state_next = fifo_state_reg;

        case(fifo_state_reg)
         
        FIFO_IDLE : 
        begin
            fifo_output_ready       = 1'b0;
            start_counter_fifo      = 1'b1;
            start_counter_ready     = 1'b0; 
            start_counter_not_ready = 1'b0;
            if(counter_fifo_tick)
                fifo_state_next = FIFO_READY;       
        end
        
        FIFO_READY : 
        begin // Output READY
            fifo_output_ready       = 1'b1;
            start_counter_fifo      = 1'b0;
            start_counter_ready     = 1'b1; 
            start_counter_not_ready = 1'b0;
            if(~fifo_enable)
                fifo_state_next = FIFO_IDLE;
            else if (counter_ready_tick)
                fifo_state_next = FIFO_NOT_READY;           
        end
        
        FIFO_NOT_READY : 
        begin // Output Not READY 
      
            fifo_output_ready       = 1'b0;
            start_counter_fifo      = 1'b0;
            start_counter_ready     = 1'b0; 
            start_counter_not_ready = 1'b1; 
            if(~fifo_enable)
                fifo_state_next = FIFO_IDLE;
            if (counter_not_ready_tick)  
                fifo_state_next = FIFO_READY;     
        end
        
        default :
        begin
            fifo_output_ready       = 1'b0;
            start_counter_fifo      = 1'b0;
            start_counter_ready     = 1'b0;
            start_counter_not_ready = 1'b0;
            fifo_state_next         = FIFO_IDLE;
        end
        
        endcase
    end
    
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            counter_fifo <= {COUNTER_FIFO_SIZE{1'b0}};       
        else if(counter_fifo == FIFO_SIZE-1)
            counter_fifo <= {COUNTER_FIFO_SIZE{1'b0}};
        else if(fifo_enable & start_counter_fifo)
            counter_fifo <= counter_fifo + 1'b1;
    end
    assign  counter_fifo_tick = (counter_fifo == ( FIFO_SIZE/STRIDE )-1);
    
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            counter_ready <= {COUNTER_READY_SIZE{1'b0}};       
        else if(start_counter_ready)
            counter_ready <= counter_ready + 1'b1;
        else
            counter_ready <= {COUNTER_READY_SIZE{1'b0}};
    end
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
    assign  counter_ready_tick = (counter_ready == ( (IFM_WIDTH_PAD-KERNAL_SIZE)/STRIDE + 1 )-1);
DONATE
}
else{
    print $fh <<"DONATE";
    assign  counter_ready_tick = (counter_ready == ( (IFM_WIDTH-KERNAL_SIZE)/STRIDE + 1 )-1);
DONATE
}
    
print $fh <<"DONATE";
    
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            counter_not_ready <= {COUNTER_NOT_READY_SIZE{1'b0}};
        else if(start_counter_not_ready)
            counter_not_ready <= counter_not_ready + 1'b1;
        else
            counter_not_ready <= {COUNTER_NOT_READY_SIZE{1'b0}};
    end
DONATE

if($padding_exist == 1){
    print $fh <<"DONATE";
    assign  counter_not_ready_tick = (counter_not_ready == ( (STRIDE-1)*(IFM_WIDTH_PAD/STRIDE)+(KERNAL_SIZE/STRIDE-1))-1);
DONATE
}
else{
    print $fh <<"DONATE";
    assign  counter_not_ready_tick = (counter_not_ready == ( (STRIDE-1)*(IFM_WIDTH/STRIDE)+(KERNAL_SIZE/STRIDE-1))-1);
DONATE
}

print $fh <<"DONATE";    
    assign conv_enable = fifo_output_ready;
DONATE

print $fh <<"DONATE";        
    
/////////////////////////////////////
////// Writing Results in OFM ///////
/////////////////////////////////////

    // Address Read Counter to read previous partial sum in OFM Memory
	always @(posedge clk, posedge reset)
    begin
        if(reset)
            ifm_address_read_next <= {ADDRESS_SIZE_NEXT_IFM{1'b0}}; 
        else if(ifm_address_read_next == IFM_WIDTH_NEXT*IFM_HEIGHT_NEXT-1)
            ifm_address_read_next <= {ADDRESS_SIZE_IFM{1'b0}};      
        else if(ifm_enable_read_next)
            ifm_address_read_next <= ifm_address_read_next + 1'b1;
    end
    

DONATE



# Calculating needed delay cycles to synchronize result data with related control signals
# This problem appeared due to pipelining and using multiple number of units

my $signal_bits;
my $delay_cycles = 1;

if($padding_exist == 1){
    $signal_bits = ceil(log(($actual_ifm_width - $ARGV[6] + 1)*($actual_ifm_width - $ARGV[6] + 1))/log(2));
}
else{
    $signal_bits = ceil(log(($ARGV[3] - $ARGV[6] + 1)*($ARGV[3] - $ARGV[6] + 1))/log(2));
}

chdir "./Modules";

system("perl delay.pl $delay_cycles $signal_bits $ARGV[9]");

my $delay_name = "delay_$delay_cycles$under_Score$signal_bits";
 
 
print $fh <<"DONATE";   
    // Address Write of next OFM memory is the same as Address read after 1 cycle (due to accumelator delay)  
$delay_name #(.SIG_DATA_WIDTH($signal_bits), .delay_cycles($delay_cycles))
	DBlock_$delay_cycles$under_Score$signal_bits (.clk(clk), .reset(reset), .Data_In(ifm_address_read_next), 
		.Data_Out(ifm_address_write_next)
		);

    assign ifm_address_write_next_tick = (ifm_address_write_next == IFM_WIDTH_NEXT*IFM_HEIGHT_NEXT-1);
		
DONATE



$dummy_level = $ARGV[1]; 
$levels_number = ceil(log($dummy_level)/log(2)) - 1;
$delay_cycles = $levels_number;

$dummy_level = $ARGV[8]; 
$levels_number = ceil(log($dummy_level+1)/log(2));
$delay_cycles = $delay_cycles + $levels_number;

$signal_bits = 1;

system("perl delay.pl $delay_cycles $signal_bits $ARGV[9]");

$delay_name = "delay_$delay_cycles$under_Score$signal_bits";
 
 
print $fh <<"DONATE";   

$delay_name #(.SIG_DATA_WIDTH($signal_bits), .delay_cycles($delay_cycles))
	DBlock_$delay_cycles$under_Score$signal_bits (.clk(clk), .reset(reset), .Data_In(conv_enable), 
		.Data_Out(ifm_enable_read_next)
		);
		
DONATE


$delay_cycles = 1;
system("perl delay.pl $delay_cycles $signal_bits $ARGV[9]");

$delay_name = "delay_$delay_cycles$under_Score$signal_bits";
 
 
print $fh <<"DONATE";   

$delay_name #(.SIG_DATA_WIDTH($signal_bits), .delay_cycles($delay_cycles))
	DBlock_$delay_cycles$under_Score$signal_bits (.clk(clk), .reset(reset), .Data_In(ifm_enable_read_next), 
		.Data_Out(ifm_enable_write_next)
		);
		
DONATE

 
 
print $fh <<"DONATE";   

    //////////////////////////
    ////// start to next /////
    //////////////////////////

    localparam  s0   = 1'b0,
                s1   = 1'b1;	  
							  
    reg state_reg2, state_next2; 
    
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            state_reg2 <= s0;       
        else
            state_reg2 <= state_next2;
    end

    always @*
    begin     
        state_next2 = state_reg2;
        		
        case(state_reg2)
        
        s0 : 
        begin
            start_to_next = 1'b0;
            mem_empty     = 1'b1;
            if(psums_counter_next_tick)
                state_next2 = s1;          
        end
        
        s1 : 
        begin 

            if ( end_from_next )
            begin
                start_to_next = 1'b1;
                mem_empty     = 1'b1;
                state_next2    = s0;
            end
            
            else 
            begin
                start_to_next = 1'b0;
                mem_empty     = 1'b0;
                state_next2    = s1;  
            end      
        end
        
        endcase
    end
    
endmodule

DONATE
close $fh or die "Couldn't Close File : $!";
