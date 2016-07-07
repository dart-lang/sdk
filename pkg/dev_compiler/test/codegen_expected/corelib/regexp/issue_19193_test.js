dart_library.library('corelib/regexp/issue_19193_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue_19193_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue_19193_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue_19193_test.main = function() {
    let re = core.RegExp.new('.*(a+)+\\d');
    expect$.Expect.isTrue("a0aaaaaaaaaaaaa"[dartx.contains](re));
    expect$.Expect.isTrue("a0aaaaaaaaaaaaaa"[dartx.contains](re));
  };
  dart.fn(issue_19193_test.main, VoidTodynamic());
  // Exports:
  exports.issue_19193_test = issue_19193_test;
});
