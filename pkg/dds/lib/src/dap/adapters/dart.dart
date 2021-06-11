// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart' as vm;

import '../base_debug_adapter.dart';
import '../exceptions.dart';
import '../isolate_manager.dart';
import '../logging.dart';
import '../protocol_converter.dart';
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
  late final T args;
  final _debuggerInitializedCompleter = Completer<void>();
  final _configurationDoneCompleter = Completer<void>();

  /// Manages VM Isolates and their events, including fanning out any requests
  /// to set breakpoints etc. from the client to all Isolates.
  late IsolateManager _isolateManager;

  /// A helper that handlers converting to/from DAP and VM Service types.
  late ProtocolConverter _converter;

  /// All active VM Service subscriptions.
  ///
  /// TODO(dantup): This may be changed to use StreamManager as part of using
  /// DDS in this process.
  final _subscriptions = <StreamSubscription<vm.Event>>[];

  /// The VM service of the app being debugged.
  ///
  /// `null` if the session is running in noDebug mode of the connection has not
  /// yet been made.
  vm.VmServiceInterface? vmService;

  /// Whether the current debug session is an attach request (as opposed to a
  /// launch request). Not available until after launchRequest or attachRequest
  /// have been called.
  late final bool isAttach;

  DartDebugAdapter(ByteStreamServerChannel channel, Logger? logger)
      : super(channel, logger) {
    _isolateManager = IsolateManager(this);
    _converter = ProtocolConverter(this);
  }

  /// Completes when the debugger initialization has completed. Used to delay
  /// processing isolate events while initialization is still running to avoid
  /// race conditions (for example if an isolate unpauses before we have
  /// processed its initial paused state).
  Future<void> get debuggerInitialized => _debuggerInitializedCompleter.future;

  /// attachRequest is called by the client when it wants us to to attach to
  /// an existing app. This will only be called once (and only one of this or
  /// launchRequest will be called).
  @override
  Future<void> attachRequest(
    Request request,
    T args,
    void Function() sendResponse,
  ) async {
    this.args = args;
    isAttach = true;

    // Common setup.
    await _prepareForLaunchOrAttach();

    // TODO(dantup): Implement attach support.
    throw UnimplementedError();

    // Delegate to the sub-class to attach to the process.
    // await attachImpl();
    //
    // sendResponse();
  }

  /// configurationDone is called by the client when it has finished sending
  /// any initial configuration (such as breakpoints and exception pause
  /// settings).
  ///
  /// We delay processing `launchRequest`/`attachRequest` until this request has
  /// been sent to ensure we're not still getting breakpoints (which are sent
  /// per-file) while we're launching and initializing over the VM Service.
  @override
  Future<void> configurationDoneRequest(
    Request request,
    ConfigurationDoneArguments? args,
    void Function() sendResponse,
  ) async {
    _configurationDoneCompleter.complete();
    sendResponse();
  }

  /// Connects to the VM Service at [uri] and initializes debugging.
  ///
  /// This method will be called by sub-classes when they are ready to start
  /// a debug session and may provide a URI given by the user (in the case
  /// of attach) or from something like a vm-service-info file or Flutter
  /// app.debugPort message.
  ///
  /// The URI protocol will be changed to ws/wss but otherwise not normalised.
  /// The caller should handle any other normalisation (such as adding /ws to
  /// the end if required).
  Future<void> connectDebugger(Uri uri) async {
    // The VM Service library always expects the WebSockets URI so fix the
    // scheme (http -> ws, https -> wss).
    final isSecure = uri.isScheme('https') || uri.isScheme('wss');
    uri = uri.replace(scheme: isSecure ? 'wss' : 'ws');

    logger?.call('Connecting to debugger at $uri');
    sendOutput('console', 'Connecting to VM Service at $uri\n');
    final vmService =
        await _vmServiceConnectUri(uri.toString(), logger: logger);
    logger?.call('Connected to debugger at $uri!');

    // TODO(dantup): VS Code currently depends on a custom dart.debuggerUris
    // event to notify it of VM Services that become available (for example to
    // register with the DevTools server). If this is still required, it will
    // need implementing here (and also documented as a customisation and
    // perhaps gated on a capability/argument).
    this.vmService = vmService;

    _subscriptions.addAll([
      vmService.onIsolateEvent.listen(_handleIsolateEvent),
      vmService.onDebugEvent.listen(_handleDebugEvent),
      vmService.onLoggingEvent.listen(_handleLoggingEvent),
      // TODO(dantup): Implement these.
      // vmService.onExtensionEvent.listen(_handleExtensionEvent),
      // vmService.onServiceEvent.listen(_handleServiceEvent),
      // vmService.onStdoutEvent.listen(_handleStdoutEvent),
      // vmService.onStderrEvent.listen(_handleStderrEvent),
    ]);
    await Future.wait([
      vmService.streamListen(vm.EventStreams.kIsolate),
      vmService.streamListen(vm.EventStreams.kDebug),
      vmService.streamListen(vm.EventStreams.kLogging),
      // vmService.streamListen(vm.EventStreams.kExtension),
      // vmService.streamListen(vm.EventStreams.kService),
      // vmService.streamListen(vm.EventStreams.kStdout),
      // vmService.streamListen(vm.EventStreams.kStderr),
    ]);

    final vmInfo = await vmService.getVM();
    logger?.call('Connected to ${vmInfo.name} on ${vmInfo.operatingSystem}');

    // Let the subclass do any existing setup once we have a connection.
    await debuggerConnected(vmInfo);

    // Process any existing isolates that may have been created before the
    // streams above were set up.
    final existingIsolateRefs = vmInfo.isolates;
    final existingIsolates = existingIsolateRefs != null
        ? await Future.wait(existingIsolateRefs
            .map((isolateRef) => isolateRef.id)
            .whereNotNull()
            .map(vmService.getIsolate))
        : <vm.Isolate>[];
    await Future.wait(existingIsolates.map((isolate) async {
      // Isolates may have the "None" pauseEvent kind at startup, so infer it
      // from the runnable field.
      final pauseEventKind = isolate.runnable ?? false
          ? vm.EventKind.kIsolateRunnable
          : vm.EventKind.kIsolateStart;
      await _isolateManager.registerIsolate(isolate, pauseEventKind);

      // If the Isolate already has a Pause event we can give it to the
      // IsolateManager to handle (if it's PausePostStart it will re-configure
      // the isolate before resuming), otherwise we can just resume it (if it's
      // runnable - otherwise we'll handle this when it becomes runnable in an
      // event later).
      if (isolate.pauseEvent?.kind?.startsWith('Pause') ?? false) {
        await _isolateManager.handleEvent(isolate.pauseEvent!);
      } else if (isolate.runnable == true) {
        await _isolateManager.resumeIsolate(isolate);
      }
    }));

    _debuggerInitializedCompleter.complete();
  }

  /// Handles the clients "continue" ("resume") request for the thread in
  /// [args.threadId].
  @override
  Future<void> continueRequest(
    Request request,
    ContinueArguments args,
    void Function(ContinueResponseBody) sendResponse,
  ) async {
    await _isolateManager.resumeThread(args.threadId);
    sendResponse(ContinueResponseBody(allThreadsContinued: false));
  }

  /// Overridden by sub-classes to perform any additional setup after the VM
  /// Service is connected.
  Future<void> debuggerConnected(vm.VM vmInfo);

  /// Overridden by sub-classes to handle when the client sends a
  /// `disconnectRequest` (a forceful request to shut down).
  Future<void> disconnectImpl();

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
  Future<void> disconnectRequest(
    Request request,
    DisconnectArguments? args,
    void Function() sendResponse,
  ) async {
    await disconnectImpl();
    sendResponse();
  }

  /// initializeRequest is the first request send by the client during
  /// initialization and allows exchanging capabilities and configuration
  /// between client and server.
  ///
  /// The lifecycle is described in the DAP spec here:
  /// https://microsoft.github.io/debug-adapter-protocol/overview#initialization
  /// with a summary in this classes description.
  @override
  Future<void> initializeRequest(
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
  Future<void> launchImpl();

  /// launchRequest is called by the client when it wants us to to start the app
  /// to be run/debug. This will only be called once (and only one of this or
  /// attachRequest will be called).
  @override
  Future<void> launchRequest(
    Request request,
    T args,
    void Function() sendResponse,
  ) async {
    this.args = args;
    isAttach = false;

    // Common setup.
    await _prepareForLaunchOrAttach();

    // Delegate to the sub-class to launch the process.
    await launchImpl();

    sendResponse();
  }

  /// Handles the clients "next" ("step over") request for the thread in
  /// [args.threadId].
  @override
  Future<void> nextRequest(
    Request request,
    NextArguments args,
    void Function() sendResponse,
  ) async {
    await _isolateManager.resumeThread(args.threadId, vm.StepOption.kOver);
    sendResponse();
  }

  /// Sends an OutputEvent (without a newline, since calls to this method
  /// may be used by buffered data).
  void sendOutput(String category, String message) {
    sendEvent(OutputEventBody(category: category, output: message));
  }

  /// Sends an OutputEvent for [message], prefixed with [prefix] and with [message]
  /// indented to after the prefix.
  ///
  /// Assumes the output is in full lines and will always include a terminating
  /// newline.
  void sendPrefixedOutput(String category, String prefix, String message) {
    final indentString = ' ' * prefix.length;
    final indentedMessage =
        message.trimRight().split('\n').join('\n$indentString');
    sendOutput(category, '$prefix$indentedMessage\n');
  }

  /// Handles a request from the client to set breakpoints.
  ///
  /// This method can be called at any time (before the app is launched or while
  /// the app is running) and will include the new full set of breakpoints for
  /// the file URI in [args.source.path].
  ///
  /// The VM requires breakpoints to be set per-isolate so these will be passed
  /// to [_isolateManager] that will fan them out to each isolate.
  ///
  /// When new isolates are registered, it is [isolateManager]s responsibility
  /// to ensure all breakpoints are given to them (and like at startup, this
  /// must happen before they are resumed).
  @override
  Future<void> setBreakpointsRequest(
    Request request,
    SetBreakpointsArguments args,
    void Function(SetBreakpointsResponseBody) sendResponse,
  ) async {
    final breakpoints = args.breakpoints ?? [];

    final path = args.source.path;
    final name = args.source.name;
    final uri = path != null ? Uri.file(path).toString() : name!;

    await _isolateManager.setBreakpoints(uri, breakpoints);

    // TODO(dantup): Handle breakpoint resolution rather than pretending all
    // breakpoints are verified immediately.
    sendResponse(SetBreakpointsResponseBody(
      breakpoints: breakpoints.map((e) => Breakpoint(verified: true)).toList(),
    ));
  }

  /// Handles a request from the client for the call stack for [args.threadId].
  ///
  /// This is usually called after we sent a [StoppedEvent] to the client
  /// notifying it that execution of an isolate has paused and it wants to
  /// populate the call stack view.
  ///
  /// Clients may fetch the frames in batches and VS Code in particular will
  /// send two requests initially - one for the top frame only, and then one for
  /// the next 19 frames. For better performance, the first request is satisfied
  /// entirely from the threads pauseEvent.topFrame so we do not need to
  /// round-trip to the VM Service.
  @override
  Future<void> stackTraceRequest(
    Request request,
    StackTraceArguments args,
    void Function(StackTraceResponseBody) sendResponse,
  ) async {
    // We prefer to provide frames in small batches. Rather than tell the client
    // how many frames there really are (which can be expensive to compute -
    // especially for web) we just add 20 on to the last frame we actually send,
    // as described in the spec:
    //
    // "Returning monotonically increasing totalFrames values for subsequent
    //  requests can be used to enforce paging in the client."
    const stackFrameBatchSize = 20;

    final threadId = args.threadId;
    final thread = _isolateManager.getThread(threadId);
    final topFrame = thread?.pauseEvent?.topFrame;
    final startFrame = args.startFrame ?? 0;
    final numFrames = args.levels ?? 0;
    var totalFrames = 1;

    if (thread == null) {
      throw DebugAdapterException('No thread with threadId $threadId');
    }

    if (!thread.paused) {
      throw DebugAdapterException('Thread $threadId is not paused');
    }

    final stackFrames = <StackFrame>[];
    // If the request is only for the top frame, we may be able to satisfy it
    // from the threads `pauseEvent.topFrame`.
    if (startFrame == 0 && numFrames == 1 && topFrame != null) {
      totalFrames = 1 + stackFrameBatchSize;
      final dapTopFrame = await _converter.convertVmToDapStackFrame(
        thread,
        topFrame,
        isTopFrame: true,
      );
      stackFrames.add(dapTopFrame);
    } else {
      // Otherwise, send the request on to the VM.
      // The VM doesn't support fetching an arbitrary slice of frames, only a
      // maximum limit, so if the client asks for frames 20-30 we must send a
      // request for the first 30 and trim them ourselves.
      final limit = startFrame + numFrames;
      final stack = await vmService?.getStack(thread.isolate.id!, limit: limit);
      final frames = stack?.frames;

      if (stack != null && frames != null) {
        // When the call stack is truncated, we always add [stackFrameBatchSize]
        // to the count, indicating to the client there are more frames and
        // the size of the batch they should request when "loading more".
        //
        // It's ok to send a number that runs past the actual end of the call
        // stack and the client should handle this gracefully:
        //
        // "a client should be prepared to receive less frames than requested,
        //  which is an indication that the end of the stack has been reached."
        totalFrames = (stack.truncated ?? false)
            ? frames.length + stackFrameBatchSize
            : frames.length;

        Future<StackFrame> convert(int index, vm.Frame frame) async {
          return _converter.convertVmToDapStackFrame(
            thread,
            frame,
            isTopFrame: startFrame == 0 && index == 0,
          );
        }

        final frameSubset = frames.sublist(startFrame);
        stackFrames.addAll(await Future.wait(frameSubset.mapIndexed(convert)));
      }
    }

    sendResponse(
      StackTraceResponseBody(
        stackFrames: stackFrames,
        totalFrames: totalFrames,
      ),
    );
  }

  /// Handles the clients "step in" request for the thread in [args.threadId].
  @override
  Future<void> stepInRequest(
    Request request,
    StepInArguments args,
    void Function() sendResponse,
  ) async {
    await _isolateManager.resumeThread(args.threadId, vm.StepOption.kInto);
    sendResponse();
  }

  /// Handles the clients "step out" request for the thread in [args.threadId].
  @override
  Future<void> stepOutRequest(
    Request request,
    StepOutArguments args,
    void Function() sendResponse,
  ) async {
    await _isolateManager.resumeThread(args.threadId, vm.StepOption.kOut);
    sendResponse();
  }

  /// Overridden by sub-classes to handle when the client sends a
  /// `terminateRequest` (a request for a graceful shut down).
  Future<void> terminateImpl();

  /// terminateRequest is called by the client when it wants us to gracefully
  /// shut down.
  ///
  /// It's not very obvious from the names, but `terminateRequest` is sent first
  /// (a request for a graceful shutdown) and `disconnectRequest` second (a
  /// request for a forced shutdown).
  ///
  /// https://microsoft.github.io/debug-adapter-protocol/overview#debug-session-end
  @override
  Future<void> terminateRequest(
    Request request,
    TerminateArguments? args,
    void Function() sendResponse,
  ) async {
    await terminateImpl();
    sendResponse();
  }

  void _handleDebugEvent(vm.Event event) {
    _isolateManager.handleEvent(event);
  }

  void _handleIsolateEvent(vm.Event event) {
    _isolateManager.handleEvent(event);
  }

  /// Handles a dart:developer log() event, sending output to the client.
  Future<void> _handleLoggingEvent(vm.Event event) async {
    final record = event.logRecord;
    final thread = _isolateManager.threadForIsolate(event.isolate);
    if (record == null || thread == null) {
      return;
    }

    /// Helper to convert to InstanceRef to a String, taking into account
    /// [vm.InstanceKind.kNull] which is the type for the unused fields of a
    /// log event.
    Future<String?> asString(vm.InstanceRef? ref) async {
      if (ref == null || ref.kind == vm.InstanceKind.kNull) {
        return null;
      }
      // TODO(dantup): This should handle truncation and complex types.
      return ref.valueAsString;
    }

    var loggerName = await asString(record.loggerName);
    if (loggerName?.isEmpty ?? true) {
      loggerName = 'log';
    }
    final message = await asString(record.message);
    final error = await asString(record.error);
    final stack = await asString(record.stackTrace);

    final prefix = '[$loggerName] ';

    if (message != null) {
      sendPrefixedOutput('stdout', prefix, '$message\n');
    }
    if (error != null) {
      sendPrefixedOutput('stderr', prefix, '$error\n');
    }
    if (stack != null) {
      sendPrefixedOutput('stderr', prefix, '$stack\n');
    }
  }

  /// Performs some setup that is common to both [launchRequest] and
  /// [attachRequest].
  Future<void> _prepareForLaunchOrAttach() async {
    // Don't start launching until configurationDone.
    if (!_configurationDoneCompleter.isCompleted) {
      logger?.call('Waiting for configurationDone request...');
      await _configurationDoneCompleter.future;
    }

    // Notify IsolateManager if we'll be debugging so it knows whether to set
    // up breakpoints etc. when isolates are registered.
    final debug = !(args.noDebug ?? false);
    _isolateManager.setDebugEnabled(debug);
  }

  /// A wrapper around the same name function from package:vm_service that
  /// allows logging all traffic over the VM Service.
  Future<vm.VmService> _vmServiceConnectUri(
    String wsUri, {
    Logger? logger,
  }) async {
    final socket = await WebSocket.connect(wsUri);
    final controller = StreamController();
    final streamClosedCompleter = Completer();

    socket.listen(
      (data) {
        logger?.call('<== [VM] $data');
        controller.add(data);
      },
      onDone: () => streamClosedCompleter.complete(),
    );

    return vm.VmService(
      controller.stream,
      (String message) {
        logger?.call('==> [VM] $message');
        socket.add(message);
      },
      log: logger != null ? VmServiceLogger(logger) : null,
      disposeHandler: () => socket.close(),
      streamClosed: streamClosedCompleter.future,
    );
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

  /// Whether SDK libraries should be marked as debuggable.
  ///
  /// Treated as `false` if null, which means "step in" will not step into SDK
  /// libraries.
  final bool? debugSdkLibraries;

  /// Whether external package libraries should be marked as debuggable.
  ///
  /// Treated as `false` if null, which means "step in" will not step into
  /// libraries in packages that are not either the local package or a path
  /// dependency. This allows users to debug "just their code" and treat Pub
  /// packages as block boxes.
  final bool? debugExternalPackageLibraries;

  /// Whether to evaluate getters in debug views like hovers and the variables
  /// list.
  ///
  /// Invoking getters has a performance cost and may introduce side-effects,
  /// although users may expected this functionality. null is treated like false
  /// although clients may have their own defaults (for example Dart-Code sends
  /// true by default at the time of writing).
  final bool? evaluateGettersInDebugViews;

  /// Whether to call toString() on objects in debug views like hovers and the
  /// variables list.
  ///
  /// Invoking toString() has a performance cost and may introduce side-effects,
  /// although users may expected this functionality. null is treated like false
  /// although clients may have their own defaults (for example Dart-Code sends
  /// true by default at the time of writing).
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
    this.debugExternalPackageLibraries,
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
        debugExternalPackageLibraries =
            obj['debugExternalPackageLibraries'] as bool?,
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
        if (debugExternalPackageLibraries != null)
          'debugExternalPackageLibraries': debugExternalPackageLibraries,
        if (evaluateGettersInDebugViews != null)
          'evaluateGettersInDebugViews': evaluateGettersInDebugViews,
        if (evaluateToStringInDebugViews != null)
          'evaluateToStringInDebugViews': evaluateToStringInDebugViews,
        if (sendLogsToClient != null) 'sendLogsToClient': sendLogsToClient,
      };

  static DartLaunchRequestArguments fromJson(Map<String, Object?> obj) =>
      DartLaunchRequestArguments.fromMap(obj);
}
