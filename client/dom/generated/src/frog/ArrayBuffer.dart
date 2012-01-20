
class ArrayBuffer native "*ArrayBuffer" {

  int get byteLength() native "return this.byteLength;";

  ArrayBuffer slice(int begin, [int end = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
