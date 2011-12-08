
class JavaScriptAudioNode extends AudioNode native "*JavaScriptAudioNode" {

  int bufferSize;

  // From EventTarget

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
