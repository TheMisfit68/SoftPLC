# SoftPLC ToDo

Check the need to make a PLCObject a weak var of the PLC because the PLCObject has a link back to the PLC
To prevent any retain cycles, the objects should be made weak like a delegate is to a delegator

- [ ] add counters
- [ ] Unit test against duplicated PLC-variables
- [ ] Migrate variable list to a dbase
