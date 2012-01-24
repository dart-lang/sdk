
class SharedWorkerJs extends AbstractWorkerJs implements SharedWorker native "*SharedWorker" {

  MessagePortJs get port() native "return this.port;";
}
