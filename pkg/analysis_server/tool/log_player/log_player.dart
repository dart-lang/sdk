// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/server/driver.dart';
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:collection/collection.dart';

import 'log.dart';
import 'server_driver.dart';

/// Some messages from the analysis server should just be ignored.
bool _shouldSkip(Message message) =>
    // The server always sends this but we don't record it.
    message.method == 'workspace/configuration' ||
    // This is the response to the initialize request.
    message.id == 0;

/// An object used to play back the messages in a log.
///
/// A reasonable attempt is made to retain the same timing of messages as was
/// recorded in the log, but there isn't any way to do that perfectly.
class LogPlayer {
  /// The log to be played.
  Log log;

  /// Whether the `shutdown` method has been seen.
  bool _hasSeenShutdown = false;

  /// Whether the `exit` method has been seen.
  bool _hasSeenExit = false;

  /// Arg parser equivalent to what the real driver uses, used to extract
  /// options from command line arguments.
  final driverArgParser = Driver.createArgParser();

  /// How long to wait for expected analyzer logs to come back.
  final Duration timeout;

  LogPlayer({required this.log, this.timeout = const Duration(seconds: 5)});

  /// Plays the log.
  Future<void> play() async {
    var entries = log.entries;
    var nextIndex = 0;
    ServerDriver? server;
    var pendingServerMessageExpectations = <Message>[];
    // Maps the recorded message IDs for messages initiated by the analysis
    // server to the actual message IDs observed for this run.
    var actualServerMessageIds = <int, int>{};
    try {
      while (nextIndex < entries.length) {
        // TODO(brianwilkerson): This doesn't currently attempt to retain the same
        //  timing of messages as was recorded in the log.
        var entry = entries[nextIndex];
        switch (entry.kind) {
          case EntryKind.commandLine:
            if (server != null) {
              throw StateError(
                'Analysis server already started, only one instance is allowed.',
              );
            }
            server = ServerDriver(arguments: entry.argList);
            await server.start();
            server.serverMessages.listen((message) {
              var isServerInitiatedRequest = message.method != null;
              var foundMessage = pendingServerMessageExpectations
                  .firstWhereOrNull(
                    (recorded) => recorded.equals(
                      message,
                      skipMatchId: isServerInitiatedRequest,
                    ),
                  );

              if (foundMessage != null) {
                if (isServerInitiatedRequest) {
                  actualServerMessageIds[foundMessage.id] = message.id;
                }
                pendingServerMessageExpectations.remove(foundMessage);
              } else if (!_shouldSkip(message)) {
                stderr.writeln(
                  'Unexpected message from analysis server:\n'
                  '${jsonEncode(message)}',
                );
              }
            });
          case EntryKind.message:
            if (entry.receiver == ProcessId.server) {
              // Rewrite the IDs for responses to the analysis server so they
              // match the real request ID.
              if (entry.message.isResponse) {
                var actualId = actualServerMessageIds[entry.message.id];
                if (actualId == null) {
                  throw StateError(
                    'Cannot respond to a server message that we haven\'t '
                    'received yet, expected an analysis server request with '
                    'ID: ${entry.message.id}',
                  );
                }
                entry.message.setId(actualId);
              }
              await _sendMessageToServer(entry, server);
            } else if (entry.sender == ProcessId.server) {
              pendingServerMessageExpectations.add(entry.message);
              // TODO(jakemac): Remove this once are not reliant on consistent
              // ordering.
              await _waitForMessagesFromServer(
                pendingServerMessageExpectations,
              );
            } else {
              throw StateError('''
Unexpected sender/receiver for message:

sender: ${entry.sender}
receiver: ${entry.receiver}
''');
            }
        }
        nextIndex++;
      }
      await _waitForMessagesFromServer(pendingServerMessageExpectations);
    } finally {
      if (!_hasSeenShutdown) {
        server?.shutdown();
      }
      if (!_hasSeenExit) {
        server?.exit();
      }
    }
  }

  /// Sends the message in the [entry] to the server.
  Future<void> _sendMessageToServer(
    LogEntry entry,
    ServerDriver? server,
  ) async {
    if (server == null) {
      throw StateError('Analysis server not started.');
    }
    var message = entry.message;
    switch (entry.sender) {
      case ProcessId.dtd:
        server.sendMessageFromDTD(message);
      case ProcessId.ide:
        if (message.isRequestToConnectWithDtd) {
          // Replace the original message with one that will allow the driver to
          // communicate as if it were DTD.
          await server.connectToDtd();
          return;
        }
        // Record when a shudown and/or exit request has been seen so that we
        // know whether to force send them after all of the messages in the
        // log have been seen.
        if (message.isShutdown) {
          _hasSeenShutdown = true;
        } else if (message.isExit) {
          _hasSeenExit = true;
        }
        server.sendMessageFromIde(message);
      case ProcessId.plugin:
        server.sendMessageFromPluginIsolate(message);
      case ProcessId.server:
        throw UnsupportedError(
          'Cannot send a message from the server to the server.',
        );
      case ProcessId.watcher:
        server.sendMessageFromFileWatcher(message);
    }
  }

  /// Waits up to 5 seconds for [pendingServerMessageExpectations] to be
  /// emptied out.
  Future<void> _waitForMessagesFromServer(
    List<Message> pendingServerMessageExpectations,
  ) async {
    if (pendingServerMessageExpectations.isEmpty) return;
    var watch = Stopwatch()..start();
    while (watch.elapsed < timeout) {
      if (pendingServerMessageExpectations.isEmpty) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    throw TimeoutException(
      'Timed out waiting for analysis server messages:\n\n'
      '${pendingServerMessageExpectations.join('\n\n')}',
    );
  }
}

extension MessageExtension on Message {
  bool equals(Message other, {bool skipMatchId = true}) {
    if (method != other.method) return false;
    if (!skipMatchId && id != other.id) return false;
    return switch (method) {
      // No method means this is a response, compare the result.
      null => const DeepCollectionEquality().equals(result, other.result),
      // A method means this is a request, compare the params.
      String() => const DeepCollectionEquality().equals(params, other.params),
    };
  }

  // Can't be a setter https://github.com/dart-lang/language/issues/4334
  void setId(int newId) => map['id'] = newId;
}
