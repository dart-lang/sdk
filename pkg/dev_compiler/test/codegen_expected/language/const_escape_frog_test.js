dart_library.library('language/const_escape_frog_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_escape_frog_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_escape_frog_test = Object.create(null);
  let BarOfFoo = () => (BarOfFoo = dart.constFn(const_escape_frog_test.Bar$(const_escape_frog_test.Foo)))();
  let Bar = () => (Bar = dart.constFn(const_escape_frog_test.Bar$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_escape_frog_test.Foo = class Foo extends core.Object {
    new() {
      this.bar = dart.const(new (BarOfFoo())());
    }
  };
  const_escape_frog_test.Bar$ = dart.generic(T => {
    class Bar extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(Bar);
    dart.setSignature(Bar, {
      constructors: () => ({new: dart.definiteFunctionType(const_escape_frog_test.Bar$(T), [])})
    });
    return Bar;
  });
  const_escape_frog_test.Bar = Bar();
  let const$;
  const_escape_frog_test.main = function() {
    expect$.Expect.equals(new const_escape_frog_test.Foo().bar, const$ || (const$ = dart.const(new (BarOfFoo())())));
  };
  dart.fn(const_escape_frog_test.main, VoidTodynamic());
  // Exports:
  exports.const_escape_frog_test = const_escape_frog_test;
});
