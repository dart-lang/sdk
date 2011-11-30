
class DedicatedWorkerContext extends WorkerContext native "*DedicatedWorkerContext" {

  void postMessage(Object message, [List messagePorts = null]) native;

  void webkitPostMessage(Object message, [List transferList = null]) native;
}
