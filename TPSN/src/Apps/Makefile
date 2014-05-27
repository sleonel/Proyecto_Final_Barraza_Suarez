#  19.05.2014, Barraza,Suarez.
#  This Makefile is used only when compiling tinyos code directly
#  with one of the commands:
#     make iris
#     make iris install.9 mib510./dev/ttyUSB0
#  In the last command the node ID is assumed to be 9, and using USB0 output.


# The top-level application component
#COMPONENT=TpsnL0AppC
#COMPONENT=Tpsn1AppC
COMPONENT=Tpsn2AppC

#Set RF power to 15 (minimum). Possible: 0-15. See RF230 datasheet.
CFLAGS += -DRF230_DEF_RFPOWER=15  

#Set RF channel to 11. Possible: 11-26. See RF230 datasheet. 
CFLAGS += -DRF230_DEF_CHANNEL=11

include $(MAKERULES)
