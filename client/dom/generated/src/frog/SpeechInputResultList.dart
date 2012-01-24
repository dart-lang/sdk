
class SpeechInputResultListJs extends DOMTypeJs implements SpeechInputResultList native "*SpeechInputResultList" {

  int get length() native "return this.length;";

  SpeechInputResultJs item(int index) native;
}
