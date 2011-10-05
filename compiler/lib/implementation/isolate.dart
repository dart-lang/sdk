// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SendPortImpl implements SendPort {

  const SendPortImpl(this._workerId, this._isolateId, this._receivePortId);

  void send(var message, SendPort replyTo) {
    if (PromiseQueue.isEmpty()) {
      this._sendNow(message, replyTo);
    } else {
      _enqueueSend(message, replyTo);
    }
  }

  void _enqueueSend(var message, SendPort replyTo) {
    PromiseQueue.enqueue(const []).then((ignored) {
      this._sendNow(message, replyTo);
    });
  }

  void _sendNow(var message, SendPort replyTo) native;

  ReceivePortSingleShotImpl call(var message) {
    final result = new ReceivePortSingleShotImpl();
    this.send(message, result.toSendPort());
    return result;
  }

  ReceivePortSingleShotImpl _callNow(var message) {
    final result = new ReceivePortSingleShotImpl();
    this._sendNow(message, result.toSendPort());
    return result;
  }

  bool operator==(var other) {
    return (other is SendPortImpl) &&
        (_workerId == other._workerId) &&
        (_isolateId == other._isolateId) &&
        (_receivePortId == other._receivePortId);
  }

  int hashCode() {
    return (_workerId << 16) ^ (_isolateId << 8) ^ _receivePortId;
  }

  final int _receivePortId;
  final int _isolateId;
  final int _workerId;

  static _create(int workerId, int isolateId, int receivePortId) native {
    return new SendPortImpl(workerId, isolateId, receivePortId);
  }
  static _getReceivePortId(SendPortImpl port) native {
    return port._receivePortId;
  }
  static _getIsolateId(SendPortImpl port) native {
    return port._isolateId;
  }
  static _getWorkerId(SendPortImpl port) native {
    return port._workerId;
  }
}


class ReceivePortFactory {

  factory ReceivePort() {
    return new ReceivePortImpl();
  }

  factory ReceivePort.singleShot() {
    return new ReceivePortSingleShotImpl();
  }

}


class ReceivePortImpl implements ReceivePort {
  ReceivePortImpl()
      : _id = _nextFreeId++ {
    _register(_id);
  }

  void receive(void onMessage(var message, SendPort replyTo)) {
    _callback = onMessage;
  }

  void close() {
    _callback = null;
    _unregister(_id);
  }

  SendPort toSendPort() {
    return _toNewSendPort();
  }

  /**
   * Returns a fresh [SendPort]. The implementation is not allowed to cache
   * existing ports.
   */
  SendPort _toNewSendPort() {
    return new SendPortImpl(_currentWorkerId(), _currentIsolateId(), _id);
  }

  int _id;
  Function _callback = null;

  static int _nextFreeId = 1;

  void _register(int id) native;
  void _unregister(int id) native;

  static int _currentWorkerId() native;
  static int _currentIsolateId() native;

  static void _invokeCallback(ReceivePortImpl port, message, replyTo) native {
    if (port._callback !== null) (port._callback)(message, replyTo);
  }

  static int _getId(ReceivePortImpl port) native {
    return port._id;
  }
  static Function _getCallback(ReceivePortImpl port) native {
    return port._callback;
  }
}


class ReceivePortSingleShotImpl implements ReceivePort {

  ReceivePortSingleShotImpl() : _port = new ReceivePortImpl() { }

  void receive(void callback(var message, SendPort replyTo)) {
    _port.receive((var message, SendPort replyTo) {
      _port.close();
      callback(message, replyTo);
    });
  }

  void close() {
    _port.close();
  }

  SendPort toSendPort() {
    return _toNewSendPort();
  }

  /**
   * Returns a fresh [SendPort]. The implementation is not allowed to cache
   * existing ports.
   */
  SendPort _toNewSendPort() {
    return _port._toNewSendPort();
  }

  final ReceivePortImpl _port;

}

final String _SPAWNED_SIGNAL = "spawned";

class IsolateNatives {
  static Promise<SendPort> spawn(Isolate isolate, bool isLight) {
    Promise<SendPort> result = new Promise<SendPort>();
    ReceivePort port = new ReceivePort.singleShot();
    port.receive((msg, SendPort replyPort) {
      assert(msg == _SPAWNED_SIGNAL);
      result.complete(replyPort);
    });
    _spawn(isolate, isLight, port.toSendPort());
    return result;
  }

  static SendPort _spawn(Isolate isolate, bool light, SendPort port) native;
  static Function bind(Function f) native;
}


class _IsolateJsUtil {
  static void _promiseQueueProcess() native {
    PromiseQueue.process();
  }

  static void _startIsolate(Isolate isolate, SendPort replyTo) native {
    ReceivePort port = new ReceivePort();
    replyTo.send(_SPAWNED_SIGNAL, port.toSendPort());
    isolate._run(port);
  }

  static SendPort _toSendPort(port) native {
    return port.toSendPort();
  }

  static void _print(String msg) native {
    print(msg);
  }

  static _copyObject(obj) native {
    return new Copier().traverse(obj);
  }

  static _serializeObject(obj) native {
    return new Serializer().traverse(obj);
  }

  static _deserializeMessage(message) native {
    return new Deserializer().deserialize(message);
  }
}
