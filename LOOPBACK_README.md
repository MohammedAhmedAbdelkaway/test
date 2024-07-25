Description:
 This file describes the failure condition for the loopback test and the content of the generated report STM summary in sb_bridge_loopback.

Test Fail Condition:
 The loopback test (tc_looback_commit or tc_loopback_boundary) fails under achieving any of the following conditions:
 1. Number of the received AXI4 Stream packets during the simulation = 0.
 2. Number of the received Avalon Stream packets during the simulation = 0, in case there are correctly sent AXI4 stream packets (at least one bridge to game packet).
 3. Wrong expectation in the local loopback detection and the sent axi4 stream packet is not corrupted.
 4. Wrong expectation in the remote loopback detection.
 5. There is any uvm error. Where the uvm errors happen when:
      a. There is wrong expectation in local or remote loopback detection.

Loopback summary.log:
 This report contains the different configuration of the target loopback test, the number of uvm report statements, cache timeout count, final caches contents, loopback detection errors,
 total functional coverage, functional coverage for each coveragroup and test condition.
 It contains the following information:
 1. Target Loopback test name.
 2. MAC Timeout Period.
 3. Cache Depth.
 4. MLVDS Enable value.
 5. SIL Enable value.
 6. Repacket Enable value.
 7. The number of calls for the Loopback sequence.
 8. Case descriptions of each call of loopback sequence.
 9. Number of the executed UVM Error statements during the simulation.
 10. Number of the executed UVM Info statements during the simulation.
 11. The number of times a cache timeout occurred
 12. Final local cache content.
 13. Final remote cache content.
 14. Number of decode errors in the sent bridge to game packets.
 15. Number of wrong expectations in local loopback detection.
 16. Number of wrong expectations in remote loopback detection.
 17. Total Functional coverage (FC).
 18. FC for the sent bridge packet type.
 19. FC for the sent bridge packet sub-type.
 20. FC for the received bridge packet type.
 21. FC for the received bridge packet sub-type.
 22. FC for the updated local cache addresses.
 23. FC for the updated remote cache addresses.
 24. FC for the repeated local cache addresses.
 25. FC for the repeated remote cache addresses.
 26. FC for the removed local cache addresses.
 27. FC for the removed remote cache addresses.
 28. Test state (PASS or FAIL).
