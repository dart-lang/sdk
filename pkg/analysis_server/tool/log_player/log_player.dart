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
import 'package:cli_util/cli_logging.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/protocol_special.dart' show Either2;

import 'log.dart';
import 'message_equality.dart';
import 'server_driver.dart';

/// Some messages from the analysis server should just be ignored.
bool _shouldSkip(Message message) =>
    // This is the response to the initialize request.
    (message.id?.valueEquals(0) ?? false) ||
    // Notifications, we can skip these.
    message.id == null ||
    // These are unpredictable and noisy, we can silently ignore them for now.
    message.method == 'textDocument/publishDiagnostics';

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

  final Logger logger = Logger.standard();

  LogPlayer({required this.log, this.timeout = const Duration(seconds: 5)});

  /// Plays the log.
  Future<void> play() async {
    var entries = log.entries;
    var nextIndex = 0;
    ServerDriver? server;
    var pendingServerMessageExpectations = <Message>[];
    // These are messages from the server that we didn't expect, we keep them
    // around so we can match out of order messages, and also print them at the
    // end if we want.
    var extraServerMessages = <Message>[];
    // Maps the recorded message IDs for messages initiated by the analysis
    // server to the actual message IDs observed for this run.
    var actualServerMessageIds = <Either2<int, String>, Either2<int, String>>{};
    // Original recorded ids for work progress notifications. We will skip the
    // responses to these and not expect the requests as they are unreliable.
    var workProgressIds = <Either2<int, String>>{};
    try {
      while (nextIndex < entries.length) {
        try {
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
              server.serverMessages.listen(
                (message) => _handleServerMessage(
                  message,
                  server,
                  pendingServerMessageExpectations,
                  actualServerMessageIds,
                  extraServerMessages,
                ),
              );
            case EntryKind.message:
              if (entry.sender == ProcessId.ide &&
                  entry.receiver == ProcessId.server) {
                if (entry.message.isResponse &&
                    workProgressIds.contains(entry.message.id)) {
                  // Skip these responses, we return a canned response and ignore
                  // them in expectations.
                  continue;
                }
                // Rewrite the IDs for responses to the analysis server so they
                // match the real request ID.
                if (entry.message.isResponse) {
                  var actualId = actualServerMessageIds[entry.message.id];
                  if (actualId == null) {
                    throw StateError(
                      'Cannot respond to a server message that we haven\'t '
                      'received yet, expected an analysis server request with '
                      'ID: ${entry.message.id}\n${json.encode(entry)}',
                    );
                  }
                  entry.message.setId(actualId);
                }
                await _sendMessageToServer(entry, server);
              } else if (entry.sender == ProcessId.server &&
                  entry.receiver == ProcessId.ide) {
                var isServerInitiatedRequest = entry.message.method != null;
                var foundMessage = extraServerMessages.firstWhereOrNull(
                  (recorded) => recorded.equals(
                    entry.message,
                    skipMatchId: isServerInitiatedRequest,
                  ),
                );
                if (foundMessage != null) {
                  // We have already seen this message, just remove it from the
                  // list of extra messages.
                  extraServerMessages.remove(foundMessage);
                  if (isServerInitiatedRequest && entry.message.id != null) {
                    // Record the ID mapping if it was a server initiated request.
                    actualServerMessageIds[entry.message.id!] =
                        foundMessage.id!;
                  }
                  stderr.writeln(
                    'Matched previous message: ${foundMessage.preview}',
                  );
                } else if (isServerInitiatedRequest &&
                    entry.message.id == null) {
                  // This is a notification, ignore them for now.
                } else if (isServerInitiatedRequest &&
                    entry.message.method == 'window/workDoneProgress/create' &&
                    entry.message.params?['token'] == 'ANALYZING') {
                  // Ignore these, they are unreliable.
                  // There is corresponding code to always return a canned
                  // response to them.
                  workProgressIds.add(entry.message.id!);
                } else {
                  pendingServerMessageExpectations.add(entry.message);
                  // TODO(jakemac): Remove this once we are not reliant on
                  // consistent ordering.
                  await _waitForMessagesFromServer(
                    pendingServerMessageExpectations,
                    extraServerMessages,
                  );
                }
              } else if (entry.sender == ProcessId.watcher &&
                  entry.receiver == ProcessId.server) {
                await _sendMessageToServer(entry, server);
              } else {
                stderr.writeln(
                  'Unsupported sender/receiver for message:\n'
                  '${json.encode(entry)}',
                );
              }
          }
        } finally {
          nextIndex++;
        }
      }
      await _waitForMessagesFromServer(
        pendingServerMessageExpectations,
        extraServerMessages,
      );
      if (extraServerMessages.isNotEmpty) {
        stderr.writeln(
          'There were ${extraServerMessages.length} extra messages '
          'recieved from the server, but the scenario succeeded.',
        );
      }
    } finally {
      if (!_hasSeenShutdown) {
        server?.shutdown();
      }
      if (!_hasSeenExit) {
        server?.exit();
      }
    }
  }

  void _handleServerMessage(
    Message message,
    ServerDriver? server,
    List<Message> pendingServerMessageExpectations,
    Map<Either2<int, String>, Either2<int, String>> actualServerMessageIds,
    List<Message> extraServerMessages,
  ) {
    var isServerInitiatedRequest = message.method != null;

    // We always do canned responses to these.
    if (message.method == 'window/workDoneProgress/create' &&
        message.params?['token'] == 'ANALYZING') {
      server?.sendMessageFromIde(
        Message({'jsonrpc': '2.0', 'id': message.id, 'result': null}),
      );
      return;
    }

    // Check if this message matches any pending expectations.
    var foundMessage = pendingServerMessageExpectations.firstWhereOrNull(
      (recorded) =>
          recorded.equals(message, skipMatchId: isServerInitiatedRequest),
    );

    if (foundMessage != null) {
      if (isServerInitiatedRequest && message.id != null) {
        actualServerMessageIds[foundMessage.id!] = message.id!;
      }
      pendingServerMessageExpectations.remove(foundMessage);
    } else {
      // Anything else we record for future matching.
      extraServerMessages.add(message);

      if (message.method == 'workspace/configuration') {
        // The server always sends this but we don't always record it,
        // and it requires a response.
        server?.sendMessageFromIde(
          Message({
            'jsonrpc': '2.0',
            'id': message.id,
            'result': [
              {
                'analysisExcludedFolders': [],
                'clientRequestTime': DateTime.now().millisecond,
              },
            ],
          }),
        );
      } else if (message.method == 'client/registerCapability') {
        // The server always sends this but we don't always record
        // it, just return an empty response.
        server?.sendMessageFromIde(
          Message({'jsonrpc': '2.0', 'id': message.id, 'result': []}),
        );
      } else {
        if (!_shouldSkip(message)) {
          stderr.writeln(
            'Unexpected message from analysis server: ${message.preview}',
          );
        }
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
    List<Message> extraServerMessages,
  ) async {
    if (pendingServerMessageExpectations.isEmpty) return;
    var watch = Stopwatch()..start();
    var progress = logger.progress(
      'Waiting for ${pendingServerMessageExpectations.length} analysis server '
      'message(s): ${pendingServerMessageExpectations.first.preview}',
    );
    try {
      while (watch.elapsed < timeout) {
        if (pendingServerMessageExpectations.isEmpty) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
      throw TimeoutException(
        'Timed out waiting for analysis server messages:\n\n'
        '${pendingServerMessageExpectations.map((m) => m.preview).join('\n\n')}'
        '\n\nUnmatched analysis server messages:\n\n'
        '${extraServerMessages.map((m) => m.preview).join('\n\n')}',
      );
    } finally {
      progress.finish(showTiming: true);
    }
  }
}

extension MessageExtension on Message {
  static final _messageEquality = MessageEquality(ignoredKeys: {'version'});

  // A preview of the message, first 100 chars followed by "..."
  String get preview {
    var content = json.encode(map);
    if (content.length > 100) {
      content = '${content.substring(0, 100)}...';
    }
    return content;
  }

  bool equals(Message other, {bool skipMatchId = true}) =>
      _messageEquality.equals(this, other, skipMatchId: skipMatchId);

  // Can't be a setter https://github.com/dart-lang/language/issues/4334
  void setId(Either2<int, String> newId) =>
      // We always store the underlying value in the map, not the Either2,
      // because that matches what a real JSON map would have.
      map['id'] = newId.map((i) => i, (s) => s);
}
