dart_library.library('language/range_analysis2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__range_analysis2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const range_analysis2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  range_analysis2_test.main = function() {
    let a = 0;
    let b = JSArrayOfint().of([1]);
    function foo() {
      return dart.notNull(b[dartx.get](a--)) + dart.notNull(b[dartx.get](a));
    }
    dart.fn(foo, VoidTodynamic());
    expect$.Expect.throws(foo, dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(range_analysis2_test.main, VoidTodynamic());
  // Exports:
  exports.range_analysis2_test = range_analysis2_test;
});
