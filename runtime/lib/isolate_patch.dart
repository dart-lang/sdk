// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection" show HashMap;

patch class ReceivePort {
  /* patch */ factory ReceivePort() = _ReceivePortImpl;

  /* patch */ factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) =
      _ReceivePortImpl.fromRawReceivePort;
}

patch class Capability {
  /* patch */ factory Capability() = _CapabilityImpl;
}

class _CapabilityImpl implements Capability {
  factory _CapabilityImpl() native "CapabilityImpl_factory";
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

void _runPendingImmediateCallback() {
  if (_pendingImmediateCallback != null) {
    var callback = _pendingImmediateCallback;
    _pendingImmediateCallback = null;
    callback();
  }
}

/// The embedder can execute this function to get hold of
/// [_isolateScheduleImmediate] above.
Function _getIsolateScheduleImmediateClosure() {
  return _isolateScheduleImmediate;
}

class _RawReceivePortImpl implements RawReceivePort {
  factory _RawReceivePortImpl() native "RawReceivePortImpl_factory";

  close() {
    // Close the port and remove it from the handler map.
    _handlerMap.remove(this._closeInternal());
  }

  SendPort get sendPort {
    return _get_sendport();
  }

  bool operator==(var other) {
    return (other is _RawReceivePortImpl) &&
        (this._get_id() == other._get_id());
  }

  int get hashCode {
    return sendPort.hashCode();
  }

  /**** Internal implementation details ****/
  _get_id() native "RawReceivePortImpl_get_id";
  _get_sendport() native "RawReceivePortImpl_get_sendport";

  // Called from the VM to retrieve the handler for a message.
  static _lookupHandler(int id) {
    var result = _handlerMap[id];
    return result;
  }

  // Called from the VM to dispatch to the handler.
  static void _handleMessage(Function handler, var message) {
    // TODO(floitsch): this relies on the fact that any exception aborts the
    // VM. Once we have non-fatal global exceptions we need to catch errors
    // so that we can run the immediate callbacks.
    handler(message);
    _runPendingImmediateCallback();
  }

  // Call into the VM to close the VM maintained mappings.
  _closeInternal() native "RawReceivePortImpl_closeInternal";

  void set handler(Function value) {
    _handlerMap[this._get_id()] = value;
  }

  // TODO(iposva): Ideally keep this map in the VM.
  // id to handler mapping.
  static _initHandlerMap() {
    // TODO(18511): Workaround bad CheckSmi hoisting.
    var tempMap = new HashMap();
    // Collect feedback that not all keys are Smis.
    tempMap["."] = 1;
    tempMap["."] = 2;

    return new HashMap();
  }
  static final Map _handlerMap = _initHandlerMap();
}


class _SendPortImpl implements SendPort {
  /*--- public interface ---*/
  void send(var message) {
    _sendInternal(message);
  }

  bool operator==(var other) {
    return (other is _SendPortImpl) && (this._get_id() == other._get_id());
  }

  int get hashCode {
    return _get_hashcode();
  }

  /*--- private implementation ---*/
  _get_id() native "SendPortImpl_get_id";
  _get_hashcode() native "SendPortImpl_get_hashcode";

  // Forward the implementation of sending messages to the VM.
  void _sendInternal(var message) native "SendPortImpl_sendInternal_";
}

typedef _MainFunction();
typedef _MainFunctionArgs(args);
typedef _MainFunctionArgsMessage(args, message);

/**
 * Takes the real entry point as argument and invokes it with the
 * initial message.  Defers execution of the entry point until the
 * isolate is in the message loop.
 */
void _startMainIsolate(Function entryPoint,
                       List<String> args) {
  RawReceivePort port = new RawReceivePort();
  port.handler = (_) {
    port.close();
    _startIsolate(null,   // no parent port
                  entryPoint,
                  args,
                  null,   // no message
                  true,   // isSpawnUri
                  null,   // no control port
                  null);  // no capabilities
  };
  port.sendPort.send(null);
}

/**
 * Takes the real entry point as argument and invokes it with the initial
 * message.
 */
void _startIsolate(SendPort parentPort,
                   Function entryPoint,
                   List<String> args,
                   var message,
                   bool isSpawnUri,
                   RawReceivePort controlPort,
                   List capabilities) {
  if (controlPort != null) {
    controlPort.handler = (_) {};  // Nobody home on the control port.
  }
  if (parentPort != null) {
    // Build a message to our parent isolate providing access to the
    // current isolate's control port and capabilities.
    //
    // TODO(floitsch): Send an error message if we can't find the entry point.
    var readyMessage = new List(2);
    readyMessage[0] = controlPort.sendPort;
    readyMessage[1] = capabilities;

    // Out of an excess of paranoia we clear the capabilities from the
    // stack.  Not really necessary.
    capabilities = null;
    parentPort.send(readyMessage);
  }
  assert(capabilities == null);

  if (isSpawnUri) {
    if (entryPoint is _MainFunctionArgsMessage) {
      entryPoint(args, message);
    } else if (entryPoint is _MainFunctionArgs) {
      entryPoint(args);
    } else {
      entryPoint();
    }
  } else {
    entryPoint(message);
  }
  _runPendingImmediateCallback();
}

patch class Isolate {
  /* patch */ static Future<Isolate> spawn(
      void entryPoint(message), var message, { bool paused: false }) {
    // `paused` isn't handled yet.
    RawReceivePort readyPort;
    try {
      // The VM will invoke [_startIsolate] with entryPoint as argument.
      readyPort = new RawReceivePort();
      _spawnFunction(readyPort.sendPort, entryPoint, message);
      Completer completer = new Completer<Isolate>.sync();
      readyPort.handler = (readyMessage) {
        readyPort.close();
        assert(readyMessage is List);
        assert(readyMessage.length == 2);
        SendPort controlPort = readyMessage[0];
        List capabilities = readyMessage[1];
        completer.complete(new Isolate(controlPort,
                                       pauseCapability: capabilities[0],
                                       terminateCapability: capabilities[1]));
      };
      return completer.future;
    } catch (e, st) {
      if (readyPort != null) {
        readyPort.close();
      }
      return new Future<Isolate>.error(e, st);
    };
  }

  /* patch */ static Future<Isolate> spawnUri(
      Uri uri, List<String> args, var message,
      { bool paused: false, Uri packageRoot }) {
    // `paused` isn't handled yet.
    RawReceivePort readyPort;
    try {
      // The VM will invoke [_startIsolate] and not `main`.
      readyPort = new RawReceivePort();
      var packageRootString =
          (packageRoot == null) ? null : packageRoot.toString();
      _spawnUri(
          readyPort.sendPort, uri.toString(), args, message, packageRootString);
      Completer completer = new Completer<Isolate>.sync();
      readyPort.handler = (readyMessage) {
        readyPort.close();
        assert(readyMessage is List);
        assert(readyMessage.length == 2);
        SendPort controlPort = readyMessage[0];
        List capabilities = readyMessage[1];
        completer.complete(new Isolate(controlPort,
                                       pauseCapability: capabilities[0],
                                       terminateCapability: capabilities[1]));
      };
      return completer.future;
    } catch (e, st) {
      if (readyPort != null) {
        readyPort.close();
      }
      return new Future<Isolate>.error(e, st);
    };
    return completer.future;
  }

  // TODO(iposva): Cleanup to have only one definition.
  // These values need to be kept in sync with the class IsolateMessageHandler
  // in vm/isolate.cc.
  static const _PAUSE = 1;
  static const _RESUME = 2;

  static SendPort _spawnFunction(SendPort readyPort, Function topLevelFunction,
                                 var message)
      native "Isolate_spawnFunction";

  static SendPort _spawnUri(SendPort readyPort, String uri,
                            List<String> args, var message,
                            String packageRoot)
      native "Isolate_spawnUri";

  static void _sendOOB(port, msg) native "Isolate_sendOOB";

  /* patch */ void _pause(Capability resumeCapability) {
    var msg = new List(4)
        ..[0] = 0  // Make room for OOM message type.
        ..[1] = _PAUSE
        ..[2] = pauseCapability
        ..[3] = resumeCapability;
    _sendOOB(controlPort, msg);
  }

  /* patch */ void resume(Capability resumeCapability) {
    var msg = new List(4)
        ..[0] = 0  // Make room for OOM message type.
        ..[1] = _RESUME
        ..[2] = pauseCapability
        ..[3] = resumeCapability;
    _sendOOB(controlPort, msg);
  }

  /* patch */ void addOnExitListener(SendPort responsePort) {
    throw new UnsupportedError("addOnExitListener");
  }

  /* patch */ void removeOnExitListener(SendPort responsePort) {
    throw new UnsupportedError("removeOnExitListener");
  }

  /* patch */ void setErrorsFatal(bool errorsAreFatal) {
    throw new UnsupportedError("setErrorsFatal");
  }

  /* patch */ void kill([int priority = BEFORE_NEXT_EVENT]) {
    throw new UnsupportedError("kill");
  }

  /* patch */ void ping(SendPort responsePort, [int pingType = IMMEDIATE]) {
    throw new UnsupportedError("ping");
  }

  /* patch */ void addErrorListener(SendPort port) {
    throw new UnsupportedError("addErrorListener");
  }

  /* patch */ void removeErrorListener(SendPort port) {
    throw new UnsupportedError("removeErrorListener");
  }
}
