dart_library.library('language/infinity_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__infinity_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const infinity_test = Object.create(null);
  let JSArrayOfnum = () => (JSArrayOfnum = dart.constFn(_interceptors.JSArray$(core.num)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  infinity_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(infinity_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(infinity_test.inscrutable, intToint());
  infinity_test.main = function() {
    let things = JSArrayOfnum().of([0, core.double.INFINITY, core.double.NEGATIVE_INFINITY]);
    let first = things[dartx.get](1);
    let second = things[dartx.get](2);
    expect$.Expect.isFalse(typeof first == 'number');
    expect$.Expect.isFalse(typeof second == 'number');
    expect$.Expect.isTrue(typeof first == 'number');
    expect$.Expect.isTrue(typeof second == 'number');
  };
  dart.fn(infinity_test.main, VoidTodynamic());
  // Exports:
  exports.infinity_test = infinity_test;
});
