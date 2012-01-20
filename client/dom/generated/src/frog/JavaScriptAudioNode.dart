
class JavaScriptAudioNode extends AudioNode native "*JavaScriptAudioNode" {

  int get bufferSize() native "return this.bufferSize;";

  EventListener get onaudioprocess() native "return this.onaudioprocess;";

  void set onaudioprocess(EventListener value) native "this.onaudioprocess = value;";
}
