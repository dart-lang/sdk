
class SpeechInputResultJs extends DOMTypeJs implements SpeechInputResult native "*SpeechInputResult" {

  num get confidence() native "return this.confidence;";

  String get utterance() native "return this.utterance;";
}
