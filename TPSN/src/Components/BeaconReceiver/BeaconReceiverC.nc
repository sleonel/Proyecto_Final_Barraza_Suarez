/**
 * BeaconReceiver configuration. Basically, when this node hears 
 * a Beacon message, it sends another packet "Report Message" with the 
 * beacon sequence number and the time at which the packet was received.
 * 
 * @author Barraza, Suarez.
 * @modified Apr 22, 2014
 */


#include "Beacon.h"
#include "BeaconReceiver.h"

configuration BeaconReceiverC {
}
implementation {
  components MainC;
  components LedsC;
  components BeaconReceiverP as BRP;
  components new TimerMilliC() as TimerC;
  components RandomC;
  components CorrectTimeC;
  //use our components
  components TPSN_ActiveMessageC as AMC;
  components new TPSN_SenderC(REPORT_MSG) as SenderC;
  components new TPSN_ReceiverC(BEACON_MSG) as ReceiverC;

  // connections  
  BRP.Boot                 -> MainC;
  BRP.Leds                 -> LedsC;
  BRP.TimerWait            -> TimerC;
  BRP.CorrectTime          -> CorrectTimeC;
  BRP.Random               -> RandomC;

  BRP.Packet               -> AMC;
  BRP.AMControl            -> AMC;
  BRP.PacketTimeStampMilli -> AMC;
  BRP.AMSend               -> SenderC;
  BRP.Receive              -> ReceiverC;

}