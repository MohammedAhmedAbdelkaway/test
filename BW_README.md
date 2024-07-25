Description:
 This file describes the failure condition for the bw test and the content of the generated report BW summary in sb_bridge_bw.

Test Fail Condition:
 The BW test (tc_bw_bursts_commit or tc_bw_bursts_boundary) fails under achieving any of the following conditions:
 1. Number of the received AXI4 Stream packets during the simulation = 0.
 2. Number of the received Avalon Stream packets during the simulation = 0, in case there are correctly sent AXI4 stream packets (at least one bridge to game packet).
 3. Burst loss in AXI4 Stream to Avalon path without error injection or local loopback detection.
 4. Burst loss in Avalon to AXI4 Stream path without remote loopback detection.
 5. There is any uvm error. Where the uvm errors happen when:
      a. There is loss in the AXI4 stream or Avalon bursts without error injection or loopback detection.

BW Summary.log:
 This report contains the different configuration of the target BW test, the number of uvm report statements, number of received axi and avalon packets, maximum raw and encoded BW for each tx path,
 number of burst losses for each path, number of sent HP, LP and BE for each path, total functional coverage, functional coverage for each coveragroup and test condition.
 It contains the following information:
 1. Target BW test name.
 2. MLVDS Enable value.
 3. SIL Enable value.
 4. Repacket Enable value.
 5. The number of calls for the BW sequence.
 6. Case descriptions of each call of BW sequence.
 7. Number of the executed UVM Error statements during the simulation.
 8. Number of the executed UVM Info statements during the simulation.
 9. Number of received AXI stream packets.
 10. Number of received Avalon packets.
 11. Maximum TX Avalon BW for raw and encoded lengths.
 12. Maximum TX AXI4 Stream BW for raw and encoded lengths.
 13. Number of burst losses in AXI4 Stream to Avalon path.
 14. Number of burst losses in Avalon to AXI4 Stream path.
 15. Number of sent HP Avalon packets.
 16. Number of sent LP Avalon packets.
 17. Number of sent BE Avalon packets.
 18. Number of sent HP AXI4 Stream packets.
 19. Number of sent LP AXI4 Stream packets.
 20. Number of sent BE AXI4 Stream packets.
 21. Total Functional coverage (FC).
 22. FC for the received bridge packet type.
 23. FC for the sent bridge packet type.
 24. FC for the count of the different packets at the four interface.
 25. FC for the sent AXI4 Stream packet length (raw length).
 26. FC for the received AXI4 Stream packet length.
 27. FC for the sent Avalon packet length (raw length).
 28. FC for the received Avalon packet length.
 29. FC for the inter-packet delay between AXI4 stream packets.
 30. FC for the inter-packet delay between Avalon packets.
 31. FC for the number of slots in AXI4 Stream bursts.
 32. FC for the number of slots in Avalon bursts.
 38. Test state (PASS or FAIL).
