dart_library.library('language/string_interpolate2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_interpolate2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_interpolate2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  string_interpolate2_test.StringInterpolate2Test = class StringInterpolate2Test extends core.Object {
    static testMain() {
      string_interpolate2_test.StringInterpolate2Test.F1 = dart.str`1 + 5 = ${1 + 5}`;
      expect$.Expect.equals("1 + 5 = 6", string_interpolate2_test.StringInterpolate2Test.F1);
      let fib = JSArrayOfint().of([1, 1, 2, 3, 5, 8, 13, 21]);
      let i = 5;
      let s = dart.str`${i}`;
      expect$.Expect.equals("5", s);
      s = dart.str`fib(${i}) = ${fib[dartx.get](i)}`;
      expect$.Expect.equals("fib(5) = 8", s);
      i = 5;
      s = dart.str`${i} squared is ${dart.dcall(dart.fn(x => dart.dsend(x, '*', x), dynamicTodynamic()), i)}`;
      expect$.Expect.equals("5 squared is 25", s);
      expect$.Expect.equals("8", dart.str`${fib[dartx.length]}`);
      expect$.Expect.equals("8", dart.str`${fib[dartx.length]}`);
      expect$.Expect.equals("8", dart.str`${fib[dartx.length]}`);
      let map = dart.map({red: 1, green: 2, blue: 3});
      s = dart.str`green has value ${map[dartx.get]("green")}`;
      expect$.Expect.equals("green has value 2", s);
      i = 0;
      function b() {
        return dart.str`${++i}`;
      }
      dart.fn(b, VoidTodynamic());
      s = dart.str`aaa ${dart.str`bbb ${b()} bbb`} aaa ${b()}`;
      expect$.Expect.equals("aaa bbb 1 bbb aaa 2", s);
      s = dart.str`a ${dart.fn(() => dart.str`b ${dart.fn(() => "c", VoidToString())()}`, VoidToString())()} d`;
      expect$.Expect.equals("a b c d", s);
    }
  };
  dart.setSignature(string_interpolate2_test.StringInterpolate2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  string_interpolate2_test.StringInterpolate2Test.F1 = null;
  string_interpolate2_test.main = function() {
    string_interpolate2_test.StringInterpolate2Test.testMain();
  };
  dart.fn(string_interpolate2_test.main, VoidTodynamic());
  // Exports:
  exports.string_interpolate2_test = string_interpolate2_test;
});
