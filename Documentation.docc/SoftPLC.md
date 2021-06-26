# ``SoftPLC``

A first attempt to mimic a PLC (Progammable Logic Controller) in Swift.


## Overview

PLC's are typically rugedized hardware controllers used in industrial environments, to control all sorts of industrial processes and machinery.
A PLC connects with the outside world using Input- and Output-modules (IO for short) that gets installed alongside its CPU (both digital and analog IO-modules exist).
Due to its specific field of application a PLC needs to be a super stable platform. Therefor:
- A PLC needs a dedicated simple OS
- A PLC is programmed with its own small instruction set 
- A PLC provides strict defined behaviour with little or no side effects allowed.

This framework tries to be a 'Soft PLC'.
A Soft-PLC simulates PLC functionality for testing purposes while running as a computer-program on a regular computer-platform instead of as special dedicated hardware.
A Soft-PLC could be used for non critical automation applications, like you personal home automation system provided it is connected to some form of IO.
Many IO-modules use 'Modbus over Ethernet' as their communication protocol. Modbus is well documented and easy to implement communication protocol used in industrial applications.


## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
 
