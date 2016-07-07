dart_library.library('language/list_tracer_return_from_tearoff_closure_test', null, /* Imports */[
  'dart_sdk'
], function load__list_tracer_return_from_tearoff_closure_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const list_tracer_return_from_tearoff_closure_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(list_tracer_return_from_tearoff_closure_test, {
    get a() {
      return JSArrayOfint().of([42]);
    },
    set a(_) {}
  });
  list_tracer_return_from_tearoff_closure_test.foo = function() {
    return list_tracer_return_from_tearoff_closure_test.a;
  };
  dart.fn(list_tracer_return_from_tearoff_closure_test.foo, VoidTodynamic());
  list_tracer_return_from_tearoff_closure_test.main = function() {
    dart.dsend(list_tracer_return_from_tearoff_closure_test.foo(), 'clear');
    if (list_tracer_return_from_tearoff_closure_test.a[dartx.length] == 1) {
      dart.throw('Test failed');
    }
  };
  dart.fn(list_tracer_return_from_tearoff_closure_test.main, VoidTodynamic());
  // Exports:
  exports.list_tracer_return_from_tearoff_closure_test = list_tracer_return_from_tearoff_closure_test;
});
