
class SpeechInputResultListJS implements SpeechInputResultList native "*SpeechInputResultList" {

  int get length() native "return this.length;";

  SpeechInputResultJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
