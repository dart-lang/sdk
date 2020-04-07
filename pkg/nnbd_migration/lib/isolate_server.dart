// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library implements [ServerBase], except unlike analysis_server_client's
/// `Server`, [Server] runs the analysis server in an isolate.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:analysis_server/starter.dart';
import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/src/server_base.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:stream_channel/isolate_channel.dart';

/// Wrap server arguments and communication port into a single parameter
/// for [Isolate.spawn].
class _IsolateParameters {
  final List<String> arguments;
  final SendPort sendPort;

  _IsolateParameters(this.arguments, this.sendPort);
}

/// Manage an analysis_server launched in an isolate.
class Server extends ServerBase {
  /// Server isolate object, or `null` if server hasn't been started yet
  /// or if the server has already been stopped.
  Isolate _isolate;

  /// The [ReceivePort] data subscription via an [IsolateChannel], or `null`
  /// if either [listenToOutput] has not been called or [stop] has been called.
  StreamSubscription<String> _receiveSubscription;

  /// Construct a Server.
  ///
  /// [isolate] and [isolateChannel] are testing-only parameters, allowing
  /// you to bypass start().
  Server(
      {ServerListener listener,
      Isolate isolate,
      IsolateChannel isolateChannel,
      bool stdioPassthrough = false})
      : _isolate = isolate,
        _isolateChannel = isolateChannel,
        super(listener: listener, stdioPassthrough: stdioPassthrough);

  /// Completes when the [_isolate] has exited.
  Completer isolateExited = Completer();

  /// The [IsolateChannel] by which this class communicates with the [_isolate].
  IsolateChannel _isolateChannel;

  /// Force kill the server.  The returned future completes when the isolate
  /// is dead.
  Future<void> kill({String reason = 'none'}) {
    listener?.killingServerProcess(reason);
    final isolate = _isolate;
    final isolateExitedOriginal = isolateExited;
    _isolate = null;
    isolateExited = null;
    isolate.kill(priority: Isolate.immediate);
    return isolateExitedOriginal.future;
  }

  /// Start listening to output from the server,
  /// and deliver notifications to [notificationProcessor].
  void listenToOutput({NotificationProcessor notificationProcessor}) {
    _receiveSubscription = _isolateChannel.stream
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) => outputProcessor(line, notificationProcessor));
  }

  /// Send a command to the server. An 'id' will be automatically assigned.
  /// The returned [Future] will be completed when the server acknowledges
  /// the command with a response.
  /// If the server acknowledges the command with a normal (non-error) response,
  /// the future will be completed with the 'result' field from the response.
  /// If the server acknowledges the command with an error response,
  /// the future will be completed with an error.
  Future<Map<String, dynamic>> send(
          String method, Map<String, dynamic> params) =>
      sendCommandWith(method, params, _isolateChannel.sink.add);

  /// Start the server in a new [Isolate].
  Future start({
    String clientId,
    String clientVersion,
    int diagnosticPort,
    String instrumentationLogFile,
    String sdkPath,
    bool suppressAnalytics = true,
    bool useAnalysisHighlight2 = false,
  }) async {
    if (_isolate != null) {
      throw Exception('Isolate already started');
    }

    // Even though this is an isolate, most of the analysis server code
    // can't tell the difference.  So we construct "command line" arguments
    // just the same as analysis_server_client.
    List<String> arguments = [];
    arguments.addAll(getServerArguments(
        clientId: clientId,
        clientVersion: clientVersion,
        suppressAnalytics: suppressAnalytics,
        diagnosticPort: diagnosticPort,
        instrumentationLogFile: instrumentationLogFile,
        sdkPath: sdkPath,
        useAnalysisHighlight2: useAnalysisHighlight2));

    listener?.startingServer('((isolate))', arguments);
    ReceivePort receivePort = ReceivePort();
    ReceivePort onExitReceivePort = ReceivePort();
    ReceivePort onErrorReceivePort = ReceivePort();
    onExitReceivePort.listen((_) {
      isolateExited.complete(0);
    });
    onErrorReceivePort.listen((_) {
      listener?.unexpectedStop(null);
    });
    _isolateChannel = IsolateChannel<List<int>>.connectReceive(receivePort);
    _isolate = await Isolate.spawn(
        _runIsolate, _IsolateParameters(arguments, receivePort.sendPort),
        onExit: onExitReceivePort.sendPort);
  }

  /// This is the function passed to [Isolate.spawn] to actually begin
  /// the server.
  static void _runIsolate(_IsolateParameters parameters) {
    ServerStarter starter = ServerStarter();
    // TODO(jcollins-g): consider a refactor that does not require passing
    // text arguments to start the server.
    starter.start(parameters.arguments, parameters.sendPort);
  }

  /// Attempt to gracefully shutdown the server.
  /// If that fails, then kill the isolate.
  Future<void> stop({Duration timeLimit}) async {
    timeLimit ??= const Duration(seconds: 5);
    if (_isolate == null) {
      // isolate already exited
      return;
    }
    final future = send(SERVER_REQUEST_SHUTDOWN, null);
    final isolate = _isolate;
    _isolate = null;
    await future
        // fall through to wait for exit
        .timeout(timeLimit, onTimeout: () {
      return null;
    }).whenComplete(() async {
      await _receiveSubscription?.cancel();
      _receiveSubscription = null;
    });
    return isolateExited.future.timeout(timeLimit, onTimeout: () {
      listener?.killingServerProcess('server failed to exit');
      isolate.kill(priority: Isolate.immediate);
    });
  }
}
