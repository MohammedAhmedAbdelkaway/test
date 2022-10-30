use strict;
use warnings;
use diagnostics;

# say prints a line followed by a newline
use feature 'say';
 
# Use a Perl version of switch called given when
use feature "switch";


#argumets 
#ARGV[0] data_width 32
#ARGV[1] M - Mantissa, precision
#ARGV[2] E - Exponent, integer bits
#$ARGV[3]
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
my $data_width = "DATA_WIDTH";
my $end = "end";
my $end_module = "endmodule";
my $i_p = "input";
my $o_p = "output";
my $under_Score = "_";
my $full_path = "../../../../../$ARGV[3]/";
#######################################################################################
my $i = 0;

my $file_name;
my $module_name = "floating_point_max";
my $arith_type = "ARITH_TYPE";



$file_name = $full_path . $module_name . ".v";

open my $fh, '>', $file_name
  or die "Can't open file : $!";


print $fh <<"DONATE";
$module $module_name $parameter
	$data_width = $ARGV[0],
	E           = $ARGV[2], 
	M           = $ARGV[1] )
    (
	input   [DATA_WIDTH - 1 : 0]    IN1,
	input   [DATA_WIDTH - 1 : 0]    IN2,
	output  [DATA_WIDTH - 1 : 0]    OUT 
	);

wire [ E-1 : 0 ] exp1 ,   exp2 ;
wire [ M-1 : 0 ] mant1 , mant2 ;
wire 			 sign1,  sign2 ;
wire [M : 0]   temp_mant;
wire [E : 0]   temp_exp ;

reg flag_IN1, flag_IN2, flag_same ;
reg [DATA_WIDTH - 1 : 0] outreg ;

assign sign1 = IN1 [DATA_WIDTH - 1] ;
assign sign2 = IN2 [DATA_WIDTH - 1] ;
assign exp1  = IN1 [DATA_WIDTH - 2 : DATA_WIDTH-E-1] ;
assign exp2  = IN2 [DATA_WIDTH - 2 : DATA_WIDTH-E-1] ;
assign mant1 = IN1 [M-1 : 0];
assign mant2 = IN2 [M-1 : 0];

assign temp_mant = mant1 - mant2 ;
assign temp_exp  = exp1  - exp2  ;

always @(*) begin
	outreg	 = 32'b0;
	flag_IN1 = 1'b0;
	flag_IN2 = 1'b0;
	flag_same = (sign1 == sign2) ? 1'b1 : 1'b0 ;

	if(!flag_same) begin
		flag_IN1 = ((sign1 ==1'b0) & (sign2 == 1'b1)) ? 1'b1 : 1'b0 ;
		flag_IN2 = ((sign1 ==1'b1) & (sign2 == 1'b0)) ? 1'b1 : 1'b0 ;
		
        if (flag_IN1)
			outreg = IN1;
		else if (flag_IN2)
			outreg = IN2;
	end
	else begin
		if (temp_exp == 9'b0) begin
			if (temp_mant == 24'b0) begin
				outreg = IN1 ;
			end
			else if (temp_mant[M] == 1'b0) begin			
				outreg = sign1 ? IN2 : IN1 ;
			end
			else begin
				outreg = sign2 ? IN1 : IN2 ;
			end
		end
		else if (temp_exp[E] == 1'b0) begin		
			outreg = sign1 ? IN2 : IN1 ;
		end
		else if (temp_exp[E] == 1'b1) begin
			outreg = sign2 ? IN1 : IN2 ;
		end
	end
end

assign OUT = outreg ;

endmodule

DONATE


close $fh or die "Couldn't Close File : $!";
