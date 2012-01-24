
class MessageChannelJS implements MessageChannel native "*MessageChannel" {

  MessagePortJS get port1() native "return this.port1;";

  MessagePortJS get port2() native "return this.port2;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
