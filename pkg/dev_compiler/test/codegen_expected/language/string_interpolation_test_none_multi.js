dart_library.library('language/string_interpolation_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_interpolation_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_interpolation_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_interpolation_test_none_multi.StringInterpolationTest = class StringInterpolationTest extends core.Object {
    new() {
      this.j = null;
      this.k = null;
    }
    static m() {}
    static testMain(alwaysFalse) {
      let test = new string_interpolation_test_none_multi.StringInterpolationTest();
      test.j = 3;
      test.k = 5;
      expect$.Expect.equals(" hi ", " hi ");
      let c1 = '1';
      let c2 = '2';
      let c3 = '3';
      let c4 = '4';
      expect$.Expect.equals(" 1", dart.str` ${c1}`);
      expect$.Expect.equals("1 ", dart.str`${c1} `);
      expect$.Expect.equals("1", dart.str`${c1}`);
      expect$.Expect.equals("12", dart.str`${c1}${c2}`);
      expect$.Expect.equals("12 34", dart.str`${c1}${c2} ${c3}${c4}`);
      expect$.Expect.equals(" hi 1 ", dart.str` hi ${string_interpolation_test_none_multi.StringInterpolationTest.i} `);
      expect$.Expect.equals(" hi <hi> ", dart.str` hi ${string_interpolation_test_none_multi.StringInterpolationTest.a} `);
      expect$.Expect.equals("param = 9", test.embedParams(9));
      expect$.Expect.equals("j = 3", test.embedSingleField());
      expect$.Expect.equals(" hi 1 <hi>", dart.str` hi ${string_interpolation_test_none_multi.StringInterpolationTest.i} ${string_interpolation_test_none_multi.StringInterpolationTest.a}`);
      expect$.Expect.equals("j = 3; k = 5", test.embedMultipleFields());
      expect$.Expect.equals("$", "escaped     ${3+2}"[dartx.get](12));
      expect$.Expect.equals("{", "escaped     ${3+2}"[dartx.get](13));
      expect$.Expect.equals("3", "escaped     ${3+2}"[dartx.get](14));
      expect$.Expect.equals("+", "escaped     ${3+2}"[dartx.get](15));
      expect$.Expect.equals("2", "escaped     ${3+2}"[dartx.get](16));
      expect$.Expect.equals("}", "escaped     ${3+2}"[dartx.get](17));
      if (dart.test(alwaysFalse)) {
      }
      expect$.Expect.equals(dart.str`${string_interpolation_test_none_multi.StringInterpolationTest.m}`, dart.str`${string_interpolation_test_none_multi.StringInterpolationTest.m}`);
    }
    embedParams(z) {
      return dart.str`param = ${z}`;
    }
    embedSingleField() {
      return dart.str`j = ${this.j}`;
    }
    embedMultipleFields() {
      return dart.str`j = ${this.j}; k = ${this.k}`;
    }
  };
  dart.setSignature(string_interpolation_test_none_multi.StringInterpolationTest, {
    constructors: () => ({new: dart.definiteFunctionType(string_interpolation_test_none_multi.StringInterpolationTest, [])}),
    methods: () => ({
      embedParams: dart.definiteFunctionType(core.String, [core.int]),
      embedSingleField: dart.definiteFunctionType(core.String, []),
      embedMultipleFields: dart.definiteFunctionType(core.String, [])
    }),
    statics: () => ({
      m: dart.definiteFunctionType(dart.void, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [core.bool])
    }),
    names: ['m', 'testMain']
  });
  string_interpolation_test_none_multi.StringInterpolationTest.i = 1;
  string_interpolation_test_none_multi.StringInterpolationTest.a = "<hi>";
  string_interpolation_test_none_multi.main = function() {
    string_interpolation_test_none_multi.StringInterpolationTest.testMain(false);
  };
  dart.fn(string_interpolation_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.string_interpolation_test_none_multi = string_interpolation_test_none_multi;
});
