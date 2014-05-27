/**
 * Application for Node level 2 in TPSN protocol.
 * 
 * It includes the functionality of Beacon RECEIVER. 
 * 
 * Note that we define the macro:
 *  - NODE_LEVEL as 1:  Used by the NaiveSyncC component
 * 
 * @author  Barraza, Suarez.
 * @modified Apr 22, 2014 
 */

//read above
#define NODE_LEVEL 2 

configuration Tpsn2AppC{
}
implementation{
  components BeaconReceiverC;  //Reporte para el Beacon
  components Tpsn2C; // Sincronizacion protocolo TPSN en el Nodo 1,
}