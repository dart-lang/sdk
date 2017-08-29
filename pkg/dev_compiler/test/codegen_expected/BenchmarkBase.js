define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const BenchmarkBase$ = Object.create(null);
  const $length = dartx.length;
  const $_get = dartx._get;
  let VoidToNull = () => (VoidToNull = dart.constFn(dart.fnType(core.Null, [])))();
  BenchmarkBase$.Expect = class Expect extends core.Object {
    static equals(expected, actual) {
      if (!dart.equals(expected, actual)) {
        dart.throw(dart.str`Values not equal: ${expected} vs ${actual}`);
      }
    }
    static listEquals(expected, actual) {
      if (expected[$length] != actual[$length]) {
        dart.throw(dart.str`Lists have different lengths: ${expected[$length]} vs ${actual[$length]}`);
      }
      for (let i = 0; i < dart.notNull(actual[$length]); i++) {
        BenchmarkBase$.Expect.equals(expected[$_get](i), actual[$_get](i));
      }
    }
    fail(message) {
      dart.throw(message);
    }
  };
  (BenchmarkBase$.Expect.new = function() {
  }).prototype = BenchmarkBase$.Expect.prototype;
  dart.addTypeTests(BenchmarkBase$.Expect);
  dart.setSignature(BenchmarkBase$.Expect, {
    methods: () => ({fail: dart.fnType(dart.dynamic, [dart.dynamic])}),
    statics: () => ({
      equals: dart.fnType(dart.void, [dart.dynamic, dart.dynamic]),
      listEquals: dart.fnType(dart.void, [core.List, core.List])
    }),
    names: ['equals', 'listEquals']
  });
  BenchmarkBase$.BenchmarkBase = class BenchmarkBase extends core.Object {
    get name() {
      return this[name$];
    }
    set name(value) {
      super.name = value;
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
      let watch = new core.Stopwatch.new();
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
  (BenchmarkBase$.BenchmarkBase.new = function(name) {
    this[name$] = name;
  }).prototype = BenchmarkBase$.BenchmarkBase.prototype;
  dart.addTypeTests(BenchmarkBase$.BenchmarkBase);
  const name$ = Symbol("BenchmarkBase.name");
  dart.setSignature(BenchmarkBase$.BenchmarkBase, {
    fields: () => ({name: dart.finalFieldType(core.String)}),
    methods: () => ({
      run: dart.fnType(dart.void, []),
      warmup: dart.fnType(dart.void, []),
      exercise: dart.fnType(dart.void, []),
      setup: dart.fnType(dart.void, []),
      teardown: dart.fnType(dart.void, []),
      measure: dart.fnType(core.double, []),
      report: dart.fnType(dart.void, [])
    }),
    statics: () => ({measureFor: dart.fnType(core.double, [core.Function, core.int])}),
    names: ['measureFor']
  });
  dart.trackLibraries("BenchmarkBase", {
    "BenchmarkBase.dart": BenchmarkBase$
  }, null);
  // Exports:
  return {
    BenchmarkBase: BenchmarkBase$
  };
});
