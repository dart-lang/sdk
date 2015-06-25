// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.driver;

import 'dart:async';
import 'dart:math' show max;

import 'package:logging/logging.dart';

import '../integration/integration_test_methods.dart';
import '../integration/integration_tests.dart';
import 'operation.dart';

final SPACE = ' '.codeUnitAt(0);

void _printColumn(StringBuffer sb, String text, int keyLen,
    {bool rightJustified: false}) {
  if (!rightJustified) {
    sb.write(text);
    sb.write(',');
  }
  for (int i = text.length; i < keyLen; ++i) {
    sb.writeCharCode(SPACE);
  }
  if (rightJustified) {
    sb.write(text);
    sb.write(',');
  }
  sb.writeCharCode(SPACE);
}

/**
 * [Driver] launches and manages an instance of analysis server,
 * reads a stream of operations, sends requests to analysis server
 * based upon those operations, and evaluates the results.
 */
class Driver extends IntegrationTestMixin {
  /**
   * The amount of time to give the server to respond to a shutdown request
   * before forcibly terminating it.
   */
  static const Duration SHUTDOWN_TIMEOUT = const Duration(seconds: 5);

  final Logger logger;

  /**
   * A flag indicating whether the server is running.
   */
  bool running = false;

  @override
  Server server;

  /**
   * The results collected while running analysis server.
   */
  final Results results = new Results();

  /**
   * The [Completer] for [runComplete].
   */
  Completer<Results> _runCompleter = new Completer<Results>();

  Driver(this.logger);

  /**
   * Return a [Future] that completes with the [Results] of running
   * the analysis server once all operations have been performed.
   */
  Future<Results> get runComplete => _runCompleter.future;

  /**
   * Perform the given operation.
   * Return a [Future] that completes when the next operation can be performed,
   * or `null` if the next operation can be performed immediately
   */
  Future perform(Operation op) {
    return op.perform(this);
  }

  /**
   * Send a command to the server.  An 'id' will be automatically assigned.
   * The returned [Future] will be completed when the server acknowledges the
   * command with a response.  If the server acknowledges the command with a
   * normal (non-error) response, the future will be completed with the 'result'
   * field from the response.  If the server acknowledges the command with an
   * error response, the future will be completed with an error.
   */
  Future send(String method, Map<String, dynamic> params) {
    return server.send(method, params);
  }

  /**
   * Launch the analysis server.
   * Return a [Future] that completes when analysis server has started.
   */
  Future startServer() async {
    logger.log(Level.FINE, 'starting server');
    initializeInttestMixin();
    server = new Server();
    Completer serverConnected = new Completer();
    onServerConnected.listen((_) {
      logger.log(Level.FINE, 'connected to server');
      serverConnected.complete();
    });
    running = true;
    return server.start(/*profileServer: true*/).then((params) {
      server.listenToOutput(dispatchNotification);
      server.exitCode.then((_) {
        logger.log(Level.FINE, 'server stopped');
        running = false;
        _resultsReady();
      });
      return serverConnected.future;
    });
  }

  /**
   * Shutdown the analysis server if it is running.
   */
  Future stopServer([Duration timeout = SHUTDOWN_TIMEOUT]) async {
    if (running) {
      logger.log(Level.FINE, 'requesting server shutdown');
      // Give the server a short time to comply with the shutdown request; if it
      // doesn't exit, then forcibly terminate it.
      sendServerShutdown();
      await server.exitCode.timeout(timeout, onTimeout: () {
        return server.kill();
      });
    }
    _resultsReady();
  }

  /**
   * If not already complete, signal the completer with the collected results.
   */
  void _resultsReady() {
    if (!_runCompleter.isCompleted) {
      _runCompleter.complete(results);
    }
  }
}

/**
 * [Measurement] tracks elapsed time for a given operation.
 */
class Measurement {
  final String tag;
  final List<Duration> elapsedTimes = new List<Duration>();
  int errorCount = 0;

  Measurement(this.tag);

  void printSummary(int keyLen) {
    int count = 0;
    int totalTimeMicros = 0;
    for (Duration elapsed in elapsedTimes) {
      ++count;
      totalTimeMicros += elapsed.inMicroseconds;
    }
    int averageTimeMicros = (totalTimeMicros / count).round();
    StringBuffer sb = new StringBuffer();
    _printColumn(sb, tag, keyLen);
    _printColumn(sb, count.toString(), 5, rightJustified: true);
    _printColumn(sb, errorCount.toString(), 5, rightJustified: true);
    sb.write('  ');
    sb.write(new Duration(microseconds: averageTimeMicros));
    sb.write(',   ');
    sb.write(new Duration(microseconds: totalTimeMicros));
    print(sb.toString());
  }

  void record(bool success, Duration elapsed) {
    if (!success) {
      ++errorCount;
    }
    elapsedTimes.add(elapsed);
  }
}

/**
 * [Results] contains information gathered by [Driver]
 * while running the analysis server
 */
class Results {
  Map<String, Measurement> measurements = new Map<String, Measurement>();

  /**
   * Display results on stdout.
   */
  void printResults() {
    print('==================================================================');
    List<String> keys = measurements.keys.toList()..sort();
    int keyLen = keys.fold(0, (int len, String key) => max(len, key.length));
    StringBuffer sb = new StringBuffer();
    _printColumn(sb, 'Results', keyLen);
    _printColumn(sb, 'count', 5);
    _printColumn(sb, 'errors', 5);
    sb.write('   average,          total,');
    print(sb.toString());
    int totalCount = 0;
    int totalErrorCount = 0;
    for (String tag in keys) {
      Measurement m = measurements[tag];
      m.printSummary(keyLen);
      totalCount += m.elapsedTimes.length;
      totalErrorCount += m.errorCount;
    }
    sb.clear();
    _printColumn(sb, 'Totals', keyLen);
    _printColumn(sb, totalCount.toString(), 5);
    _printColumn(sb, totalErrorCount.toString(), 5);
    print(sb.toString());
  }

  /**
   * Record the elapsed time for the given operation.
   */
  void record(String tag, Duration elapsed, {bool success: true}) {
    Measurement measurement = measurements[tag];
    if (measurement == null) {
      measurement = new Measurement(tag);
      measurements[tag] = measurement;
    }
    measurement.record(success, elapsed);
  }
}
