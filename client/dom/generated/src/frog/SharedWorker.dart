
class SharedWorkerJS extends AbstractWorkerJS implements SharedWorker native "*SharedWorker" {

  MessagePortJS get port() native "return this.port;";
}
