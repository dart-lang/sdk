dart_library.library('language/const_switch2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_switch2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_switch2_test_none_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  const_switch2_test_none_multi.main = function() {
    let a = JSArrayOfint().of([1, 2, 3])[dartx.get](2);
    switch (a) {
      case 1:
      {
        core.print("OK");
      }
    }
  };
  dart.fn(const_switch2_test_none_multi.main, VoidToint());
  // Exports:
  exports.const_switch2_test_none_multi = const_switch2_test_none_multi;
});
