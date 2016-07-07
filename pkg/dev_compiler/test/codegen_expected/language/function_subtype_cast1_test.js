dart_library.library('language/function_subtype_cast1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_cast1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_cast1_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_cast1_test.Foo$()))();
  let Class = () => (Class = dart.constFn(function_subtype_cast1_test.Class$()))();
  let FooOfbool = () => (FooOfbool = dart.constFn(function_subtype_cast1_test.Foo$(core.bool)))();
  let FooOfint = () => (FooOfint = dart.constFn(function_subtype_cast1_test.Foo$(core.int)))();
  let ClassOfint = () => (ClassOfint = dart.constFn(function_subtype_cast1_test.Class$(core.int)))();
  let ClassOfbool = () => (ClassOfbool = dart.constFn(function_subtype_cast1_test.Class$(core.bool)))();
  let VoidToFooOfbool = () => (VoidToFooOfbool = dart.constFn(dart.definiteFunctionType(FooOfbool(), [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidToFooOfint = () => (VoidToFooOfint = dart.constFn(dart.definiteFunctionType(FooOfint(), [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  function_subtype_cast1_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [T]));
    return Foo;
  });
  function_subtype_cast1_test.Foo = Foo();
  function_subtype_cast1_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.int]));
  function_subtype_cast1_test.Class$ = dart.generic(T => {
    class Class extends core.Object {
      bar(i) {
        T._check(i);
      }
    }
    dart.addTypeTests(Class);
    dart.setSignature(Class, {
      methods: () => ({bar: dart.definiteFunctionType(dart.void, [T])})
    });
    return Class;
  });
  function_subtype_cast1_test.Class = Class();
  function_subtype_cast1_test.main = function() {
    expect$.Expect.isNotNull(dart.bind(new function_subtype_cast1_test.Class(), 'bar'));
    expect$.Expect.isNotNull(FooOfbool().as(dart.bind(new function_subtype_cast1_test.Class(), 'bar')));
    expect$.Expect.isNotNull(FooOfint().as(dart.bind(new function_subtype_cast1_test.Class(), 'bar')));
    expect$.Expect.isNotNull(function_subtype_cast1_test.Bar.as(dart.bind(new function_subtype_cast1_test.Class(), 'bar')));
    expect$.Expect.isNotNull(dart.bind(new (ClassOfint())(), 'bar'));
    expect$.Expect.throws(dart.fn(() => FooOfbool().as(dart.bind(new (ClassOfint())(), 'bar')), VoidToFooOfbool()), dart.fn(e => true, dynamicTobool()));
    expect$.Expect.isNotNull(dart.bind(new (ClassOfint())(), 'bar'));
    expect$.Expect.isNotNull(dart.bind(new (ClassOfint())(), 'bar'));
    expect$.Expect.isNotNull(dart.bind(new (ClassOfbool())(), 'bar'));
    expect$.Expect.isNotNull(dart.bind(new (ClassOfbool())(), 'bar'));
    expect$.Expect.throws(dart.fn(() => FooOfint().as(dart.bind(new (ClassOfbool())(), 'bar')), VoidToFooOfint()), dart.fn(e => true, dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => function_subtype_cast1_test.Bar.as(dart.bind(new (ClassOfbool())(), 'bar')), VoidToFooOfint()), dart.fn(e => true, dynamicTobool()));
  };
  dart.fn(function_subtype_cast1_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_cast1_test = function_subtype_cast1_test;
});
