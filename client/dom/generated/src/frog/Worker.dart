
class Worker extends AbstractWorker native "*Worker" {

  EventListener onmessage;

  void postMessage(String message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(String message, [List messagePorts = null]) native;
}
