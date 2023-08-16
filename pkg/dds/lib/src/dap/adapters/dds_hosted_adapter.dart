// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:dap/dap.dart';
import 'package:vm_service/vm_service.dart' as vm;

import '../constants.dart';
import '../protocol_stream.dart';
import '../variables.dart';
import 'dart.dart';
import 'mixins.dart';

/// A DAP Debug Adapter for attaching to already-running Dart and Flutter applications.
class DdsHostedAdapter extends DartDebugAdapter<DartLaunchRequestArguments,
        DartAttachRequestArguments>
    with PidTracker, VmServiceInfoFileUtils, PackageConfigUtils, TestAdapter {
  Uri? ddsUri;

  @override
  final parseLaunchArgs = DartLaunchRequestArguments.fromJson;

  @override
  final parseAttachArgs = DartAttachRequestArguments.fromJson;

  DdsHostedAdapter()
      : super(
          // TODO(helin24): Make channel optional for base adapter class.
          ByteStreamServerChannel(
            Stream.empty(),
            NullStreamSink(),
            (message) {},
          ),
          ipv6: true,
          enableDds: false,
        );

  /// Whether the VM Service closing should be used as a signal to terminate the
  /// debug session.
  ///
  /// True here because we no longer need this adapter once the VM service has closed.
  @override
  bool get terminateOnVmServiceClose => true;

  final _dapEventsController = StreamController<Event>();

  @override
  Future<void> debuggerConnected(vm.VM vmInfo) async {}

  /// Called by [disconnectRequest] to request that we forcefully shut down the
  /// app being run (or in the case of an attach, disconnect).
  @override
  Future<void> disconnectImpl() async {
    await handleDetach();
  }

  /// Called by [launchRequest] to request that we actually start the app to be
  /// run/debugged.
  ///
  /// For debugging, this should start paused, connect to the VM Service, set
  /// breakpoints, and resume.
  @override
  Future<void> launchImpl() async {
    sendConsoleOutput(
      'Launch is not supported for the attach only adapter',
    );
    handleSessionTerminate();
  }

  /// Called by [attachRequest] to request that we actually connect to the app
  /// to be debugged.
  @override
  Future<void> attachImpl() async {
    final args = this.args as DartAttachRequestArguments;
    final vmServiceUri = args.vmServiceUri;

    if (vmServiceUri == null) {
      sendConsoleOutput(
        'To attach, provide vmServiceUri',
      );
      handleSessionTerminate();
      return;
    }
    if (vmServiceUri != ddsUri.toString()) {
      sendConsoleOutput(
        'To use the attach-only adapter, VM service URI must match DDS URI',
      );
      handleSessionTerminate();
    }

    // TODO(helin24): In this method, we only need to verify that the DDS URI
    // matches the VM service URI. The DDS URI isn't really needed because this
    // adapter is running in the same process. We need to refactor so that we
    // call DDS/VM service methods directly instead of using the websocket.
    unawaited(connectDebugger(ddsUri!));
  }

  /// Handles custom requests that are specific to the DDS-hosted adapter, such
  /// as translating between VM IDs and DAP IDs.
  @override
  Future<void> customRequest(
    Request request,
    RawRequestArguments? args,
    void Function(Object?) sendResponse,
  ) async {
    switch (request.command) {
      case Command.createVariableForInstance:
        sendResponse(_createVariableForInstance(request.arguments));
        break;

      case Command.getVariablesInstanceId:
        sendResponse(_getVariablesInstanceId(request.arguments));
        break;

      default:
        await super.customRequest(request, args, sendResponse);
    }
  }

  /// Creates a DAP variablesReference for a VM Instance ID.
  Map<String, Object?> _createVariableForInstance(Object? arguments) {
    if (arguments is! Map<String, Object?>) {
      throw DebugAdapterException(
        '${Command.createVariableForInstance} arguments must be Map<String, Object?>',
      );
    }
    final isolateId = arguments[Parameters.isolateId];
    final instanceId = arguments[Parameters.instanceId];
    if (isolateId is! String) {
      throw DebugAdapterException(
        'createVariableForInstance requires a valid String ${Parameters.isolateId}',
      );
    }
    if (instanceId is! String) {
      throw DebugAdapterException(
        'createVariableForInstance requires a value String ${Parameters.instanceId}',
      );
    }

    final thread = isolateManager.threadForIsolateId(isolateId);
    if (thread == null) {
      throw DebugAdapterException('Isolate $isolateId is not valid');
    }

    // Create a new reference for this instance ID.
    final variablesReference =
        thread.storeData(WrappedInstanceVariable(instanceId));

    return {
      Parameters.variablesReference: variablesReference,
    };
  }

  /// Tries to extract a VM Instance ID from a DAP variablesReference.
  Map<String, Object?> _getVariablesInstanceId(Object? arguments) {
    if (arguments is! Map<String, Object?>) {
      throw DebugAdapterException(
        '${Command.getVariablesInstanceId} arguments must be Map<String, Object?>',
      );
    }
    final variablesReference = arguments[Parameters.variablesReference];
    if (variablesReference is! int) {
      throw DebugAdapterException(
        '${Command.getVariablesInstanceId} requires a valid int ${Parameters.variablesReference}',
      );
    }

    // Extract the stored data. This should generally always be a
    // `WrappedInstanceVariable` (created by `_createVariableForInstance`) but
    // for possible future compatibility, we'll also handle `VariableData` and
    // other variables we can extract IDs for.
    var data = isolateManager.getStoredData(variablesReference)?.data;

    // Unwrap if it was wrapped for formatting.
    if (data is VariableData) {
      data = data.data;
    }

    // Extract the ID.
    final instanceId = data is WrappedInstanceVariable
        ? data.instanceId
        : data is vm.ObjRef
            ? data.id
            : null;

    return {
      Parameters.instanceId: instanceId,
    };
  }

  /// Called by [terminateRequest] to request that we gracefully shut down the
  /// app being run (or in the case of an attach, disconnect).
  @override
  Future<void> terminateImpl() async {
    await handleDetach();
    terminatePids(ProcessSignal.sigterm);
  }

  void handleMessage(String message, void Function(Response) responseWriter) {
    final potentialException =
        DebugAdapterException('Message does not conform to DAP spec: $message');

    try {
      final Map<String, Object?> json = jsonDecode(message);
      final type = json['type'] as String;
      if (type == 'request') {
        handleIncomingRequest(Request.fromJson(json), responseWriter);
        // TODO(helin24): Handle event and response?
      } else {
        throw potentialException;
      }
    } catch (e) {
      throw potentialException;
    }
  }

  @override
  void sendEventToChannel(Event event) {
    _dapEventsController.add(event);
  }

  void setEventHandler(void Function(Event) eventHandler) {
    _dapEventsController.stream.listen(eventHandler);
  }
}
