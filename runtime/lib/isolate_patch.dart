// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:isolate" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal" show VMLibraryHooks, patch;

import "dart:async"
    show Completer, Future, Stream, StreamController, StreamSubscription, Timer;

import "dart:collection" show HashMap;

/// These are the additional parts of this patch library:
// part "timer_impl.dart";

@patch
class ReceivePort {
  @patch
  factory ReceivePort() = _ReceivePortImpl;

  @patch
  factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) =
      _ReceivePortImpl.fromRawReceivePort;
}

@patch
class Capability {
  @patch
  factory Capability() = _CapabilityImpl;
}

class _CapabilityImpl implements Capability {
  factory _CapabilityImpl() native "CapabilityImpl_factory";

  bool operator ==(var other) {
    return (other is _CapabilityImpl) && _equals(other);
  }

  int get hashCode {
    return _get_hashcode();
  }

  _equals(other) native "CapabilityImpl_equals";
  _get_hashcode() native "CapabilityImpl_get_hashcode";
}

@patch
class RawReceivePort {
  /**
   * Opens a long-lived port for receiving messages.
   *
   * A [RawReceivePort] is low level and does not work with [Zone]s. It
   * can not be paused. The data-handler must be set before the first
   * event is received.
   */
  @patch
  factory RawReceivePort([Function handler]) {
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
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  close() {
    _rawPort.close();
    _controller.close();
  }

  final RawReceivePort _rawPort;
  StreamController _controller;
}

typedef void _ImmediateCallback();

/// The callback that has been registered through `scheduleImmediate`.
_ImmediateCallback _pendingImmediateCallback;

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

_ImmediateCallback _removePendingImmediateCallback() {
  var callback = _pendingImmediateCallback;
  _pendingImmediateCallback = null;
  return callback;
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

  bool operator ==(var other) {
    return (other is _RawReceivePortImpl) &&
        (this._get_id() == other._get_id());
  }

  int get hashCode {
    return sendPort.hashCode;
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

  bool operator ==(var other) {
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

typedef _NullaryFunction();
typedef _UnaryFunction(Null args);
typedef _BinaryFunction(Null args, Null message);

/**
 * Takes the real entry point as argument and invokes it with the
 * initial message.  Defers execution of the entry point until the
 * isolate is in the message loop.
 */
void _startMainIsolate(Function entryPoint, List<String> args) {
  _startIsolate(
      null, // no parent port
      entryPoint,
      args,
      null, // no message
      true, // isSpawnUri
      null, // no control port
      null); // no capabilities
}

/**
 * Takes the real entry point as argument and invokes it with the initial
 * message.
 */
void _startIsolate(
    SendPort parentPort,
    Function entryPoint,
    List<String> args,
    var message,
    bool isSpawnUri,
    RawReceivePort controlPort,
    List capabilities) {
  // The control port (aka the main isolate port) does not handle any messages.
  if (controlPort != null) {
    controlPort.handler = (_) {}; // Nobody home on the control port.
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

  // Delay all user code handling to the next run of the message loop. This
  // allows us to intercept certain conditions in the event dispatch, such as
  // starting in paused state.
  RawReceivePort port = new RawReceivePort();
  port.handler = (_) {
    port.close();

    if (isSpawnUri) {
      if (entryPoint is _BinaryFunction) {
        (entryPoint as dynamic)(args, message);
      } else if (entryPoint is _UnaryFunction) {
        (entryPoint as dynamic)(args);
      } else {
        entryPoint();
      }
    } else {
      entryPoint(message);
    }
  };
  // Make sure the message handler is triggered.
  port.sendPort.send(null);
}

@patch
class Isolate {
  static final _currentIsolate = _getCurrentIsolate();
  static final _rootUri = _getCurrentRootUri();

  @patch
  static Isolate get current => _currentIsolate;

  @patch
  static Future<Uri> get packageRoot {
    var hook = VMLibraryHooks.packageRootUriFuture;
    if (hook == null) {
      throw new UnsupportedError("Isolate.packageRoot");
    }
    return hook();
  }

  @patch
  static Future<Uri> get packageConfig {
    var hook = VMLibraryHooks.packageConfigUriFuture;
    if (hook == null) {
      throw new UnsupportedError("Isolate.packageConfig");
    }
    return hook();
  }

  @patch
  static Future<Uri> resolvePackageUri(Uri packageUri) {
    var hook = VMLibraryHooks.resolvePackageUriFuture;
    if (hook == null) {
      throw new UnsupportedError("Isolate.resolvePackageUri");
    }
    return hook(packageUri);
  }

  static bool _packageSupported() =>
      (VMLibraryHooks.packageRootUriFuture != null) &&
      (VMLibraryHooks.packageConfigUriFuture != null) &&
      (VMLibraryHooks.resolvePackageUriFuture != null);

  @patch
  static Future<Isolate> spawn(void entryPoint(message), var message,
      {bool paused: false,
      bool errorsAreFatal,
      SendPort onExit,
      SendPort onError}) async {
    // `paused` isn't handled yet.
    RawReceivePort readyPort;
    try {
      // Check for the type of `entryPoint` on the spawning isolate to make
      // error-handling easier.
      if (entryPoint is! _UnaryFunction) {
        throw new ArgumentError(entryPoint);
      }
      // The VM will invoke [_startIsolate] with entryPoint as argument.
      readyPort = new RawReceivePort();

      // We do not inherit the package root or package config settings
      // from the parent isolate, instead we use the values that were
      // set on the command line.
      var packageRoot = VMLibraryHooks.packageRootString;
      var packageConfig = VMLibraryHooks.packageConfigString;
      var script = VMLibraryHooks.platformScript;
      if (script == null) {
        // We do not have enough information to support spawning the new
        // isolate.
        throw new UnsupportedError("Isolate.spawn");
      }
      if (script.scheme == "package") {
        script = await Isolate.resolvePackageUri(script);
      }

      _spawnFunction(readyPort.sendPort, script.toString(), entryPoint, message,
          paused, errorsAreFatal, onExit, onError, packageRoot, packageConfig);
      return await _spawnCommon(readyPort);
    } catch (e, st) {
      if (readyPort != null) {
        readyPort.close();
      }
      return await new Future<Isolate>.error(e, st);
    }
  }

  @patch
  static Future<Isolate> spawnUri(Uri uri, List<String> args, var message,
      {bool paused: false,
      SendPort onExit,
      SendPort onError,
      bool errorsAreFatal,
      bool checked,
      Map<String, String> environment,
      Uri packageRoot,
      Uri packageConfig,
      bool automaticPackageResolution: false}) async {
    RawReceivePort readyPort;
    if (environment != null) {
      throw new UnimplementedError("environment");
    }

    // Verify that no mutually exclusive arguments have been passed.
    if (automaticPackageResolution) {
      if (packageRoot != null) {
        throw new ArgumentError("Cannot simultaneously request "
            "automaticPackageResolution and specify a"
            "packageRoot.");
      }
      if (packageConfig != null) {
        throw new ArgumentError("Cannot simultaneously request "
            "automaticPackageResolution and specify a"
            "packageConfig.");
      }
    } else {
      if ((packageRoot != null) && (packageConfig != null)) {
        throw new ArgumentError("Cannot simultaneously specify a "
            "packageRoot and a packageConfig.");
      }
    }
    try {
      // Resolve the uri against the current isolate's root Uri first.
      var spawnedUri = _rootUri.resolveUri(uri);

      // Inherit this isolate's package resolution setup if not overridden.
      if (!automaticPackageResolution &&
          (packageRoot == null) &&
          (packageConfig == null)) {
        if (Isolate._packageSupported()) {
          packageRoot = await Isolate.packageRoot;
          packageConfig = await Isolate.packageConfig;
        }
      }

      // Ensure to resolve package: URIs being handed in as parameters.
      if (packageRoot != null) {
        // Avoid calling resolvePackageUri if not stricly necessary in case
        // the API is not supported.
        if (packageRoot.scheme == "package") {
          packageRoot = await Isolate.resolvePackageUri(packageRoot);
        }
      } else if (packageConfig != null) {
        // Avoid calling resolvePackageUri if not strictly necessary in case
        // the API is not supported.
        if (packageConfig.scheme == "package") {
          packageConfig = await Isolate.resolvePackageUri(packageConfig);
        }
      }

      // The VM will invoke [_startIsolate] and not `main`.
      readyPort = new RawReceivePort();
      var packageRootString = packageRoot?.toString();
      var packageConfigString = packageConfig?.toString();

      _spawnUri(
          readyPort.sendPort,
          spawnedUri.toString(),
          args,
          message,
          paused,
          onExit,
          onError,
          errorsAreFatal,
          checked,
          null,
          /* environment */
          packageRootString,
          packageConfigString);
      return await _spawnCommon(readyPort);
    } catch (e, st) {
      if (readyPort != null) {
        readyPort.close();
      }
      rethrow;
    }
  }

  static Future<Isolate> _spawnCommon(RawReceivePort readyPort) {
    Completer completer = new Completer<Isolate>.sync();
    readyPort.handler = (readyMessage) {
      readyPort.close();
      if (readyMessage is List && readyMessage.length == 2) {
        SendPort controlPort = readyMessage[0];
        List capabilities = readyMessage[1];
        completer.complete(new Isolate(controlPort,
            pauseCapability: capabilities[0],
            terminateCapability: capabilities[1]));
      } else if (readyMessage is String) {
        // We encountered an error while starting the new isolate.
        completer.completeError(new IsolateSpawnException(
            'Unable to spawn isolate: ${readyMessage}'));
      } else {
        // This shouldn't happen.
        completer.completeError(new IsolateSpawnException(
            "Internal error: unexpected format for ready message: "
            "'${readyMessage}'"));
      }
    };
    return completer.future;
  }

  // TODO(iposva): Cleanup to have only one definition.
  // These values need to be kept in sync with the class IsolateMessageHandler
  // in vm/isolate.cc.
  static const _PAUSE = 1;
  static const _RESUME = 2;
  static const _PING = 3;
  static const _KILL = 4;
  static const _ADD_EXIT = 5;
  static const _DEL_EXIT = 6;
  static const _ADD_ERROR = 7;
  static const _DEL_ERROR = 8;
  static const _ERROR_FATAL = 9;

  static void _spawnFunction(
      SendPort readyPort,
      String uri,
      Function topLevelFunction,
      var message,
      bool paused,
      bool errorsAreFatal,
      SendPort onExit,
      SendPort onError,
      String packageRoot,
      String packageConfig) native "Isolate_spawnFunction";

  static void _spawnUri(
      SendPort readyPort,
      String uri,
      List<String> args,
      var message,
      bool paused,
      SendPort onExit,
      SendPort onError,
      bool errorsAreFatal,
      bool checked,
      List environment,
      String packageRoot,
      String packageConfig) native "Isolate_spawnUri";

  static void _sendOOB(port, msg) native "Isolate_sendOOB";

  @patch
  void _pause(Capability resumeCapability) {
    var msg = new List(4)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _PAUSE
      ..[2] = pauseCapability
      ..[3] = resumeCapability;
    _sendOOB(controlPort, msg);
  }

  @patch
  void resume(Capability resumeCapability) {
    var msg = new List(4)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _RESUME
      ..[2] = pauseCapability
      ..[3] = resumeCapability;
    _sendOOB(controlPort, msg);
  }

  @patch
  void addOnExitListener(SendPort responsePort, {Object response}) {
    var msg = new List(4)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _ADD_EXIT
      ..[2] = responsePort
      ..[3] = response;
    _sendOOB(controlPort, msg);
  }

  @patch
  void removeOnExitListener(SendPort responsePort) {
    var msg = new List(3)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _DEL_EXIT
      ..[2] = responsePort;
    _sendOOB(controlPort, msg);
  }

  @patch
  void setErrorsFatal(bool errorsAreFatal) {
    var msg = new List(4)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _ERROR_FATAL
      ..[2] = terminateCapability
      ..[3] = errorsAreFatal;
    _sendOOB(controlPort, msg);
  }

  @patch
  void kill({int priority: BEFORE_NEXT_EVENT}) {
    var msg = new List(4)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _KILL
      ..[2] = terminateCapability
      ..[3] = priority;
    _sendOOB(controlPort, msg);
  }

  @patch
  void ping(SendPort responsePort, {Object response, int priority: IMMEDIATE}) {
    var msg = new List(5)
      ..[0] = 0 // Make room for OOM message type.
      ..[1] = _PING
      ..[2] = responsePort
      ..[3] = priority
      ..[4] = response;
    _sendOOB(controlPort, msg);
  }

  @patch
  void addErrorListener(SendPort port) {
    var msg = new List(3)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _ADD_ERROR
      ..[2] = port;
    _sendOOB(controlPort, msg);
  }

  @patch
  void removeErrorListener(SendPort port) {
    var msg = new List(3)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _DEL_ERROR
      ..[2] = port;
    _sendOOB(controlPort, msg);
  }

  static Isolate _getCurrentIsolate() {
    List portAndCapabilities = _getPortAndCapabilitiesOfCurrentIsolate();
    return new Isolate(portAndCapabilities[0],
        pauseCapability: portAndCapabilities[1],
        terminateCapability: portAndCapabilities[2]);
  }

  static List _getPortAndCapabilitiesOfCurrentIsolate()
      native "Isolate_getPortAndCapabilitiesOfCurrentIsolate";

  static Uri _getCurrentRootUri() {
    try {
      return Uri.parse(_getCurrentRootUriStr());
    } catch (e, s) {
      return null;
    }
  }

  static String _getCurrentRootUriStr() native "Isolate_getCurrentRootUriStr";
}
