
class _MessagePortJs extends _EventTargetJs implements MessagePort native "*MessagePort" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(_EventJs evt) native;

  void postMessage(String message, [List messagePorts = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void start() native;

  void webkitPostMessage(String message, [List transfer = null]) native;
}
