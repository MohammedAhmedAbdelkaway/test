Description:
 This file describes the failure condition for the bridge_to_bridge test and the content of the generated report PING summary in sb_bridge_ping.

Test Fail Condition:
 The bridge to bridge test (tc_ping_asset) fails under achieving any of the following conditions:
 1. Number of the received bridge to bridge messages during the simulation = 0. Where the bridge to bridge packet types are (Schedule - PING - PING Response - Asset Info).
 2. The sent corrected ping to recevied ping response loss is greater than 2.
 3. There is any uvm error. Where the uvm errors happen when:
      a. There is incorrect received axi4 stream packet (not bridge to bridge type).

PING summary.log:
 This report contains the different configuration of the target stm test, the number of uvm report statements, the different number of sent and received bridge to bridge types, total functional coverage, functional coverage for each coveragroup and test condition.
 It contains the following information:
 1. Repacket Enable value.
 2. Number of the executed UVM Error statements during the simulation.
 3. Number of the executed UVM Info statements during the simulation.
 4. The total number of sent bridge packets.
 5. Number of sent ping messages.
 6. Number of correct sent ping messages.
 7. Number of sent ping response messages.
 8. Number of sent asset info messages.
 9. Number of sent schedule messages.
 10. The total number of received bridge packets without duplication.
 11. Number of received ping messages.
 12. Number of received ping response messages.
 13. Number of received asset info messages.
 14. Number of received schedule messages.
 15. The difference between the correct sent ping messages and the received ping response messages.
 16. The difference between the received ping messages and the sent ping response messages.
 17. Total Functional coverage (FC).
 18. FC for the sent bridge packet type.
 19. FC for the received bridge packet type.
 20. Test state (PASS or FAIL).
