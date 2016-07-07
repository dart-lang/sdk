dart_library.library('corelib/reg_exp5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp5_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp5_test.main = function() {
    let str = "";
    try {
      let ex = core.RegExp.new(str);
    } catch (e) {
      if (!core.ArgumentError.is(e)) {
        expect$.Expect.fail(dart.str`Expected: ArgumentError got: ${e}`);
      }
    }

    expect$.Expect.isFalse(core.RegExp.new("^\\w+$").hasMatch(str));
    let fm = core.RegExp.new("^\\w+$").firstMatch(str);
    expect$.Expect.equals(null, fm);
    let am = core.RegExp.new("^\\w+$").allMatches(str);
    expect$.Expect.isFalse(am[dartx.iterator].moveNext());
    expect$.Expect.equals(null, core.RegExp.new("^\\w+$").stringMatch(str));
  };
  dart.fn(reg_exp5_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp5_test = reg_exp5_test;
});
