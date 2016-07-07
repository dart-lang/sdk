dart_library.library('corelib/string_trim_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_trim_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_trim_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_trim_test.StringTrimTest = class StringTrimTest extends core.Object {
    static testMain() {
      expect$.Expect.equals("", " "[dartx.trim]());
      expect$.Expect.equals("", "     "[dartx.trim]());
      let a = "      lots of space on the left";
      expect$.Expect.equals("lots of space on the left", a[dartx.trim]());
      a = "lots of space on the right           ";
      expect$.Expect.equals("lots of space on the right", a[dartx.trim]());
      a = "         lots of space           ";
      expect$.Expect.equals("lots of space", a[dartx.trim]());
      a = "  x  ";
      expect$.Expect.equals("x", a[dartx.trim]());
      expect$.Expect.equals("", " \t \n \r "[dartx.trim]());
    }
  };
  dart.setSignature(string_trim_test.StringTrimTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  string_trim_test.main = function() {
    string_trim_test.StringTrimTest.testMain();
  };
  dart.fn(string_trim_test.main, VoidTodynamic());
  // Exports:
  exports.string_trim_test = string_trim_test;
});
