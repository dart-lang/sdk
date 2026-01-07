// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' hide File;

import 'package:analysis_server/src/server/driver.dart';
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

import 'log.dart';
import 'server_driver.dart';

/// Either reads in a log file and sends messages one at a time to the
/// analysis server, or reads them from stdin.
///
/// Note that a limited number of bytes at a time can be sent manually through
/// interactive terminals (4096 bytes on linux, 1028 on mac), which limites the
/// size of the messages that can be sent that way.
///
/// This is useful for manually testing the analysis server, or a given log.
Future<void> main(List<String> args) async {
  print('Starting analysis server...');
  var driver = ServerDriver(
    arguments: [
      '--${Driver.serverProtocolOption}',
      ServerProtocol.lsp.flagValue,
    ],
  );
  await driver.start();
  driver.serverMessages.listen((message) {
    print('<<< ${json.encode(message)}');
  });

  if (args.isEmpty) {
    sendManualMessages(driver);
  } else if (args.length == 1) {
    replayLogFile(args.single, driver);
  } else {
    print('Requires at most a single argument: the path to the log file.');
    exit(1);
  }
}

void replayLogFile(String path, ServerDriver driver) {
  var logFile = PhysicalResourceProvider.INSTANCE.getFile(p.normalize(path));
  if (!logFile.exists) {
    throw ArgumentError('Log file does not exist: ${logFile.path}');
  }
  print('Replaying log file at: $path with workspace folder: ${p.current}');
  var log = Log.fromFile(logFile, {'{{workspaceFolder-0}}': p.current});

  print('ready, hit enter to send next message');
  var entriesIterator = log.entries.iterator;
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    while (true) {
      if (!entriesIterator.moveNext()) {
        print('no more entries');
        break;
      }
      var entry = entriesIterator.current;
      if (entry.kind != EntryKind.message ||
          entry.receiver != ProcessId.server) {
        continue;
      } else {
        print('>>> ${json.encode(entry.message)}');
        driver.sendMessageFromIde(entry.message);
        break;
      }
    }
  });
}

void sendManualMessages(ServerDriver driver) {
  print('Enter JSON messages to send to the server, one per line:');
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    driver.sendMessageFromIde(Message(json.decode(line) as JsonMap));
  });
}
