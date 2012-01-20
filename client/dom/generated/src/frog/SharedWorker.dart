
class SharedWorker extends AbstractWorker native "*SharedWorker" {

  MessagePort get port() native "return this.port;";
}
