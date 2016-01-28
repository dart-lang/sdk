dart_library.library('BenchmarkBase', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  class Expect extends core.Object {
    static equals(expected, actual) {
      if (!dart.equals(expected, actual)) {
        dart.throw(`Values not equal: ${expected} vs ${actual}`);
      }
    }
    static listEquals(expected, actual) {
      if (expected[dartx.length] != actual[dartx.length]) {
        dart.throw(`Lists have different lengths: ${expected[dartx.length]} vs ${actual[dartx.length]}`);
      }
      for (let i = 0; i < dart.notNull(actual[dartx.length]); i++) {
        Expect.equals(expected[dartx.get](i), actual[dartx.get](i));
      }
    }
    fail(message) {
      dart.throw(message);
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
      for (let i = 0; i < 10; i++) {
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
        iter++;
      }
      return 1000.0 * dart.notNull(elapsed) / iter;
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
});
