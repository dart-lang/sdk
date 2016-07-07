dart_library.library('language/string_join_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_join_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_join_test = Object.create(null);
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_join_test.StringJoinTest = class StringJoinTest extends core.Object {
    static testMain() {
      let ga = ListOfString().new();
      ga[dartx.add]("a");
      ga[dartx.add]("b");
      expect$.Expect.equals("ab", ga[dartx.join]());
      expect$.Expect.equals("ab", ga[dartx.join](""));
    }
  };
  dart.setSignature(string_join_test.StringJoinTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  string_join_test.main = function() {
    string_join_test.StringJoinTest.testMain();
  };
  dart.fn(string_join_test.main, VoidTodynamic());
  // Exports:
  exports.string_join_test = string_join_test;
});
