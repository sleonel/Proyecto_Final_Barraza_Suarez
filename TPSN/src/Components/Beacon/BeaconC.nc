/**
 * Beacon sender. 
 * 
 * Every time a timer fires, this component sends a packet with this node ID 
 * and the packet's sequence number. This component does not receive packets.
 * 
 * This component is fully wired and can be used by any application as an 
 * autonomous block.
 * 
 * 
 * @author Barraza,Suarez
 * @modified Apr 22, 2014
 */


#include "Beacon.h"

configuration BeaconC {
}
implementation {
  components MainC;
//  components LedsC as MyLedsC;
  components NoLedsC as MyLedsC;
  components BeaconP;
  components new TimerMilliC() as TimerC;
  //use our components
  components TPSN_ActiveMessageC as AMC; 
  components new TPSN_SenderC(BEACON_MSG) as SenderC;
  
  //connections
  BeaconP.Boot      -> MainC;
  BeaconP.Leds      -> MyLedsC;
  BeaconP.Timer0    -> TimerC;
  
  BeaconP.Packet    -> AMC;
  BeaconP.AMControl -> AMC;
  BeaconP.AMSend    -> SenderC;
}