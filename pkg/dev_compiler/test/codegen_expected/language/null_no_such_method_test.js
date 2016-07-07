dart_library.library('language/null_no_such_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_no_such_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_no_such_method_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(null_no_such_method_test, {
    get array() {
      return JSArrayOfint().of([1]);
    },
    set array(_) {}
  });
  null_no_such_method_test.main = function() {
    expect$.Expect.throws(dart.fn(() => -dart.notNull(null), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    core.print(-dart.notNull(null_no_such_method_test.array[dartx.get](0)));
  };
  dart.fn(null_no_such_method_test.main, VoidTodynamic());
  // Exports:
  exports.null_no_such_method_test = null_no_such_method_test;
});
