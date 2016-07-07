dart_library.library('language/list_tracer_call_last_test', null, /* Imports */[
  'dart_sdk'
], function load__list_tracer_call_last_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const list_tracer_call_last_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.functionType(core.int, [])))();
  let JSArrayOfVoidToint = () => (JSArrayOfVoidToint = dart.constFn(_interceptors.JSArray$(VoidToint())))();
  let VoidToint$ = () => (VoidToint$ = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_tracer_call_last_test.main = function() {
    let a = JSArrayOfVoidToint().of([dart.fn(() => 123, VoidToint$())]);
    if (!(typeof a[dartx.last]() == 'number')) {
      dart.throw('Test failed');
    }
  };
  dart.fn(list_tracer_call_last_test.main, VoidTodynamic());
  // Exports:
  exports.list_tracer_call_last_test = list_tracer_call_last_test;
});
