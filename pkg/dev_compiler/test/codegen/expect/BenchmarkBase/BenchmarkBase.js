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
        equals(expected.get(i), actual.get(i));
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
      let watch = new core.Stopwatch();
      watch.start();
      let elapsed = 0;
      while (elapsed < timeMinimum) {
        dart.dinvokef(f);
        elapsed = watch.elapsedMilliseconds;
        iter++;
      }
      return 1000.0 * elapsed / iter;
    }
    measure() {
      this.setup();
      measureFor(() => {
        this.warmup();
      }, 100);
      let result = measureFor(() => {
        this.exercise();
      }, 2000);
      this.teardown();
      return result;
    }
    report() {
      let score = this.measure();
      core.print("" + (this.name) + "(RunTime): " + (score) + " us.");
    }
  }

  // Exports:
  BenchmarkBase.Expect = Expect;
  BenchmarkBase.BenchmarkBase = BenchmarkBase;
})(BenchmarkBase || (BenchmarkBase = {}));
