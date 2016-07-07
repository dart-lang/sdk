dart_library.library('language/regress_22445_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22445_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22445_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22445_test.foo = function() {
    return dart.async(function*() {
      try {
        core.print("a");
        yield async.Future.value(3);
        core.print("b");
        dart.throw("Error");
        core.print("c");
      } catch (e) {
        core.print("d");
        yield async.Future.error("Error2");
      }
 finally {
        core.print("e");
      }
      core.print("f");
    }, dart.dynamic);
  };
  dart.fn(regress_22445_test.foo, VoidTodynamic());
  regress_22445_test.main = function() {
    return dart.async(function*() {
      let error = "no error";
      try {
        yield regress_22445_test.foo();
      } catch (e) {
        error = core.String._check(e);
      }

      expect$.Expect.equals("Error2", error);
    }, dart.dynamic);
  };
  dart.fn(regress_22445_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22445_test = regress_22445_test;
});
