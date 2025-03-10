// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dap/dap.dart';
import 'package:dds/src/dap/adapters/dart.dart';
import 'package:dds/src/dap/logging.dart';
import 'package:dds/src/dap/protocol_stream.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'test_server.dart';
import 'test_support.dart';

/// A helper class to simplify acting as a client for interacting with the
/// [DapTestServer] in tests.
///
/// Methods on this class should map directly to protocol methods. Additional
/// helpers are available in [DapTestClientExtension].
class DapTestClient {
  final ByteStreamServerChannel _channel;
  late final StreamSubscription<String> _subscription;

  final Logger? _logger;
  final bool captureVmServiceTraffic;
  final _requestWarningDuration = const Duration(seconds: 10);
  final Map<int, _OutgoingRequest> _pendingRequests = {};
  final _eventController = StreamController<Event>.broadcast();
  int _seq = 1;

  /// Whether to advertise support for URIs and expect them in stack traces
  /// and breakpoint updates from the debug adapter.
  bool supportUris = false;

  /// Whether to send URIs in breakpoints even for standard file paths.
  ///
  /// This is separate from [supportUris] so that we can test when support is
  /// enabled that the client can still send paths. This is because VS Code will
  /// send file paths for file:/// documents even though URIs are supported.
  bool sendFileUris = false;

  /// Functions provided by tests to handle requests that may come from the
  /// server (such as `runInTerminal`).
  final _serverRequestHandlers =
      <String, FutureOr<Object?> Function(Object?)>{};

  late final Future<Uri?> vmServiceUri;

  /// Used to control drive letter casing for the 'program' value on Windows for
  /// testing.
  DriveLetterCasing? forceProgramDriveLetterCasing;

  /// Used to control drive letter casing for the 'cwd' value on Windows for
  /// testing.
  DriveLetterCasing? forceCwdDriveLetterCasing;

  /// Used to control drive letter casing for breakpoint paths on Windows for
  /// testing.
  DriveLetterCasing? forceBreakpointDriveLetterCasing;

  /// All stderr OutputEvents that have occurred so far.
  final StringBuffer _stderr = StringBuffer();

  /// A default cwd to use for all launches.
  String? defaultCwd;

  DapTestClient._(
    this._channel,
    this._logger, {
    this.captureVmServiceTraffic = false,
  }) {
    // Set up a future that will complete when the 'dart.debuggerUris' event is
    // emitted by the debug adapter so tests have easy access to it.
    vmServiceUri = event('dart.debuggerUris').then<Uri?>((event) {
      final body = event.body as Map<String, Object?>;
      return Uri.parse(body['vmServiceUri'] as String);
    }).catchError((e) => null);

    _subscription = _channel.listen(
      _handleMessage,
      onDone: () {
        _isStopping = true;
        if (_pendingRequests.isNotEmpty) {
          _logger?.call(
              'Application terminated without a response to ${_pendingRequests.length} requests');
        }
        _pendingRequests.forEach((id, request) => request.completer.completeError(
            'Application terminated without a response to request $id (${request.name})'));
        _pendingRequests.clear();
      },
    );

    // Collect stderr output events so if we can write this to the real
    // stderr when the app terminates to help track down things like VM crashes.
    outputEvents
        .where((event) => event.category == 'stderr')
        .listen((event) => _stderr.write(event.output));
  }

  /// Returns a stream of [OutputEventBody] events.
  Stream<OutputEventBody> get outputEvents => events('output')
      .map((e) => OutputEventBody.fromJson(e.body as Map<String, Object?>));

  /// Returns a stream of custom 'dart.serviceExtensionAdded' events.
  Stream<Map<String, Object?>> get serviceExtensionAddedEvents =>
      events('dart.serviceExtensionAdded')
          .map((e) => e.body as Map<String, Object?>);

  /// Returns a stream of custom 'dart.serviceRegistered' events.
  Stream<Map<String, Object?>> get serviceRegisteredEvents =>
      events('dart.serviceRegistered')
          .map((e) => e.body as Map<String, Object?>);

  /// Returns a stream of 'dart.testNotification' custom events from the
  /// package:test JSON reporter.
  Stream<Map<String, Object?>> get testNotificationEvents =>
      events('dart.testNotification')
          .map((e) => e.body as Map<String, Object?>);

  /// Waits for a 'breakpoint' event that changes the breakpoint with [id].
  Stream<BreakpointEventBody> get breakpointChangeEvents => events('breakpoint')
      .map((event) =>
          BreakpointEventBody.fromJson(event.body as Map<String, Object?>))
      .where((body) => body.reason == 'changed');

  /// Returns a stream of [ThreadEventBody] events.
  Stream<ThreadEventBody> get threadEvents => events('thread')
      .map((e) => ThreadEventBody.fromJson(e.body as Map<String, Object?>));

  /// Send an attachRequest to the server, asking it to attach to an existing
  /// Dart program.
  Future<Response> attach({
    required bool autoResumeOnEntry,
    required bool autoResumeOnExit,
    String? vmServiceUri,
    String? vmServiceInfoFile,
    String? cwd,
    List<String>? additionalProjectPaths,
    bool? debugSdkLibraries,
    bool? debugExternalPackageLibraries,
    bool? showGettersInDebugViews,
    bool? evaluateGettersInDebugViews,
    bool? evaluateToStringInDebugViews,
  }) async {
    assert(
      (vmServiceUri == null) != (vmServiceInfoFile == null),
      'Provide exactly one of vmServiceUri/vmServiceInfoFile',
    );

    // When attaching, the paused VM will not be automatically unpaused, but
    // instead send a Stopped(reason: 'entry') event. Respond to this by
    // resuming (if requested).
    final resumeFuture = autoResumeOnEntry
        ? expectStop('entry').then((event) => continue_(event.threadId!))
        : null;

    // Also handle resuming on exit. This should be done if the test has
    // started the app with a user-provided pause-on-exit but wants to
    // simulate the user resuming after the exit pause.
    if (autoResumeOnExit) {
      stoppedEvents
          .firstWhere((e) => e.reason == 'exit')
          .then((event) => continue_(event.threadId!));
    }

    cwd ??= defaultCwd;
    final attachResponse = sendRequest(
      DartAttachRequestArguments(
        vmServiceUri: vmServiceUri,
        vmServiceInfoFile: vmServiceInfoFile,
        cwd: cwd != null
            ? setDriveLetterCasing(cwd, forceCwdDriveLetterCasing)
            : null,
        additionalProjectPaths:
            additionalProjectPaths?.map(uppercaseDriveLetter).toList(),
        debugSdkLibraries: debugSdkLibraries,
        debugExternalPackageLibraries: debugExternalPackageLibraries,
        showGettersInDebugViews: showGettersInDebugViews,
        evaluateGettersInDebugViews: evaluateGettersInDebugViews,
        evaluateToStringInDebugViews: evaluateToStringInDebugViews,
        // When running out of process, VM Service traffic won't be available
        // to the client-side logger, so force logging on which sends VM Service
        // traffic in a custom event.
        sendLogsToClient: captureVmServiceTraffic,
      ),
      // We can't automatically pick the command when using a custom type
      // (DartAttachRequestArguments).
      overrideCommand: 'attach',
    );

    // If we were expecting a pause and to resume, ensure that happens.
    await resumeFuture;

    return attachResponse;
  }

  /// Calls a service method via a custom request.
  Future<Response> callService(String name, Object? params) {
    return custom('callService', {'method': name, 'params': params});
  }

  /// Sends a continue request for the given thread.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> continue_(int threadId) =>
      sendRequest(ContinueArguments(threadId: threadId));

  /// Sends a custom request to the server and waits for a response.
  Future<Response> custom(String name, [Object? args]) async {
    return sendRequest(args, overrideCommand: name);
  }

  Future<Response> disconnect() => sendRequest(DisconnectArguments());

  /// Sends an evaluate request for the given [expression], optionally for a
  /// specific [frameId].
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> evaluate(
    String expression, {
    int? frameId,
    String? context,
    ValueFormat? format,
  }) {
    return sendRequest(EvaluateArguments(
      expression: expression,
      frameId: frameId,
      context: context,
      format: format,
    ));
  }

  /// Returns a Future that completes with the next [event] event.
  Future<Event> event(String event) => _logIfSlow(
      'Event "$event"',
      allEvents.firstWhere((e) => e.event == event,
          orElse: () =>
              throw 'Did not receive $event event before stream closed'));

  /// Returns a stream for [event] events.
  Stream<Event> events(String event) {
    return allEvents.where((e) => e.event == event);
  }

  Stream<Event> get allEvents => _eventController.stream;

  /// Returns a stream for 'stopped' events.
  Stream<StoppedEventBody> get stoppedEvents {
    return allEvents
        .where((e) => e.event == 'stopped')
        .map((e) => StoppedEventBody.fromJson(e.body as Map<String, Object?>));
  }

  /// Returns a stream for standard progress events.
  Stream<Event> standardProgressEvents() {
    const standardProgressEvents = {
      'progressStart',
      'progressUpdate',
      'progressEnd'
    };
    return allEvents.where((e) => standardProgressEvents.contains(e.event));
  }

  /// Returns a stream for custom Dart progress events.
  Stream<Event> customProgressEvents() {
    const customProgressEvents = {
      'dart.progressStart',
      'dart.progressUpdate',
      'dart.progressEnd'
    };
    return allEvents.where((e) => customProgressEvents.contains(e.event));
  }

  /// Records a handler for when the server sends a [request] request.
  void handleRequest(
    String request,
    FutureOr<Object?> Function(Object?) handler,
  ) {
    _serverRequestHandlers[request] = handler;
  }

  /// Send a custom 'hotReload' request to the server.
  Future<Response> hotReload() async {
    return custom('hotReload');
  }

  /// Send an initialize request to the server.
  ///
  /// This occurs before the request to start running/debugging a script and is
  /// used to exchange capabilities and send breakpoints and other settings.
  Future<Response> initialize({
    String exceptionPauseMode = 'None',
    bool? supportsRunInTerminalRequest,
    bool? supportsProgressReporting,
  }) async {
    final responses = await Future.wait([
      event('initialized'),
      sendRequest(DartInitializeRequestArguments(
        adapterID: 'test',
        supportsRunInTerminalRequest: supportsRunInTerminalRequest,
        supportsProgressReporting: supportsProgressReporting,
        supportsDartUris: supportUris,
      )),
      sendRequest(
        SetExceptionBreakpointsArguments(
          filters: [exceptionPauseMode],
        ),
      ),
    ]);
    await sendRequest(ConfigurationDoneArguments());
    return responses[1] as Response; // Return the initialize response.
  }

  /// Send a launchRequest to the server, asking it to start a Dart program.
  Future<Response> launch(
    String program, {
    List<String>? args,
    List<String>? vmAdditionalArgs,
    List<String>? toolArgs,
    String? cwd,
    bool? noDebug,
    List<String>? additionalProjectPaths,
    String? console,
    bool? debugSdkLibraries,
    bool? debugExternalPackageLibraries,
    bool? showGettersInDebugViews,
    bool? evaluateGettersInDebugViews,
    bool? evaluateToStringInDebugViews,
    bool? sendLogsToClient,
    bool? sendCustomProgressEvents,
    bool? allowAnsiColorOutput,
  }) {
    cwd ??= defaultCwd;
    return sendRequest(
      DartLaunchRequestArguments(
        noDebug: noDebug,
        program: setDriveLetterCasing(program, forceProgramDriveLetterCasing),
        cwd: cwd != null
            ? setDriveLetterCasing(cwd, forceCwdDriveLetterCasing)
            : null,
        args: args,
        vmAdditionalArgs: vmAdditionalArgs,
        toolArgs: toolArgs,
        additionalProjectPaths:
            additionalProjectPaths?.map(uppercaseDriveLetter).toList(),
        console: console,
        debugSdkLibraries: debugSdkLibraries,
        debugExternalPackageLibraries: debugExternalPackageLibraries,
        showGettersInDebugViews: showGettersInDebugViews,
        evaluateGettersInDebugViews: evaluateGettersInDebugViews,
        evaluateToStringInDebugViews: evaluateToStringInDebugViews,
        // When running out of process, VM Service traffic won't be available
        // to the client-side logger, so force logging on which sends VM Service
        // traffic in a custom event.
        sendLogsToClient: sendLogsToClient ?? captureVmServiceTraffic,
        sendCustomProgressEvents: sendCustomProgressEvents,
        allowAnsiColorOutput: allowAnsiColorOutput,
      ),
      // We can't automatically pick the command when using a custom type
      // (DartLaunchRequestArguments).
      overrideCommand: 'launch',
    );
  }

  /// Sends a pause request for the given thread.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> pause(int threadId) =>
      sendRequest(PauseArguments(threadId: threadId));

  /// Sends a restartFrame request for the given frame.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> restartFrame(int frameId) =>
      sendRequest(RestartFrameArguments(frameId: frameId));

  /// Sends a next (step over) request for the given thread.
  ///
  /// [granularity] is always ignored because the Dart debugger does not support
  /// it (indicated in its capabilities), but it is used by tests to ensure the
  /// adapter does not crash on the presence of it.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> next(int threadId, {SteppingGranularity? granularity}) =>
      sendRequest(NextArguments(threadId: threadId, granularity: granularity));

  /// Sends a request to the server for variables scopes available for a given
  /// stack frame.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> scopes(int frameId) {
    return sendRequest(ScopesArguments(frameId: frameId));
  }

  /// Sends an arbitrary request to the server.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> sendRequest(Object? arguments,
      {bool allowFailure = false, String? overrideCommand}) {
    final command = overrideCommand ?? commandTypes[arguments.runtimeType]!;
    final request =
        Request(seq: _seq++, command: command, arguments: arguments);
    final completer = Completer<Response>();
    _pendingRequests[request.seq] =
        _OutgoingRequest(completer, command, allowFailure);
    _channel.sendRequest(request);
    return _logIfSlow('Request "$command"', completer.future);
  }

  /// Sends a response to the server.
  ///
  /// This is used to respond to server-to-client requests such as
  /// `runInTerminal`.
  void sendResponse(Request request, Object? responseBody) {
    final response = Response(
      success: true,
      requestSeq: request.seq,
      seq: _seq++,
      command: request.command,
      body: responseBody,
    );
    _channel.sendResponse(response);
  }

  /// Sends a source request to the server to request source code for a [source]
  /// reference that may have come from a stack frame or similar.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> source(Source source) => sendRequest(
        SourceArguments(
          source: source,
          sourceReference: source.sourceReference!,
        ),
      );

  /// Sends a stackTrace request to the server to request the call stack for a
  /// given thread.
  ///
  /// If [startFrame] and/or [numFrames] are supplied, only a slice of the
  /// frames will be returned.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> stackTrace(int threadId,
          {int? startFrame, int? numFrames}) =>
      sendRequest(StackTraceArguments(
          threadId: threadId, startFrame: startFrame, levels: numFrames));

  /// Initializes the debug adapter and launches [file] or calls the custom
  /// [launch] method.
  Future<void> start({
    File? file,
    Future<Object?> Function()? launch,
  }) {
    return Future.wait([
      initialize(),
      launch?.call() ?? this.launch(file!.path),
    ], eagerError: true);
  }

  /// Sends a stepIn request for the given thread.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> stepIn(int threadId) =>
      sendRequest(StepInArguments(threadId: threadId));

  /// Sends a stepOut request for the given thread.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> stepOut(int threadId) =>
      sendRequest(StepOutArguments(threadId: threadId));

  Future<void> stop() async {
    _isStopping = true;
    _channel.close();
    await _subscription.cancel();
  }

  /// Whether this client is stopping (for any shutdown reason).
  bool _isStopping = false;

  /// Whether or not any `terminate()` request has been sent.
  bool get hasSentTerminateRequest => _hasSentTerminateRequest;
  bool _hasSentTerminateRequest = false;

  /// Sends a terminate request.
  ///
  /// For convenience, returns a Future that completes when either this request
  /// completes, or when a `terminated` event is received since it is not
  /// guaranteed that this request will return a response during a shutdown.
  Future<void> terminate() async {
    _isStopping = true;
    _hasSentTerminateRequest = true;
    return Future.any([
      event('terminated').then(
        (event) => event,
        // Ignore errors caused by this event not occurring before the stream
        // closes as this is very possible if the application terminated just
        // before this method was called.
        onError: (_) => null,
      ),
      sendRequest(TerminateArguments()),
    ]);
  }

  /// Sends a threads request to the server to request the list of active
  /// threads (isolates).
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> threads() => sendRequest(null, overrideCommand: 'threads');

  /// Sends a request for child variables (fields/list elements/etc.) for the
  /// variable with reference [variablesReference].
  ///
  /// If [start] and/or [count] are supplied, only a slice of the variables will
  /// be returned. This is used to allow the client to page through large Lists
  /// or Maps without needing all of the data immediately.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> variables(
    int variablesReference, {
    int? start,
    int? count,
    ValueFormat? format,
  }) {
    return sendRequest(VariablesArguments(
      variablesReference: variablesReference,
      start: start,
      count: count,
      format: format,
    ));
  }

  /// Handles an incoming message from the server, completing the relevant request
  /// of raising the appropriate event.
  Future<void> _handleMessage(ProtocolMessage message) async {
    _verifyMessageOrdering(message);
    if (message is Response) {
      final pendingRequest = _pendingRequests.remove(message.requestSeq);
      if (pendingRequest == null) {
        return;
      }
      final completer = pendingRequest.completer;
      if (message.success || pendingRequest.allowFailure) {
        completer.complete(message);
      } else {
        completer.completeError(RequestException(pendingRequest.name, message));
      }
    } else if (message is Event && !_eventController.isClosed) {
      _eventController.add(message);

      // When we see a terminated event, close the event stream so if any
      // tests are waiting on something that will never come, they fail at
      // a useful location.
      if (message.event == 'terminated') {
        _isStopping = true;
        unawaited(_eventController.close());

        if (_stderr.isNotEmpty) {
          stderr.writeln('STDERR output collected before app terminated:');
          stderr.write(_stderr.toString());
        }
      }
    } else if (message is Request) {
      // The server sent a request to the client. Call the handler and then send
      // back its result in a response.
      final command = message.command;
      final args = message.arguments;
      final handler = _serverRequestHandlers[command];
      if (handler == null) {
        throw 'Test did not configure a handler for servers request: $command';
      }
      final result = await handler(args);
      sendResponse(message, result);
    }
  }

  /// Prints a warning if [future] takes longer than [_requestWarningDuration]
  /// to complete aid debugging test failures on bots from logs.
  ///
  /// Returns [future].
  Future<T> _logIfSlow<T>(String name, Future<T> future) {
    // Use a loop to periodically check so that we can exit earlier if
    // the test is being torn down.
    var endTime = DateTime.now().add(_requestWarningDuration);
    late Timer timer;
    timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      // Shutting down, so just abort.
      if (_isStopping) {
        timer.cancel();
        return;
      }

      // We've hit the warning threshold, report and then abort.
      if (DateTime.now().isAfter(endTime)) {
        print(
            '$name has taken longer than ${_requestWarningDuration.inSeconds}s');
        timer.cancel();
        return;
      }

      // Otherwise, do nothing and check on the next tick.
    });
    return future.whenComplete(timer.cancel);
  }

  /// Ensures that protocol messages are received in the correct order where
  /// ordering matters.
  void _verifyMessageOrdering(ProtocolMessage message) {
    if (message is Event) {
      if (message.event == 'initialized' &&
          !_receivedResponses.contains('initialize')) {
        throw StateError(
          'Adapter sent "initialized" event before the "initialize" request had '
          'been responded to',
        );
      }

      _receivedEvents.add(message.event);
    } else if (message is Request) {
      if (message.command == 'runInTerminal' &&
          !_receivedResponses.contains('launch')) {
        throw StateError(
          'Adapter sent a "runInTerminal" request before it had '
          'responded to the "launch" request',
        );
      }

      _receivedResponses.add(message.command);
    } else if (message is Response) {
      if (message.command == 'initialize' &&
          _receivedEvents.contains('initialized')) {
        throw StateError(
          'Adapter sent a response to an "initialize" request after it had '
          'already send the "initialized" event',
        );
      }

      _receivedResponses.add(message.command);
    }
  }

  /// A list of all event names that have been received during this session.
  ///
  /// Used by [_verifyMessageOrdering].
  final _receivedEvents = <String>{};

  /// A list of all request names that have been responded to during this
  /// session.
  ///
  /// Used by [_verifyMessageOrdering].
  final _receivedResponses = <String>{};

  /// Creates a [DapTestClient] that connects the server listening on
  /// [host]:[port].
  static Future<DapTestClient> connect(
    DapTestServer server, {
    bool captureVmServiceTraffic = false,
    Logger? logger,
  }) async {
    final channel = ByteStreamServerChannel(server.stream, server.sink, logger);
    return DapTestClient._(
      channel,
      logger,
      captureVmServiceTraffic: captureVmServiceTraffic,
    );
  }
}

/// Useful events produced by the debug adapter during a debug session.
class TestEvents {
  final List<OutputEventBody> output;
  final List<Map<String, Object?>> testNotifications;

  TestEvents({
    required this.output,
    required this.testNotifications,
  });
}

class _OutgoingRequest {
  final Completer<Response> completer;
  final String name;
  final bool allowFailure;

  _OutgoingRequest(this.completer, this.name, this.allowFailure);
}

/// Additional helper method for tests to simplify interaction with [DapTestClient].
///
/// Unlike the methods on [DapTestClient] these methods might not map directly
/// onto protocol methods. They may call multiple protocol methods and/or
/// simplify assertion specific conditions/results.
extension DapTestClientExtension on DapTestClient {
  /// Sets a breakpoint at [line] in [file] and expects to hit it after running
  /// the script.
  ///
  /// Launch options can be customised by passing a custom [launch] function that
  /// will be used instead of calling `launch(file.path)`.
  Future<StoppedEventBody> hitBreakpoint(
    File file,
    int line, {
    List<int>? additionalBreakpoints,
    File? entryFile,
    String? condition,
    String? cwd,
    List<String>? args,
    List<String>? vmAdditionalArgs,
    List<String>? toolArgs,
    bool? evaluateToStringInDebugViews,
    Future<Response> Function()? launch,
  }) async {
    assert(condition == null || additionalBreakpoints == null,
        'Only one of condition/additionalBreakpoints can be sent');
    entryFile ??= file;
    final stop = expectStop('breakpoint', file: file, line: line);

    await Future.wait([
      initialize(),
      if (additionalBreakpoints != null)
        setBreakpoints(file, [line, ...additionalBreakpoints])
      else
        setBreakpoint(file, line, condition: condition),
      launch?.call() ??
          this.launch(
            entryFile.path,
            cwd: cwd,
            args: args,
            vmAdditionalArgs: vmAdditionalArgs,
            toolArgs: toolArgs,
            evaluateToStringInDebugViews: evaluateToStringInDebugViews,
          ),
    ], eagerError: true);

    return stop;
  }

  /// Converts a file path to a URI to send to the debug adapter if
  /// [sendFileUris] is `true` and otherwise returns as-is.
  String toPathOrUri(String filePath) {
    assert(path.isAbsolute(filePath));
    return sendFileUris ? Uri.file(filePath).toString() : filePath;
  }

  /// Converts a string from the debug adapter back to a file path, asserting
  /// it was a URI if [useUris] is `true`, and not if [useUris] is `false`.
  String fromPathOrUri(String filePathOrUri) {
    if (!supportUris) {
      // Expect an absolute path.
      assert(path.isAbsolute(filePathOrUri));
      return filePathOrUri;
    }

    // Expect a URI with file:/// scheme.
    final uri = Uri.parse(filePathOrUri);
    assert(uri.isScheme('file'));
    return uri.toFilePath();
  }

  /// Sets a breakpoint at [line] in [file].
  Future<SetBreakpointsResponseBody> setBreakpoint(File file, int line,
      {String? condition}) async {
    final response = await sendRequest(
      SetBreakpointsArguments(
        source: Source(path: toPathOrUri(_normalizeBreakpointPath(file.path))),
        breakpoints: [SourceBreakpoint(line: line, condition: condition)],
      ),
    );

    return SetBreakpointsResponseBody.fromJson(
      response.body as Map<String, Object?>,
    );
  }

  /// Sets breakpoints at [lines] in [file].
  Future<SetBreakpointsResponseBody> setBreakpoints(
      File file, List<int> lines) async {
    final response = await sendRequest(
      SetBreakpointsArguments(
        source: Source(path: toPathOrUri(_normalizeBreakpointPath(file.path))),
        breakpoints: lines.map((line) => SourceBreakpoint(line: line)).toList(),
      ),
    );

    return SetBreakpointsResponseBody.fromJson(
      response.body as Map<String, Object?>,
    );
  }

  /// Normalizes a breakpoint path being sent to the debug adapter based on
  /// the values of [forceBreakpointDriveLetterCasingUpper] and
  /// [forceBreakpointDriveLetterCasingLower].
  String _normalizeBreakpointPath(String path) {
    return setDriveLetterCasing(path, forceBreakpointDriveLetterCasing);
  }

  /// Sets the exception pause mode to [pauseMode] and expects to pause after
  /// running the script.
  ///
  /// Launch options can be customised by passing a custom [launch] function that
  /// will be used instead of calling `launch(file.path)`.
  Future<StoppedEventBody> pauseOnException(
    File file, {
    String? exceptionPauseMode, // All, Unhandled, None
    String? expectText,
    Future<Response> Function()? launch,
  }) async {
    final stopFuture = expectStop('exception', file: file);

    await Future.wait([
      initialize(),
      sendRequest(
        SetExceptionBreakpointsArguments(
          filters: [if (exceptionPauseMode != null) exceptionPauseMode],
        ),
      ),
      launch?.call() ?? this.launch(file.path),
    ], eagerError: true);

    final stop = await stopFuture;
    if (expectText != null) {
      expect(stop.text, expectText);
    }
    return stop;
  }

  /// Sets a breakpoint at [line] in [file] and expects _not_ to hit it after
  /// running the script (instead the script is expected to terminate).
  ///
  /// Launch options can be customised by passing a custom [launch] function that
  /// will be used instead of calling `launch(file.path)`.
  Future<void> doNotHitBreakpoint(
    File file,
    int line, {
    String? condition,
    String? logMessage,
    Future<Response> Function()? launch,
  }) async {
    await Future.wait([
      event('terminated'),
      initialize(),
      sendRequest(
        SetBreakpointsArguments(
          source:
              Source(path: toPathOrUri(_normalizeBreakpointPath(file.path))),
          breakpoints: [
            SourceBreakpoint(
              line: line,
              condition: condition,
              logMessage: logMessage,
            )
          ],
        ),
      ),
      launch?.call() ?? this.launch(file.path),
    ], eagerError: true);
  }

  /// Returns whether DDS is available for the VM Service the debug adapter
  /// is connected to.
  Future<bool> get ddsAvailable async {
    final response = await custom(
      '_getSupportedProtocols',
      null,
    );

    // For convenience, use the ProtocolList to deserialize the custom
    // response to check if included DDS.
    final protocolList =
        vm.ProtocolList.parse(response.body as Map<String, Object?>?);

    final ddsProtocol = protocolList?.protocols?.singleWhereOrNull(
      (protocol) => protocol.protocolName == 'DDS',
    );
    return ddsProtocol != null;
  }

  /// Runs a script and expects to pause at an exception in [file].
  Future<StoppedEventBody> hitException(
    File file, [
    String exceptionPauseMode = 'Unhandled',
    int? line,
  ]) async {
    final stop = expectStop('exception', file: file, line: line);

    await Future.wait([
      initialize(exceptionPauseMode: exceptionPauseMode),
      launch(file.path),
    ], eagerError: true);

    return stop;
  }

  /// Expects a 'stopped' event for [reason].
  ///
  /// If [file] or [line] are provided, they will be checked against the stop
  /// location for the top stack frame.
  ///
  /// Stopped-on-entry events will be automatically skipped unless
  /// [skipFirstStopOnEntry] is `false` or [reason] is `"entry"`.
  Future<StoppedEventBody> expectStop(
    String reason, {
    File? file,
    int? line,
    String? sourceName,
    bool? skipFirstStopOnEntry,
  }) async {
    skipFirstStopOnEntry ??= reason != 'entry';
    assert(skipFirstStopOnEntry != (reason == 'entry'));

    // Unless we're specifically waiting for stop-on-entry, skip over those
    // events because they can be emitted at during startup because now we use
    // readyToResume we don't know if the isolate will be immediately unpaused
    // and the client needs to have a consistent view of threads.
    final stop = skipFirstStopOnEntry
        ? await stoppedEvents.skipWhile((e) => e.reason == 'entry').first
        : await stoppedEvents.first;
    expect(stop.reason, equals(reason));

    final result =
        await getValidStack(stop.threadId!, startFrame: 0, numFrames: 1);

    if (file != null || line != null || sourceName != null) {
      expect(result.stackFrames, hasLength(1));
      final frame = result.stackFrames[0];

      if (file != null) {
        expect(fromPathOrUri(frame.source!.path!),
            equals(uppercaseDriveLetter(file.path)));
      }
      if (sourceName != null) {
        expect(frame.source?.name, equals(sourceName));
      }
      if (line != null) {
        expect(frame.line, equals(line));
      }
    }

    return stop;
  }

  /// Fetches a stack trace and asserts it was a valid response.
  Future<StackTraceResponseBody> getValidStack(int threadId,
      {required int startFrame, required int numFrames}) async {
    final response = await stackTrace(threadId,
        startFrame: startFrame, numFrames: numFrames);
    expect(response.success, isTrue);
    expect(response.command, equals('stackTrace'));
    return StackTraceResponseBody.fromJson(
        response.body as Map<String, Object?>);
  }

  /// Fetches source for a sourceReference and asserts it was a valid response.
  Future<SourceResponseBody> getValidSource(Source source) async {
    final response = await this.source(source);
    expect(response.success, isTrue);
    expect(response.command, equals('source'));
    return SourceResponseBody.fromJson(response.body as Map<String, Object?>);
  }

  /// Fetches threads and asserts a valid response.
  Future<ThreadsResponseBody> getValidThreads() async {
    final response = await threads();
    expect(response.success, isTrue);
    expect(response.command, equals('threads'));
    return ThreadsResponseBody.fromJson(response.body as Map<String, Object?>);
  }

  /// Collects all output events until the program terminates.
  ///
  /// These results include all events in the order they are received, including
  /// console, stdout and stderr.
  ///
  /// Only one of [start] or [launch] may be provided. Use [start] to customise
  /// the whole start of the session (including initialise) or [launch] to only
  /// customise the [launchRequest].
  Future<List<OutputEventBody>> collectOutput({
    File? file,
    Future<Response> Function()? start,
    Future<Response> Function()? launch,
  }) async {
    assert(
      start == null || launch == null,
      'Only one of "start" or "launch" may be provided',
    );
    final outputEventsFuture = outputEvents.toList();

    if (start != null) {
      await start();
    } else {
      await this.start(file: file, launch: launch);
    }

    return outputEventsFuture;
  }

  /// Collects all output and test events until the program terminates.
  ///
  /// These results include all events in the order they are received, including
  /// console, stdout, stderr and test notifications from the test JSON reporter.
  ///
  /// Only one of [start] or [launch] may be provided. Use [start] to customise
  /// the whole start of the session (including initialise) or [launch] to only
  /// customise the [launchRequest].
  Future<TestEvents> collectTestOutput({
    File? file,
    Future<Response> Function()? start,
    Future<Object?> Function()? launch,
  }) async {
    assert(
      start == null || launch == null,
      'Only one of "start" or "launch" may be provided',
    );

    final outputEventsFuture = outputEvents.toList();
    final testNotificationEventsFuture = testNotificationEvents.toList();

    if (start != null) {
      await start();
    } else {
      await this.start(file: file, launch: launch);
    }

    return TestEvents(
      output: await outputEventsFuture,
      testNotifications: await testNotificationEventsFuture,
    );
  }

  /// A helper that fetches scopes for a frame, checks for one with the name
  /// [expectedName] and verifies its variables.
  Future<Scope> expectScopeVariables(
    int frameId,
    String expectedName,
    String expectedVariables, {
    bool ignorePrivate = true,
    Set<String>? ignore,
    ValueFormat? format,
  }) async {
    final scope = await getValidScope(frameId, expectedName);
    await expectVariables(
      scope.variablesReference,
      expectedVariables,
      ignorePrivate: ignorePrivate,
      ignore: ignore,
      format: format,
    );
    return scope;
  }

  /// Requests variables scopes for a frame returns one with a specific name.
  Future<Scope> getValidScope(int frameId, String name) async {
    final scopes = await getValidScopes(frameId);
    return scopes.scopes.singleWhere(
      (s) => s.name == name,
      orElse: () => throw 'Did not find scope with name $name',
    );
  }

  /// A helper that finds a named variable in the Variables scope for the top
  /// frame and asserts its child variables (fields/getters/etc) match.
  Future<VariablesResponseBody> expectLocalVariable(
    int threadId, {
    required String expectedName,
    required String expectedDisplayString,
    int? expectedIndexedItems,
    required String expectedVariables,
    int? start,
    int? count,
    ValueFormat? format,
    bool ignorePrivate = true,
    Set<String>? ignore,
  }) async {
    final expectedVariable = await getLocalVariable(threadId, expectedName);

    // Check basic variable values.
    expect(expectedVariable.value, equals(expectedDisplayString));
    expect(expectedVariable.indexedVariables, equals(expectedIndexedItems));

    // Check the child fields.
    return expectVariables(
      expectedVariable.variablesReference,
      expectedVariables,
      start: start,
      count: count,
      ignorePrivate: ignorePrivate,
      format: format,
      ignore: ignore,
    );
  }

  /// A helper that finds a named variable in the Variables scope for the top
  /// frame.
  Future<Variable> getLocalVariable(int threadId, String name) async {
    final stack = await getValidStack(
      threadId,
      startFrame: 0,
      numFrames: 1,
    );
    final topFrame = stack.stackFrames.first;

    final variablesScope = await getValidScope(topFrame.id, 'Locals');
    return getChildVariable(variablesScope.variablesReference, name);
  }

  /// A helper that finds a named variable in the child variables for
  /// [variablesReference].
  Future<Variable> getChildVariable(int variablesReference, String name) async {
    final variables = await getValidVariables(variablesReference);
    return variables.variables.singleWhere(
      (variable) => variable.name == name,
      orElse: () =>
          throw 'Did not find $name in ${variables.variables.map((v) => v.name).join(', ')}',
    );
  }

  /// Requests variables scopes for a frame and asserts a valid response.
  Future<ScopesResponseBody> getValidScopes(int frameId) async {
    final response = await scopes(frameId);
    expect(response.success, isTrue);
    expect(response.command, equals('scopes'));
    return ScopesResponseBody.fromJson(response.body as Map<String, Object?>);
  }

  /// Requests variables by reference and asserts a valid response.
  Future<VariablesResponseBody> getValidVariables(
    int variablesReference, {
    int? start,
    int? count,
    ValueFormat? format,
  }) async {
    final response = await variables(
      variablesReference,
      start: start,
      count: count,
      format: format,
    );
    expect(response.success, isTrue);
    expect(response.command, equals('variables'));
    return VariablesResponseBody.fromJson(
        response.body as Map<String, Object?>);
  }

  /// A helper that calls the private `_collectAllGarbage` custom request to
  /// force a GC.
  Future<void> forceGc(int threadId) async {
    await sendRequest(
      {
        'threadId': threadId,
      },
      overrideCommand: '_collectAllGarbage',
    );
  }

  /// A helper that verifies the variables list matches [expectedVariables].
  ///
  /// [expectedVariables] is a simple text format of `name: value` for each
  /// variable with some additional annotations to simplify writing tests.
  Future<VariablesResponseBody> expectVariables(
    int variablesReference,
    String expectedVariables, {
    int? start,
    int? count,
    bool ignorePrivate = true,
    Set<String>? ignore,
    ValueFormat? format,
  }) async {
    final expectedLines =
        expectedVariables.trim().split('\n').map((l) => l.trim()).toList();

    final variables = await getValidVariables(
      variablesReference,
      start: start,
      count: count,
      format: format,
    );

    // If a variable was set to be ignored but wasn't in the list, that's
    // likely an error in the test.
    if (ignore != null) {
      final variableNames = variables.variables.map((v) => v.name).toSet();
      for (final ignored in ignore) {
        expect(
          variableNames.contains(ignored),
          isTrue,
          reason: 'Variable "$ignored" should be ignored but was '
              'not in the results ($variableNames)',
        );
      }
    }

    /// Helper to format the variables into a simple text representation that's
    /// easy to maintain in tests.
    String toSimpleTextRepresentation(Variable v) {
      final buffer = StringBuffer();
      final evaluateName = v.evaluateName;
      final indexedVariables = v.indexedVariables;
      final namedVariables = v.namedVariables;
      final value = v.value;
      final type = v.type;
      final presentationHint = v.presentationHint;

      buffer.write('${v.name}: $value');
      if (evaluateName != null) {
        buffer.write(', eval: $evaluateName');
      }
      if (indexedVariables != null) {
        buffer.write(', $indexedVariables items');
      }
      if (namedVariables != null) {
        buffer.write(', $namedVariables named items');
      }
      if (type != null) {
        buffer.write(', $type');
      }
      if (presentationHint != null) {
        if (presentationHint.lazy != null) {
          buffer.write(', lazy: ${presentationHint.lazy}');
        }
        if (presentationHint.kind != null) {
          buffer.write(', kind: ${presentationHint.kind}');
        }
        if (presentationHint.visibility != null) {
          buffer.write(', visibility: ${presentationHint.visibility}');
        }
        if (presentationHint.attributes != null) {
          buffer.write(
              ', attributes: ${presentationHint.attributes!.join(", ")}');
        }
      }

      return buffer.toString();
    }

    final actual = variables.variables
        .where((v) => ignorePrivate ? !v.name.startsWith('_') : true)
        .where((v) => !(ignore?.contains(v.name) ?? false))
        // Always exclude hashCode because its value is not guaranteed.
        .where((v) => v.name != 'hashCode')
        .map(toSimpleTextRepresentation);

    expect(actual.join('\n'), equals(expectedLines.join('\n')));

    return variables;
  }

  Future<int> getTopFrameId(
    int threadId,
  ) async {
    final stack = await getValidStack(threadId, startFrame: 0, numFrames: 1);
    return stack.stackFrames.first.id;
  }

  /// Evaluates [expression] in frame [frameId] and expects a specific
  /// [expectedResult].
  Future<EvaluateResponseBody> expectEvalResult(
    int frameId,
    String expression,
    String expectedResult, {
    String? context,
    ValueFormat? format,
  }) async {
    final response = await evaluate(
      expression,
      frameId: frameId,
      context: context,
      format: format,
    );
    expect(response.success, isTrue);
    expect(response.command, equals('evaluate'));
    final body =
        EvaluateResponseBody.fromJson(response.body as Map<String, Object?>);

    expect(body.result, equals(expectedResult));

    return body;
  }

  /// Evaluates [expression] without a frame and  expects a specific
  /// [expectedResult].
  Future<EvaluateResponseBody> expectGlobalEvalResult(
    String expression,
    String expectedResult, {
    String? context,
    ValueFormat? format,
  }) async {
    final response = await evaluate(
      expression,
      context: context,
      format: format,
    );
    expect(response.success, isTrue);
    expect(response.command, equals('evaluate'));
    final body =
        EvaluateResponseBody.fromJson(response.body as Map<String, Object?>);

    expect(body.result, equals(expectedResult));

    return body;
  }
}

/// Represents an error message returned from the debug adapter in response
/// to a request.
class RequestException implements Exception {
  /// The name of the request that was made by the client.
  final String requestName;

  /// The raw message that came from back from the adapter.
  final ProtocolMessage message;

  RequestException(this.requestName, this.message);

  @override
  String toString() => 'Request "$requestName" failed:\n'
      '${JsonEncoder.withIndent('    ').convert(message.toJson())}';
}
