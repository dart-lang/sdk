
class SpeechInputEventJs extends EventJs implements SpeechInputEvent native "*SpeechInputEvent" {

  SpeechInputResultListJs get results() native "return this.results;";
}
