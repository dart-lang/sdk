// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection" show HashMap;

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

typedef void ImmediateCallback();

/// The callback that has been registered through `scheduleImmediate`.
ImmediateCallback _pendingImmediateCallback;

/// The closure that should be used as scheduleImmediateClosure, when the VM
/// is responsible for the event loop.
void _isolateScheduleImmediate(void callback()) {
  assert(_pendingImmediateCallback == null);
  _pendingImmediateCallback = callback;
}

/// The embedder can execute this function to get hold of
/// [_isolateScheduleImmediate] above.
Function _getIsolateScheduleImmediateClosure() {
  return _isolateScheduleImmediate;
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
  static void _handleMessage(_RawReceivePortImpl port, var message) {
    assert(port != null);
    // TODO(floitsch): this relies on the fact that any exception aborts the
    // VM. Once we have non-fatal global exceptions we need to catch errors
    // so that we can run the immediate callbacks.
    port._handler(message);
    if (_pendingImmediateCallback != null) {
      var callback = _pendingImmediateCallback;
      _pendingImmediateCallback = null;
      callback();
    }
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
  void send(var message) {
    _sendInternal(_id, message);
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
  static _sendInternal(int sendId, var message)
      native "SendPortImpl_sendInternal_";

  final int _id;
}

typedef _MainFunction();
typedef _MainFunctionArgs(args);
typedef _MainFunctionArgsMessage(args, message);

/**
 * Takes the real entry point as argument and invokes it with the initial
 * message.
 *
 * The initial startup message is received through the control port.
 */
void _startIsolate(Function entryPoint, bool isSpawnUri) {
  // This port keeps the isolate alive until the initial startup message has
  // been received.
  var keepAlivePort = new RawReceivePort();

  ignoreHandler(message) {
    // Messages on the current Isolate's control port are dropped after the
    // initial startup message has been received.
  }

  isolateStartHandler(message) {
    // We received the initial startup message. Ignore all further messages and
    // close the port which kept this isolate alive.
    Isolate._self.handler = ignoreHandler;
    keepAlivePort.close();

    SendPort replyTo = message[0];
    if (replyTo != null) {
      // TODO(floitsch): don't send ok-message if we can't find the entry point.
      replyTo.send("started");
    }
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
  }

  Isolate._self.handler = isolateStartHandler;
}

patch class Isolate {
  /* patch */ static Future<Isolate> spawn(
      void entryPoint(message), var message, { bool paused: false }) {
    // `paused` isn't handled yet.
    try {
      // The VM will invoke [_startIsolate] with entryPoint as argument.
      SendPort controlPort = _spawnFunction(entryPoint);
      RawReceivePort readyPort = new RawReceivePort();
      controlPort.send([readyPort.sendPort, message]);
      Completer completer = new Completer<Isolate>.sync();
      readyPort.handler = (readyMessage) {
        assert(readyMessage == 'started');
        readyPort.close();
        completer.complete(new Isolate(controlPort));
      };
      return completer.future;
    } catch (e, st) {
      return new Future<Isolate>.error(e, st);
    };
  }

  /* patch */ static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message, { bool paused: false }) {
    // `paused` isn't handled yet.
    try {
      // The VM will invoke [_startIsolate] and not `main`.
      SendPort controlPort = _spawnUri(uri.toString());
      RawReceivePort readyPort = new RawReceivePort();
      controlPort.send([readyPort.sendPort, args, message]);
      Completer completer = new Completer<Isolate>.sync();
      readyPort.handler = (readyMessage) {
        assert(readyMessage == 'started');
        readyPort.close();
        completer.complete(new Isolate(controlPort));
      };
      return completer.future;
    } catch (e, st) {
      return new Future<Isolate>.error(e, st);
    };
    return completer.future;
  }

  static final RawReceivePort _self = _mainPort;
  static RawReceivePort get _mainPort native "Isolate_mainPort";

  static SendPort _spawnFunction(Function topLevelFunction)
      native "Isolate_spawnFunction";

  static SendPort _spawnUri(String uri) native "Isolate_spawnUri";
}

patch class Capability {
  /* patch */ factory Capability() {
    throw new UnimplementedError();
  }
}
