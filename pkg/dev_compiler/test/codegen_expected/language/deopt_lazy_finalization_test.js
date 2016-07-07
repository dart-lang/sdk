dart_library.library('language/deopt_lazy_finalization_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deopt_lazy_finalization_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deopt_lazy_finalization_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deopt_lazy_finalization_test.main = function() {
    expect$.Expect.equals(20000, deopt_lazy_finalization_test.part1());
    expect$.Expect.equals(-20000, deopt_lazy_finalization_test.part2());
  };
  dart.fn(deopt_lazy_finalization_test.main, VoidTodynamic());
  deopt_lazy_finalization_test.part1 = function() {
    let a = new deopt_lazy_finalization_test.A();
    a.loop();
    return a.loop();
  };
  dart.fn(deopt_lazy_finalization_test.part1, VoidTodynamic());
  deopt_lazy_finalization_test.part2 = function() {
    let b = new deopt_lazy_finalization_test.B();
    b.loop();
    return b.loop();
  };
  dart.fn(deopt_lazy_finalization_test.part2, VoidTodynamic());
  deopt_lazy_finalization_test.A = class A extends core.Object {
    foo() {
      return 2;
    }
    loop() {
      let sum = 0;
      for (let i = 0; i < 10000; i++) {
        sum = dart.notNull(sum) + dart.notNull(core.int._check(this.foo()));
      }
      return sum;
    }
  };
  dart.setSignature(deopt_lazy_finalization_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      loop: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  deopt_lazy_finalization_test.Aa = class Aa extends deopt_lazy_finalization_test.A {};
  deopt_lazy_finalization_test.B = class B extends deopt_lazy_finalization_test.Aa {
    foo() {
      return -2;
    }
  };
  // Exports:
  exports.deopt_lazy_finalization_test = deopt_lazy_finalization_test;
});
