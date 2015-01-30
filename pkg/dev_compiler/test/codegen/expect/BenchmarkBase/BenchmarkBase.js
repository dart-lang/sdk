var BenchmarkBase;
(function (BenchmarkBase) {
  'use strict';
  class Expect {
    static equals(expected, actual) {
      if (!dart.equals(expected, actual)) {
        throw "Values not equal: " + (expected) + " vs " + (actual) + "";
      }
    }
    static listEquals(expected, actual) {
      if (expected.length !== actual.length) {
        throw "Lists have different lengths: " + (expected.length) + " vs " + (actual.length) + "";
      }
      for (let i = 0; i < actual.length; i++) {
        equals(expected[i], actual[i]);
      }
    }
    fail(message) {
      throw message;
    }
  }

  class BenchmarkBase {
    constructor(name) {
      this.name = name;
    }
    run() {
    }
    warmup() {
      this.run();
    }
    exercise() {
      for (let i = 0; i < 10; i++) {
        this.run();
      }
    }
    setup() {
    }
    teardown() {
    }
    static measureFor(f, timeMinimum) {
      let time = 0;
      let iter = 0;
      let watch = new dart_core.Stopwatch();
      watch.start();
      let elapsed = 0;
      while (elapsed < timeMinimum) {
        /* Unimplemented dynamic method call: f() */;
        elapsed = watch.elapsedMilliseconds;
        iter++;
      }
      return 1000.0 * elapsed / iter;
    }
    measure() {
      this.setup();
      measureFor(() => {
        this.this.warmup();
      }, 100);
      let result = measureFor(() => {
        this.this.exercise();
      }, 2000);
      this.teardown();
      return result;
    }
    report() {
      let score = this.measure();
      dart_core.print("" + (this.name) + "(RunTime): " + (score) + " us.");
    }
  }

  // Exports:
  BenchmarkBase.Expect = Expect;
  BenchmarkBase.BenchmarkBase = BenchmarkBase;
})(BenchmarkBase || (BenchmarkBase = {}));
