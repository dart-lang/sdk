dart_library.library('language/int2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int2_test.main = function() {
    let b = JSArrayOfint().of([null, 10000000000000000000000000000000000000]);
    42 + dart.notNull(b[dartx.get](1));
    let c = dart.notNull(b[dartx.get](1)) & 1;
    expect$.Expect.equals(0, c);
  };
  dart.fn(int2_test.main, VoidTodynamic());
  // Exports:
  exports.int2_test = int2_test;
});
