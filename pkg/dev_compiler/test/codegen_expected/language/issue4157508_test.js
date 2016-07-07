dart_library.library('language/issue4157508_test', null, /* Imports */[
  'dart_sdk'
], function load__issue4157508_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue4157508_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue4157508_test.Issue4157508Test = class Issue4157508Test extends core.Object {
    new(v) {
      let d = new core.DateTime.fromMillisecondsSinceEpoch(core.int._check(v), {isUtc: true});
    }
    static testMain() {
      let d = new issue4157508_test.Issue4157508Test(0);
    }
  };
  dart.setSignature(issue4157508_test.Issue4157508Test, {
    constructors: () => ({new: dart.definiteFunctionType(issue4157508_test.Issue4157508Test, [dart.dynamic])}),
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  issue4157508_test.main = function() {
    issue4157508_test.Issue4157508Test.testMain();
  };
  dart.fn(issue4157508_test.main, VoidTodynamic());
  // Exports:
  exports.issue4157508_test = issue4157508_test;
});
