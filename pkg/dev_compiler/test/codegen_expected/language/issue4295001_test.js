dart_library.library('language/issue4295001_test', null, /* Imports */[
  'dart_sdk'
], function load__issue4295001_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue4295001_test = Object.create(null);
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue4295001_test.Issue4295001Test = class Issue4295001Test extends core.Object {
    new(s) {
      this.foo = s;
      let f = dart.fn(() => s, VoidToString());
    }
    static testMain() {
      let d = new issue4295001_test.Issue4295001Test("Hello");
    }
  };
  dart.setSignature(issue4295001_test.Issue4295001Test, {
    constructors: () => ({new: dart.definiteFunctionType(issue4295001_test.Issue4295001Test, [core.String])}),
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  issue4295001_test.main = function() {
    issue4295001_test.Issue4295001Test.testMain();
  };
  dart.fn(issue4295001_test.main, VoidTodynamic());
  // Exports:
  exports.issue4295001_test = issue4295001_test;
});
