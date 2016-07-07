dart_library.library('language/operator4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__operator4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const operator4_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  operator4_test.A = class A extends core.Object {
    ['<'](other) {
      return 1;
    }
  };
  dart.setSignature(operator4_test.A, {
    methods: () => ({'<': dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  operator4_test.foo = function(a) {
    try {
      if (dart.test(dart.dsend(a, '<', a))) {
        return "bad";
      } else {
        return 499;
      }
    } catch (e) {
      if (core.TypeError.is(e)) {
        return 499;
      } else
        throw e;
    }

  };
  dart.fn(operator4_test.foo, dynamicTodynamic());
  operator4_test.main = function() {
    expect$.Expect.equals(499, operator4_test.foo(new operator4_test.A()));
  };
  dart.fn(operator4_test.main, VoidTodynamic());
  // Exports:
  exports.operator4_test = operator4_test;
});
