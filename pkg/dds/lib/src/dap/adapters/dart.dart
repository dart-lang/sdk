// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../base_debug_adapter.dart';
import '../logging.dart';
import '../protocol_generated.dart';
import '../protocol_stream.dart';

/// A base DAP Debug Adapter implementation for running and debugging Dart-based
/// applications (including Flutter and Tests).
///
/// This class implements all functionality common to Dart, Flutter and Test
/// debug sessions, including things like breakpoints and expression eval.
///
/// Sub-classes should handle the launching/attaching of apps and any custom
/// behaviour (such as Flutter's Hot Reload). This is generally done by overriding
/// `fooImpl` methods that are called during the handling of a `fooRequest` from
/// the client.
///
/// A DebugAdapter instance will be created per application being debugged (in
/// multi-session mode, one DebugAdapter corresponds to one incoming TCP
/// connection, though a client may make multiple of these connections if it
/// wants to debug multiple scripts concurrently, such as with a compound launch
/// configuration in VS Code).
///
/// The lifecycle is described in the DAP spec here:
/// https://microsoft.github.io/debug-adapter-protocol/overview#initialization
///
/// In summary:
///
/// The client will create a connection to the server (which will create an
///   instance of the debug adapter) and send an `initializeRequest` message,
///   wait for the server to return a response and then an initializedEvent
/// The client will then send breakpoints and exception config
///   (`setBreakpointsRequest`, `setExceptionBreakpoints`) and then a
///   `configurationDoneRequest`.
/// Finally, the client will send a `launchRequest` or `attachRequest` to start
///   running/attaching to the script.
///
/// The client will continue to send requests during the debug session that may
/// be in response to user actions (for example changing breakpoints or typing
/// an expression into an evaluation console) or to events sent by the server
/// (for example when the server sends a `StoppedEvent` it may cause the client
/// to then send a `stackTraceRequest` or `scopesRequest` to get variables).
abstract class DartDebugAdapter<T extends DartLaunchRequestArguments>
    extends BaseDebugAdapter<T> {
  late T args;
  final _debuggerInitializedCompleter = Completer<void>();
  final _configurationDoneCompleter = Completer<void>();

  DartDebugAdapter(ByteStreamServerChannel channel, Logger? logger)
      : super(channel, logger);

  /// Completes when the debugger initialization has completed. Used to delay
  /// processing isolate events while initialization is still running to avoid
  /// race conditions (for example if an isolate unpauses before we have
  /// processed its initial paused state).
  Future<void> get debuggerInitialized => _debuggerInitializedCompleter.future;

  /// configurationDone is called by the client when it has finished sending
  /// any initial configuration (such as breakpoints and exception pause
  /// settings).
  ///
  /// We delay processing `launchRequest`/`attachRequest` until this request has
  /// been sent to ensure we're not still getting breakpoints (which are sent
  /// per-file) while we're launching and initializing over the VM Service.
  @override
  FutureOr<void> configurationDoneRequest(
    Request request,
    ConfigurationDoneArguments? args,
    void Function(void) sendResponse,
  ) async {
    _configurationDoneCompleter.complete();
    sendResponse(null);
  }

  /// Overridden by sub-classes to handle when the client sends a
  /// `disconnectRequest` (a forceful request to shut down).
  FutureOr<void> disconnectImpl();

  /// disconnectRequest is called by the client when it wants to forcefully shut
  /// us down quickly. This comes after the `terminateRequest` which is intended
  /// to allow a graceful shutdown.
  ///
  /// It's not very obvious from the names, but `terminateRequest` is sent first
  /// (a request for a graceful shutdown) and `disconnectRequest` second (a
  /// request for a forced shutdown).
  ///
  /// https://microsoft.github.io/debug-adapter-protocol/overview#debug-session-end
  @override
  FutureOr<void> disconnectRequest(
    Request request,
    DisconnectArguments? args,
    void Function(void) sendResponse,
  ) async {
    await disconnectImpl();
    sendResponse(null);
  }

  /// initializeRequest is the first request send by the client during
  /// initialization and allows exchanging capabilities and configuration
  /// between client and server.
  ///
  /// The lifecycle is described in the DAP spec here:
  /// https://microsoft.github.io/debug-adapter-protocol/overview#initialization
  /// with a summary in this classes description.
  @override
  FutureOr<void> initializeRequest(
    Request request,
    InitializeRequestArguments? args,
    void Function(Capabilities) sendResponse,
  ) async {
    // TODO(dantup): Capture/honor editor-specific settings like linesStartAt1
    sendResponse(Capabilities(
      exceptionBreakpointFilters: [
        ExceptionBreakpointsFilter(
          filter: 'All',
          label: 'All Exceptions',
          defaultValue: false,
        ),
        ExceptionBreakpointsFilter(
          filter: 'Unhandled',
          label: 'Uncaught Exceptions',
          defaultValue: true,
        ),
      ],
      supportsClipboardContext: true,
      // TODO(dantup): All of these...
      // supportsConditionalBreakpoints: true,
      supportsConfigurationDoneRequest: true,
      supportsDelayedStackTraceLoading: true,
      supportsEvaluateForHovers: true,
      // supportsLogPoints: true,
      // supportsRestartFrame: true,
      supportsTerminateRequest: true,
    ));

    // This must only be sent AFTER the response!
    sendEvent(InitializedEventBody());
  }

  /// Overridden by sub-classes to handle when the client sends a
  /// `launchRequest` (a request to start running/debugging an app).
  ///
  /// Sub-classes can use the [args] field to access the arguments provided
  /// to this request.
  FutureOr<void> launchImpl();

  /// launchRequest is called by the client when it wants us to to start the app
  /// to be run/debug. This will only be called once (and only one of this or
  /// attachRequest will be called).
  @override
  FutureOr<void> launchRequest(
    Request request,
    T args,
    void Function(void) sendResponse,
  ) async {
    this.args = args;

    // Don't start launching until configurationDone.
    if (!_configurationDoneCompleter.isCompleted) {
      logger?.call('Waiting for configurationDone request...');
      await _configurationDoneCompleter.future;
    }

    // Delegate to the sub-class to launch the process.
    await launchImpl();

    sendResponse(null);
  }

  /// Sends an OutputEvent (without a newline, since calls to this method
  /// may be used by buffered data).
  void sendOutput(String category, String message) {
    sendEvent(OutputEventBody(category: category, output: message));
  }

  /// Overridden by sub-classes to handle when the client sends a
  /// `terminateRequest` (a request for a graceful shut down).
  FutureOr<void> terminateImpl();

  /// terminateRequest is called by the client when it wants us to gracefully
  /// shut down.
  ///
  /// It's not very obvious from the names, but `terminateRequest` is sent first
  /// (a request for a graceful shutdown) and `disconnectRequest` second (a
  /// request for a forced shutdown).
  ///
  /// https://microsoft.github.io/debug-adapter-protocol/overview#debug-session-end
  @override
  FutureOr<void> terminateRequest(
    Request request,
    TerminateArguments? args,
    void Function(void) sendResponse,
  ) async {
    terminateImpl();
    sendResponse(null);
  }
}

/// An implementation of [LaunchRequestArguments] that includes all fields used
/// by the base Dart debug adapter.
///
/// This class represents the data passed from the client editor to the debug
/// adapter in launchRequest, which is a request to start debugging an
/// application.
///
/// Specialised adapters (such as Flutter) will likely extend this class with
/// their own additional fields.
class DartLaunchRequestArguments extends LaunchRequestArguments {
  final String program;
  final List<String>? args;
  final String? cwd;
  final String? vmServiceInfoFile;
  final int? vmServicePort;
  final List<String>? vmAdditionalArgs;
  final bool? enableAsserts;
  final bool? debugSdkLibraries;
  final bool? evaluateGettersInDebugViews;
  final bool? evaluateToStringInDebugViews;

  /// Whether to send debug logging to clients in a custom `dart.log` event. This
  /// is used both by the out-of-process tests to ensure the logs contain enough
  /// information to track down issues, but also by Dart-Code to capture VM
  /// service traffic in a unified log file.
  final bool? sendLogsToClient;

  DartLaunchRequestArguments({
    Object? restart,
    bool? noDebug,
    required this.program,
    this.args,
    this.cwd,
    this.vmServiceInfoFile,
    this.vmServicePort,
    this.vmAdditionalArgs,
    this.enableAsserts,
    this.debugSdkLibraries,
    this.evaluateGettersInDebugViews,
    this.evaluateToStringInDebugViews,
    this.sendLogsToClient,
  }) : super(restart: restart, noDebug: noDebug);

  DartLaunchRequestArguments.fromMap(Map<String, Object?> obj)
      : program = obj['program'] as String,
        args = (obj['args'] as List?)?.cast<String>(),
        cwd = obj['cwd'] as String?,
        vmServiceInfoFile = obj['vmServiceInfoFile'] as String?,
        vmServicePort = obj['vmServicePort'] as int?,
        vmAdditionalArgs = (obj['vmAdditionalArgs'] as List?)?.cast<String>(),
        enableAsserts = obj['enableAsserts'] as bool?,
        debugSdkLibraries = obj['debugSdkLibraries'] as bool?,
        evaluateGettersInDebugViews =
            obj['evaluateGettersInDebugViews'] as bool?,
        evaluateToStringInDebugViews =
            obj['evaluateToStringInDebugViews'] as bool?,
        sendLogsToClient = obj['sendLogsToClient'] as bool?,
        super.fromMap(obj);

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        'program': program,
        if (args != null) 'args': args,
        if (cwd != null) 'cwd': cwd,
        if (vmServiceInfoFile != null) 'vmServiceInfoFile': vmServiceInfoFile,
        if (vmServicePort != null) 'vmServicePort': vmServicePort,
        if (vmAdditionalArgs != null) 'vmAdditionalArgs': vmAdditionalArgs,
        if (enableAsserts != null) 'enableAsserts': enableAsserts,
        if (debugSdkLibraries != null) 'debugSdkLibraries': debugSdkLibraries,
        if (evaluateGettersInDebugViews != null)
          'evaluateGettersInDebugViews': evaluateGettersInDebugViews,
        if (evaluateToStringInDebugViews != null)
          'evaluateToStringInDebugViews': evaluateToStringInDebugViews,
        if (sendLogsToClient != null) 'sendLogsToClient': sendLogsToClient,
      };

  static DartLaunchRequestArguments fromJson(Map<String, Object?> obj) =>
      DartLaunchRequestArguments.fromMap(obj);
}
