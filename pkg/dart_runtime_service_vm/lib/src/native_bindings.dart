// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a special situation where we're allowed to import dart:_vmservice
// from outside the core libraries to access the native entrypoints.
//
// See VmTarget in package:vm for the exception for this library to access
// dart:_vmservice.
// ignore: uri_does_not_exist
import 'dart:_vmservice' as vm_service_natives;
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';

import 'vm_isolate_manager.dart';

/// Allows for sending messages to the native VM service implementation.
class NativeBindings {
  factory NativeBindings() => _instance;
  NativeBindings._();

  static final NativeBindings _instance = NativeBindings._();
  static final jsonUtf8Decoder = json.fuse(utf8);

  final _logger = Logger('$NativeBindings');

  /// Sends a general RPC to the VM for processing.
  ///
  /// The RPC is not executed in the scope of any particular isolate.
  Future<RpcResponse> sendToVM({
    required String method,
    required Map<String, Object?> params,
  }) {
    final receivePort = RawReceivePort(null, 'VM Message');
    final completer = Completer<RpcResponse>();
    receivePort.handler = (Object value) {
      receivePort.close();
      try {
        completer.complete(_toResponse(value: value));
      } on json_rpc.RpcException catch (e) {
        completer.completeError(e);
      }
    };
    vm_service_natives.sendRootServiceMessage(
      _toRequest(responsePort: receivePort, method: method, params: params),
    );
    return completer.future;
  }

  /// Sends an RPC to a specific isolate for processing.
  ///
  /// The RPC is not executed in the scope of any particular isolate.
  Future<RpcResponse> sendToIsolate({
    required VmRunningIsolate isolate,
    required String method,
    required Map<String, Object?> params,
  }) {
    final receivePort = RawReceivePort(
      null,
      'Isolate Message (${isolate.name})',
    );
    // Keep track of receive port associated with the request so we can close
    // it if isolate exits before sending a response.
    isolate.outstandingRequestPorts.add(receivePort);
    final completer = Completer<RpcResponse>();
    receivePort.handler = (Object value) {
      receivePort.close();
      isolate.outstandingRequestPorts.remove(receivePort);
      try {
        completer.complete(_toResponse(value: value));
      } on json_rpc.RpcException catch (e) {
        completer.completeError(e);
      }
    };
    if (!vm_service_natives.sendIsolateServiceMessage(
      isolate.sendPort,
      _toRequest(responsePort: receivePort, method: method, params: params),
    )) {
      receivePort.close();
      isolate.outstandingRequestPorts.remove(receivePort);
      _logger.warning('Could not send message to $isolate.');
      completer.completeError(RpcException.internalError.toException());
    }
    return completer.future;
  }

  /// Notifies the VM to start sending events for [streamId].
  ///
  /// This only needs to be called once the first client has subscribed to the
  /// stream. Subsequent subscriptions to the stream are handled by the
  /// [EventStreamManager].
  ///
  /// If [includePrivates] is true, private event properties starting with '_'
  /// will be included in events. This is false by default to reduce the size of
  /// events for clients that don't rely on private properties.
  bool streamListen({required String streamId, bool includePrivates = false}) =>
      // TODO(bkonyi): handle case where some clients want privates included
      // and others don't.
      vm_service_natives.vmListenStream(streamId, includePrivates);

  /// Notifies the VM to stop sending events for [streamId].
  ///
  /// This only needs to be called once the last client subscribed to the
  /// stream has cancelled its subscription or disconnected. While clients have
  /// active subscriptions to this stream, stream cancellation requests  are
  /// handled by the [EventStreamManager].
  void streamCancel({required String streamId}) =>
      vm_service_natives.vmCancelStream(streamId);

  /// Notifies the VM that the VM service server has finished initializing.
  void onStart() => vm_service_natives.onStart();

  /// Notifies the VM that the VM service server has finished exiting.
  void onExit() => vm_service_natives.onExit();

  /// Notifies the VM that the VM service server address has been updated.
  ///
  /// If [address] is null, the VM will assume the server is not running.
  void onServerAddressChange(String? address) =>
      vm_service_natives.onServerAddressChange(address);

  RpcResponse _toResponse({required Object value}) {
    const kResult = 'result';
    const kError = 'error';
    const kCode = 'code';
    const kMessage = 'message';
    const kData = 'data';

    final Object? converted;
    if (value case [final Uint8List utf8String]) {
      converted = jsonUtf8Decoder.decode(utf8String);
    } else {
      RpcException.internalError.throwException();
    }
    if (converted case {kResult: final Map<String, Object?> result}) {
      return result;
    } else if (converted case {
      kError: {kCode: final int code, kMessage: final String message},
    }) {
      // 'data' is not always present, so it can't be included in the object
      // destructuring pattern.
      final data = (converted[kError]! as Map<String, Object?>)[kData];
      throw json_rpc.RpcException(code, message, data: data);
    } else {
      RpcException.internalError.throwException();
    }
  }

  // Calls toString on all non-String elements of [list]. We do this so all
  // elements in the list are strings, making consumption by C++ simpler.
  // This has a side effect that boolean literal values like true become 'true'
  // and thus indistinguishable from the string literal 'true'.
  static void _convertAllToStringInPlace(List<Object?> list) {
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].toString();
    }
  }

  List<Object?> _toRequest({
    required RawReceivePort responsePort,
    required String method,
    required Map<String, Object?> params,
  }) {
    final parametersAreObjects = _methodNeedsObjectParameters(method);
    final keys = params.keys.toList(growable: false);
    final values = params.values.cast<Object?>().toList(growable: false);
    if (!parametersAreObjects) {
      _convertAllToStringInPlace(values);
    }

    // This is the request ID that will be inserted into the JSON response in
    // service.cc. package:json_rpc_2 already handles these IDs, so we just
    // pass in a placeholder for now until we can update Service::InvokeMethod
    // to not expect it.
    // TODO(bkonyi): remove request ID from service message.
    const kPlaceholderRequestId = -1;

    // Keep in sync with Service::InvokeMethod in service.cc.
    return List<Object?>.filled(7, null)
      ..[0] =
          0 // Make room for OOB message type.
      ..[1] = responsePort.sendPort
      ..[2] = kPlaceholderRequestId
      ..[3] = method
      ..[4] = parametersAreObjects
      ..[5] = keys
      ..[6] = values;
  }

  // We currently support two ways of passing parameters from Dart code to C
  // code. The original way always converts the parameters to strings before
  // passing them over. Our goal is to convert all C handlers to take the
  // parameters as Dart objects but until the conversion is complete, we
  // maintain the list of supported methods below.
  bool _methodNeedsObjectParameters(String method) {
    switch (method) {
      case '_listDevFS':
      case '_listDevFSFiles':
      case '_createDevFS':
      case '_deleteDevFS':
      case '_writeDevFSFile':
      case '_writeDevFSFiles':
      case '_readDevFSFile':
      case '_spawnUri':
      case '_reloadKernel':
      case '_reloadSources':
      case 'reloadSources':
        return true;
      default:
        return false;
    }
  }
}
