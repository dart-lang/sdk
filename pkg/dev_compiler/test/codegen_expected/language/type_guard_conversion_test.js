dart_library.library('language/type_guard_conversion_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_guard_conversion_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_guard_conversion_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_guard_conversion_test.foo = function() {
    return 'bar';
  };
  dart.fn(type_guard_conversion_test.foo, VoidTodynamic());
  type_guard_conversion_test.main = function() {
    let a = type_guard_conversion_test.foo();
    let b = 'c';
    do {
      b = core.String._check(dart.dindex(a, 2));
    } while (b != 'r');
    if (core.Comparable.is(a)) {
      a = dart.dsend(a, '+', a);
    }
    expect$.Expect.equals('barbar', a);
  };
  dart.fn(type_guard_conversion_test.main, VoidTodynamic());
  // Exports:
  exports.type_guard_conversion_test = type_guard_conversion_test;
});
