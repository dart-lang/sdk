dart_library.library('language/regress_23498_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_23498_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_23498_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_23498_test.foo = function() {
    return dart.async(function*() {
      try {
        try {
          yield async.Future.error('error');
        } catch (error) {
          core.print("caught once");
          dart.throw('error');
        }

      } catch (error) {
        core.print("caught twice");
        dart.throw('error');
      }

    }, dart.dynamic);
  };
  dart.fn(regress_23498_test.foo, VoidTodynamic());
  regress_23498_test.main = function() {
    return dart.async(function*() {
      let error = "no error";
      try {
        yield regress_23498_test.foo();
      } catch (e) {
        error = core.String._check(e);
      }

      expect$.Expect.equals("error", error);
    }, dart.dynamic);
  };
  dart.fn(regress_23498_test.main, VoidTodynamic());
  // Exports:
  exports.regress_23498_test = regress_23498_test;
});
