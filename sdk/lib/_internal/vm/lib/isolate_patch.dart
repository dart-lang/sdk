// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:isolate" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal" show ClassID, VMLibraryHooks, patch;

import "dart:async"
    show Completer, Future, Stream, StreamController, StreamSubscription, Timer;

import "dart:collection" show HashMap;
import "dart:typed_data" show ByteBuffer, TypedData, Uint8List;
import "dart:_internal" show spawnFunction;

/// These are the additional parts of this patch library:
// part "timer_impl.dart";

@patch
class ReceivePort {
  @patch
  factory ReceivePort([String debugName = '']) =>
      new _ReceivePortImpl(debugName);

  @patch
  factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) {
    return new _ReceivePortImpl.fromRawReceivePort(rawPort);
  }
}

@patch
class Capability {
  @patch
  factory Capability() => new _CapabilityImpl();
}

@pragma("vm:entry-point")
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
  factory RawReceivePort([Function? handler, String debugName = '']) {
    _RawReceivePortImpl result = new _RawReceivePortImpl(debugName);
    result.handler = handler;
    return result;
  }
}

class _ReceivePortImpl extends Stream implements ReceivePort {
  _ReceivePortImpl([String debugName = ''])
      : this.fromRawReceivePort(new RawReceivePort(null, debugName));

  _ReceivePortImpl.fromRawReceivePort(this._rawPort)
      : _controller = new StreamController(sync: true) {
    _controller.onCancel = close;
    _rawPort.handler = _controller.add;
  }

  SendPort get sendPort {
    return _rawPort.sendPort;
  }

  StreamSubscription listen(void onData(var message)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  close() {
    _rawPort.close();
    _controller.close();
  }

  final RawReceivePort _rawPort;
  final StreamController _controller;
}

typedef void _ImmediateCallback();

/// The callback that has been registered through `scheduleImmediate`.
_ImmediateCallback? _pendingImmediateCallback;

/// The closure that should be used as scheduleImmediateClosure, when the VM
/// is responsible for the event loop.
void _isolateScheduleImmediate(void callback()) {
  assert((_pendingImmediateCallback == null) ||
      (_pendingImmediateCallback == callback));
  _pendingImmediateCallback = callback;
}

@pragma("vm:entry-point", "call")
void _runPendingImmediateCallback() {
  final callback = _pendingImmediateCallback;
  if (callback != null) {
    _pendingImmediateCallback = null;
    callback();
  }
}

/// The embedder can execute this function to get hold of
/// [_isolateScheduleImmediate] above.
@pragma("vm:entry-point", "call")
Function _getIsolateScheduleImmediateClosure() {
  return _isolateScheduleImmediate;
}

@pragma("vm:entry-point")
class _RawReceivePortImpl implements RawReceivePort {
  factory _RawReceivePortImpl(String debugName) {
    final port = _RawReceivePortImpl._(debugName);
    _portMap[port._get_id()] = <String, dynamic>{
      'port': port,
    };
    return port;
  }

  factory _RawReceivePortImpl._(String debugName)
      native "RawReceivePortImpl_factory";

  close() {
    // Close the port and remove it from the handler map.
    _portMap.remove(this._closeInternal());
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
  @pragma("vm:entry-point", "call")
  static _lookupHandler(int id) {
    var result = _portMap[id]?['handler'];
    return result;
  }

  @pragma("vm:entry-point", "call")
  static _lookupOpenPorts() {
    return _portMap.values.map((e) => e['port']).toList();
  }

  // Called from the VM to dispatch to the handler.
  @pragma("vm:entry-point", "call")
  static void _handleMessage(Function handler, var message) {
    // TODO(floitsch): this relies on the fact that any exception aborts the
    // VM. Once we have non-fatal global exceptions we need to catch errors
    // so that we can run the immediate callbacks.
    handler(message);
    _runPendingImmediateCallback();
  }

  // Call into the VM to close the VM maintained mappings.
  _closeInternal() native "RawReceivePortImpl_closeInternal";

  // Set this port as active or inactive in the VM. If inactive, this port
  // will not be considered live even if it hasn't been explicitly closed.
  // TODO(bkonyi): determine if we want to expose this as an option through
  // RawReceivePort.
  _setActive(bool active) native "RawReceivePortImpl_setActive";

  void set handler(Function? value) {
    final id = this._get_id();
    if (!_portMap.containsKey(id)) {
      _portMap[id] = <String, dynamic>{
        'port': this,
      };
    }
    _portMap[id]!['handler'] = value;
  }

  static final _portMap = <dynamic, Map<String, dynamic>>{};
}

@pragma("vm:entry-point")
class _SendPortImpl implements SendPort {
  factory _SendPortImpl._uninstantiable() {
    throw "Unreachable";
  }

  /*--- public interface ---*/
  @pragma("vm:entry-point", "call")
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
typedef _UnaryFunction(Never args);
typedef _BinaryFunction(Never args, Never message);

/**
 * Takes the real entry point as argument and schedules it to run in the message
 * queue.
 */
@pragma("vm:entry-point", "call")
void _startMainIsolate(Function entryPoint, List<String>? args) {
  _delayEntrypointInvocation(entryPoint, args, null, true);
}

/**
 * Returns the _startMainIsolate function. This closurization allows embedders
 * to setup trampolines to the main function. This workaround can be removed
 * once support for @pragma("vm:entry_point", "get") as documented in
 * https://github.com/dart-lang/sdk/issues/35720 lands.
 */
@pragma("vm:entry-point", "call")
Function _getStartMainIsolateFunction() {
  return _startMainIsolate;
}

/**
 * Takes the real entry point as argument and schedules it to run in the message
 * queue.
 */
@pragma("vm:entry-point", "call")
void _startIsolate(
    Function entryPoint, List<String>? args, Object? message, bool isSpawnUri) {
  _delayEntrypointInvocation(entryPoint, args, message, isSpawnUri);
}

void _delayEntrypointInvocation(Function entryPoint, List<String>? args,
    Object? message, bool allowZeroOneOrTwoArgs) {
  final port = RawReceivePort();
  port.handler = (_) {
    port.close();
    if (allowZeroOneOrTwoArgs) {
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
  port.sendPort.send(null);
}

@patch
class Isolate {
  static final _currentIsolate = _getCurrentIsolate();
  static final _rootUri = _getCurrentRootUri();

  @patch
  static Isolate get current => _currentIsolate;

  @patch
  String get debugName => _getDebugName(controlPort);

  @patch
  static Future<Uri?> get packageRoot {
    return Future.value(null);
  }

  @patch
  static Future<Uri?> get packageConfig {
    var hook = VMLibraryHooks.packageConfigUriFuture;
    if (hook == null) {
      throw new UnsupportedError("Isolate.packageConfig");
    }
    return hook();
  }

  @patch
  static Future<Uri?> resolvePackageUri(Uri packageUri) {
    var hook = VMLibraryHooks.resolvePackageUriFuture;
    if (hook == null) {
      throw new UnsupportedError("Isolate.resolvePackageUri");
    }
    return hook(packageUri);
  }

  static bool _packageSupported() =>
      (VMLibraryHooks.packageConfigUriFuture != null) &&
      (VMLibraryHooks.resolvePackageUriFuture != null);

  @patch
  static Future<Isolate> spawn<T>(void entryPoint(T message), T message,
      {bool paused = false,
      bool errorsAreFatal = true,
      SendPort? onExit,
      SendPort? onError,
      String? debugName}) async {
    // `paused` isn't handled yet.
    // Check for the type of `entryPoint` on the spawning isolate to make
    // error-handling easier.
    if (entryPoint is! _UnaryFunction) {
      throw new ArgumentError(entryPoint);
    }
    // The VM will invoke [_startIsolate] with entryPoint as argument.

    // We do not inherit the package config settings from the parent isolate,
    // instead we use the values that were set on the command line.
    var packageConfig = VMLibraryHooks.packageConfigString;
    var script = VMLibraryHooks.platformScript;
    if (script == null) {
      // We do not have enough information to support spawning the new
      // isolate.
      throw new UnsupportedError("Isolate.spawn");
    }
    if (script.isScheme("package")) {
      script = await Isolate.resolvePackageUri(script);
    }

    const bool newIsolateGroup = false;
    final RawReceivePort readyPort =
        new RawReceivePort(null, 'Isolate.spawn ready');
    try {
      spawnFunction(
          readyPort.sendPort,
          script.toString(),
          entryPoint,
          message,
          paused,
          errorsAreFatal,
          onExit,
          onError,
          packageConfig,
          newIsolateGroup,
          debugName);
      return await _spawnCommon(readyPort);
    } catch (e, st) {
      readyPort.close();
      return await new Future<Isolate>.error(e, st);
    }
  }

  @patch
  static Future<Isolate> spawnUri(Uri uri, List<String> args, var message,
      {bool paused = false,
      SendPort? onExit,
      SendPort? onError,
      bool errorsAreFatal = true,
      bool? checked,
      Map<String, String>? environment,
      Uri? packageRoot,
      Uri? packageConfig,
      bool automaticPackageResolution = false,
      String? debugName}) async {
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
    // Resolve the uri against the current isolate's root Uri first.
    final Uri spawnedUri = _rootUri!.resolveUri(uri);

    // Inherit this isolate's package resolution setup if not overridden.
    if (!automaticPackageResolution && packageConfig == null) {
      if (Isolate._packageSupported()) {
        packageConfig = await Isolate.packageConfig;
      }
    }

    // Ensure to resolve package: URIs being handed in as parameters.
    if (packageConfig != null) {
      // Avoid calling resolvePackageUri if not strictly necessary in case
      // the API is not supported.
      if (packageConfig.isScheme("package")) {
        packageConfig = await Isolate.resolvePackageUri(packageConfig);
      }
    }

    // The VM will invoke [_startIsolate] and not `main`.
    final packageConfigString = packageConfig?.toString();

    final RawReceivePort readyPort =
        new RawReceivePort(null, 'Isolate.spawnUri ready');
    try {
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
          packageConfigString,
          debugName);
      return await _spawnCommon(readyPort);
    } catch (e) {
      readyPort.close();
      rethrow;
    }
  }

  static Future<Isolate> _spawnCommon(RawReceivePort readyPort) {
    final completer = new Completer<Isolate>.sync();
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

  // For 'spawnFunction' see internal_patch.dart.

  static void _spawnUri(
      SendPort readyPort,
      String uri,
      List<String> args,
      var message,
      bool paused,
      SendPort? onExit,
      SendPort? onError,
      bool errorsAreFatal,
      bool? checked,
      List? environment,
      String? packageConfig,
      String? debugName) native "Isolate_spawnUri";

  static void _sendOOB(port, msg) native "Isolate_sendOOB";

  static String _getDebugName(SendPort controlPort)
      native "Isolate_getDebugName";

  @patch
  void _pause(Capability resumeCapability) {
    // _sendOOB expects a fixed length array and hence we create a fixed
    // length array and assign values to it instead of using [ ... ].
    var msg = new List<Object?>.filled(4, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _PAUSE
      ..[2] = pauseCapability
      ..[3] = resumeCapability;
    _sendOOB(controlPort, msg);
  }

  @patch
  void resume(Capability resumeCapability) {
    var msg = new List<Object?>.filled(4, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _RESUME
      ..[2] = pauseCapability
      ..[3] = resumeCapability;
    _sendOOB(controlPort, msg);
  }

  @patch
  void addOnExitListener(SendPort responsePort, {Object? response}) {
    var msg = new List<Object?>.filled(4, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _ADD_EXIT
      ..[2] = responsePort
      ..[3] = response;
    _sendOOB(controlPort, msg);
  }

  @patch
  void removeOnExitListener(SendPort responsePort) {
    var msg = new List<Object?>.filled(3, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _DEL_EXIT
      ..[2] = responsePort;
    _sendOOB(controlPort, msg);
  }

  @patch
  void setErrorsFatal(bool errorsAreFatal) {
    var msg = new List<Object?>.filled(4, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _ERROR_FATAL
      ..[2] = terminateCapability
      ..[3] = errorsAreFatal;
    _sendOOB(controlPort, msg);
  }

  @patch
  void kill({int priority: beforeNextEvent}) {
    var msg = new List<Object?>.filled(4, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _KILL
      ..[2] = terminateCapability
      ..[3] = priority;
    _sendOOB(controlPort, msg);
  }

  @patch
  void ping(SendPort responsePort,
      {Object? response, int priority: immediate}) {
    var msg = new List<Object?>.filled(5, null)
      ..[0] = 0 // Make room for OOM message type.
      ..[1] = _PING
      ..[2] = responsePort
      ..[3] = priority
      ..[4] = response;
    _sendOOB(controlPort, msg);
  }

  @patch
  void addErrorListener(SendPort port) {
    var msg = new List<Object?>.filled(3, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = _ADD_ERROR
      ..[2] = port;
    _sendOOB(controlPort, msg);
  }

  @patch
  void removeErrorListener(SendPort port) {
    var msg = new List<Object?>.filled(3, null)
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

  static Uri? _getCurrentRootUri() {
    try {
      return Uri.parse(_getCurrentRootUriStr());
    } catch (e) {
      return null;
    }
  }

  static String _getCurrentRootUriStr() native "Isolate_getCurrentRootUriStr";
}

@patch
abstract class TransferableTypedData {
  @patch
  factory TransferableTypedData.fromList(List<TypedData> chunks) {
    if (chunks == null) {
      throw ArgumentError(chunks);
    }
    final int cid = ClassID.getID(chunks);
    if (cid != ClassID.cidArray &&
        cid != ClassID.cidGrowableObjectArray &&
        cid != ClassID.cidImmutableArray) {
      chunks = List.unmodifiable(chunks);
    }
    return _TransferableTypedDataImpl(chunks);
  }
}

@pragma("vm:entry-point")
class _TransferableTypedDataImpl implements TransferableTypedData {
  factory _TransferableTypedDataImpl(List<TypedData> list)
      native "TransferableTypedData_factory";

  ByteBuffer materialize() {
    return _materializeIntoUint8List().buffer;
  }

  Uint8List _materializeIntoUint8List()
      native "TransferableTypedData_materialize";
}
