dart_library.library('language/regress_22728_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22728_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22728_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22728_test.assertsChecked = function() {
    let checked = false;
    try {
      dart.assert(false);
    } catch (error) {
      if (core.AssertionError.is(error)) {
        checked = true;
      } else
        throw error;
    }

    return checked;
  };
  dart.fn(regress_22728_test.assertsChecked, VoidTobool());
  regress_22728_test.main = function() {
    return dart.async(function*() {
      let fault = false;
      try {
        dart.assert(yield false);
      } catch (error) {
        if (core.AssertionError.is(error)) {
          fault = true;
        } else
          throw error;
      }

      expect$.Expect.equals(regress_22728_test.assertsChecked(), fault);
    }, dart.dynamic);
  };
  dart.fn(regress_22728_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22728_test = regress_22728_test;
});
