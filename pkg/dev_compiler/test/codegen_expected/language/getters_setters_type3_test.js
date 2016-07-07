dart_library.library('language/getters_setters_type3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getters_setters_type3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getters_setters_type3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getters_setters_type3_test.bar = 499;
  dart.copyProperties(getters_setters_type3_test, {
    get foo() {
      return getters_setters_type3_test.bar;
    },
    set foo(str) {
      getters_setters_type3_test.bar = str[dartx.length];
    }
  });
  getters_setters_type3_test.main = function() {
    let x = core.int._check(getters_setters_type3_test.foo);
    expect$.Expect.equals(499, x);
    getters_setters_type3_test.foo = "1234";
    let y = core.int._check(getters_setters_type3_test.foo);
    expect$.Expect.equals(4, y);
  };
  dart.fn(getters_setters_type3_test.main, VoidTodynamic());
  // Exports:
  exports.getters_setters_type3_test = getters_setters_type3_test;
});
