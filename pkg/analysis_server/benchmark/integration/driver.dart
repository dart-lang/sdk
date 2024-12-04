// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' show max, sqrt;

import 'package:logging/logging.dart';
import 'package:path/path.dart';

import '../../test/integration/support/integration_test_methods.dart';
import '../../test/integration/support/integration_tests.dart';
import 'operation.dart';

/// [Driver] launches and manages an instance of analysis server,
/// reads a stream of operations, sends requests to analysis server
/// based upon those operations, and evaluates the results.
class Driver extends IntegrationTest {
  /// The amount of time to give the server to respond to a shutdown request
  /// before forcibly terminating it.
  static const Duration SHUTDOWN_TIMEOUT = Duration(seconds: 5);

  final Logger logger = Logger('Driver');

  /// The diagnostic port for Analysis Server or `null` if none.
  final int? diagnosticPort;

  /// A flag indicating whether the server is running.
  bool running = false;

  @override
  late Server server;

  /// The results collected while running analysis server.
  final Results results = Results();

  /// The [Completer] for [runComplete].
  final Completer<Results> _runCompleter = Completer<Results>();

  Driver({this.diagnosticPort});

  /// Return a [Future] that completes with the [Results] of running
  /// the analysis server once all operations have been performed.
  Future<Results> get runComplete => _runCompleter.future;

  /// Perform the given operation.
  ///
  /// Return a [Future] that completes when the next operation can be performed,
  /// or `null` if the next operation can be performed immediately
  Future<void>? perform(Operation op) {
    return op.perform(this);
  }

  /// Send a command to the server.
  ///
  /// An 'id' will be automatically assigned. The returned [Future] will be
  /// completed when the server acknowledges the command with a response.  If
  /// the server acknowledges the command with a normal (non-error) response,
  /// the future will be completed with the 'result' field from the response.
  /// If the server acknowledges the command with an error response, the future
  /// will be completed with an error.
  Future<Map<String, Object?>?> send(
    String method,
    Map<String, dynamic> params,
  ) {
    return server.send(method, params);
  }

  /// Launch the analysis server.
  ///
  /// Return a [Future] that completes when analysis server has started.
  Future<void> startServer() async {
    logger.log(Level.FINE, 'starting server');
    server = Server();
    var serverConnected = Completer<void>();
    onServerConnected.listen((_) {
      logger.log(Level.FINE, 'connected to server');
      serverConnected.complete();
    });
    running = true;
    var dartSdkPath = dirname(dirname(Platform.resolvedExecutable));
    return server
        .start(dartSdkPath: dartSdkPath, diagnosticPort: diagnosticPort)
        .then((params) {
          server.listenToOutput(dispatchNotification);
          server.exitCode.then((_) {
            logger.log(Level.FINE, 'server stopped');
            running = false;
            _resultsReady();
          });
          return serverConnected.future;
        });
  }

  /// Shutdown the analysis server if it is running.
  Future<void> stopServer([Duration timeout = SHUTDOWN_TIMEOUT]) async {
    if (running) {
      logger.log(Level.FINE, 'requesting server shutdown');
      // Give the server a short time to comply with the shutdown request; if it
      // doesn't exit, then forcibly terminate it.
      unawaited(sendServerShutdown());
      await server.exitCode.timeout(
        timeout,
        onTimeout: () {
          return server.kill('server failed to exit');
        },
      );
    }
    _resultsReady();
  }

  /// If not already complete, signal the completer with the collected results.
  void _resultsReady() {
    if (!_runCompleter.isCompleted) {
      _runCompleter.complete(results);
    }
  }
}

/// [Measurement] tracks elapsed time for a given operation.
class Measurement {
  final String tag;
  final bool notification;
  final List<Duration> elapsedTimes = <Duration>[];
  int errorCount = 0;
  int unexpectedResultCount = 0;

  Measurement(this.tag, this.notification);

  int get count => elapsedTimes.length;

  void printSummary(int keyLen) {
    var count = 0;
    var maxTime = elapsedTimes[0];
    var minTime = elapsedTimes[0];
    var totalTimeMicros = 0;
    for (var elapsed in elapsedTimes) {
      ++count;
      var timeMicros = elapsed.inMicroseconds;
      maxTime = maxTime.compareTo(elapsed) > 0 ? maxTime : elapsed;
      minTime = minTime.compareTo(elapsed) < 0 ? minTime : elapsed;
      totalTimeMicros += timeMicros;
    }
    var meanTime = (totalTimeMicros / count).round();
    var sorted = elapsedTimes.toList()..sort();
    var time90th = sorted[(sorted.length * 0.90).round() - 1];
    var time99th = sorted[(sorted.length * 0.99).round() - 1];
    var differenceFromMeanSquared = 0;
    for (var elapsed in elapsedTimes) {
      var timeMicros = elapsed.inMicroseconds;
      var differenceFromMean = timeMicros - meanTime;
      differenceFromMeanSquared += differenceFromMean * differenceFromMean;
    }
    var variance = differenceFromMeanSquared / count;
    var standardDeviation = sqrt(variance).round();

    var buffer = StringBuffer();
    buffer.writePadRight(tag, keyLen);
    buffer.writePadLeft(count.toString(), 6);
    buffer.writePadLeft(errorCount.toString(), 6);
    buffer.writePadLeft(unexpectedResultCount.toString(), 6);
    buffer.writeDuration(Duration(microseconds: meanTime));
    buffer.writeDuration(time90th);
    buffer.writeDuration(time99th);
    buffer.writeDuration(Duration(microseconds: standardDeviation));
    buffer.writeDuration(minTime);
    buffer.writeDuration(maxTime);
    buffer.writeDuration(Duration(microseconds: totalTimeMicros));
    print(buffer.toString());
  }

  void record(bool success, Duration elapsed) {
    if (!success) {
      ++errorCount;
    }
    elapsedTimes.add(elapsed);
  }

  void recordUnexpectedResults() {
    ++unexpectedResultCount;
  }
}

/// [Results] contains information gathered by [Driver] while running the
/// analysis server.
class Results {
  Map<String, Measurement> measurements = <String, Measurement>{};

  /// Display results on stdout.
  void printResults() {
    print('');
    print('==================================================================');
    print('');
    var sortedEntries = measurements.entries.toList();
    sortedEntries.sort((a, b) => a.key.compareTo(b.key));
    var keyLen = sortedEntries
        .map((e) => e.key)
        .fold(0, (int len, String key) => max(len, key.length));
    _printGroupHeader('Request/Response', keyLen);
    var totalCount = 0;
    var totalErrorCount = 0;
    var totalUnexpectedResultCount = 0;
    for (var entry in sortedEntries) {
      var m = entry.value;
      if (!m.notification) {
        m.printSummary(keyLen);
        totalCount += m.count;
        totalErrorCount += m.errorCount;
        totalUnexpectedResultCount += m.unexpectedResultCount;
      }
    }
    _printTotals(
      keyLen,
      totalCount,
      totalErrorCount,
      totalUnexpectedResultCount,
    );
    print('');
    _printGroupHeader('Notifications', keyLen);
    for (var entry in sortedEntries) {
      var m = entry.value;
      if (m.notification) {
        m.printSummary(keyLen);
      }
    }

    // TODO(danrubel): print warnings if driver caches are not empty.
    print('''

(1) uxr = UneXpected Results or responses received from the server
          that do not match the recorded response for that request.
(2) all times in milliseconds''');
  }

  /// Record the elapsed time for the given operation.
  void record(
    String tag,
    Duration elapsed, {
    bool notification = false,
    bool success = true,
  }) {
    var measurement = measurements[tag];
    if (measurement == null) {
      measurement = Measurement(tag, notification);
      measurements[tag] = measurement;
    }
    measurement.record(success, elapsed);
  }

  void recordUnexpectedResults(String tag) {
    measurements[tag]!.recordUnexpectedResults();
  }

  static void _printGroupHeader(String groupName, int keyLength) {
    var buffer = StringBuffer();
    buffer.writePadRight(groupName, keyLength);
    buffer.writePadLeft('count', 6);
    buffer.writePadLeft('error', 6);
    buffer.writePadLeft('uxr(1)', 6);
    buffer.write('  ');
    buffer.writePadRight('mean(2)', 15);
    buffer.writePadRight('90th', 15);
    buffer.writePadRight('99th', 15);
    buffer.writePadRight('std-dev', 15);
    buffer.writePadRight('minimum', 15);
    buffer.writePadRight('maximum', 15);
    buffer.writePadRight('total', 15);
    print(buffer.toString());
  }

  static void _printTotals(
    int keyLength,
    int totalCount,
    int totalErrorCount,
    int totalUnexpectedResultCount,
  ) {
    var buffer = StringBuffer();
    buffer.writePadRight('Totals', keyLength);
    buffer.writePadLeft(totalCount.toString(), 6);
    buffer.writePadLeft(totalErrorCount.toString(), 6);
    buffer.writePadLeft(totalUnexpectedResultCount.toString(), 6);
    print(buffer.toString());
  }
}

extension on StringBuffer {
  void writeDuration(Duration duration) {
    writePadLeft(duration.inMilliseconds.toString(), 15);
  }

  void writePadLeft(String text, int keyLength) {
    write(text.padLeft(keyLength));
    write(' ');
  }

  void writePadRight(String text, int keyLength) {
    write(text.padRight(keyLength));
    write(' ');
  }
}
