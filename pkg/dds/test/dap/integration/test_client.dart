// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dds/src/dap/adapters/dart.dart';
import 'package:dds/src/dap/logging.dart';
import 'package:dds/src/dap/protocol_generated.dart';
import 'package:dds/src/dap/protocol_stream.dart';
import 'package:dds/src/dap/protocol_stream_transformers.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'test_server.dart';

/// A helper class to simplify acting as a client for interacting with the
/// [DapTestServer] in tests.
///
/// Methods on this class should map directly to protocol methods. Additional
/// helpers are available in [DapTestClientExtension].
class DapTestClient {
  final Socket _socket;
  final ByteStreamServerChannel _channel;
  late final StreamSubscription<String> _subscription;

  final Logger? _logger;
  final bool captureVmServiceTraffic;
  final _requestWarningDuration = const Duration(seconds: 2);
  final Map<int, _OutgoingRequest> _pendingRequests = {};
  final _eventController = StreamController<Event>.broadcast();
  int _seq = 1;

  DapTestClient._(
    this._socket,
    this._channel,
    this._logger, {
    this.captureVmServiceTraffic = false,
  }) {
    _subscription = _channel.listen(
      _handleMessage,
      onDone: () {
        if (_pendingRequests.isNotEmpty) {
          _logger?.call(
              'Application terminated without a response to ${_pendingRequests.length} requests');
        }
        _pendingRequests.forEach((id, request) => request.completer.completeError(
            'Application terminated without a response to request $id (${request.name})'));
        _pendingRequests.clear();
      },
    );
  }

  /// Returns a stream of [OutputEventBody] events.
  Stream<OutputEventBody> get outputEvents => events('output')
      .map((e) => OutputEventBody.fromJson(e.body as Map<String, Object?>));

  /// Collects all output events until the program terminates.
  Future<List<OutputEventBody>> collectOutput(
      {File? file, Future<Response> Function()? launch}) async {
    final outputEventsFuture = outputEvents.toList();

    // Launch script and wait for termination.
    await Future.wait([
      event('terminated'),
      initialize(),
      launch?.call() ?? this.launch(file!.path),
    ], eagerError: true);

    return outputEventsFuture;
  }

  /// Sends a continue request for the given thread.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> continue_(int threadId) =>
      sendRequest(ContinueArguments(threadId: threadId));

  /// Sends a custom request to the server and waits for a response.
  Future<Response> custom(String name, Object? args) async {
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
  }) {
    return sendRequest(EvaluateArguments(
      expression: expression,
      frameId: frameId,
      context: context,
    ));
  }

  /// Returns a Future that completes with the next [event] event.
  Future<Event> event(String event) => _logIfSlow(
      'Event "$event"',
      _eventController.stream.firstWhere((e) => e.event == event,
          orElse: () =>
              throw 'Did not recieve $event event before stream closed'));

  /// Returns a stream for [event] events.
  Stream<Event> events(String event) {
    return _eventController.stream.where((e) => e.event == event);
  }

  /// Send an initialize request to the server.
  ///
  /// This occurs before the request to start running/debugging a script and is
  /// used to exchange capabilities and send breakpoints and other settings.
  Future<Response> initialize({String exceptionPauseMode = 'None'}) async {
    final responses = await Future.wait([
      event('initialized'),
      sendRequest(InitializeRequestArguments(adapterID: 'test')),
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
    String? cwd,
    bool? noDebug,
    bool? debugSdkLibraries,
    bool? debugExternalPackageLibraries,
    bool? evaluateGettersInDebugViews,
    bool? evaluateToStringInDebugViews,
  }) {
    return sendRequest(
      DartLaunchRequestArguments(
        noDebug: noDebug,
        program: program,
        cwd: cwd,
        args: args,
        debugSdkLibraries: debugSdkLibraries,
        debugExternalPackageLibraries: debugExternalPackageLibraries,
        evaluateGettersInDebugViews: evaluateGettersInDebugViews,
        evaluateToStringInDebugViews: evaluateToStringInDebugViews,
        // When running out of process, VM Service traffic won't be available
        // to the client-side logger, so force logging on which sends VM Service
        // traffic in a custom event.
        sendLogsToClient: captureVmServiceTraffic,
      ),
      // We can't automatically pick the command when using a custom type
      // (DartLaunchRequestArguments).
      overrideCommand: 'launch',
    );
  }

  /// Sends a next (step over) request for the given thread.
  ///
  /// Returns a Future that completes when the server returns a corresponding
  /// response.
  Future<Response> next(int threadId) =>
      sendRequest(NextArguments(threadId: threadId));

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
    _channel.close();
    await _socket.close();
    await _subscription.cancel();
  }

  Future<Response> terminate() => sendRequest(TerminateArguments());

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
  }) {
    return sendRequest(VariablesArguments(
      variablesReference: variablesReference,
      start: start,
      count: count,
    ));
  }

  /// Handles an incoming message from the server, completing the relevant request
  /// of raising the appropriate event.
  void _handleMessage(message) {
    if (message is Response) {
      final pendingRequest = _pendingRequests.remove(message.requestSeq);
      if (pendingRequest == null) {
        return;
      }
      final completer = pendingRequest.completer;
      if (message.success || pendingRequest.allowFailure) {
        completer.complete(message);
      } else {
        completer.completeError(message);
      }
    } else if (message is Event) {
      _eventController.add(message);

      // When we see a terminated event, close the event stream so if any
      // tests are waiting on something that will never come, they fail at
      // a useful location.
      if (message.event == 'terminated') {
        _eventController.close();
      }
    }
  }

  /// Prints a warning if [future] takes longer than [_requestWarningDuration]
  /// to complete.
  ///
  /// Returns [future].
  Future<T> _logIfSlow<T>(String name, Future<T> future) {
    var didComplete = false;
    future.then((_) => didComplete = true);
    Future.delayed(_requestWarningDuration).then((_) {
      if (!didComplete) {
        print(
            '$name has taken longer than ${_requestWarningDuration.inSeconds}s');
      }
    });
    return future;
  }

  /// Creates a [DapTestClient] that connects the server listening on
  /// [host]:[port].
  static Future<DapTestClient> connect(
    String host,
    int port, {
    bool captureVmServiceTraffic = false,
    Logger? logger,
  }) async {
    final socket = await Socket.connect(host, port);
    final channel = ByteStreamServerChannel(
        socket.transform(Uint8ListTransformer()), socket, logger);

    return DapTestClient._(socket, channel, logger,
        captureVmServiceTraffic: captureVmServiceTraffic);
  }
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
    Future<Response> Function()? launch,
  }) async {
    final stop = expectStop('breakpoint', file: file, line: line);

    await Future.wait([
      initialize(),
      sendRequest(
        SetBreakpointsArguments(
          source: Source(path: file.path),
          breakpoints: [SourceBreakpoint(line: line)],
        ),
      ),
      launch?.call() ?? this.launch(file.path),
    ], eagerError: true);

    return stop;
  }

  /// Returns whether DDS is available for the VM Service the debug adapter
  /// is connected to.
  Future<bool> get ddsAvailable async {
    final response = await custom(
      '_getSupportedProtocols',
      null,
    );

    // For convenience, use the ProtocolList to deserialise the custom
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
  Future<StoppedEventBody> expectStop(String reason,
      {File? file, int? line, String? sourceName}) async {
    final e = await event('stopped');
    final stop = StoppedEventBody.fromJson(e.body as Map<String, Object?>);
    expect(stop.reason, equals(reason));

    final result =
        await getValidStack(stop.threadId!, startFrame: 0, numFrames: 1);
    expect(result.stackFrames, hasLength(1));
    final frame = result.stackFrames[0];

    if (file != null) {
      expect(frame.source!.path, equals(file.path));
    }
    if (sourceName != null) {
      expect(frame.source!.name, equals(sourceName));
    }
    if (line != null) {
      expect(frame.line, equals(line));
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

  /// Fetches threads and asserts a valid response.
  Future<ThreadsResponseBody> getValidThreads() async {
    final response = await threads();
    expect(response.success, isTrue);
    expect(response.command, equals('threads'));
    return ThreadsResponseBody.fromJson(response.body as Map<String, Object?>);
  }

  /// A helper that fetches scopes for a frame, checks for one with the name
  /// [expectedName] and verifies its variables.
  Future<Scope> expectScopeVariables(
    int frameId,
    String expectedName,
    String expectedVariables, {
    bool ignorePrivate = true,
    Set<String>? ignore,
  }) async {
    final scope = await getValidScope(frameId, expectedName);
    await expectVariables(
      scope.variablesReference,
      expectedVariables,
      ignorePrivate: ignorePrivate,
      ignore: ignore,
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
  Future<void> expectLocalVariable(
    int threadId, {
    required String expectedName,
    required String expectedDisplayString,
    required String expectedVariables,
    int? start,
    int? count,
    bool ignorePrivate = true,
    Set<String>? ignore,
  }) async {
    final stack = await getValidStack(
      threadId,
      startFrame: 0,
      numFrames: 1,
    );
    final topFrame = stack.stackFrames.first;

    final variablesScope = await getValidScope(topFrame.id, 'Variables');
    final variables =
        await getValidVariables(variablesScope.variablesReference);
    final expectedVariable = variables.variables
        .singleWhere((variable) => variable.name == expectedName);

    // Check the display string.
    expect(expectedVariable.value, equals(expectedDisplayString));

    // Check the child fields.
    await expectVariables(
      expectedVariable.variablesReference,
      expectedVariables,
      start: start,
      count: count,
      ignorePrivate: ignorePrivate,
      ignore: ignore,
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
  }) async {
    final response = await variables(
      variablesReference,
      start: start,
      count: count,
    );
    expect(response.success, isTrue);
    expect(response.command, equals('variables'));
    return VariablesResponseBody.fromJson(
        response.body as Map<String, Object?>);
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
  }) async {
    final expectedLines =
        expectedVariables.trim().split('\n').map((l) => l.trim()).toList();

    final variables = await getValidVariables(
      variablesReference,
      start: start,
      count: count,
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

      buffer.write(v.name);
      if (evaluateName != null) {
        buffer.write(', eval: $evaluateName');
      }
      if (indexedVariables != null) {
        buffer.write(', $indexedVariables items');
      }
      if (namedVariables != null) {
        buffer.write(', $namedVariables named items');
      }
      buffer.write(': $value');
      if (type != null) {
        buffer.write(' ($type)');
      }
      if (presentationHint != null) {
        buffer.write(' ($presentationHint)');
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

  /// Evalutes [expression] in the top frame of thread [threadId] and expects a
  /// specific [expectedResult].
  Future<EvaluateResponseBody> expectTopFrameEvalResult(
    int threadId,
    String expression,
    String expectedResult,
  ) async {
    final stack = await getValidStack(threadId, startFrame: 0, numFrames: 1);
    final topFrameId = stack.stackFrames.first.id;

    return expectEvalResult(topFrameId, expression, expectedResult);
  }

  /// Evalutes [expression] in frame [frameId] and expects a specific
  /// [expectedResult].
  Future<EvaluateResponseBody> expectEvalResult(
    int frameId,
    String expression,
    String expectedResult,
  ) async {
    final response = await evaluate(expression, frameId: frameId);
    expect(response.success, isTrue);
    expect(response.command, equals('evaluate'));
    final body =
        EvaluateResponseBody.fromJson(response.body as Map<String, Object?>);

    expect(body.result, equals(expectedResult));

    return body;
  }
}
