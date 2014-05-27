/**
 * This component plays the role of ActiveMessageC in 
 * the TPSN project for the node acting as Base Station. 
 * 
 * Basically, it is an intermediary between:
 * 1) the radio
 * 2) the other components in the TPSN project
 * 3) the serial interface
 * 
 * Our implementation behaves as a layer between the real ActiveMessageC layer
 * and the other components that need to send and receive packets. 
 * 
 * Usage at PC:
 * 
 *   java net.tinyos.tools.Listen -comm serial@/dev/ttyUSB1:iris
 * 
 * 
 * @author Barraza, Suarez
 * @modified Apr 15, 2014
 */


configuration TPSN_Base_AMC{
  provides
  {
    interface SplitControl;
    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];
    interface Packet;
    interface AMPacket;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
  }
  
}
implementation{
  components MainC;
//  components LedsC as MyLedsC;
  components NoLedsC as MyLedsC;
  components TPSN_Base_AMP as TBaseAMP;
  components ActiveMessageC as RadioAMC;
  components SerialActiveMessageC as SerialAMC;
  
  // export these PROVIDED interfaces directly from real Active Message Layer
  SplitControl         = RadioAMC.SplitControl;
  Packet               = RadioAMC.Packet;
  AMPacket             = RadioAMC.AMPacket;
  PacketTimeStampMilli = RadioAMC.PacketTimeStampMilli;
  
  // export these PROVIDED interfaces from our implementation
  AMSend               = TBaseAMP.AMSend;
  Receive              = TBaseAMP.Receive;
  Snoop                = TBaseAMP.Snoop;
  
 
  // connection of USED interfaces (by our implementation) 
  TBaseAMP.Boot  -> MainC.Boot;
  TBaseAMP.Leds  -> MyLedsC.Leds;
  //Radio (packets that come from radio)
  TBaseAMP.RadioControl         -> RadioAMC.SplitControl;
  TBaseAMP.RadioAMSend          -> RadioAMC.AMSend;
  TBaseAMP.RadioReceive         -> RadioAMC.Receive;
  TBaseAMP.RadioSnoop           -> RadioAMC.Snoop;
  TBaseAMP.RadioPacket          -> RadioAMC.Packet;
  TBaseAMP.RadioAMPacket        -> RadioAMC.AMPacket;
  TBaseAMP.PacketTimeStampMilli -> RadioAMC.PacketTimeStampMilli;
  //Serial (packets that are sent to serial)
  TBaseAMP.SerialControl  -> SerialAMC.SplitControl;
  TBaseAMP.SerialAMSend   -> SerialAMC.AMSend;
  TBaseAMP.SerialPacket   -> SerialAMC.Packet;
  TBaseAMP.SerialAMPacket -> SerialAMC.AMPacket;
  

}