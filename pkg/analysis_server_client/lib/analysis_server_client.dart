// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Type of callbacks used to process notification.
typedef void NotificationProcessor(String event, Map<String, Object> params);

/// Instances of the class [AnalysisServerClient] manage a connection to an
/// [AnalysisServer] process, and facilitate communication to and from the
/// client/user.
class AnalysisServerClient {
  /// AnalysisServer process object, or null if the server has been shut down.
  final Process _process;

  /// Commands that have been sent to the server but not yet acknowledged,
  /// and the [Completer] objects which should be completed when
  /// acknowledgement is received.
  final Map<String, Completer> _pendingCommands = <String, Completer>{};

  /// Number which should be used to compute the 'id' to send to the next
  /// command sent to the server.
  int _nextId = 0;

  AnalysisServerClient(this._process);

  /// Return a future that will complete when all commands that have been
  /// sent to the server so far have been flushed to the OS buffer.
  Future<Null> flushCommands() {
    return _process.stdin.flush();
  }

  void listenToOutput({NotificationProcessor notificationProcessor}) {
    _process.stdout
        .transform((new Utf8Codec()).decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      String trimmedLine = line.trim();
      if (trimmedLine.startsWith('Observatory listening on ')) {
        return;
      }
      final result = JSON.decoder.convert(trimmedLine) as Map;
      if (result.containsKey('id')) {
        final id = result['id'] as String;
        final completer = _pendingCommands.remove(id);

        if (result.containsKey('error')) {
          completer.completeError(new ServerErrorMessage(result['error']));
        } else {
          completer.complete(result['result']);
        }
      } else if (notificationProcessor != null && result.containsKey('event')) {
        // Message is a notification. It should have an event and possibly
        // params.
        notificationProcessor(result['event'], result['params']);
      }
    });
  }

  /// Sends a command to the server. An 'id' will be automatically assigned.
  /// The returned [Future] will be completed when the server acknowledges
  /// the command with a response. If the server acknowledges the command
  /// with a normal (non-error) response, the future will be completed
  /// with the 'result' field from the response. If the server acknowledges
  /// the command with an error response, the future will be completed with an
  /// error.
  Future send(String method, Map<String, dynamic> params) {
    String id = '${_nextId++}';
    Map<String, dynamic> command = <String, dynamic>{
      'id': id,
      'method': method
    };
    if (params != null) {
      command['params'] = params;
    }
    Completer completer = new Completer();
    _pendingCommands[id] = completer;
    String commandAsJson = JSON.encode(command);
    _process.stdin.add(UTF8.encoder.convert('$commandAsJson\n'));
    return completer.future;
  }

  /// Force kill the server. Returns exit code future.
  Future<int> kill() {
    _process.kill();
    return _process.exitCode;
  }
}

class ServerErrorMessage {
  final Map errorJson;

  ServerErrorMessage(this.errorJson);

  String get code => errorJson['code'].toString();
  String get message => errorJson['message'];
  String get stackTrace => errorJson['stackTrace'];
}
