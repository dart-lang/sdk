dart_library.library('language/function_subtype_typearg0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_typearg0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_typearg0_test = Object.create(null);
  let A = () => (A = dart.constFn(function_subtype_typearg0_test.A$()))();
  let AOfFoo = () => (AOfFoo = dart.constFn(function_subtype_typearg0_test.A$(function_subtype_typearg0_test.Foo)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  function_subtype_typearg0_test.Foo = dart.typedef('Foo', () => dart.functionType(dart.void, []));
  function_subtype_typearg0_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo(a) {
        return T.is(a);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(core.bool, [dart.dynamic])})
    });
    return A;
  });
  function_subtype_typearg0_test.A = A();
  function_subtype_typearg0_test.bar1 = function() {
  };
  dart.fn(function_subtype_typearg0_test.bar1, VoidTovoid());
  function_subtype_typearg0_test.bar2 = function(i) {
  };
  dart.fn(function_subtype_typearg0_test.bar2, dynamicTovoid());
  function_subtype_typearg0_test.main = function() {
    function bar3() {
    }
    dart.fn(bar3, VoidTovoid());
    function bar4(i) {
    }
    dart.fn(bar4, dynamicTovoid());
    expect$.Expect.isTrue(new (AOfFoo())().foo(function_subtype_typearg0_test.bar1));
    expect$.Expect.isFalse(new (AOfFoo())().foo(function_subtype_typearg0_test.bar2));
    expect$.Expect.isTrue(new (AOfFoo())().foo(bar3));
    expect$.Expect.isFalse(new (AOfFoo())().foo(bar4));
    expect$.Expect.isTrue(new (AOfFoo())().foo(dart.fn(() => {
    }, VoidTodynamic())));
    expect$.Expect.isFalse(new (AOfFoo())().foo(dart.fn(i => {
    }, dynamicTodynamic())));
  };
  dart.fn(function_subtype_typearg0_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_typearg0_test = function_subtype_typearg0_test;
});
