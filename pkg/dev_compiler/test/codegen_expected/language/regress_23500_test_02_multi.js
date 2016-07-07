dart_library.library('language/regress_23500_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_23500_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_23500_test_02_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_23500_test_02_multi.foo = function() {
    return dart.async(function*() {
      try {
        try {
          yield 0;
        } catch (error) {
        }

      } catch (error) {
      }

      dart.throw("error");
    }, dart.dynamic);
  };
  dart.fn(regress_23500_test_02_multi.foo, VoidTodynamic());
  regress_23500_test_02_multi.main = function() {
    return dart.async(function*() {
      let error = "no error";
      try {
        yield regress_23500_test_02_multi.foo();
      } catch (e) {
        error = core.String._check(e);
      }

      expect$.Expect.equals("error", error);
    }, dart.dynamic);
  };
  dart.fn(regress_23500_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.regress_23500_test_02_multi = regress_23500_test_02_multi;
});
