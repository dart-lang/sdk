// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common functionality to all send ports. */
class _BaseSendPort implements SendPort {
  /** Id for the destination isolate. */
  final int _isolateId;

  const _BaseSendPort(this._isolateId);

  static void checkReplyTo(SendPort replyTo) {
    if (replyTo !== null
        && replyTo is! _NativeJsSendPort
        && replyTo is! _WorkerSendPort
        && replyTo is! _BufferingSendPort) {
      throw new Exception("SendPort.send: Illegal replyTo port type");
    }
  }

  Future call(var message) {
    final completer = new Completer();
    final port = new _ReceivePortImpl();
    send(message, port.toSendPort());
    port.receive((value, ignoreReplyTo) {
      port.close();
      if (value is Exception) {
        completer.completeException(value);
      } else {
        completer.complete(value);
      }
    });
    return completer.future;
  }

  abstract void send(var message, [SendPort replyTo]);
  abstract bool operator ==(var other);
  abstract int hashCode();
}

/** A send port that delivers messages in-memory via native JavaScript calls. */
class _NativeJsSendPort extends _BaseSendPort implements SendPort {
  final _ReceivePortImpl _receivePort;

  const _NativeJsSendPort(this._receivePort, int isolateId) : super(isolateId);

  void send(var message, [SendPort replyTo = null]) {
    _waitForPendingPorts([message, replyTo], () {
      checkReplyTo(replyTo);
      // Check that the isolate still runs and the port is still open
      final isolate = _globalState.isolates[_isolateId];
      if (isolate == null) return;
      if (_receivePort._callback == null) return;

      // We force serialization/deserialization as a simple way to ensure
      // isolate communication restrictions are respected between isolates that
      // live in the same worker. [_NativeJsSendPort] delivers both messages
      // from the same worker and messages from other workers. In particular,
      // messages sent from a worker via a [_WorkerSendPort] are received at
      // [_processWorkerMessage] and forwarded to a native port. In such cases,
      // here we'll see [_globalState.currentContext == null].
      final shouldSerialize = _globalState.currentContext != null
          && _globalState.currentContext.id != _isolateId;
      var msg = message;
      var reply = replyTo;
      if (shouldSerialize) {
        msg = _serializeMessage(msg);
        reply = _serializeMessage(reply);
      }
      _globalState.topEventLoop.enqueue(isolate, () {
        if (_receivePort._callback != null) {
          if (shouldSerialize) {
            msg = _deserializeMessage(msg);
            reply = _deserializeMessage(reply);
          }
          _receivePort._callback(msg, reply);
        }
      }, 'receive $message');
    });
  }

  bool operator ==(var other) => (other is _NativeJsSendPort) &&
      (_receivePort == other._receivePort);

  int hashCode() => _receivePort._id;
}

/** A send port that delivers messages via worker.postMessage. */
// TODO(eub): abstract this for iframes.
class _WorkerSendPort extends _BaseSendPort implements SendPort {
  final int _workerId;
  final int _receivePortId;

  const _WorkerSendPort(this._workerId, int isolateId, this._receivePortId)
      : super(isolateId);

  void send(var message, [SendPort replyTo = null]) {
    _waitForPendingPorts([message, replyTo], () {
      checkReplyTo(replyTo);
      final workerMessage = _serializeMessage({
          'command': 'message',
          'port': this,
          'msg': message,
          'replyTo': replyTo});

      if (_globalState.isWorker) {
        // communication from one worker to another go through the main worker:
        _globalState.mainManager.postMessage(workerMessage);
      } else {
        _globalState.managers[_workerId].postMessage(workerMessage);
      }
    });
  }

  bool operator ==(var other) {
    return (other is _WorkerSendPort) &&
        (_workerId == other._workerId) &&
        (_isolateId == other._isolateId) &&
        (_receivePortId == other._receivePortId);
  }

  int hashCode() {
    // TODO(sigmund): use a standard hash when we get one available in corelib.
    return (_workerId << 16) ^ (_isolateId << 8) ^ _receivePortId;
  }
}

/** A port that buffers messages until an underlying port gets resolved. */
class _BufferingSendPort extends _BaseSendPort implements SendPort {
  /** Internal counter to assign unique ids to each port. */
  static int _idCount = 0;

  /** For implementing equals and hashcode. */
  final int _id;

  /** Underlying port, when resolved. */
  SendPort _port;

  /**
   * Future of the underlying port, so that we can detect when this port can be
   * sent on messages.
   */
  Future<SendPort> _futurePort;

  /** Pending messages (and reply ports). */
  List pending;

  _BufferingSendPort(isolateId, this._futurePort)
      : super(isolateId), _id = _idCount, pending = [] {
    _idCount++;
    _futurePort.then((p) {
      _port = p;
      for (final item in pending) {
        p.send(item['message'], item['replyTo']);
      }
      pending = null;
    });
  }

  _BufferingSendPort.fromPort(isolateId, this._port)
      : super(isolateId), _id = _idCount {
    _idCount++;
  }

  void send(var message, [SendPort replyTo]) {
    if (_port != null) {
      _port.send(message, replyTo);
    } else {
      pending.add({'message': message, 'replyTo': replyTo});
    }
  }

  bool operator ==(var other) =>
      other is _BufferingSendPort && _id == other._id;
  int hashCode() => _id;
}

/** Default factory for receive ports. */
class _ReceivePortFactory {

  factory ReceivePort() {
    return new _ReceivePortImpl();
  }

}

/** Implementation of a multi-use [ReceivePort] on top of JavaScript. */
class _ReceivePortImpl implements ReceivePort {
  int _id;
  Function _callback;
  static int _nextFreeId = 1;

  _ReceivePortImpl()
      : _id = _nextFreeId++ {
    _globalState.currentContext.register(_id, this);
  }

  void receive(void onMessage(var message, SendPort replyTo)) {
    _callback = onMessage;
  }

  void close() {
    _callback = null;
    _globalState.currentContext.unregister(_id);
  }

  SendPort toSendPort() {
    return new _NativeJsSendPort(this, _globalState.currentContext.id);
  }
}

/** Wait until all ports in a message are resolved. */
_waitForPendingPorts(var message, void callback()) {
  final finder = new _PendingSendPortFinder();
  finder.traverse(message);
  Futures.wait(finder.ports).then((_) => callback());
}


/** Visitor that finds all unresolved [SendPort]s in a message. */
class _PendingSendPortFinder extends _MessageTraverser {
  List<Future<SendPort>> ports;
  _PendingSendPortFinder() : super(), ports = [];

  visitPrimitive(x) {}
  visitNativeJsSendPort(_NativeJsSendPort port) {}
  visitWorkerSendPort(_WorkerSendPort port) {}

  visitList(List list) {
    final visited = _getInfo(list);
    if (visited !== null) return;
    _attachInfo(list, true);
    // TODO(sigmund): replace with the following: (bug #1660)
    // list.forEach(_dispatch);
    list.forEach((e) => _dispatch(e));
  }

  visitMap(Map map) {
    final visited = _getInfo(map);
    if (visited !== null) return;

    _attachInfo(map, true);
    // TODO(sigmund): replace with the following: (bug #1660)
    // map.getValues().forEach(_dispatch);
    map.getValues().forEach((e) => _dispatch(e));
  }

  visitBufferingSendPort(_BufferingSendPort port) {
    if (port._port == null) {
      ports.add(port._futurePort);
    }
  }
}
