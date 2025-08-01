// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart';

import '../../integration_test/support/integration_test_methods.dart';
import '../../integration_test/support/integration_tests.dart';

/// Instances of the class [TimingResult] represent the timing information
/// gathered while executing a given timing test.
class TimingResult {
  /// The number of nanoseconds in a millisecond.
  static int NANOSECONDS_PER_MILLISECOND = 1000000;

  /// The amount of time spent executing each test, in nanoseconds.
  List<int> times;

  /// Initialize a newly created timing result.
  TimingResult(this.times);

  /// The average amount of time spent executing a single iteration, in
  /// milliseconds.
  int get averageTime {
    return totalTime ~/ times.length;
  }

  /// The maximum amount of time spent executing a single iteration, in
  /// milliseconds.
  int get maxTime {
    var maxTime = 0;
    var count = times.length;
    for (var i = 0; i < count; i++) {
      maxTime = max(maxTime, times[i]);
    }
    return maxTime ~/ NANOSECONDS_PER_MILLISECOND;
  }

  /// The minimum amount of time spent executing a single iteration, in
  /// milliseconds.
  int get minTime {
    var minTime = times[0];
    var count = times.length;
    for (var i = 1; i < count; i++) {
      minTime = min(minTime, times[i]);
    }
    return minTime ~/ NANOSECONDS_PER_MILLISECOND;
  }

  /// The standard deviation of the times.
  double get standardDeviation {
    return computeStandardDeviation(toMilliseconds(times));
  }

  /// The total amount of time spent executing the test, in milliseconds.
  int get totalTime {
    var totalTime = 0;
    var count = times.length;
    for (var i = 0; i < count; i++) {
      totalTime += times[i];
    }
    return totalTime ~/ NANOSECONDS_PER_MILLISECOND;
  }

  /// Compute the standard deviation of the given set of [values].
  double computeStandardDeviation(List<int> values) {
    var count = values.length;
    var sumOfValues = 0;
    for (var i = 0; i < count; i++) {
      sumOfValues += values[i];
    }
    var average = sumOfValues / count;
    var sumOfDiffSquared = 0.0;
    for (var i = 0; i < count; i++) {
      var diff = values[i] - average;
      sumOfDiffSquared += diff * diff;
    }
    return sqrt(sumOfDiffSquared / (count - 1));
  }

  /// Convert the given [times], expressed in nanoseconds, to times expressed in
  /// milliseconds.
  List<int> toMilliseconds(List<int> times) {
    var count = times.length;
    var convertedValues = <int>[];
    for (var i = 0; i < count; i++) {
      convertedValues.add(times[i] ~/ NANOSECONDS_PER_MILLISECOND);
    }
    return convertedValues;
  }
}

/// The abstract class [TimingTest] defines the behavior of objects that measure
/// the time required to perform some sequence of server operations.
abstract class TimingTest extends IntegrationTest {
  /// The number of times the test will be performed in order to warm up the VM.
  static final int DEFAULT_WARMUP_COUNT = 10;

  /// The number of times the test will be performed in order to compute a time.
  static final int DEFAULT_TIMING_COUNT = 10;

  /// The file suffix used to identify Dart files.
  static final String DART_SUFFIX = '.dart';

  /// The file suffix used to identify HTML files.
  static final String HTML_SUFFIX = '.html';

  /// The amount of time to give the server to respond to a shutdown request
  /// before forcibly terminating it.
  static const Duration SHUTDOWN_TIMEOUT = Duration(seconds: 5);

  /// The connection to the analysis server.
  @override
  late Server server;

  /// The temporary directory in which source files can be stored.
  late Directory sourceDirectory;

  /// A flag indicating whether the teardown process should skip sending a
  /// "server.shutdown" request because the server is known to have already
  /// shutdown.
  bool skipShutdown = false;

  /// Return the number of iterations that should be performed in order to
  /// compute a time.
  int get timingCount => DEFAULT_TIMING_COUNT;

  /// Return the number of iterations that should be performed in order to warm
  /// up the VM.
  int get warmupCount => DEFAULT_WARMUP_COUNT;

  /// Perform any operations that need to be performed once before any
  /// iterations.
  Future<void> oneTimeSetUp() {
    server = Server();
    sourceDirectory = Directory.systemTemp.createTempSync(
      'analysisServer_test_timing',
    );
    var serverConnected = Completer<void>();
    onServerConnected.listen((_) {
      serverConnected.complete();
    });
    skipShutdown = true;
    var dartSdkPath = dirname(dirname(Platform.resolvedExecutable));
    return server.start(dartSdkPath: dartSdkPath).then((_) {
      server.listenToOutput(dispatchNotification);
      server.exitCode.then((_) {
        skipShutdown = true;
      });
      return serverConnected.future;
    });
  }

  /// Perform any operations that need to be performed once after all
  /// iterations.
  Future<void> oneTimeTearDown() {
    return _shutdownIfNeeded().then((_) {
      sourceDirectory.deleteSync(recursive: true);
    });
  }

  /// Perform any operations that part of a single iteration. It is the
  /// execution of this method that will be measured.
  Future<void> perform();

  /// Return a future that will complete with a timing result representing the
  /// number of milliseconds required to perform the operation the specified
  /// number of times.
  Future<TimingResult> run() async {
    var times = <int>[];
    await oneTimeSetUp();
    await _repeat(warmupCount, null);
    await _repeat(timingCount, times);
    await oneTimeTearDown();
    return TimingResult(times);
  }

  /// Perform any operations that need to be performed before each iteration.
  Future<void> setUp();

  /// Convert the given [relativePath] to an absolute path, by interpreting it
  /// relative to [sourceDirectory].  On Windows any forward slashes in
  /// [relativePath] are converted to backslashes.
  String sourcePath(String relativePath) {
    return join(sourceDirectory.path, relativePath.replaceAll('/', separator));
  }

  /// Perform any operations that need to be performed after each iteration.
  Future<void> tearDown();

  /// Write a source file with the given absolute [pathname] and [contents].
  ///
  /// If the file didn't previously exist, it is created.  If it did, it is
  /// overwritten.
  ///
  /// Parent directories are created as necessary.
  void writeFile(String pathname, String contents) {
    Directory(dirname(pathname)).createSync(recursive: true);
    File(pathname).writeAsStringSync(contents);
  }

  /// Return the number of nanoseconds that have elapsed since the given
  /// [stopwatch] was last stopped.
  int _elapsedNanoseconds(Stopwatch stopwatch) {
    return (stopwatch.elapsedTicks * 1000000000) ~/ stopwatch.frequency;
  }

  /// Repeatedly execute this test [count] times, adding timing information to
  /// the given list of [times] if it is non-`null`.
  Future<void> _repeat(int count, List<int>? times) {
    var stopwatch = Stopwatch();
    return setUp().then((_) {
      stopwatch.start();
      return perform().then((_) {
        stopwatch.stop();
        if (times != null) {
          times.add(_elapsedNanoseconds(stopwatch));
        }
        return tearDown().then((_) {
          if (count > 0) {
            return _repeat(count - 1, times);
          } else {
            return Future.value();
          }
        });
      });
    });
  }

  /// Shut the server down unless [skipShutdown] is `true`.
  Future<void> _shutdownIfNeeded() {
    if (skipShutdown) {
      return Future.value();
    }
    // Give the server a short time to comply with the shutdown request; if it
    // doesn't exit, then forcibly terminate it.
    sendServerShutdown();
    return server.exitCode.timeout(
      SHUTDOWN_TIMEOUT,
      onTimeout: () {
        return server.kill('server failed to exit');
      },
    );
  }
}
