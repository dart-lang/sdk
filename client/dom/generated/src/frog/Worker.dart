
class _WorkerJs extends _AbstractWorkerJs implements Worker native "*Worker" {

  void postMessage(Dynamic message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(Dynamic message, [List messagePorts = null]) native;
}
