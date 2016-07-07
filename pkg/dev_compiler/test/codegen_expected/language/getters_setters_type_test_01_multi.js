dart_library.library('language/getters_setters_type_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getters_setters_type_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getters_setters_type_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getters_setters_type_test_01_multi.bar = 499;
  dart.copyProperties(getters_setters_type_test_01_multi, {
    get foo() {
      return getters_setters_type_test_01_multi.bar;
    },
    set foo(str) {
      getters_setters_type_test_01_multi.bar = str[dartx.length];
    }
  });
  getters_setters_type_test_01_multi.main = function() {
    let x = getters_setters_type_test_01_multi.foo;
    expect$.Expect.equals(499, x);
    getters_setters_type_test_01_multi.foo = "1234";
    let y = getters_setters_type_test_01_multi.foo;
    expect$.Expect.equals(4, y);
  };
  dart.fn(getters_setters_type_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.getters_setters_type_test_01_multi = getters_setters_type_test_01_multi;
});
