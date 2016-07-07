dart_library.library('language/function_subtype_cast0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_cast0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_cast0_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_cast0_test.Foo$()))();
  let FooOfbool = () => (FooOfbool = dart.constFn(function_subtype_cast0_test.Foo$(core.bool)))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidToFooOfbool = () => (VoidToFooOfbool = dart.constFn(dart.definiteFunctionType(FooOfbool(), [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  function_subtype_cast0_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [T]));
    return Foo;
  });
  function_subtype_cast0_test.Foo = Foo();
  function_subtype_cast0_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.int]));
  function_subtype_cast0_test.bar = function(i) {
  };
  dart.fn(function_subtype_cast0_test.bar, intTovoid());
  function_subtype_cast0_test.main = function() {
    expect$.Expect.isNotNull(function_subtype_cast0_test.bar);
    expect$.Expect.throws(dart.fn(() => FooOfbool().as(function_subtype_cast0_test.bar), VoidToFooOfbool()), dart.fn(e => true, dynamicTobool()));
    expect$.Expect.isNotNull(function_subtype_cast0_test.bar);
    expect$.Expect.isNotNull(function_subtype_cast0_test.bar);
  };
  dart.fn(function_subtype_cast0_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_cast0_test = function_subtype_cast0_test;
});
