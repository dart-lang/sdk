dart_library.library('language/string_interpolate_null_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_interpolate_null_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_interpolate_null_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_interpolate_null_test.A = class A extends core.Object {
    new(name) {
      this.name = name;
    }
  };
  dart.setSignature(string_interpolate_null_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(string_interpolate_null_test.A, [core.String])})
  });
  string_interpolate_null_test.main = function() {
    let a = new string_interpolate_null_test.A("Kermit");
    let s = dart.str`Hello Mr. ${a.name}`;
    expect$.Expect.stringEquals("Hello Mr. Kermit", s);
    a = null;
    try {
      s = dart.str`Hello Mr. ${a.name}`;
    } catch (e) {
      if (core.NoSuchMethodError.is(e)) {
        return;
      } else
        throw e;
    }

    expect$.Expect.fail("NoSuchMethodError not thrown");
  };
  dart.fn(string_interpolate_null_test.main, VoidTodynamic());
  // Exports:
  exports.string_interpolate_null_test = string_interpolate_null_test;
});
