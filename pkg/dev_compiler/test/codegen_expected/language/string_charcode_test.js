dart_library.library('language/string_charcode_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_charcode_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_charcode_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  string_charcode_test.main = function() {
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isTrue(string_charcode_test.moo("x"));
      expect$.Expect.isFalse(string_charcode_test.moo("X"));
      expect$.Expect.isFalse(string_charcode_test.moo("xx"));
      expect$.Expect.isTrue(string_charcode_test.mooRev("x"));
      expect$.Expect.isFalse(string_charcode_test.mooRev("X"));
      expect$.Expect.isFalse(string_charcode_test.mooRev("xx"));
      expect$.Expect.isTrue(string_charcode_test.goo("Hello", "e"));
      expect$.Expect.isFalse(string_charcode_test.goo("Hello", "E"));
      expect$.Expect.isFalse(string_charcode_test.goo("Hello", "ee"));
      expect$.Expect.isTrue(string_charcode_test.gooRev("Hello", "e"));
      expect$.Expect.isFalse(string_charcode_test.gooRev("Hello", "E"));
      expect$.Expect.isFalse(string_charcode_test.gooRev("Hello", "ee"));
      expect$.Expect.isTrue(string_charcode_test.hoo("HH"));
      expect$.Expect.isFalse(string_charcode_test.hoo("Ha"));
      expect$.Expect.isTrue(string_charcode_test.hooRev("HH"));
      expect$.Expect.isFalse(string_charcode_test.hooRev("Ha"));
    }
    expect$.Expect.isFalse(string_charcode_test.moo(12));
    expect$.Expect.isFalse(string_charcode_test.mooRev(12));
    expect$.Expect.isTrue(string_charcode_test.goo(JSArrayOfint().of([1, 2]), 2));
    expect$.Expect.isTrue(string_charcode_test.gooRev(JSArrayOfint().of([1, 2]), 2));
    expect$.Expect.throws(dart.fn(() => string_charcode_test.hoo("H"), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => string_charcode_test.hooRev("H"), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(string_charcode_test.main, VoidTodynamic());
  string_charcode_test.moo = function(j) {
    return dart.equals("x", j);
  };
  dart.fn(string_charcode_test.moo, dynamicTodynamic());
  string_charcode_test.goo = function(a, j) {
    return dart.equals(dart.dindex(a, 1), j);
  };
  dart.fn(string_charcode_test.goo, dynamicAnddynamicTodynamic());
  string_charcode_test.hoo = function(a) {
    return dart.equals(dart.dindex(a, 1), "Hello"[dartx.get](0));
  };
  dart.fn(string_charcode_test.hoo, dynamicTodynamic());
  string_charcode_test.mooRev = function(j) {
    return dart.equals(j, "x");
  };
  dart.fn(string_charcode_test.mooRev, dynamicTodynamic());
  string_charcode_test.gooRev = function(a, j) {
    return dart.equals(j, dart.dindex(a, 1));
  };
  dart.fn(string_charcode_test.gooRev, dynamicAnddynamicTodynamic());
  string_charcode_test.hooRev = function(a) {
    return dart.equals("Hello"[dartx.get](0), dart.dindex(a, 1));
  };
  dart.fn(string_charcode_test.hooRev, dynamicTodynamic());
  // Exports:
  exports.string_charcode_test = string_charcode_test;
});
