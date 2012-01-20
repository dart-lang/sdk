
class SpeechInputResult native "*SpeechInputResult" {

  num get confidence() native "return this.confidence;";

  String get utterance() native "return this.utterance;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
