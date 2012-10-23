// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The results of a single block of tests (count times run, overall time).
 */
class BlockSample {
  BlockSample(this.count, this.durationNanos);
  int count;
  int durationNanos;

  static int _totalCount(List<BlockSample> samples) =>
      _sum(samples, int (BlockSample s) => s.count);

  static int _totalTime(List<BlockSample> samples) =>
      _sum(samples, int (BlockSample s) => s.durationNanos);

  static BlockSample _select(List<BlockSample> samples,
      BlockSample selector(BlockSample a, BlockSample b)) {
    BlockSample r = null;
    for (BlockSample s in samples) {
      r = (r == null) ? s : selector(r, s);
    }
    return r;
  }

  static int _sum(List<BlockSample> samples, int extract(BlockSample s)) {
    int total = 0;
    for (BlockSample s in samples) {
      total += extract(s);
    }
    return total;
  }
}

/**
 * Uses sample data to build a performance model for a test. Construct
 * the model from a set of sample results, and it generates a simple
 * predivtive model for execution of future requests. It uses
 * a simple least-squares linear solution to build the model.
 */
class PerformanceModel {
  PerformanceModel.calculate(List<BlockSample> source) {
    if (0 == source.length) {
      throw "Missing data exception";
    } else if (1 == source.length) {
      overheadNanos = 0;
      perRequestNanos = source[0].durationNanos / source[0].count;
    } else {
      double n = source.length.toDouble();
      double sumY = BlockSample._totalTime(source).toDouble();
      double sumXSquared = BlockSample._sum(source,
          int _(BlockSample s) => s.count * s.count).toDouble();
      double sumX = BlockSample._totalCount(source).toDouble();
      double sumXY = BlockSample._sum(source,
          int _(BlockSample s) => s.durationNanos * s.count).toDouble();

      overheadNanos =
          ((((sumY * sumXSquared) - (sumX * sumXY)) /
          ((n * sumXSquared) - (sumX * sumX))) / source.length).toInt();

      perRequestNanos =
          (((n * sumXY) - (sumX * sumY)) /
          ((n * sumXSquared) - (sumX * sumX))).toInt();
    }
  }

  bool isValid() => overheadNanos >= 0 && perRequestNanos >= 0;

  int overheadNanos;
  int perRequestNanos;
  int repsFor(int targetDurationNanos, [int blocksize = -1]) {
    if (blocksize <= 0) {
      return ((targetDurationNanos - overheadNanos) / perRequestNanos).toInt();
    } else {
      int blockTime = overheadNanos + (blocksize * perRequestNanos);
      int fullBlocks = targetDurationNanos ~/ blockTime;
      int extraReps =
          ((targetDurationNanos - (fullBlocks * blockTime)) - overheadNanos)
          ~/ perRequestNanos;
      return ((fullBlocks * blocksize) + extraReps).toInt();
    }
  }
}

/**
 * Report overall test performance
 */
class TestReport {
  TestReport(this.id, this.desc, this.warmup, this.results) {
    spaceChar = " ".charCodes()[0];
  }

  int spaceChar;

  int resultsCount() => BlockSample._totalCount(results);

  int resultsNanos() => BlockSample._totalTime(results);

  int resultsBestNanos() {
    BlockSample best = bestBlock(results);
    return best.durationNanos ~/ best.count;
  }

  int resultsMeanNanos() =>
      (BlockSample._totalTime(results) /
      BlockSample._totalCount(results)).toInt();

  int resultsWorstNanos() {
    BlockSample worst = worstBlock(results);
    return worst.durationNanos / worst.count;
  }

  int warmupBestNanos() {
    BlockSample best = bestBlock(warmup);
    return best.durationNanos / best.count;
  }

  int warmupMeanNanos() => _totalTime(warmup) / _totalCount(warmup);

  int warmupWorstNanos() {
    BlockSample worst = worstBlock(warmup);
    return worst.durationNanos / worst.count;
  }

  BlockSample bestBlock(List<BlockSample> samples) {
    return BlockSample._select(samples,
          BlockSample selector(BlockSample a, BlockSample b) {
            return a.durationNanos <= b.durationNanos ? a : b;
    });
  }

  BlockSample worstBlock(List<BlockSample> samples) {
    return BlockSample._select(samples,
          BlockSample selector(BlockSample a, BlockSample b) {
      return a.durationNanos >= b.durationNanos ? a : b;
    });
  }

  void printReport() {
    String text = _leftAlign("${id}", 30);
    String totalCount = _rightAlign(resultsCount().toString(), 10);
    String totalDurationMs =
        _rightAlign(_stringifyDoubleAsInt(resultsNanos() / 1E6), 6);
    String meanDuration =
       _rightAlign(_stringifyDoubleAsInt(resultsMeanNanos().toDouble()), 8);

    print("${text} total time:${totalDurationMs} ms" +
        "    iterations:${totalCount}    mean:${meanDuration} ns");
  }

  void printReportWithThroughput(int sizeBytes) {
    String text = _leftAlign("${id}", 30);
    String totalCount = _rightAlign(resultsCount().toString(), 10);
    String totalDurationMs =
        _rightAlign(_stringifyDoubleAsInt(resultsNanos() / 1E6), 6);
    String meanDuration =
        _rightAlign(_stringifyDoubleAsInt(resultsMeanNanos()), 8);

    int totalBytes = sizeBytes * resultsCount();
    String mbPerSec = (((1E9 * sizeBytes * resultsCount()) /
       (1024 * 1024 * resultsNanos()))).toString();
    print("${text} total time:${totalDurationMs} ms" +
        "    iterations:${totalCount}" +
        "    mean:${meanDuration} ns;   ${mbPerSec} MB/sec");
  }

  String _leftAlign(String s, int width) {
    List<int> outCodes = [];
    outCodes.insertRange(0, width, spaceChar);
    outCodes.setRange(0, Math.min(width, s.length), s.charCodes());
    return new String.fromCharCodes(outCodes);
  }

  String _rightAlign(String s, int width) {
    List<int> outCodes = [];
    outCodes.insertRange(0, width, spaceChar);
    outCodes.setRange(Math.max(0, width - s.length), Math.min(width, s.length),
        s.charCodes());
    return new String.fromCharCodes(outCodes);
  }

  static String _stringifyDoubleAsInt(double val) {
    if (val.isInfinite || val.isNaN) {
      return "NaN";
    } else {
      return val.toInt().toString();
    }
  }

  String id;
  String desc;
  List<BlockSample> warmup;
  List<BlockSample> results;
}

class Runner {
  static bool runTest(String testId) {
    Options opts = new Options();
    return opts.arguments.length == 0 ||
        opts.arguments.some(_(String id) => id == testId);
  }
}

/**
 * Run traditional blocking-style tests. Tests may be run a specified number
 * of times, or they can be run based on performance to estimate a particular
 * duration.
 */
class BenchmarkRunner extends Runner {
  static void runCount(String id, String desc, CountTestConfig config,
      Function test) {
    if (runTest(id)) {
      List<BlockSample> warmupSamples = _runTests(test, config._warmup, 1);
      List<BlockSample> resultSamples = _runTests(test, config._reps, 1);
      config.reportHandler(
          new TestReport(id, desc, warmupSamples, resultSamples));
    }
  }

  static void runTimed(String id, String desc, TimedTestConfig config,
      Function test) {
    if (runTest(id)) {
      List<BlockSample> warmupSamples = _runTests(test, config._warmup, 1);
      PerformanceModel model = _calibrate(config._minSampleTimeMs, 16, test);
      int reps = model.repsFor(1E6 * config._targetTimeMs, config._blocksize);
      int blocksize = config._blocksize < 0 ? reps : config._blocksize;
      List<BlockSample> resultSamples = _runTests(test, reps, blocksize);
      config.reportHandler(
          new TestReport(id, desc, warmupSamples, resultSamples));
    }
  }

  static PerformanceModel _calibrate(int minSampleTimeMs, int maxAttempts,
      Function test) {
    PerformanceModel model;
    int i = 0;
    do {
      model = _buildPerformanceModel(minSampleTimeMs, test);
      i++;
    } while (i < maxAttempts && !model.isValid());
    return model;
  }

  static PerformanceModel _buildPerformanceModel(
      int minSampleTimeMs, Function test) {
    int iterations = 1;
    List<BlockSample> calibrationResults = [];
    BlockSample calibration = _execBlock(test, iterations);
    calibrationResults.add(calibration);
    while (calibration.durationNanos < (1E6 * minSampleTimeMs)) {
      iterations *= 2;
      calibration = _execBlock(test, iterations);
      calibrationResults.add(calibration);
    }
    return new PerformanceModel.calculate(calibrationResults);
  }

  static List<BlockSample> _runTests(Function test, int count, int blocksize) {
    List<BlockSample> samples = [];
    for (int rem = count; rem > 0; rem -= blocksize) {
      BlockSample bs = _execBlock(test, Math.min(blocksize, rem));
      samples.add(bs);
    }
    return samples;
  }

  static BlockSample _execBlock(Function test, int count) {
    Stopwatch s = new Stopwatch();
    s.start();
    for (int i = 0; i < count; i++) {
      test();
    }
    s.stop();
    return new BlockSample(count, s.elapsedInUs() * 1000);
  }
}

/**
 * Define CPSTest type.
 */
typedef void CPSTest(Function continuation);

typedef void ReportHandler(TestReport r);

/**
 * Run non-blocking-style using Continuation Passing Style callbacks. Tests may
 * be run a specified number of times, or they can be run based on performance
 * to estimate a particular duration.
 */
class CPSBenchmarkRunner extends Runner {

  CPSBenchmarkRunner(): _cpsTests = [];

  void addTest(CPSTest test) {
    _cpsTests.add(test);
  }

  void runTests([int index = 0, Function continuation = null]) {
    if (index < _cpsTests.length) {
      _cpsTests[index](_(){
        _addToEventQueue(_() => runTests(index + 1, continuation));
      });
    } else {
      if (null != continuation) {
        _addToEventQueue(_() => continuation());
      }
    }
  }

  List<CPSTest> _cpsTests;

  static void runCount(String id, String desc, CountTestConfig config,
      CPSTest test, void continuation()) {
    if (runTest(id)) {
      _runTests(test, config._warmup, 1, (List<BlockSample> warmupSamples){
        int blocksize =
            config._blocksize <= 0 ? config._reps : config._blocksize;
        _runTests(test, config._reps, blocksize,
          _(List<BlockSample> resultSamples) {
            config.reportHandler(
                new TestReport(id, desc, warmupSamples, resultSamples));
            continuation();
          });
      });
    } else {
      continuation();
    }
  }

  static void runTimed(String id, String desc, TimedTestConfig config,
      CPSTest test, void continuation()) {
    if (runTest(id)) {
      _runTests(test, config._warmup, 1, (List<BlockSample> warmupSamples){
        _calibrate(config._minSampleTimeMs, 5, test, (PerformanceModel model){
          int reps =
              model.repsFor(1E6 * config._targetTimeMs, config._blocksize);
          int blocksize =
              config._blocksize <= 0 ? reps : config._blocksize;
          _runTests(test, reps, blocksize, (List<BlockSample> results) {
              config.reportHandler(
                  new TestReport(id, desc, warmupSamples, results));
              continuation();
            });
        });
      });
    } else {
      continuation();
    }
  }

  static void nextTest(Function testLoop, int iteration) {
    _addToEventQueue(() => testLoop(iteration + 1));
  }

  static void _calibrate(int minSampleTimeMs, int maxAttempts,
      CPSTest test, void continuation(PerformanceModel model)) {
    _buildPerformanceModel(minSampleTimeMs, test, (PerformanceModel model){
      if (maxAttempts > 1 && !model.isValid()) {
        _calibrate(minSampleTimeMs, maxAttempts - 1, test, continuation);
      } else {
        continuation(model);
      }
    });
  }

  static void _buildPerformanceModel(
      int minSampleTimeMs, CPSTest test, void continuation(PerformanceModel m),
          [int iterations = 1, List<BlockSample> calibrationResults = null]) {
    List<BlockSample> _calibrationResults =
        null == calibrationResults ? [] : calibrationResults;
    _runTests(test, iterations, 1000, (List<BlockSample> calibration) {
      _calibrationResults.addAll(calibration);
      if (BlockSample._totalTime(calibration) < (1E6 * minSampleTimeMs)) {
        _buildPerformanceModel(minSampleTimeMs, test, continuation,
            iterations: iterations * 2,
            calibrationResults: _calibrationResults);
      } else {
        PerformanceModel model =
            new PerformanceModel.calculate(_calibrationResults);
        continuation(model);
      }
    });
  }

  static void _runTests(CPSTest test, int reps, int blocksize,
        void continuation(List<BlockSample> samples),
        [List<BlockSample> samples = null]) {
    List<BlockSample> localSamples = (null == samples) ? [] : samples;
    if (reps > 0) {
      int blockCount = Math.min(blocksize, reps);
      _execBlock(test, blockCount, (BlockSample sample){
        localSamples.add(sample);
        _addToEventQueue(() =>
            _runTests(test, reps - blockCount, blocksize,
                continuation, localSamples));
      });
    } else {
      continuation(localSamples);
    }
  }

  static void _execBlock(CPSTest test, int count,
      void continuation(BlockSample sample)) {
    Stopwatch s = new Stopwatch();
    s.start();
    _innerLoop(test, count, () {
      s.stop();
      continuation(new BlockSample(count, s.elapsedInUs() * 1000));
    });
  }

  static void _innerLoop(CPSTest test, int remainingCount,
      Function continuation) {
    if (remainingCount > 1) {
      test(() => _innerLoop(test, remainingCount - 1, continuation));
    } else {
      continuation();
    }
  }

  static void _addToEventQueue(Function action) {
    new Timer(0, _(Timer t) => action());
  }
}

class CountTestConfig {
  CountTestConfig(int this._warmup, int this._reps,
      [int blocksize = -1, ReportHandler reportHandler = null]) {
        this._blocksize = blocksize;
        this._reportHandler = (null == reportHandler) ?
            _(TestReport r) => r.printReport() : reportHandler;
      }

  Function _reportHandler;
  Function get reportHandler => _reportHandler;
  int _warmup;
  int _reps;
  int _blocksize;
}

class TimedTestConfig {
  TimedTestConfig(int this._warmup, int this._targetTimeMs,
      [int minSampleTimeMs = 100, int blocksize = -1,
      ReportHandler reportHandler = null]) :
      this._minSampleTimeMs = minSampleTimeMs,
      this._blocksize = blocksize {
    this._reportHandler = (null == reportHandler) ?
        _(TestReport r) => r.printReport() : reportHandler;
  }

  Function _reportHandler;
  Function get reportHandler => _reportHandler;
  int _warmup;
  int _targetTimeMs;
  int _minSampleTimeMs;
  int _blocksize;
}
