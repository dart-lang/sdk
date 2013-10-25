// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class ReceivePort {
  /* patch */ factory ReceivePort() = _ReceivePortImpl;

  /* patch */ factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) =
      _ReceivePortImpl.fromRawReceivePort;
}

patch class RawReceivePort {
  /**
   * Opens a long-lived port for receiving messages.
   *
   * A [RawReceivePort] is low level and does not work with [Zone]s. It
   * can not be paused. The data-handler must be set before the first
   * event is received.
   */
  /* patch */ factory RawReceivePort([void handler(event)]) {
    _RawReceivePortImpl result = new _RawReceivePortImpl();
    result.handler = handler;
    return result;
  }
}

class _ReceivePortImpl extends Stream implements ReceivePort {
  _ReceivePortImpl() : this.fromRawReceivePort(new RawReceivePort());

  _ReceivePortImpl.fromRawReceivePort(this._rawPort) {
    _controller = new StreamController(onCancel: close, sync: true);
    _rawPort.handler = _controller.add;
  }

  SendPort get sendPort {
    return _rawPort.sendPort;
  }

  StreamSubscription listen(void onData(var message),
                            { Function onError,
                              void onDone(),
                              bool cancelOnError }) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  close() {
    _rawPort.close();
    _controller.close();
  }

  final RawReceivePort _rawPort;
  StreamController _controller;
}

class _RawReceivePortImpl implements RawReceivePort {
  factory _RawReceivePortImpl() native "RawReceivePortImpl_factory";

  close() {
    _portMap.remove(_id);
    _closeInternal(_id);
  }

  SendPort get sendPort {
    return new _SendPortImpl(_id);
  }

  /**** Internal implementation details ****/
  // Called from the VM to create a new RawReceivePort instance.
  static _RawReceivePortImpl _get_or_create(int id) {
    _RawReceivePortImpl port = _portMap[id];
    if (port != null) {
      return port;
    }
    return new _RawReceivePortImpl._internal(id);
  }

  _RawReceivePortImpl._internal(int id) : _id = id {
    _portMap[id] = this;
  }

  // Called from the VM to retrieve the RawReceivePort for a message.
  static _RawReceivePortImpl _lookupReceivePort(int id) {
    return _portMap[id];
  }

  // Called from the VM to dispatch to the handler.
  static void _handleMessage(
      _RawReceivePortImpl port, int replyId, var message) {
    assert(port != null);
    port._handler(message);
  }

  // Call into the VM to close the VM maintained mappings.
  static _closeInternal(int id) native "RawReceivePortImpl_closeInternal";

  void set handler(Function newHandler) {
    this._handler = newHandler;
  }

  final int _id;
  Function _handler;

  // id to RawReceivePort mapping.
  static final Map _portMap = new HashMap();
}


class _SendPortImpl implements SendPort {
  /*--- public interface ---*/
  void send(var message, [SendPort replyTo = null]) {
    this._sendNow(message, replyTo);
  }

  void _sendNow(var message, SendPort replyTo) {
    int replyId = (replyTo == null) ? 0 : replyTo._id;
    _sendInternal(_id, replyId, message);
  }

  bool operator==(var other) {
    return (other is _SendPortImpl) && _id == other._id;
  }

  int get hashCode {
    const int MASK = 0x3FFFFFFF;
    int hash = _id;
    hash = (hash + ((hash & (MASK >> 10)) << 10)) & MASK;
    hash ^= (hash >> 6);
    hash = (hash + ((hash & (MASK >> 3)) << 3)) & MASK;
    hash ^= (hash >> 11);
    hash = (hash + ((hash & (MASK >> 15)) << 15)) & MASK;
    return hash;
  }

  /*--- private implementation ---*/
  const _SendPortImpl(int id) : _id = id;

  // _SendPortImpl._create is called from the VM when a new SendPort instance is
  // needed by the VM code.
  static SendPort _create(int id) {
    return new _SendPortImpl(id);
  }

  // Forward the implementation of sending messages to the VM. Only port ids
  // are being handed to the VM.
  static _sendInternal(int sendId, int replyId, var message)
      native "SendPortImpl_sendInternal_";

  final int _id;
}

_getPortInternal() native "isolate_getPortInternal";

typedef _MainFunction();
typedef _MainFunctionArgs(args);
typedef _MainFunctionArgsMessage(args, message);

/**
 * Takes the real entry point as argument and invokes it with the initial
 * message.
 *
 * The initial message is (currently) received through the global port variable.
 */
void _startIsolate(Function entryPoint, bool isSpawnUri) {
  Isolate._port.first.then((message) {
    SendPort replyTo = message[0];
    // TODO(floitsch): don't send ok-message if we can't find the entry point.
    replyTo.send("started");
    if (isSpawnUri) {
      assert(message.length == 3);
      List<String> args = message[1];
      var isolateMessage = message[2];
      if (entryPoint is _MainFunctionArgsMessage) {
        entryPoint(args, isolateMessage);
      } else if (entryPoint is _MainFunctionArgs) {
        entryPoint(args);
      } else {
        entryPoint();
      }
    } else {
      assert(message.length == 2);
      var entryMessage = message[1];
      entryPoint(entryMessage);
    }
  });
}

patch class Isolate {
  /* patch */ static Future<Isolate> spawn(
      void entryPoint(message), var message) {
    Completer completer = new Completer<Isolate>.sync();
    try {
      // The VM will invoke [_startIsolate] with entryPoint as argument.
      SendPort controlPort = _spawnFunction(entryPoint);
      RawReceivePort readyPort = new RawReceivePort();
      controlPort.send([readyPort.sendPort, message]);
      readyPort.handler = (readyMessage) {
        assert(readyMessage == 'started');
        readyPort.close();
        completer.complete(new Isolate._fromControlPort(controlPort));
      };
    } catch(e, st) {
      // TODO(floitsch): we want errors to go into the returned future.
      rethrow;
    };
    return completer.future;
  }

  /* patch */ static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message) {
    Completer completer = new Completer<Isolate>.sync();
    try {
      // The VM will invoke [_startIsolate] and not `main`.
      SendPort controlPort = _spawnUri(uri.toString());
      RawReceivePort readyPort = new RawReceivePort();
      controlPort.send([readyPort.sendPort, args, message]);
      readyPort.handler = (readyMessage) {
        assert(readyMessage == 'started');
        readyPort.close();
        completer.complete(new Isolate._fromControlPort(controlPort));
      };
    } catch(e, st) {
      // TODO(floitsch): we want errors to go into the returned future.
      rethrow;
    };
    return completer.future;
  }

  static final ReceivePort _port =
      new ReceivePort.fromRawReceivePort(_getPortInternal());

  static SendPort _spawnFunction(Function topLevelFunction)
      native "isolate_spawnFunction";

  static SendPort _spawnUri(String uri) native "isolate_spawnUri";
}
