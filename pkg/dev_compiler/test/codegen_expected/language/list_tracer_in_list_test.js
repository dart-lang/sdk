dart_library.library('language/list_tracer_in_list_test', null, /* Imports */[
  'dart_sdk'
], function load__list_tracer_in_list_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const list_tracer_in_list_test = Object.create(null);
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_tracer_in_list_test.main = function() {
    let a = JSArrayOfList().of([[]]);
    a[dartx.get](0)[dartx.add](42);
    if (a[dartx.get](0)[dartx.length] != 1) {
      dart.throw('Test failed');
    }
  };
  dart.fn(list_tracer_in_list_test.main, VoidTodynamic());
  // Exports:
  exports.list_tracer_in_list_test = list_tracer_in_list_test;
});
