// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/server/driver.dart';
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

// Relative imports to log player tools
import '../../../../tool/log_player/log.dart';
import '../../../../tool/log_player/server_driver.dart';

Future<void> main(List<String> rawArgs) async {
  var parser = ArgParser()
    ..addOption(
      'request-id',
      abbr: 'i',
      help: 'Target request ID to measure latency for.',
    )
    ..addOption(
      'method',
      abbr: 'm',
      help: 'Target request method to measure latency for (first match if no ID).',
    )
    ..addOption(
      'workspace',
      abbr: 'w',
      help: 'Workspace directory to map {{workspaceFolder-0}} to (defaults to CWD).',
    )
    ..addOption(
      'repeat',
      abbr: 'r',
      help: 'Number of times to repeat the target request to measure consistency.',
      defaultsTo: '1',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display usage instructions.',
    );

  ArgResults args;
  try {
    args = parser.parse(rawArgs);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    _printUsage(parser);
    exit(1);
  }

  if (args.flag('help') || args.rest.isEmpty) {
    _printUsage(parser);
    exit(args.flag('help') ? 0 : 1);
  }

  var logPath = args.rest.first;
  var logFile = PhysicalResourceProvider.INSTANCE.getFile(p.normalize(logPath));
  if (!logFile.exists) {
    stderr.writeln('Error: Log file not found: $logPath');
    exit(1);
  }

  var workspaceDir = p.normalize(args.option('workspace') ?? p.current);
  var targetIdStr = args.option('request-id');
  var targetMethod = args.option('method');
  var repeatCount = int.tryParse(args.option('repeat') ?? '1') ?? 1;

  if (targetIdStr == null && targetMethod == null) {
    stderr.writeln(
      'Error: You must specify either --request-id (-i) or --method (-m).',
    );
    exit(1);
  }

  stdout.writeln('Loading and denormalizing log: $logPath');
  stdout.writeln('Workspace root: $workspaceDir');

  var normalizer = LogNormalizer()
    ..addReplacementsForPath(workspaceDir, 'workspaceFolder-0')
    ..addReplacementsForPath(workspaceDir, 'rootPath')
    ..addReplacementsForPath(workspaceDir, 'rootUri');

  var log = Log.fromFile(logFile, normalizer.denormalize);

  // Find target request entry in log.
  LogEntry? targetEntry;
  Message? targetMessage;
  for (var entry in log.entries) {
    if (_isServerBoundMessage(entry)) {
      var msg = _getMessage(entry);
      if (msg == null) continue;
      var msgId = msg.map['id']?.toString();
      var method = msg.method;

      if (targetIdStr != null && msgId == targetIdStr) {
        targetEntry = entry;
        targetMessage = msg;
        break;
      } else if (targetIdStr == null &&
          targetMethod != null &&
          method != null) {
        if (method.toLowerCase().contains(targetMethod.toLowerCase())) {
          targetEntry = entry;
          targetMessage = msg;
          break;
        }
      }
    }
  }

  if (targetEntry == null || targetMessage == null) {
    stderr.writeln('Error: Target request not found in log.');
    exit(1);
  }

  var targetId = targetMessage.map['id'];
  var targetReqMethod = targetMessage.method ?? '';
  stdout.writeln('Target request found: [ID $targetId] $targetReqMethod');

  stdout.writeln(
    'Starting analysis server (${Platform.resolvedExecutable})...',
  );
  var driver = ServerDriver(
    arguments: [
      '--${Driver.serverProtocolOption}',
      ServerProtocol.lsp.flagValue,
    ],
  );
  await driver.start();

  var analysisCompleter = Completer<void>();
  var responseCompleter = Completer<Message>();

  driver.serverMessages.listen((msg) {
    var method = msg.method;
    var msgMap = msg.map;

    // Handle workspace/configuration request from server.
    if (msg.isWorkspaceConfiguration) {
      var reqId = msgMap['id'];
      driver.sendMessageFromIde(
        Message({
          'jsonrpc': '2.0',
          'id': reqId,
          'result': [{}],
        }),
      );
      return;
    }

    // Track analysis progress.
    if (method == r'$/progress') {
      var params = msgMap['params'] as Map<String, dynamic>?;
      if (params?['token'] == 'ANALYZING') {
        var value = params?['value'] as Map<String, dynamic>?;
        var kind = value?['kind'] as String?;
        if (kind == 'end' && !analysisCompleter.isCompleted) {
          analysisCompleter.complete();
        }
      }
    }

    // Check for target response.
    if (msgMap['id'] == targetId) {
      if (!responseCompleter.isCompleted) {
        responseCompleter.complete(msg);
      }
    }
  });

  stdout.writeln('Feeding setup messages up to target request...');
  for (var entry in log.entries) {
    if (identical(entry, targetEntry)) {
      break;
    }
    if (_isServerBoundMessage(entry)) {
      var msg = _getMessage(entry);
      if (msg == null) continue;
      driver.sendMessageFromIde(msg);
      // Slight delay after initialized to let server launch analyzer isolates
      if (msg.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  stdout.writeln('Waiting for initial background analysis to complete...');
  try {
    await analysisCompleter.future.timeout(const Duration(seconds: 30));
    stdout.writeln('Background analysis finished. Server is warm.');
  } on TimeoutException {
    stdout.writeln(
      'Warning: Background analysis did not signal completion within 30s; proceeding anyway.',
    );
  }

  // Let event loop settle
  await Future.delayed(const Duration(milliseconds: 200));

  var measurements = <int>[];
  Message? lastResponse;

  stdout.writeln('\nExecuting target request ($repeatCount iteration(s))...');
  for (var i = 0; i < repeatCount; i++) {
    responseCompleter = Completer<Message>();
    var sw = Stopwatch()..start();
    driver.sendMessageFromIde(targetMessage);

    try {
      lastResponse = await responseCompleter.future.timeout(
        const Duration(seconds: 30),
      );
      sw.stop();
      var elapsedMs = sw.elapsedMilliseconds;
      measurements.add(elapsedMs);
      stdout.writeln('  Iteration ${i + 1}: $elapsedMs ms');
    } on TimeoutException {
      sw.stop();
      stdout.writeln('  Iteration ${i + 1}: TIMEOUT (> 30s)');
    }

    if (i + 1 < repeatCount) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  stdout.writeln('\n${'=' * 60}');
  stdout.writeln('LATENCY MEASUREMENT RESULTS');
  stdout.writeln('=' * 60);
  if (measurements.isNotEmpty) {
    var minMs = measurements.reduce((a, b) => a < b ? a : b);
    var maxMs = measurements.reduce((a, b) => a > b ? a : b);
    var avgMs = (measurements.reduce((a, b) => a + b) / measurements.length)
        .round();

    stdout.writeln('Method:               $targetReqMethod');
    stdout.writeln('Target Request ID:    $targetId');
    stdout.writeln('Iterations:           ${measurements.length}');
    stdout.writeln('Min Duration:         $minMs ms');
    stdout.writeln('Avg Duration:         $avgMs ms');
    stdout.writeln('Max Duration:         $maxMs ms');

    if (lastResponse != null) {
      var respMap = lastResponse.map;
      if (respMap.containsKey('error')) {
        stdout.writeln('Response Status:      ERROR: ${respMap["error"]}');
      } else {
        var result = respMap['result'];
        var resultStr = jsonEncode(result);
        var sizeBytes = resultStr.length;
        stdout.writeln('Response Status:      OK ($sizeBytes bytes)');
      }
    }
  } else {
    stdout.writeln('No successful measurements recorded.');
  }
  stdout.writeln('=' * 60);

  stdout.writeln('Shutting down server...');
  driver.shutdown();
  await Future.delayed(const Duration(milliseconds: 100));
  driver.exit();
  exit(0);
}

/// Safely extracts the [Message] from [entry], or returns `null` if absent or not a map.
Message? _getMessage(LogEntry entry) {
  var rawMessage = entry.map['message'];
  if (rawMessage is Map<String, dynamic>) {
    return Message(rawMessage);
  }
  return null;
}

/// Returns true if [entry] represents a message bound for the server (from the IDE / client).
///
/// This checks `receiver` and `sender` defensively, falling back to message structure
/// if `receiver` or `sender` are omitted from the log entry.
bool _isServerBoundMessage(LogEntry entry) {
  var map = entry.map;
  var kind = map['kind']?.toString();
  if (kind != null && kind.isNotEmpty && kind != 'message') {
    return false;
  }

  var rawMessage = map['message'];
  if (rawMessage is! Map<String, dynamic>) {
    return false;
  }

  var receiver = map['receiver']?.toString();
  if (receiver == 'server') return true;
  if (receiver != null && receiver.isNotEmpty && receiver != 'server') {
    return false;
  }

  var sender = map['sender']?.toString();
  if (sender == 'server') return false;
  if (sender == 'ide') return true;

  // If sender and receiver are absent, infer from message structure.
  var method = rawMessage['method'];
  if (method is String) {
    if (method.startsWith(r'$/') ||
        method.startsWith('window/') ||
        method == 'workspace/configuration') {
      return false;
    }
    return true;
  }

  return false;
}

void _printUsage(ArgParser parser) {
  stdout.writeln(
    'Usage: dart measure_request_latency.dart [options] <path_to_normalized_log>\n',
  );
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
}
