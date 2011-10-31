
class DedicatedWorkerContext extends WorkerContext native "DedicatedWorkerContext" {

  EventListener onmessage;

  void postMessage(Object message) native;

  void webkitPostMessage(Object message) native;
}
