
class MessageChannelJs extends DOMTypeJs implements MessageChannel native "*MessageChannel" {

  MessagePortJs get port1() native "return this.port1;";

  MessagePortJs get port2() native "return this.port2;";
}
