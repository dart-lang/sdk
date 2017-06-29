// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of benchmark_lib;

/** Accessors for our Singleton variables. */
BenchmarkSuite get BENCHMARK_SUITE {
  if (BenchmarkSuite._ONLY == null) {
    BenchmarkSuite._ONLY = new BenchmarkSuite._internal();
  }
  return BenchmarkSuite._ONLY;
}

BenchmarkView get BENCHMARK_VIEW {
  if (BenchmarkView._ONLY == null) {
    BenchmarkView._ONLY = new BenchmarkView._internal();
  }
  return BenchmarkView._ONLY;
}

/** The superclass from which all benchmarks inherit from. */
class BenchmarkBase {
  /** Benchmark name. */
  final String name;

  const BenchmarkBase(String name) : this.name = name;

  /**
   * The benchmark code.
   * This function is not used, if both [warmup] and [exercise] are overwritten.
   */
  void run() {}

  /** Runs a short version of the benchmark. By default invokes [run] once. */
  void warmup() {
    run();
  }

  /** Exercises the benchmark. By default invokes [run] 10 times. */
  void exercise() {
    for (int i = 0; i < 10; i++) {
      run();
    }
  }

  /** Not measured setup code executed prior to the benchmark runs. */
  void setup() {}

  /** Not measures teardown code executed after the benchmark runs. */
  void teardown() {}

  /**
   * Measures the score for this benchmark by executing it repeately until
   * time minimum has been reached.
   */
  static double measureFor(Function f, int timeMinimum) {
    int time = 0;
    int iter = 0;
    Stopwatch watch = new Stopwatch();
    watch.start();
    int elapsed = 0;
    while (elapsed < timeMinimum || iter < 32) {
      f();
      elapsed = watch.elapsedMilliseconds;
      iter++;
    }
    return (1000.0 * iter) / elapsed;
  }

  /**
   * Measures the score for the benchmark and returns it.
   * We measure iterations / sec (so bigger = better!).
   */
  double measure() {
    setup();
    // Warmup for at least 1000ms. Discard result.
    measureFor(() {
      this.warmup();
    }, 1000);
    // Run the benchmark for at least 1000ms.
    double result = measureFor(() {
      this.exercise();
    }, 1000);
    teardown();
    return result;
  }

  void report() {
    num score = measure();
    Map<String, int> normalizingDict = {'Smoketest': 100};
    score = score / normalizingDict[name];
    BENCHMARK_SUITE.updateIndividualScore(name, score);
  }
}

/** The controller class that runs all of the benchmarks. */
class BenchmarkSuite {
  /** The set of benchmarks that have yet to run. */
  List<Function> benchmarks;

  /**
   * The set of scores from the benchmarks that have already run. (Used for
   * calculating the Geometric mean).
   */
  List<num> scores;

  /** The total number of benchmarks we will be running. */
  int totalBenchmarks;

  /** Singleton pattern: There's only one BenchmarkSuite. */
  static BenchmarkSuite _ONLY = null;

  BenchmarkSuite._internal() {
    scores = [];
    benchmarks = [() => Smoketest.main()];
    totalBenchmarks = benchmarks.length;
  }

  /** Run all of the benchmarks that we have in our benchmarks list. */
  runBenchmarks() {
    runBenchmarksHelper(benchmarks);
  }

  /**
   * Run the remaining benchmarks in our list. We chain the calls providing
   * little breaks for the main page to gain control, so we don't force the
   * entire page to hang the whole time.
   */
  runBenchmarksHelper(List<Function> remainingBenchmarks) {
    // Remove the last benchmark, and run it.
    var benchmark = remainingBenchmarks.removeLast();
    benchmark();
    if (remainingBenchmarks.length > 0) {
      /* Provide small breaks between each benchmark, so that the browser
      doesn't get unhappy about long running scripts, and so the user
      can regain control of the UI to kill the page as needed. */
      new Timer(const Duration(milliseconds: 25),
          () => runBenchmarksHelper(remainingBenchmarks));
    } else if (remainingBenchmarks.length == 0) {
      // We've run all of the benchmarks. Update the page with the score.
      BENCHMARK_VIEW.setScore(geometricMean(scores));
    }
  }

  /** Store the results of a single benchmark run. */
  updateIndividualScore(String name, num score) {
    scores.add(score);
    BENCHMARK_VIEW.incrementProgress(name, score, totalBenchmarks);
  }

  /** Computes the geometric mean of a set of numbers. */
  geometricMean(numbers) {
    num log = 0;
    for (num n in numbers) {
      log += Math.log(n);
    }
    return Math.pow(Math.E, log / numbers.length);
  }
}

/** Controls how results are displayed to the user, by updating the HTML. */
class BenchmarkView {
  /** The number of benchmarks that have finished executing. */
  int numCompleted = 0;

  /** Singleton pattern: There's only one BenchmarkSuite. */
  static BenchmarkView _ONLY = null;

  BenchmarkView._internal();

  /** Update the page HTML to show the calculated score. */
  setScore(num score) {
    String newScore = formatScore(score * 100.0);
    Element body = document.queryAll("body")[0];
    body.nodes
        .add(new Element.html("<p id='testResultScore'>Score: $newScore</p>"));
  }

  /**
   * Update the page HTML to show how much progress we've made through the
   * benchmarks.
   */
  incrementProgress(String name, num score, num totalBenchmarks) {
    String newScore = formatScore(score * 100.0);
    numCompleted++;
    // Slightly incorrect (truncating) percentage, but this is just to show
    // the user we're making progress.
    num percentage = 100 * numCompleted ~/ totalBenchmarks;
  }

  /**
   * Rounds the score to have at least three significant digits (hopefully)
   * helping readability of the scores.
   */
  String formatScore(num value) {
    if (value > 100) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(2);
    }
  }
}
