
class DedicatedWorkerContext extends WorkerContext native "*DedicatedWorkerContext" {

  EventListener onmessage;

  void postMessage(Object message, [List messagePorts = null]) native;

  void webkitPostMessage(Object message, [List transferList = null]) native;
}
