/**
 * Application for Node level 0 in TPSN protocol.
 * 
 * It includes the functionality of Beacon RECEIVER. 
 * 
 * Note that we define the macro:
 *  - NODE_LEVEL as 1:  Used by the NaiveSyncC component
 * 
 * @author  Barraza, Suarez.
 * @modified Apr 22, 2014 
 */


// read above
#define TPSN_BASE_NODE

//read above
#define NODE_LEVEL 0 

configuration TpsnL0AppC{
}
implementation{
  components BeaconC;   //Realiza las funciones del Nodo de señalizacion (Beacon)
  components TpsnReceiver0C;  //Conecta con la aplicacion para realizar la Sincronizacion.
  
}