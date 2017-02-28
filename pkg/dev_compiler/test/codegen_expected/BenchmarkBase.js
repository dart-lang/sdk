define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const BenchmarkBase$ = Object.create(null);
  let VoidToNull = () => (VoidToNull = dart.constFn(dart.definiteFunctionType(core.Null, [])))();
  BenchmarkBase$.Expect = class Expect extends core.Object {
    static equals(expected, actual) {
      if (!dart.equals(expected, actual)) {
        dart.throw(dart.str`Values not equal: ${expected} vs ${actual}`);
      }
    }
    static listEquals(expected, actual) {
      if (expected[dartx.length] != actual[dartx.length]) {
        dart.throw(dart.str`Lists have different lengths: ${expected[dartx.length]} vs ${actual[dartx.length]}`);
      }
      for (let i = 0; i < dart.notNull(actual[dartx.length]); i++) {
        BenchmarkBase$.Expect.equals(expected[dartx._get](i), actual[dartx._get](i));
      }
    }
    fail(message) {
      dart.throw(message);
    }
  };
  dart.setSignature(BenchmarkBase$.Expect, {
    methods: () => ({fail: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])}),
    statics: () => ({
      equals: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic]),
      listEquals: dart.definiteFunctionType(dart.void, [core.List, core.List])
    }),
    names: ['equals', 'listEquals']
  });
  BenchmarkBase$.BenchmarkBase = class BenchmarkBase extends core.Object {
    new(name) {
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
      BenchmarkBase$.BenchmarkBase.measureFor(dart.fn(() => {
        this.warmup();
      }, VoidToNull()), 100);
      let result = BenchmarkBase$.BenchmarkBase.measureFor(dart.fn(() => {
        this.exercise();
      }, VoidToNull()), 2000);
      this.teardown();
      return result;
    }
    report() {
      let score = this.measure();
      core.print(dart.str`${this.name}(RunTime): ${score} us.`);
    }
  };
  dart.setSignature(BenchmarkBase$.BenchmarkBase, {
    fields: () => ({name: core.String}),
    methods: () => ({
      run: dart.definiteFunctionType(dart.void, []),
      warmup: dart.definiteFunctionType(dart.void, []),
      exercise: dart.definiteFunctionType(dart.void, []),
      setup: dart.definiteFunctionType(dart.void, []),
      teardown: dart.definiteFunctionType(dart.void, []),
      measure: dart.definiteFunctionType(core.double, []),
      report: dart.definiteFunctionType(dart.void, [])
    }),
    statics: () => ({measureFor: dart.definiteFunctionType(core.double, [core.Function, core.int])}),
    names: ['measureFor']
  });
  // Exports:
  return {
    BenchmarkBase: BenchmarkBase$
  };
});
