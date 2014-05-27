/**
 * This component plays the role of ActiveMessageC in the TPSN project
 * 
 * Depending on whether the macro TPSN_BASE_NODE was defined in 
 * an upper module or not (that is, whether this node is the Base or not),
 * this component provides the functionality of:
 * - our implementation of a base station (TPSN_Base_AMC) stack, or 
 * - the normal ActiveMessageC stack. 
 * 
 * @author Barraza, Suarez
 * @modified Apr 23, 2014
 */


configuration TPSN_ActiveMessageC{
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

#ifdef TPSN_BASE_NODE  
  // use our TPSN_Base_ActiveMessage stack to send packets also to serial
  components TPSN_Base_AMC as AMC;  
#else
  //use normal ActiveMessageC Stack
  components ActiveMessageC as AMC; 
#endif  
  
  // export these PROVIDED interfaces 
  SplitControl         = AMC.SplitControl;
  AMSend               = AMC.AMSend;
  Receive              = AMC.Receive;
  Snoop                = AMC.Snoop;
  Packet               = AMC.Packet;
  AMPacket             = AMC.AMPacket;
  PacketTimeStampMilli = AMC.PacketTimeStampMilli;

}