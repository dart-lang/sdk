var BenchmarkBase;
(function(exports) {
  'use strict';
  class Expect extends core.Object {
    static equals(expected, actual) {
      if (!dart.equals(expected, actual)) {
        throw `Values not equal: ${expected} vs ${actual}`;
      }
    }
    static listEquals(expected, actual) {
      if (expected.length !== actual.length) {
        throw `Lists have different lengths: ${expected.length} vs ${actual.length}`;
      }
      for (let i = 0; dart.notNull(i) < dart.notNull(actual.length); i = dart.notNull(i) + 1) {
        equals(expected.get(i), actual.get(i));
      }
    }
    fail(message) {
      throw message;
    }
  }
  class BenchmarkBase extends core.Object {
    BenchmarkBase(name) {
      this.name = name;
    }
    run() {}
    warmup() {
      this.run();
    }
    exercise() {
      for (let i = 0; dart.notNull(i) < 10; i = dart.notNull(i) + 1) {
        this.run();
      }
    }
    setup() {}
    teardown() {}
    static measureFor(f, timeMinimum) {
      let time = 0;
      let iter = 0;
      let watch = new core.Stopwatch();
      watch.start();
      let elapsed = 0;
      while (dart.notNull(elapsed) < dart.notNull(timeMinimum)) {
        dart.dinvokef(f);
        elapsed = watch.elapsedMilliseconds;
        iter = dart.notNull(iter) + 1;
      }
      return 1000.0 * dart.notNull(elapsed) / dart.notNull(iter);
    }
    measure() {
      this.setup();
      measureFor((() => {
        this.warmup();
      }).bind(this), 100);
      let result = measureFor((() => {
        this.exercise();
      }).bind(this), 2000);
      this.teardown();
      return result;
    }
    report() {
      let score = this.measure();
      core.print(`${this.name}(RunTime): ${score} us.`);
    }
  }
  // Exports:
  exports.Expect = Expect;
  exports.BenchmarkBase = BenchmarkBase;
})(BenchmarkBase || (BenchmarkBase = {}));
