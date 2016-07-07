dart_library.library('language/function_subtype_not2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_not2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_not2_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_not2_test.Foo$()))();
  let Class = () => (Class = dart.constFn(function_subtype_not2_test.Class$()))();
  let ClassOfint = () => (ClassOfint = dart.constFn(function_subtype_not2_test.Class$(core.int)))();
  let ClassOfbool = () => (ClassOfbool = dart.constFn(function_subtype_not2_test.Class$(core.bool)))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  function_subtype_not2_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [T]));
    return Foo;
  });
  function_subtype_not2_test.Foo = Foo();
  function_subtype_not2_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.int]));
  function_subtype_not2_test.Class$ = dart.generic(T => {
    let FooOfT = () => (FooOfT = dart.constFn(function_subtype_not2_test.Foo$(T)))();
    class Class extends core.Object {
      test(expectedResult, o, typeName) {
        expect$.Expect.equals(expectedResult, !FooOfT().is(o), dart.str`bar is! Foo<${typeName}>`);
        expect$.Expect.isFalse(!function_subtype_not2_test.Bar.is(o), "bar is! Bar");
      }
    }
    dart.addTypeTests(Class);
    dart.setSignature(Class, {
      methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [core.bool, dart.dynamic, core.String])})
    });
    return Class;
  });
  function_subtype_not2_test.Class = Class();
  function_subtype_not2_test.bar = function(i) {
  };
  dart.fn(function_subtype_not2_test.bar, intTovoid());
  function_subtype_not2_test.main = function() {
    new function_subtype_not2_test.Class().test(false, function_subtype_not2_test.bar, "dynamic");
    new (ClassOfint())().test(false, function_subtype_not2_test.bar, "int");
    new (ClassOfbool())().test(true, function_subtype_not2_test.bar, "bool");
  };
  dart.fn(function_subtype_not2_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_not2_test = function_subtype_not2_test;
});
