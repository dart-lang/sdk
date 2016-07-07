dart_library.library('language/no_such_method3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__no_such_method3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const no_such_method3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  no_such_method3_test.A = class A extends core.Object {
    foobarbaz() {
      return new no_such_method3_test.B();
    }
  };
  dart.setSignature(no_such_method3_test.A, {
    methods: () => ({foobarbaz: dart.definiteFunctionType(no_such_method3_test.B, [])})
  });
  no_such_method3_test.B = class B extends core.Object {
    noSuchMethod(im) {
      return 42;
    }
  };
  no_such_method3_test.bar = function() {
    let b = null;
    for (let i = 0; i < 20; ++i)
      if (i[dartx['%']](2) == 0)
        b = new no_such_method3_test.A();
      else
        b = new no_such_method3_test.B();
    return b;
  };
  dart.fn(no_such_method3_test.bar, VoidTodynamic());
  no_such_method3_test.main = function() {
    let x = no_such_method3_test.bar();
    let y = dart.dsend(x, 'foobarbaz');
    expect$.Expect.equals(42, y);
    expect$.Expect.isFalse(no_such_method3_test.B.is(y));
  };
  dart.fn(no_such_method3_test.main, VoidTovoid());
  // Exports:
  exports.no_such_method3_test = no_such_method3_test;
});
