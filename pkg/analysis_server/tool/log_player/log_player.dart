// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/process_id.dart';

import 'log.dart';
import 'log_entry.dart';
import 'server_driver.dart';

/// An object used to play back the messages in a log.
///
/// A reasonable attempt is made to retain the same timing of messages as was
/// recorded in the log, but there isn't any way to do that perfectly.
class LogPlayer {
  /// The log to be played.
  Log log;

  /// The object used to communicate with the running server.
  ServerDriver server;

  /// Whether the `shutdown` method has been seen.
  bool _hasSeenShutdown = false;

  /// Whether the `exit` method has been seen.
  bool _hasSeenExit = false;

  LogPlayer({required this.log, required this.server});

  /// Plays the log.
  Future<void> play() async {
    // TODO(brianwilkerson): This doesn't currently attempt to retain the same
    //  timing of messages as was recorded in the log.
    var entries = log.entries;
    // TODO(brianwilkerson): Enhance the log entries to support an optional
    //  'started server' entry that includes the command-line arguments passed
    //  in to the server. If the extry is present then check here to see whether
    //  there are arguments that need to be passed to the server on start-up.
    for (var entry in entries) {
      if (entry.receiver == ProcessId.server) {
        await _sendMessageToServer(entry);
      } else if (entry.sender == ProcessId.server) {
        _handleMessageFromServer(entry);
      }
    }
    if (!_hasSeenShutdown) {
      server.shutdown();
    }
    if (!_hasSeenExit) {
      server.exit();
    }
  }

  /// Responds to a message sent from the server to some other process.
  void _handleMessageFromServer(LogEntry entry) {
    var message = entry.message;
    switch (entry.receiver) {
      case ProcessId.dtd:
        throw UnimplementedError();
      case ProcessId.ide:
        if (message.isLogMessage ||
            message.isShowDocument ||
            message.isShowMessage ||
            message.isShowMessageRequest) {
          // The response from the client should be recorded in the log, so it
          // will eventually be sent to the server.
          return;
        }
      // throw UnimplementedError();
      case ProcessId.plugin:
        throw UnimplementedError();
      case ProcessId.server:
        throw StateError(
          'Cannot send a message from the server to the server.',
        );
      case ProcessId.watcher:
        throw StateError(
          'Cannot send a message from the server to the file watcher.',
        );
    }
  }

  /// Sends the message in the [entry] to the server.
  Future<void> _sendMessageToServer(LogEntry entry) async {
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
}
