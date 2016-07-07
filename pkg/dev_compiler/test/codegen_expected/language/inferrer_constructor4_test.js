dart_library.library('language/inferrer_constructor4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inferrer_constructor4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inferrer_constructor4_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToB = () => (VoidToB = dart.constFn(dart.definiteFunctionType(inferrer_constructor4_test.B, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inferrer_constructor4_test.escape = function(object) {
    core.print(dart.dsend(dart.dload(object, 'field'), '+', 42));
  };
  dart.fn(inferrer_constructor4_test.escape, dynamicTodynamic());
  inferrer_constructor4_test.A = class A extends core.Object {
    new() {
      inferrer_constructor4_test.escape(this);
    }
  };
  dart.setSignature(inferrer_constructor4_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_constructor4_test.A, [])})
  });
  inferrer_constructor4_test.B = class B extends inferrer_constructor4_test.A {
    new() {
      this.field = null;
      super.new();
      this.field = 42;
    }
  };
  dart.setSignature(inferrer_constructor4_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_constructor4_test.B, [])})
  });
  inferrer_constructor4_test.main = function() {
    expect$.Expect.throws(dart.fn(() => new inferrer_constructor4_test.B(), VoidToB()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(inferrer_constructor4_test.main, VoidTodynamic());
  // Exports:
  exports.inferrer_constructor4_test = inferrer_constructor4_test;
});
