dart_library.library('language/optimized_lists_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optimized_lists_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optimized_lists_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  optimized_lists_test.main = function() {
    for (let i = 0; i < 20; i++) {
      optimized_lists_test.test(2);
    }
  };
  dart.fn(optimized_lists_test.main, VoidTodynamic());
  let const$;
  optimized_lists_test.test = function(n) {
    let a = core.List.new();
    let b = core.List.new(10);
    let c = const$ || (const$ = dart.constList([1, 2, 3, 4], core.int));
    a[dartx.add](4);
    b[dartx.set](0, 5);
    expect$.Expect.equals(4, a[dartx.get](0));
    expect$.Expect.equals(5, b[dartx.get](0));
    expect$.Expect.equals(2, c[dartx.get](1));
    let v = c[dartx.get](core.int._check(n));
    expect$.Expect.equals(v, c[dartx.get](core.int._check(n)));
  };
  dart.fn(optimized_lists_test.test, dynamicTodynamic());
  // Exports:
  exports.optimized_lists_test = optimized_lists_test;
});
