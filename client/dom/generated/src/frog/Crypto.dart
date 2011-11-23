
class Crypto native "*Crypto" {

  void getRandomValues(ArrayBufferView array) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
