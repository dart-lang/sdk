
class ArrayBuffer native "*ArrayBuffer" {

  int byteLength;

  ArrayBuffer slice(int begin, [int end = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
