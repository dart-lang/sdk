dart_library.library('language/list_in_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_in_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_in_closure_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  list_in_closure_test.main = function() {
    let c = dart.fn(() => {
      dart.throw(42);
    }, VoidTodynamic());
    dart.fn(() => {
      let a = JSArrayOfint().of([42]);
      list_in_closure_test.foo(a);
    }, VoidTodynamic())();
  };
  dart.fn(list_in_closure_test.main, VoidTodynamic());
  list_in_closure_test.foo = function(arg) {
    expect$.Expect.isTrue(dart.equals(dart.dindex(arg, 0), 42));
  };
  dart.fn(list_in_closure_test.foo, dynamicTodynamic());
  // Exports:
  exports.list_in_closure_test = list_in_closure_test;
});
