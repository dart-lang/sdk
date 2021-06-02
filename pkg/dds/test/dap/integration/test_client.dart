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

import 'test_server.dart';

/// A helper class to simplify acting as a client for interacting with the
/// [DapTestServer] in tests.
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

  FutureOr<void> stop() async {
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
  static FutureOr<DapTestClient> connect(
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
