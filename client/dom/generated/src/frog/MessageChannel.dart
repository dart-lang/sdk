
class MessageChannel native "*MessageChannel" {

  MessagePort get port1() native "return this.port1;";

  MessagePort get port2() native "return this.port2;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
