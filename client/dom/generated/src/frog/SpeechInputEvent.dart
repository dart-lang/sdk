
class SpeechInputEventJS extends EventJS implements SpeechInputEvent native "*SpeechInputEvent" {

  SpeechInputResultListJS get results() native "return this.results;";
}
