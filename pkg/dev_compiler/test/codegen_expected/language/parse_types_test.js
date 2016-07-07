dart_library.library('language/parse_types_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__parse_types_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const parse_types_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  parse_types_test.ParseTypesTest = class ParseTypesTest extends core.Object {
    static callBool1() {
      return true;
    }
    static callBool2() {
      return false;
    }
    static callInt() {
      return 2;
    }
    static callString() {
      return "Hey";
    }
    static callDouble() {
      return 4.0;
    }
    static testMain() {
      expect$.Expect.equals(true, parse_types_test.ParseTypesTest.callBool1());
      expect$.Expect.equals(false, parse_types_test.ParseTypesTest.callBool2());
      expect$.Expect.equals(2, parse_types_test.ParseTypesTest.callInt());
      expect$.Expect.equals("Hey", parse_types_test.ParseTypesTest.callString());
      expect$.Expect.equals(4.0, parse_types_test.ParseTypesTest.callDouble());
    }
  };
  dart.setSignature(parse_types_test.ParseTypesTest, {
    statics: () => ({
      callBool1: dart.definiteFunctionType(core.bool, []),
      callBool2: dart.definiteFunctionType(core.bool, []),
      callInt: dart.definiteFunctionType(core.int, []),
      callString: dart.definiteFunctionType(core.String, []),
      callDouble: dart.definiteFunctionType(core.double, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['callBool1', 'callBool2', 'callInt', 'callString', 'callDouble', 'testMain']
  });
  parse_types_test.main = function() {
    parse_types_test.ParseTypesTest.testMain();
  };
  dart.fn(parse_types_test.main, VoidTodynamic());
  // Exports:
  exports.parse_types_test = parse_types_test;
});
