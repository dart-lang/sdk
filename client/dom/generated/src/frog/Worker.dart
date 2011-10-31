
class Worker extends AbstractWorker native "Worker" {

  EventListener onmessage;

  void postMessage(String message, [MessagePort messagePort = null]) native;

  void terminate() native;
}
