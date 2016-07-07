dart_library.library('language/string_interpolation7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_interpolation7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_interpolation7_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_interpolation7_test.A = class A extends core.Object {
    new() {
    }
    toString() {
      return "A";
    }
  };
  dart.setSignature(string_interpolation7_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(string_interpolation7_test.A, [])})
  });
  string_interpolation7_test.StringInterpolation7Test = class StringInterpolation7Test extends core.Object {
    static testMain() {
      let a = new string_interpolation7_test.A();
      expect$.Expect.equals("A + A", dart.str`${a} + ${a}`);
      a = null;
      expect$.Expect.equals("null", dart.str`${a}`);
    }
  };
  dart.setSignature(string_interpolation7_test.StringInterpolation7Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  string_interpolation7_test.main = function() {
    string_interpolation7_test.StringInterpolation7Test.testMain();
  };
  dart.fn(string_interpolation7_test.main, VoidTodynamic());
  // Exports:
  exports.string_interpolation7_test = string_interpolation7_test;
});
