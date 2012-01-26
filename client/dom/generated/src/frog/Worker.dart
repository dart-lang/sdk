
class WorkerJs extends AbstractWorkerJs implements Worker native "*Worker" {

  void postMessage(String message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(String message, [List messagePorts = null]) native;
}
