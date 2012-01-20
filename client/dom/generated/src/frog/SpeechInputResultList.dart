
class SpeechInputResultList native "*SpeechInputResultList" {

  int get length() native "return this.length;";

  SpeechInputResult item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
