// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

Future<void> main(List<String> rawArgs) async {
  var parser = ArgParser()
    ..addOption(
      'method',
      abbr: 'm',
      help: 'Filter requests by method name (substring or exact match).',
    )
    ..addOption(
      'min-ms',
      help: 'Only show requests with duration >= this value (in milliseconds).',
      defaultsTo: '0',
    )
    ..addOption(
      'top',
      abbr: 'n',
      help: 'Show the top N slowest requests (0 to show all).',
      defaultsTo: '25',
    )
    ..addFlag(
      'warm-only',
      abbr: 'w',
      negatable: false,
      help:
          'Show only warm requests (exclude requests queued during analysis).',
    )
    ..addFlag(
      'summary',
      abbr: 's',
      negatable: false,
      help: 'Print summary table of methods with latency statistics.',
    )
    ..addFlag(
      'errors',
      abbr: 'e',
      negatable: false,
      help: 'Show only requests that resulted in error responses.',
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
  var logFile = File(logPath);
  if (!logFile.existsSync()) {
    stderr.writeln('Error: Log file not found: $logPath');
    exit(1);
  }

  var minMs = int.tryParse(args.option('min-ms') ?? '0') ?? 0;
  var topN = int.tryParse(args.option('top') ?? '25') ?? 25;
  var methodFilter = args.option('method')?.toLowerCase();
  var warmOnly = args.flag('warm-only');
  var errorsOnly = args.flag('errors');
  var showSummary = args.flag('summary');

  var analyzer = SessionLogAnalyzer();
  await analyzer.processFile(logFile);

  analyzer.printReport(
    methodFilter: methodFilter,
    minMs: minMs,
    topN: topN,
    warmOnly: warmOnly,
    errorsOnly: errorsOnly,
    showSummary: showSummary,
  );
}

void _printUsage(ArgParser parser) {
  stdout.writeln(
    'Usage: dart analyze_session_log.dart [options] <path_to_session_log>\n',
  );
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
}

class SessionLogAnalyzer {
  final List<_CompletedRequest> _completedRequests = [];
  final List<String> _crashesOrExceptions = [];
  final Map<dynamic, _PendingRequest> _pendingRequests = {};

  int _analysisPeriodsCount = 0;
  int _clientRequestsCount = 0;
  bool _isAnalyzing = false;
  int? _lastAnalysisEndTime;
  int _serverResponsesCount = 0;
  int _totalEntries = 0;

  void printReport({
    String? methodFilter,
    required int minMs,
    required int topN,
    required bool warmOnly,
    required bool errorsOnly,
    required bool showSummary,
  }) {
    stdout.writeln('=' * 80);
    stdout.writeln('SESSION LOG ANALYSIS REPORT');
    stdout.writeln('=' * 80);
    stdout.writeln('Total Entries:        $_totalEntries');
    stdout.writeln('Client Requests:      $_clientRequestsCount');
    stdout.writeln('Server Responses:     $_serverResponsesCount');
    stdout.writeln('Completed Pairs:      ${_completedRequests.length}');
    stdout.writeln('Analysis Periods:     $_analysisPeriodsCount');
    if (_crashesOrExceptions.isNotEmpty) {
      stdout.writeln('Logged Exceptions:    ${_crashesOrExceptions.length}');
    }
    stdout.writeln('-' * 80);

    // Filter requests
    var filtered = _completedRequests.where((req) {
      if (methodFilter != null &&
          !req.method.toLowerCase().contains(methodFilter)) {
        return false;
      }
      if (req.durationMs < minMs) return false;
      if (warmOnly && req.isCold) return false;
      if (errorsOnly && !req.isError) return false;
      return true;
    }).toList();

    // Sort by duration descending
    filtered.sort((a, b) => b.durationMs.compareTo(a.durationMs));

    if (showSummary || (methodFilter == null && minMs == 0 && !errorsOnly)) {
      _printSummaryTable(filtered);
    }

    stdout.writeln(
      '\nREQUESTS (showing up to ${topN == 0 ? "all" : topN} matching, sorted by duration desc):',
    );
    stdout.writeln('-' * 80);

    if (filtered.isEmpty) {
      stdout.writeln('No requests matched the specified filters.');
    } else {
      var displayCount = topN > 0
          ? min(topN, filtered.length)
          : filtered.length;
      stdout.writeln(
        '${"ID".padRight(6)} ${"Method".padRight(32)} ${"ClientDur".padLeft(10)} '
        '${"ServerDur".padLeft(10)} ${"State".padRight(6)} ${"Status".padRight(7)} Target File',
      );
      stdout.writeln('-' * 80);

      for (var i = 0; i < displayCount; i++) {
        var req = filtered[i];
        var idStr = req.id.toString().padRight(6);
        var methodStr = _truncate(req.method, 32).padRight(32);
        var clientDurStr = req.clientDurationMs != null
            ? '${req.clientDurationMs} ms'
            : '-';
        var serverDurStr = '${req.serverDurationMs} ms';
        var stateStr = (req.isCold ? 'COLD' : 'WARM').padRight(6);
        var statusStr = (req.isError ? 'ERROR' : 'OK').padRight(7);
        var fileStr = req.uri.isEmpty ? '-' : _shortenUri(req.uri);

        stdout.writeln(
          '$idStr $methodStr ${clientDurStr.padLeft(10)} ${serverDurStr.padLeft(10)} '
          '$stateStr $statusStr $fileStr',
        );
        if (req.isError && req.errorMessage.isNotEmpty) {
          stdout.writeln('       └─ Error: ${req.errorMessage}');
        }
      }

      if (filtered.length > displayCount) {
        stdout.writeln(
          '\n... and ${filtered.length - displayCount} more requests (use --top=0 to display all).',
        );
      }
    }

    if (_crashesOrExceptions.isNotEmpty) {
      stdout.writeln('\n${'=' * 80}');
      stdout.writeln('LOGGED SERVER EXCEPTIONS / ERRORS');
      stdout.writeln('=' * 80);
      for (var i = 0; i < min(3, _crashesOrExceptions.length); i++) {
        stdout.writeln('[#${i + 1}] ${_crashesOrExceptions[i].trim()}');
        stdout.writeln('-' * 40);
      }
      if (_crashesOrExceptions.length > 3) {
        stdout.writeln(
          '... and ${_crashesOrExceptions.length - 3} more exception logs.',
        );
      }
    }
  }

  Future<void> processFile(File file) async {
    var stream = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (var line in stream) {
      line = line.trim();
      if (line.isEmpty) continue;
      _totalEntries++;

      Map<String, dynamic> entry;
      try {
        entry = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }

      var time = (entry['time'] as num?)?.toInt() ?? 0;
      var sender = entry['sender']?.toString() ?? '';
      var receiver = entry['receiver']?.toString() ?? '';
      var rawMessage = entry['message'];
      if (rawMessage is! Map<String, dynamic>) continue;
      var message = rawMessage;

      // Track analysis progress tokens.
      var method = message['method'] as String?;
      if (method == r'$/progress') {
        var params = message['params'] as Map<String, dynamic>?;
        if (params != null && params['token'] == 'ANALYZING') {
          var value = params['value'] as Map<String, dynamic>?;
          if (value != null) {
            var progressKind = value['kind'] as String?;
            if (progressKind == 'begin') {
              _isAnalyzing = true;
              _analysisPeriodsCount++;
            } else if (progressKind == 'end') {
              _isAnalyzing = false;
              _lastAnalysisEndTime = time;
            }
          }
        }
      }

      // Track window/logMessage errors.
      if (method == 'window/logMessage') {
        var params = message['params'] as Map<String, dynamic>?;
        var logText = params?['message'] as String? ?? '';
        if (logText.contains('An error occurred') ||
            logText.contains('Exception') ||
            logText.contains('Bad state')) {
          _crashesOrExceptions.add(logText);
        }
      }

      // Client request: IDE -> Server (or inferred from request structure if sender/receiver omitted).
      var isClientRequest =
          (sender == 'ide' && receiver == 'server') ||
          (sender.isEmpty &&
              receiver.isEmpty &&
              method != null &&
              message.containsKey('id') &&
              !method.startsWith(r'$/') &&
              !method.startsWith('window/'));

      if (isClientRequest) {
        var id = message['id'];
        if (id != null && method != null) {
          _clientRequestsCount++;
          var params = message['params'] as Map<String, dynamic>?;
          var uri =
              params?['textDocument']?['uri'] as String? ??
              params?['uri'] as String? ??
              '';

          _pendingRequests[id] = _PendingRequest(
            id: id,
            method: method,
            startTime: time,
            clientRequestTime: (message['clientRequestTime'] as num?)?.toInt(),
            wasAnalyzingAtStart: _isAnalyzing,
            hadInitialAnalysisCompleted: _lastAnalysisEndTime != null,
            uri: uri,
          );
        }
      }

      // Server response: Server -> IDE (or inferred from response structure if sender/receiver omitted).
      var isServerResponse =
          (sender == 'server' && receiver == 'ide') ||
          (sender.isEmpty &&
              receiver.isEmpty &&
              method == null &&
              message.containsKey('id') &&
              (message.containsKey('result') || message.containsKey('error')));

      if (isServerResponse) {
        var id = message['id'];
        if (id != null &&
            (message.containsKey('result') || message.containsKey('error'))) {
          _serverResponsesCount++;
          var pending = _pendingRequests.remove(id);
          if (pending != null) {
            var isError = message.containsKey('error');
            var errorMap = message['error'] as Map<String, dynamic>?;
            var errorMessage = errorMap?['message'] as String? ?? '';

            _completedRequests.add(
              _CompletedRequest(
                id: id,
                method: pending.method,
                startTime: pending.startTime,
                endTime: time,
                clientRequestTime: pending.clientRequestTime,
                wasAnalyzingAtStart: pending.wasAnalyzingAtStart,
                hadInitialAnalysisCompleted:
                    pending.hadInitialAnalysisCompleted,
                uri: pending.uri,
                isError: isError,
                errorMessage: errorMessage,
              ),
            );
          }
        }
      }
    }
  }

  void _printSummaryTable(List<_CompletedRequest> requests) {
    var byMethod = <String, List<_CompletedRequest>>{};
    for (var r in requests) {
      byMethod.putIfAbsent(r.method, () => []).add(r);
    }

    var rows = <_MethodStat>[];
    for (var entry in byMethod.entries) {
      var reqs = entry.value;
      var warmReqs = reqs.where((r) => !r.isCold).toList();
      var durations = reqs.map((r) => r.durationMs).toList()..sort();
      var warmDurations = warmReqs.map((r) => r.durationMs).toList()..sort();

      var count = reqs.length;
      var warmCount = warmReqs.length;
      var minDur = durations.first;
      var maxDur = durations.last;
      var avgDur = (durations.reduce((a, b) => a + b) / count).round();
      var warmAvg = warmDurations.isNotEmpty
          ? (warmDurations.reduce((a, b) => a + b) / warmCount).round()
          : 0;
      var warmMax = warmDurations.isNotEmpty ? warmDurations.last : 0;
      var errorCount = reqs.where((r) => r.isError).length;

      rows.add(
        _MethodStat(
          method: entry.key,
          count: count,
          warmCount: warmCount,
          minMs: minDur,
          avgMs: avgDur,
          maxMs: maxDur,
          warmAvgMs: warmAvg,
          warmMaxMs: warmMax,
          errorCount: errorCount,
        ),
      );
    }

    // Sort by max duration descending
    rows.sort((a, b) => b.maxMs.compareTo(a.maxMs));

    stdout.writeln('LATENCY SUMMARY BY METHOD:');
    stdout.writeln(
      '${"Method".padRight(32)} ${"Total".padLeft(6)} ${"Warm".padLeft(6)} '
      '${"Min(ms)".padLeft(8)} ${"Avg(ms)".padLeft(8)} ${"Max(ms)".padLeft(8)} '
      '${"WarmAvg".padLeft(8)} ${"WarmMax".padLeft(8)} ${"Errors".padLeft(7)}',
    );
    stdout.writeln('-' * 98);

    for (var row in rows) {
      stdout.writeln(
        '${_truncate(row.method, 32).padRight(32)} '
        '${row.count.toString().padLeft(6)} '
        '${row.warmCount.toString().padLeft(6)} '
        '${row.minMs.toString().padLeft(8)} '
        '${row.avgMs.toString().padLeft(8)} '
        '${row.maxMs.toString().padLeft(8)} '
        '${row.warmAvgMs.toString().padLeft(8)} '
        '${row.warmMaxMs.toString().padLeft(8)} '
        '${row.errorCount > 0 ? row.errorCount.toString().padLeft(7) : "-".padLeft(7)}',
      );
    }
  }

  String _shortenUri(String uri) {
    var decoded = Uri.decodeComponent(uri);
    var slashIndex = decoded.lastIndexOf('/');
    if (slashIndex != -1) {
      return decoded.substring(slashIndex + 1);
    }
    return decoded;
  }

  String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen - 3)}...';
  }
}

class _CompletedRequest {
  final dynamic id;
  final String method;
  final int startTime;
  final int endTime;
  final int? clientRequestTime;
  final bool wasAnalyzingAtStart;
  final bool hadInitialAnalysisCompleted;
  final String uri;
  final bool isError;
  final String errorMessage;

  new({
    required this.id,
    required this.method,
    required this.startTime,
    required this.endTime,
    required this.clientRequestTime,
    required this.wasAnalyzingAtStart,
    required this.hadInitialAnalysisCompleted,
    required this.uri,
    required this.isError,
    required this.errorMessage,
  });

  int? get clientDurationMs =>
      clientRequestTime != null ? endTime - clientRequestTime! : null;
  int get durationMs => clientDurationMs ?? serverDurationMs;

  /// A request is cold if background analysis was in progress when it was sent,
  /// or if initial analysis had never finished yet.
  bool get isCold => wasAnalyzingAtStart || !hadInitialAnalysisCompleted;

  int get serverDurationMs => endTime - startTime;
}

class _MethodStat {
  final String method;
  final int count;
  final int warmCount;
  final int minMs;
  final int avgMs;
  final int maxMs;
  final int warmAvgMs;
  final int warmMaxMs;
  final int errorCount;

  new({
    required this.method,
    required this.count,
    required this.warmCount,
    required this.minMs,
    required this.avgMs,
    required this.maxMs,
    required this.warmAvgMs,
    required this.warmMaxMs,
    required this.errorCount,
  });
}

class _PendingRequest {
  final dynamic id;
  final String method;
  final int startTime;
  final int? clientRequestTime;
  final bool wasAnalyzingAtStart;
  final bool hadInitialAnalysisCompleted;
  final String uri;

  new({
    required this.id,
    required this.method,
    required this.startTime,
    required this.clientRequestTime,
    required this.wasAnalyzingAtStart,
    required this.hadInitialAnalysisCompleted,
    required this.uri,
  });
}
