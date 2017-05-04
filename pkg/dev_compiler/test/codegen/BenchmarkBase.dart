// Copyright 2011 Google Inc. All Rights Reserved.

library BenchmarkBase;

class Expect {
  static void equals(var expected, var actual) {
    if (expected != actual) {
      throw "Values not equal: $expected vs $actual";
    }
  }

  static void listEquals(List expected, List actual) {
    if (expected.length != actual.length) {
      throw "Lists have different lengths: ${expected.length} vs ${actual.length}";
    }
    for (int i = 0; i < actual.length; i++) {
      equals(expected[i], actual[i]);
    }
  }

  fail(message) {
    throw message;
  }
}

class BenchmarkBase {
  final String name;

  // Empty constructor.
  const BenchmarkBase(String name) : this.name = name;

  // The benchmark code.
  // This function is not used, if both [warmup] and [exercise] are overwritten.
  void run() {}

  // Runs a short version of the benchmark. By default invokes [run] once.
  void warmup() {
    run();
  }

  // Exercices the benchmark. By default invokes [run] 10 times.
  void exercise() {
    for (int i = 0; i < 10; i++) {
      run();
    }
  }

  // Not measured setup code executed prior to the benchmark runs.
  void setup() {}

  // Not measures teardown code executed after the benchmark runs.
  void teardown() {}

  // Measures the score for this benchmark by executing it repeately until
  // time minimum has been reached.
  static double measureFor(Function f, int timeMinimum) {
    int time = 0;
    int iter = 0;
    Stopwatch watch = new Stopwatch();
    watch.start();
    int elapsed = 0;
    while (elapsed < timeMinimum) {
      f();
      elapsed = watch.elapsedMilliseconds;
      iter++;
    }
    return 1000.0 * elapsed / iter;
  }

  // Measures the score for the benchmark and returns it.
  double measure() {
    setup();
    // Warmup for at least 100ms. Discard result.
    measureFor(() {
      this.warmup();
    }, 100);
    // Run the benchmark for at least 2000ms.
    double result = measureFor(() {
      this.exercise();
    }, 2000);
    teardown();
    return result;
  }

  void report() {
    double score = measure();
    print("$name(RunTime): $score us.");
  }
}
