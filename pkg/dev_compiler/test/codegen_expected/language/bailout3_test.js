dart_library.library('language/bailout3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bailout3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bailout3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bailout3_test.a = null;
  bailout3_test.bar = function() {
    if (dart.equals(dart.dindex(bailout3_test.a, 0), 0)) {
      bailout3_test.bar();
      dart.throw(0);
    }
    for (let i = 0; i < 10; i++) {
      dart.dsetindex(bailout3_test.a, 0, 42);
    }
    return bailout3_test.a;
  };
  dart.fn(bailout3_test.bar, VoidTodynamic());
  bailout3_test.foo = function() {
    if (dart.equals(dart.dindex(bailout3_test.a, 0), 0)) {
      dart.throw(0);
    }
    let b = bailout3_test.bar();
    expect$.Expect.equals(1, dart.dload(b, 'length'));
  };
  dart.fn(bailout3_test.foo, VoidTodynamic());
  bailout3_test.main = function() {
    bailout3_test.a = core.Map.new();
    bailout3_test.bar();
    bailout3_test.foo();
  };
  dart.fn(bailout3_test.main, VoidTodynamic());
  // Exports:
  exports.bailout3_test = bailout3_test;
});
