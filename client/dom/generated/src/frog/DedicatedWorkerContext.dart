
class DedicatedWorkerContextJs extends WorkerContextJs implements DedicatedWorkerContext native "*DedicatedWorkerContext" {

  EventListener get onmessage() native "return this.onmessage;";

  void set onmessage(EventListener value) native "this.onmessage = value;";

  void postMessage(Object message, [List messagePorts = null]) native;

  void webkitPostMessage(Object message, [List transferList = null]) native;
}
