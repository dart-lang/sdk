dart_library.library('language/partial_min_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__partial_min_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const partial_min_test = Object.create(null);
  let numAndnumTonum = () => (numAndnumTonum = dart.constFn(dart.definiteFunctionType(core.num, [core.num, core.num])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  partial_min_test.foo = function(a, b) {
    if (dart.notNull(a) > dart.notNull(b)) return b;
    if (typeof b == 'number') {
      if (true) {
        if (true) {
          return (dart.notNull(a) + dart.notNull(b)) * dart.notNull(a) * dart.notNull(b);
        }
      }
      if (a == 0 && b == 0 || b != b) return b;
    }
  };
  dart.fn(partial_min_test.foo, numAndnumTonum());
  partial_min_test.main = function() {
    expect$.Expect.equals(1, partial_min_test.foo(2, 1));
  };
  dart.fn(partial_min_test.main, VoidTodynamic());
  // Exports:
  exports.partial_min_test = partial_min_test;
});
