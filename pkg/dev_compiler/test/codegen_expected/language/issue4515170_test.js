dart_library.library('language/issue4515170_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue4515170_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue4515170_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue4515170_test.Issue4515170Test = class Issue4515170Test extends core.Object {
    static defaultVal(a) {
      if (a === void 0) a = issue4515170_test.Issue4515170Test.VAL;
      return a;
    }
  };
  dart.setSignature(issue4515170_test.Issue4515170Test, {
    statics: () => ({defaultVal: dart.definiteFunctionType(core.int, [], [core.int])}),
    names: ['defaultVal']
  });
  issue4515170_test.Issue4515170Test.VAL = 3;
  issue4515170_test.main = function() {
    expect$.Expect.equals(3, issue4515170_test.Issue4515170Test.defaultVal());
  };
  dart.fn(issue4515170_test.main, VoidTodynamic());
  // Exports:
  exports.issue4515170_test = issue4515170_test;
});
