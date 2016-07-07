dart_library.library('corelib/reg_exp_start_end_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp_start_end_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp_start_end_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp_start_end_test.main = function() {
    let matches = core.RegExp.new("(a(b)((c|de)+))").allMatches("abcde abcde abcde");
    let it = matches[dartx.iterator];
    let start = 0;
    let end = 5;
    while (dart.test(it.moveNext())) {
      let match = it.current;
      expect$.Expect.equals(start, match.start);
      expect$.Expect.equals(end, match.end);
      start = start + 6;
      end = end + 6;
    }
  };
  dart.fn(reg_exp_start_end_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp_start_end_test = reg_exp_start_end_test;
});
