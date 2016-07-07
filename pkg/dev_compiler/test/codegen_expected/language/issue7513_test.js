dart_library.library('language/issue7513_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue7513_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue7513_test = Object.create(null);
  let JSArrayOfdouble = () => (JSArrayOfdouble = dart.constFn(_interceptors.JSArray$(core.double)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue7513_test.foo = function(a, b) {
    dart.dsetindex(b, 0, 0.1);
    return dart.dsend(a, '*', dart.dindex(b, 0));
  };
  dart.fn(issue7513_test.foo, dynamicAnddynamicTodynamic());
  issue7513_test.main = function() {
    let a = 0.1;
    let b = JSArrayOfdouble().of([0.1]);
    for (let i = 0; i < 20; i++) {
      issue7513_test.foo(a, b);
    }
    expect$.Expect.approxEquals(0.01, core.num._check(issue7513_test.foo(a, b)));
  };
  dart.fn(issue7513_test.main, VoidTodynamic());
  // Exports:
  exports.issue7513_test = issue7513_test;
});
