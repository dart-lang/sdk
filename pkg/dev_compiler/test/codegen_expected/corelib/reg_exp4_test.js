dart_library.library('corelib/reg_exp4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp4_test.main = function() {
    try {
      let ex = core.RegExp.new(null);
      expect$.Expect.fail("Expected: ArgumentError got: no exception");
    } catch (ex) {
      if (!core.ArgumentError.is(ex)) {
        expect$.Expect.fail(dart.str`Expected: ArgumentError got: ${ex}`);
      }
    }

    try {
      core.RegExp.new("^\\w+$").hasMatch(null);
      expect$.Expect.fail("Expected: ArgumentError got: no exception");
    } catch (ex) {
      if (!core.ArgumentError.is(ex)) {
        expect$.Expect.fail(dart.str`Expected: ArgumentError got: ${ex}`);
      }
    }

    try {
      core.RegExp.new("^\\w+$").firstMatch(null);
      expect$.Expect.fail("Expected: ArgumentError got: no exception");
    } catch (ex) {
      if (!core.ArgumentError.is(ex)) {
        expect$.Expect.fail(dart.str`Expected: ArgumentError got: ${ex}`);
      }
    }

    try {
      core.RegExp.new("^\\w+$").allMatches(null);
      expect$.Expect.fail("Expected: ArgumentError got: no exception");
    } catch (ex) {
      if (!core.ArgumentError.is(ex)) {
        expect$.Expect.fail(dart.str`Expected: ArgumentError got: ${ex}`);
      }
    }

    try {
      core.RegExp.new("^\\w+$").stringMatch(null);
      expect$.Expect.fail("Expected: ArgumentError got: no exception");
    } catch (ex) {
      if (!core.ArgumentError.is(ex)) {
        expect$.Expect.fail(dart.str`Expected: ArgumentError got: ${ex}`);
      }
    }

  };
  dart.fn(reg_exp4_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp4_test = reg_exp4_test;
});
