
class _JavaScriptAudioNodeJs extends _AudioNodeJs implements JavaScriptAudioNode native "*JavaScriptAudioNode" {

  final int bufferSize;

  EventListener onaudioprocess;
}
