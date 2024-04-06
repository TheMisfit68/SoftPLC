# SoftPLC ToDo

- [ ] Migrate the configuration of the PLC to a SwiftData Model and make the PLC configurable by an external process.
- [ ] Make the PLC and it's configuration into a standalone process that can be run indipendently (to improve isolation and stability), while maintaining optimal performance on a multi-core system. 
- [ ] Test performance with shorter cycle times. To keep time sensitive PLC-code working the runcycle interval of the PLC should be double the actual needed cycle time indicated in the dashboard. Maybe compute the runcycle interval automaticly as two times the maxium cycle time instead af through a parameter.

- [ ] Check the need to make a PLCObject a weak var of the PLC because the PLCObject has a link back to the PLC
To prevent any retain cycles, the objects should be made weak like a delegate is to a delegator

- [ ] add counters
- [ ] Unit test against duplicated PLC-variables
- [ ] Migrate variable list to a dbase
