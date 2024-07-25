Description:
 This file describes the failure condition for the STM test and the content of the generated report STM summary in sb_bridge_stm.

Test Fail Condition:
 The STM test (tc_stm_commit or tc_stm_boundary) fails under achieving any of the following conditions:
 1. Number of the received AXI4 Stream packets during the simulation = 0.
 2. Number of the received Avalon Stream packets during the simulation = 0, in case there are correctly sent AXI4 stream packets (at least one bridge to game packet).
 3. There is any uvm error. Where the uvm errors happen when:
      a. There is unacceptable residence time mismatch between RTL and Golden residence time.
      b. There is received Followup STM message on RX AXI4 Stream or Avalon without previous received sync STM message at the interface.

STM Summary.log:
 This report contains the different configuration of the target stm test, the number of uvm report statements, total functional coverage, functional coverage for each coveragroup and test condition.
 It contains the following information:
 1. Target STM test name.
 2. SIL Enable value.
 3. Repacket Enable value.
 4. The number of sent STM pairs on the AXI4 Stream & Avalon interface or the number of calls for the STM sequence.
 5. Number of the executed UVM Error statements during the simulation.
 6. Number of the executed UVM Info statements during the simulation.
 7. Total Functional coverage (FC).
 8. FC for the sent bridge packet type.
 9. FC for the sent bridge packet sub-type.
 10. FC for the received bridge packet type.
 11. FC for the received bridge packet sub-type.
 12. FC for the stm bus type of the sent STM Avalon packets.
 13. FC for the stm bus type of the received STM Avalon packets.
 14. FC for the stm bus type of the sent STM AXI4 Stream packets.
 15. FC for the stm bus type of the received STM AXI4 Stream packets.
 16. FC for the inter-packet delay in the G2L path (Avalon STM).
 17. FC for the inter-packet delay in the L2G path (AXI STM).
 18. FC for the sent Avalon packets.
 19. FC for the sent AXI4 Stream packets.
 20. Test state (PASS or FAIL).

