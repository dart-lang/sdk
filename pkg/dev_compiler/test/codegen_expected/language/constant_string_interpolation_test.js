dart_library.library('language/constant_string_interpolation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constant_string_interpolation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constant_string_interpolation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  constant_string_interpolation_test.main = function() {
    let a = new constant_string_interpolation_test.A();
    for (let i = 0; i < 20; i++) {
      let r = constant_string_interpolation_test.interpolIt(a);
      expect$.Expect.stringEquals("hello home", r);
    }
    let b = new constant_string_interpolation_test.B();
    let r = constant_string_interpolation_test.interpolIt(b);
    expect$.Expect.stringEquals("hello world", r);
  };
  dart.fn(constant_string_interpolation_test.main, VoidTodynamic());
  constant_string_interpolation_test.interpolIt = function(v) {
    return dart.str`hello ${dart.dsend(v, 'foo')}`;
  };
  dart.fn(constant_string_interpolation_test.interpolIt, dynamicToString());
  constant_string_interpolation_test.A = class A extends core.Object {
    foo() {
      return "home";
    }
  };
  dart.setSignature(constant_string_interpolation_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  constant_string_interpolation_test.B = class B extends core.Object {
    foo() {
      return "world";
    }
  };
  dart.setSignature(constant_string_interpolation_test.B, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  // Exports:
  exports.constant_string_interpolation_test = constant_string_interpolation_test;
});
