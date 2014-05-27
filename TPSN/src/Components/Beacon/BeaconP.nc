/**
 * Implementation of the Beacon Node. 
 * The node turns on the red LED after booting. A timer is started. Every time
 * this timer fires, a packet is sent via broadcast, and the yellow led is 
 * toggled. The packet contains the ID of this node and a sequence number. 
 * No packets are received by this component. 
 *  
 * @author Barraza, Suarez
 * @modified Apr 4, 2014 
 */

#include <Timer.h>
#include "Beacon.h"

module BeaconP {
  uses interface Boot;
  uses interface Leds;
  uses interface SplitControl as AMControl; //Active Message Control
  uses interface Packet;
  uses interface AMSend;
  uses interface Timer<TMilli> as Timer0;
}
implementation {

  //variables reserved in memory
  uint16_t counter;  // 2 Bytes. It contains the sequence number of 
  // released packets.
  message_t pktBuff; // many Bytes, packet buffer. This is not a pointer,
  // this is the allocation(space) a packet needs in memory. Functions related  
  // to packets access them via memory pointers / addresses, e.g.: &pktBuff

  event void Boot.booted() {
    counter = 0; //initialize counter
    call AMControl.start(); //start the radio module (ActiveMessageC)
    call Leds.led0On(); //turn on the red LED.
  }

  //radio
  event void AMControl.startDone(error_t err) {
    if(err == SUCCESS) {
      //if radio started normally, start a timer that will fire every 5 secs
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI_BEACON);
    }
    else {
      //in case radio did not start normally, try again
      call AMControl.start();
    }
  }

  //radio 
  event void AMControl.stopDone(error_t err) {
    //radio was stopped. Do nothing. 
  }

  //timer reached its time limit (every 5 secs.)
  event void Timer0.fired() {
    //Declare first pointers and variables used in this function.
    BeaconMsg_t * bMsg; // Pointer to a beacon message in memory
                        // This is not an actual place/buffer in memory. 
 
    //Prepare and send packet.
    //First. Cast our packet (message_t) into a "beacon message" type
    //       Refer to the packet by using the "bMsg" pointer.
    bMsg = (BeaconMsg_t * )(call Packet.getPayload(&pktBuff, sizeof(BeaconMsg_t)));
 
    //Check that the casting was ok. 
    if (bMsg == NULL){
      // Casting failed for any reason, the pointer bMsg is NULL. 
      // Do nothing and leave this function.
      return;
    } 
    
    //Otherwise, the pointer bMsg is valid! Prepare packet!
    counter++; //increase counter
    
    bMsg->nodeId = TOS_NODE_ID; //This is the ID of this node! 
    //This value is provided at install(flashing) time by the user.

    bMsg->seqNr = counter; // Set the sequence number of this packet.
 
    // Send the packet. 
    // AMSend uses the memory address of the original packetBuffer, but
    // the size of the newly created BeaconMsg.  The destination address
    // is AM_BROADCAST_ADDR, which is defined as 0xFFFF and it means that 
    // any node around will accept the packet (broadcast).
    call AMSend.send(AM_BROADCAST_ADDR, &pktBuff, sizeof(BeaconMsg_t));
   
  }

  event void AMSend.sendDone(message_t * msg, error_t err) {
    // This function comes with two arguments: a message pointer to the sent 
    // message and an error indicator informing whether the packet was sent
    // fine or had problems. We ignore the error information. 
    
    // Check if the sendDone corresponds to the packet sent by this
    // application (BeaconC). Check that the pointer msg points to pktBuff   
    if(&pktBuff == msg) {
      // Check passed! This sendDone belongs to the pktBuff we sent, so we 
      // are sure the transmission has finished.
      call Leds.led2Toggle(); // toggle the yellow LED
    }
  }

}