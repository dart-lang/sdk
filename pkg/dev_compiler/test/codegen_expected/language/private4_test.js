dart_library.library('language/private4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__private4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const private4_test = Object.create(null);
  const other_library = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  private4_test.main = function() {
    expect$.Expect.equals(42, other_library.foo(new other_library.A()));
    expect$.Expect.throws(dart.fn(() => other_library.foo(new private4_test.B()), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(private4_test.main, VoidTodynamic());
  const _bar = Symbol('_bar');
  private4_test.B = class B extends core.Object {
    [_bar]() {
      return 42;
    }
  };
  dart.setSignature(private4_test.B, {
    methods: () => ({[_bar]: dart.definiteFunctionType(dart.dynamic, [])})
  });
  const _bar$ = Symbol('_bar');
  other_library.foo = function(a) {
    return dart.dsend(a, _bar$);
  };
  dart.fn(other_library.foo, dynamicTodynamic());
  other_library.A = class A extends core.Object {
    [_bar$]() {
      return 42;
    }
  };
  dart.setSignature(other_library.A, {
    methods: () => ({[_bar$]: dart.definiteFunctionType(dart.dynamic, [])})
  });
  // Exports:
  exports.private4_test = private4_test;
  exports.other_library = other_library;
});
