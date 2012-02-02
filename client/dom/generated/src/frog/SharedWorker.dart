
class _SharedWorkerJs extends _AbstractWorkerJs implements SharedWorker native "*SharedWorker" {

  _MessagePortJs get port() native "return this.port;";
}
