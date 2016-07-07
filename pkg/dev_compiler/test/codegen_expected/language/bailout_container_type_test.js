dart_library.library('language/bailout_container_type_test', null, /* Imports */[
  'dart_sdk'
], function load__bailout_container_type_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const bailout_container_type_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(bailout_container_type_test, {
    get a() {
      return JSArrayOfObject().of([false, JSArrayOfint().of([1, 2, 3])]);
    },
    set a(_) {}
  });
  bailout_container_type_test.b = null;
  bailout_container_type_test.main = function() {
    bailout_container_type_test.b = new core.Object();
    bailout_container_type_test.b = 42;
    bailout_container_type_test.b = [];
    if (dart.test(bailout_container_type_test.a[dartx.get](0))) bailout_container_type_test.main();
    let arrayPhi = dart.test(bailout_container_type_test.a[dartx.get](0)) ? bailout_container_type_test.a : bailout_container_type_test.b;
    if (!dart.equals(dart.dload(arrayPhi, 'length'), 0)) {
      dart.throw('Test failed');
    }
  };
  dart.fn(bailout_container_type_test.main, VoidTodynamic());
  // Exports:
  exports.bailout_container_type_test = bailout_container_type_test;
});
