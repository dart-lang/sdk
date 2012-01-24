
class AbstractWorkerJs extends DOMTypeJs implements AbstractWorker native "*AbstractWorker" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
