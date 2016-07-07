dart_library.library('language/optimize_redundant_array_load_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optimize_redundant_array_load_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optimize_redundant_array_load_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(optimize_redundant_array_load_test, {
    get A() {
      return JSArrayOfint().of([0, 2, 3]);
    },
    set A(_) {}
  });
  optimize_redundant_array_load_test.test1 = function(a) {
    let x = core.int._check(dart.dindex(a, 0));
    let y = core.int._check(dart.dindex(a, 1));
    let i = 0;
    dart.dsetindex(a, i, dart.dsend(dart.dindex(a, i), '+', 1));
    return dart.dsend(dart.dsend(dart.dindex(a, 0), '+', y), '+', dart.dindex(a, 2));
  };
  dart.fn(optimize_redundant_array_load_test.test1, dynamicTodynamic());
  optimize_redundant_array_load_test.test2 = function(a) {
    return core.int._check(dart.dsend(dart.dindex(a, 2), '+', dart.dindex(a, 2)));
  };
  dart.fn(optimize_redundant_array_load_test.test2, dynamicToint());
  optimize_redundant_array_load_test.main = function() {
    for (let i = 0; i < 20; i++) {
      optimize_redundant_array_load_test.test1(optimize_redundant_array_load_test.A);
      optimize_redundant_array_load_test.test2(optimize_redundant_array_load_test.A);
    }
    expect$.Expect.equals(26, optimize_redundant_array_load_test.test1(optimize_redundant_array_load_test.A));
    expect$.Expect.equals(6, optimize_redundant_array_load_test.test2(optimize_redundant_array_load_test.A));
  };
  dart.fn(optimize_redundant_array_load_test.main, VoidTodynamic());
  // Exports:
  exports.optimize_redundant_array_load_test = optimize_redundant_array_load_test;
});
