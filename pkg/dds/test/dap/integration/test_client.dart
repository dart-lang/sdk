// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/src/dap/adapters/dart.dart';
import 'package:dds/src/dap/logging.dart';
import 'package:dds/src/dap/protocol_generated.dart';
import 'package:dds/src/dap/protocol_stream.dart';
import 'package:dds/src/dap/protocol_stream_transformers.dart';
import 'package:test/test.dart';

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

  Future<Response> disconnect() => sendRequest(DisconnectArguments());

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
      // TODO(dantup): Support setting exception pause modes.
      // sendRequest(
      //     SetExceptionBreakpointsArguments(filters: [exceptionPauseMode])),
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
    int port, {
    String host = 'localhost',
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
  Future<StoppedEventBody> hitBreakpoint(File file, int line,
      {Future<Response> Function()? launch}) async {
    final stop = expectStop('breakpoint', file: file, line: line);

    await Future.wait([
      initialize(),
      sendRequest(
        SetBreakpointsArguments(
            source: Source(path: file.path),
            breakpoints: [SourceBreakpoint(line: line)]),
      ),
      launch?.call() ?? this.launch(file.path),
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
}
