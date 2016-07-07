dart_library.library('language/prefix24_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__prefix24_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const prefix24_test = Object.create(null);
  const prefix24_lib1 = Object.create(null);
  const prefix24_lib2 = Object.create(null);
  const prefix24_lib3 = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  prefix24_test.main = function() {
    expect$.Expect.equals("static method bar of class X", prefix24_lib3.X.bar());
    expect$.Expect.equals("prefix24_lib2_bar", prefix24_lib1.lib1_foo());
  };
  dart.fn(prefix24_test.main, VoidTodynamic());
  prefix24_lib1.lib1_foo = function() {
    return prefix24_lib2.bar();
  };
  dart.fn(prefix24_lib1.lib1_foo, VoidTodynamic());
  prefix24_lib2.bar = function() {
    return "prefix24_lib2_bar";
  };
  dart.fn(prefix24_lib2.bar, VoidTodynamic());
  prefix24_lib3.X = class X extends core.Object {
    static bar() {
      return "static method bar of class X";
    }
  };
  dart.setSignature(prefix24_lib3.X, {
    statics: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['bar']
  });
  // Exports:
  exports.prefix24_test = prefix24_test;
  exports.prefix24_lib1 = prefix24_lib1;
  exports.prefix24_lib2 = prefix24_lib2;
  exports.prefix24_lib3 = prefix24_lib3;
});
