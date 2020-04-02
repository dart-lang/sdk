// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/protocol.dart';

///
/// Add server arguments.
///
/// TODO(danrubel): Consider moving all cmdline argument consts
/// out of analysis_server and into analysis_server_client.
List<String> getServerArguments({
  String clientId,
  String clientVersion,
  int diagnosticPort,
  String instrumentationLogFile,
  String sdkPath,
  bool suppressAnalytics,
  bool useAnalysisHighlight2 = false,
}) {
  var arguments = <String>[];

  if (clientId != null) {
    arguments.add('--client-id');
    arguments.add(clientId);
  }
  if (clientVersion != null) {
    arguments.add('--client-version');
    arguments.add(clientVersion);
  }
  if (suppressAnalytics) {
    arguments.add('--suppress-analytics');
  }
  if (diagnosticPort != null) {
    arguments.add('--port');
    arguments.add(diagnosticPort.toString());
  }
  if (instrumentationLogFile != null) {
    arguments.add('--instrumentation-log-file=$instrumentationLogFile');
  }
  if (sdkPath != null) {
    arguments.add('--sdk=$sdkPath');
  }
  if (useAnalysisHighlight2) {
    arguments.add('--useAnalysisHighlight2');
  }
  return arguments;
}

/// A function via which data can be sent to a started server.
typedef CommandSender = void Function(List<int> utf8bytes);

/// Type of callbacks used to process notifications.
typedef NotificationProcessor = void Function(Notification notification);

/// Implementations of the class [ServerBase] manage an analysis server,
/// and facilitate communication to and from the server.
///
/// Clients outside of this package may not extend or implement this class.
abstract class ServerBase {
  /// Replicate all data from the server process to stdout/stderr, when true.
  final bool _stdioPassthrough;

  /// Number which should be used to compute the 'id'
  /// to send in the next command sent to the server.
  int _nextId = 0;

  /// If not `null`, [_listener] will be sent information
  /// about interactions with the server.
  final ServerListener _listener;

  /// Commands that have been sent to the server but not yet acknowledged,
  /// and the [Completer] objects which should be completed
  /// when acknowledgement is received.
  final _pendingCommands = <String, Completer<Map<String, dynamic>>>{};

  ServerBase({ServerListener listener, bool stdioPassthrough = false})
      : _listener = listener,
        _stdioPassthrough = stdioPassthrough;

  ServerListener get listener => _listener;

  /// If the implementation of [ServerBase] captures an error stream,
  /// it can use this to forward the errors to [listener] and [stderr] if
  /// appropriate.
  void errorProcessor(
      String line, NotificationProcessor notificationProcessor) {
    if (_stdioPassthrough) stderr.writeln(line);
    var trimmedLine = line.trim();
    listener?.errorMessage(trimmedLine);
  }

  /// Force kill the server. Returns a future that completes when the server
  /// stops.
  Future kill({String reason = 'none'});

  /// Start listening to output from the server,
  /// and deliver notifications to [notificationProcessor].
  void listenToOutput({NotificationProcessor notificationProcessor});

  /// Handle a (possibly) json encoded object, completing the [Completer] in
  /// [_pendingCommands] corresponding to the response.  Reports problems in
  /// decoding or message synchronization using [listener], and replicates
  /// raw data to [stdout] as appropriate.
  void outputProcessor(
      String line, NotificationProcessor notificationProcessor) {
    if (_stdioPassthrough) stdout.writeln(line);
    var trimmedLine = line.trim();

    // Guard against lines like:
    //   {"event":"server.connected","params":{...}}Observatory listening on ...
    const observatoryMessage = 'Observatory listening on ';
    if (trimmedLine.contains(observatoryMessage)) {
      trimmedLine = trimmedLine
          .substring(0, trimmedLine.indexOf(observatoryMessage))
          .trim();
    }
    if (trimmedLine.isEmpty) {
      return;
    }

    listener?.messageReceived(trimmedLine);
    Map<String, dynamic> message;
    try {
      message = json.decoder.convert(trimmedLine);
    } catch (exception) {
      listener?.badMessage(trimmedLine, exception);
      return;
    }

    final id = message[Response.ID];
    if (id != null) {
      // Handle response
      final completer = _pendingCommands.remove(id);
      if (completer == null) {
        listener?.unexpectedResponse(message, id);
      }
      if (message.containsKey(Response.ERROR)) {
        completer.completeError(RequestError.fromJson(
            ResponseDecoder(null), '.error', message[Response.ERROR]));
      } else {
        completer.complete(message[Response.RESULT]);
      }
    } else {
      // Handle notification
      final String event = message[Notification.EVENT];
      if (event != null) {
        if (notificationProcessor != null) {
          notificationProcessor(
              Notification(event, message[Notification.PARAMS]));
        }
      } else {
        listener?.unexpectedMessage(message);
      }
    }
  }

  /// Send a command to the server. An 'id' will be automatically assigned.
  /// The returned [Future] will be completed when the server acknowledges
  /// the command with a response.
  /// If the server acknowledges the command with a normal (non-error) response,
  /// the future will be completed with the 'result' field from the response.
  /// If the server acknowledges the command with an error response,
  /// the future will be completed with an error.
  Future<Map<String, dynamic>> send(String method, Map<String, dynamic> params);

  /// Encodes a request for transmission and sends it as a utf8 encoded byte
  /// string with [sendWith].
  Future<Map<String, dynamic>> sendCommandWith(
      String method, Map<String, dynamic> params, CommandSender sendWith) {
    var id = '${_nextId++}';
    var command = <String, dynamic>{Request.ID: id, Request.METHOD: method};
    if (params != null) {
      command[Request.PARAMS] = params;
    }
    final completer = Completer<Map<String, dynamic>>();
    _pendingCommands[id] = completer;
    var line = json.encode(command);
    listener?.requestSent(line);
    sendWith(utf8.encoder.convert('$line\n'));
    return completer.future;
  }

  /// Start the server.  The returned future completes when the server
  /// is started and it is valid to call [listenToOutput].
  Future start({
    String clientId,
    String clientVersion,
    int diagnosticPort,
    String instrumentationLogFile,
    String sdkPath,
    bool suppressAnalytics,
    bool useAnalysisHighlight2,
  });

  /// Attempt to gracefully shutdown the server.
  /// If that fails, then force it to shut down.
  Future stop({Duration timeLimit});
}
