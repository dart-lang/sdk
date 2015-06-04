var BenchmarkBase = dart.defineLibrary(BenchmarkBase, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  class Expect extends core.Object {
    static equals(expected, actual) {
      if (!dart.equals(expected, actual)) {
        throw `Values not equal: ${expected} vs ${actual}`;
      }
    }
    static listEquals(expected, actual) {
      if (expected.length != actual.length) {
        throw `Lists have different lengths: ${expected.length} vs ${actual.length}`;
      }
      for (let i = 0; dart.notNull(i) < dart.notNull(actual.length); i = dart.notNull(i) + 1) {
        Expect.equals(expected[dartx.get](i), actual[dartx.get](i));
      }
    }
    fail(message) {
      throw message;
    }
  }
  dart.setSignature(Expect, {
    methods: () => ({fail: [core.Object, [core.Object]]}),
    statics: () => ({
      equals: [dart.void, [core.Object, core.Object]],
      listEquals: [dart.void, [core.List, core.List]]
    }),
    names: ['equals', 'listEquals']
  });
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
        dart.dcall(f);
        elapsed = watch.elapsedMilliseconds;
        iter = dart.notNull(iter) + 1;
      }
      return 1000.0 * dart.notNull(elapsed) / dart.notNull(iter);
    }
    measure() {
      this.setup();
      BenchmarkBase.measureFor(dart.fn(() => {
        this.warmup();
      }), 100);
      let result = BenchmarkBase.measureFor(dart.fn(() => {
        this.exercise();
      }), 2000);
      this.teardown();
      return result;
    }
    report() {
      let score = this.measure();
      core.print(`${this.name}(RunTime): ${score} us.`);
    }
  }
  dart.setSignature(BenchmarkBase, {
    constructors: () => ({BenchmarkBase: [BenchmarkBase, [core.String]]}),
    methods: () => ({
      run: [dart.void, []],
      warmup: [dart.void, []],
      exercise: [dart.void, []],
      setup: [dart.void, []],
      teardown: [dart.void, []],
      measure: [core.double, []],
      report: [dart.void, []]
    }),
    statics: () => ({measureFor: [core.double, [core.Function, core.int]]}),
    names: ['measureFor']
  });
  // Exports:
  exports.Expect = Expect;
  exports.BenchmarkBase = BenchmarkBase;
})(BenchmarkBase, core);
