// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' show max, sqrt;

import 'package:logging/logging.dart';

import '../../test/integration/support/integration_test_methods.dart';
import '../../test/integration/support/integration_tests.dart';
import 'operation.dart';

final SPACE = ' '.codeUnitAt(0);

void _printColumn(StringBuffer sb, String text, int keyLen,
    {bool rightJustified = false}) {
  if (!rightJustified) {
    sb.write(text);
    sb.write(',');
  }
  for (var i = text.length; i < keyLen; ++i) {
    sb.writeCharCode(SPACE);
  }
  if (rightJustified) {
    sb.write(text);
    sb.write(',');
  }
  sb.writeCharCode(SPACE);
}

/// [Driver] launches and manages an instance of analysis server,
/// reads a stream of operations, sends requests to analysis server
/// based upon those operations, and evaluates the results.
class Driver extends IntegrationTestMixin {
  /// The amount of time to give the server to respond to a shutdown request
  /// before forcibly terminating it.
  static const Duration SHUTDOWN_TIMEOUT = Duration(seconds: 5);

  final Logger logger = Logger('Driver');

  /// The diagnostic port for Analysis Server or `null` if none.
  final int diagnosticPort;

  /// A flag indicating whether the server is running.
  bool running = false;

  @override
  Server server;

  /// The results collected while running analysis server.
  final Results results = Results();

  /// The [Completer] for [runComplete].
  final Completer<Results> _runCompleter = Completer<Results>();

  Driver({this.diagnosticPort});

  /// Return a [Future] that completes with the [Results] of running
  /// the analysis server once all operations have been performed.
  Future<Results> get runComplete => _runCompleter.future;

  /// Perform the given operation.
  /// Return a [Future] that completes when the next operation can be performed,
  /// or `null` if the next operation can be performed immediately
  Future perform(Operation op) {
    return op.perform(this);
  }

  /// Send a command to the server.  An 'id' will be automatically assigned.
  /// The returned [Future] will be completed when the server acknowledges the
  /// command with a response.  If the server acknowledges the command with a
  /// normal (non-error) response, the future will be completed with the
  /// 'result' field from the response.  If the server acknowledges the command
  /// with an error response, the future will be completed with an error.
  Future<Map<String, dynamic>> send(
      String method, Map<String, dynamic> params) {
    return server.send(method, params);
  }

  /// Launch the analysis server.
  /// Return a [Future] that completes when analysis server has started.
  Future startServer() async {
    logger.log(Level.FINE, 'starting server');
    initializeInttestMixin();
    server = Server();
    var serverConnected = Completer();
    onServerConnected.listen((_) {
      logger.log(Level.FINE, 'connected to server');
      serverConnected.complete();
    });
    running = true;
    return server
        .start(diagnosticPort: diagnosticPort /*profileServer: true*/)
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
  Future stopServer([Duration timeout = SHUTDOWN_TIMEOUT]) async {
    if (running) {
      logger.log(Level.FINE, 'requesting server shutdown');
      // Give the server a short time to comply with the shutdown request; if it
      // doesn't exit, then forcibly terminate it.
      sendServerShutdown();
      await server.exitCode.timeout(timeout, onTimeout: () {
        return server.kill('server failed to exit');
      });
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

    var sb = StringBuffer();
    _printColumn(sb, tag, keyLen);
    _printColumn(sb, count.toString(), 6, rightJustified: true);
    _printColumn(sb, errorCount.toString(), 6, rightJustified: true);
    _printColumn(sb, unexpectedResultCount.toString(), 6, rightJustified: true);
    _printDuration(sb, Duration(microseconds: meanTime));
    _printDuration(sb, time90th);
    _printDuration(sb, time99th);
    _printDuration(sb, Duration(microseconds: standardDeviation));
    _printDuration(sb, minTime);
    _printDuration(sb, maxTime);
    _printDuration(sb, Duration(microseconds: totalTimeMicros));
    print(sb.toString());
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

  void _printDuration(StringBuffer sb, Duration duration) {
    _printColumn(sb, duration.inMilliseconds.toString(), 15,
        rightJustified: true);
  }
}

/// [Results] contains information gathered by [Driver]
/// while running the analysis server
class Results {
  Map<String, Measurement> measurements = <String, Measurement>{};

  /// Display results on stdout.
  void printResults() {
    print('');
    print('==================================================================');
    print('');
    var keys = measurements.keys.toList()..sort();
    var keyLen = keys.fold(0, (int len, String key) => max(len, key.length));
    _printGroupHeader('Request/Response', keyLen);
    var totalCount = 0;
    var totalErrorCount = 0;
    var totalUnexpectedResultCount = 0;
    for (var tag in keys) {
      var m = measurements[tag];
      if (!m.notification) {
        m.printSummary(keyLen);
        totalCount += m.count;
        totalErrorCount += m.errorCount;
        totalUnexpectedResultCount += m.unexpectedResultCount;
      }
    }
    _printTotals(
        keyLen, totalCount, totalErrorCount, totalUnexpectedResultCount);
    print('');
    _printGroupHeader('Notifications', keyLen);
    for (var tag in keys) {
      var m = measurements[tag];
      if (m.notification) {
        m.printSummary(keyLen);
      }
    }

    /// TODO(danrubel) *** print warnings if driver caches are not empty ****
    print('''

(1) uxr = UneXpected Results or responses received from the server
          that do not match the recorded response for that request.
(2) all times in milliseconds''');
  }

  /// Record the elapsed time for the given operation.
  void record(String tag, Duration elapsed,
      {bool notification = false, bool success = true}) {
    var measurement = measurements[tag];
    if (measurement == null) {
      measurement = Measurement(tag, notification);
      measurements[tag] = measurement;
    }
    measurement.record(success, elapsed);
  }

  void recordUnexpectedResults(String tag) {
    measurements[tag].recordUnexpectedResults();
  }

  void _printGroupHeader(String groupName, int keyLen) {
    var sb = StringBuffer();
    _printColumn(sb, groupName, keyLen);
    _printColumn(sb, 'count', 6, rightJustified: true);
    _printColumn(sb, 'error', 6, rightJustified: true);
    _printColumn(sb, 'uxr(1)', 6, rightJustified: true);
    sb.write('  ');
    _printColumn(sb, 'mean(2)', 15);
    _printColumn(sb, '90th', 15);
    _printColumn(sb, '99th', 15);
    _printColumn(sb, 'std-dev', 15);
    _printColumn(sb, 'minimum', 15);
    _printColumn(sb, 'maximum', 15);
    _printColumn(sb, 'total', 15);
    print(sb.toString());
  }

  void _printTotals(int keyLen, int totalCount, int totalErrorCount,
      int totalUnexpectedResultCount) {
    var sb = StringBuffer();
    _printColumn(sb, 'Totals', keyLen);
    _printColumn(sb, totalCount.toString(), 6, rightJustified: true);
    _printColumn(sb, totalErrorCount.toString(), 6, rightJustified: true);
    _printColumn(sb, totalUnexpectedResultCount.toString(), 6,
        rightJustified: true);
    print(sb.toString());
  }
}
