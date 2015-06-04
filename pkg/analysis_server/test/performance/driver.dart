library server.driver;

import 'dart:async';

import 'package:logging/logging.dart';

import '../integration/integration_test_methods.dart';
import '../integration/integration_tests.dart';
import 'operation.dart';

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
  Future stopServer() async {
    if (running) {
      logger.log(Level.FINE, 'requesting server shutdown');
      // Give the server a short time to comply with the shutdown request; if it
      // doesn't exit, then forcibly terminate it.
      sendServerShutdown();
      await server.exitCode.timeout(SHUTDOWN_TIMEOUT, onTimeout: () {
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
    print('Results:');
    for (String tag in measurements.keys.toList()..sort()) {
      measurements[tag].printResults();
    }
  }

  /**
   * Record the elapsed time for the given operation.
   */
  void record(String tag, Duration elapsed) {
    Measurement measurement = measurements[tag];
    if (measurement == null) {
      measurement = new Measurement(tag);
      measurements[tag] = measurement;
    }
    measurement.record(elapsed);
  }
}

/**
 * [Measurement] tracks elapsed time for a given operation.
 */
class Measurement {
  final String tag;
  final List<Duration> elapsedTimes = new List<Duration>();
  
  Measurement(this.tag);

  void record(Duration elapsed) {
    elapsedTimes.add(elapsed);
  }

  void printResults() {
    if (elapsedTimes.length == 0) {
      return;
    }
    print('=== $tag');
    for (Duration elapsed in elapsedTimes) {
      print(elapsed);
    }
  }
}
