dart_library.library('language/field_optimization3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_optimization3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_optimization3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_optimization3_test.A = class A extends core.Object {
    new() {
      this.a = 0;
      this.b = 0;
    }
    foo() {
      let c = dart.notNull(this.b) + 27;
      for (let i = 0; i < 1; i++) {
        for (let j = 0; j < 1; j++) {
          expect$.Expect.equals(50, c + 23);
        }
      }
      return dart.notNull(this.a) > 0.2;
    }
    setA(value) {
      this.a = core.int._check(value);
    }
    setB(value) {
      this.b = core.int._check(value);
    }
    ['>'](other) {
      return dart.equals(other, 0.2);
    }
  };
  dart.setSignature(field_optimization3_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      setA: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      setB: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      '>': dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  field_optimization3_test.main = function() {
    let a = new field_optimization3_test.A();
    expect$.Expect.isFalse(a.foo());
    a.setA(new field_optimization3_test.A());
    a.setB(0);
    expect$.Expect.isTrue(a.foo());
  };
  dart.fn(field_optimization3_test.main, VoidTodynamic());
  // Exports:
  exports.field_optimization3_test = field_optimization3_test;
});
