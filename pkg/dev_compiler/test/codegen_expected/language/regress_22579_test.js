dart_library.library('language/regress_22579_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22579_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22579_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22579_test.foo = function() {
    return dart.async(function*() {
      try {
        yield 1;
      } catch (e) {
      }

      dart.throw("error");
    }, dart.dynamic);
  };
  dart.fn(regress_22579_test.foo, VoidTodynamic());
  regress_22579_test.main = function() {
    return dart.async(function*() {
      let error = "no error";
      try {
        yield regress_22579_test.foo();
      } catch (e) {
        error = core.String._check(e);
      }

      expect$.Expect.equals("error", error);
    }, dart.dynamic);
  };
  dart.fn(regress_22579_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22579_test = regress_22579_test;
});
