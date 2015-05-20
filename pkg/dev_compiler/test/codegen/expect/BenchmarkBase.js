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
      if (expected[core.$length] != actual[core.$length]) {
        throw `Lists have different lengths: ${expected[core.$length]} vs ${actual[core.$length]}`;
      }
      for (let i = 0; dart.notNull(i) < dart.notNull(actual[core.$length]); i = dart.notNull(i) + 1) {
        Expect.equals(expected[core.$get](i), actual[core.$get](i));
      }
    }
    fail(message) {
      throw message;
    }
  }
  dart.setSignature(Expect, {
    methods: () => ({fail: [dart.dynamic, [dart.dynamic]]}),
    statics: () => ({
      equals: [dart.void, [dart.dynamic, dart.dynamic]],
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
      BenchmarkBase.measureFor(dart.fn((() => {
        this.warmup();
      }).bind(this)), 100);
      let result = BenchmarkBase.measureFor(dart.fn((() => {
        this.exercise();
      }).bind(this)), 2000);
      this.teardown();
      return result;
    }
    report() {
      let score = this.measure();
      core.print(`${this.name}(RunTime): ${score} us.`);
    }
  }
  dart.setSignature(BenchmarkBase, {
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
