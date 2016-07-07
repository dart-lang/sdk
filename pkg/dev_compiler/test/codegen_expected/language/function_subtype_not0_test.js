dart_library.library('language/function_subtype_not0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_not0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_not0_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_not0_test.Foo$()))();
  let FooOfbool = () => (FooOfbool = dart.constFn(function_subtype_not0_test.Foo$(core.bool)))();
  let FooOfint = () => (FooOfint = dart.constFn(function_subtype_not0_test.Foo$(core.int)))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  function_subtype_not0_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [T]));
    return Foo;
  });
  function_subtype_not0_test.Foo = Foo();
  function_subtype_not0_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.int]));
  function_subtype_not0_test.bar = function(i) {
  };
  dart.fn(function_subtype_not0_test.bar, intTovoid());
  function_subtype_not0_test.main = function() {
    expect$.Expect.isFalse(!function_subtype_not0_test.Foo.is(function_subtype_not0_test.bar));
    expect$.Expect.isTrue(!FooOfbool().is(function_subtype_not0_test.bar));
    expect$.Expect.isFalse(!FooOfint().is(function_subtype_not0_test.bar));
    expect$.Expect.isFalse(!function_subtype_not0_test.Bar.is(function_subtype_not0_test.bar));
  };
  dart.fn(function_subtype_not0_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_not0_test = function_subtype_not0_test;
});
