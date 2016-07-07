dart_library.library('language/condition_bailout_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__condition_bailout_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const condition_bailout_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  condition_bailout_test.A = class A extends core.Object {
    ['unary-']() {
      return this;
    }
    foo(x) {
      dart.dsend(condition_bailout_test.a, 'unary-');
      if (dart.test(x)) return true;
      return false;
    }
    loop1(x) {
      dart.dsend(condition_bailout_test.a, 'unary-');
      while (dart.test(x))
        return true;
      return false;
    }
    loop2(x) {
      dart.dsend(condition_bailout_test.a, 'unary-');
      for (; dart.test(x);)
        return true;
      return false;
    }
    loop3(x) {
      dart.dsend(condition_bailout_test.a, 'unary-');
      let i = 0;
      do {
        if (i++ == 1) return false;
      } while (!dart.test(x));
      return true;
    }
  };
  dart.setSignature(condition_bailout_test.A, {
    methods: () => ({
      'unary-': dart.definiteFunctionType(dart.dynamic, []),
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      loop1: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      loop2: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      loop3: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  condition_bailout_test.a = null;
  condition_bailout_test.main = function() {
    condition_bailout_test.a = new condition_bailout_test.A();
    expect$.Expect.isTrue(dart.dsend(condition_bailout_test.a, 'foo', true));
    expect$.Expect.isTrue(dart.dsend(condition_bailout_test.a, 'loop1', true));
    expect$.Expect.isTrue(dart.dsend(condition_bailout_test.a, 'loop2', true));
    expect$.Expect.isTrue(dart.dsend(condition_bailout_test.a, 'loop3', true));
  };
  dart.fn(condition_bailout_test.main, VoidTodynamic());
  // Exports:
  exports.condition_bailout_test = condition_bailout_test;
});
