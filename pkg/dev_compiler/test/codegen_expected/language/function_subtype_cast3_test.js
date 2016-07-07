dart_library.library('language/function_subtype_cast3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_cast3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_cast3_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_cast3_test.Foo$()))();
  let Class = () => (Class = dart.constFn(function_subtype_cast3_test.Class$()))();
  let ClassOfint = () => (ClassOfint = dart.constFn(function_subtype_cast3_test.Class$(core.int)))();
  let ClassOfbool = () => (ClassOfbool = dart.constFn(function_subtype_cast3_test.Class$(core.bool)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  function_subtype_cast3_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [T]));
    return Foo;
  });
  function_subtype_cast3_test.Foo = Foo();
  function_subtype_cast3_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.int]));
  function_subtype_cast3_test.Class$ = dart.generic(T => {
    let FooOfT = () => (FooOfT = dart.constFn(function_subtype_cast3_test.Foo$(T)))();
    let VoidToFooOfT = () => (VoidToFooOfT = dart.constFn(dart.definiteFunctionType(FooOfT(), [])))();
    class Class extends core.Object {
      test(expectedResult, o, typeName) {
        function local() {
          if (dart.test(expectedResult)) {
            expect$.Expect.isNotNull(FooOfT().as(o), dart.str`bar as Foo<${typeName}>`);
          } else {
            expect$.Expect.throws(dart.fn(() => FooOfT().as(o), VoidToFooOfT()), dart.fn(e => true, dynamicTobool()), dart.str`bar as Foo<${typeName}>`);
          }
          expect$.Expect.isNotNull(function_subtype_cast3_test.Bar.as(o), "bar as Bar");
        }
        dart.fn(local, VoidTovoid());
        local();
      }
    }
    dart.addTypeTests(Class);
    dart.setSignature(Class, {
      methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [core.bool, dart.dynamic, core.String])})
    });
    return Class;
  });
  function_subtype_cast3_test.Class = Class();
  function_subtype_cast3_test.bar = function(i) {
  };
  dart.fn(function_subtype_cast3_test.bar, intTovoid());
  function_subtype_cast3_test.main = function() {
    new function_subtype_cast3_test.Class().test(true, function_subtype_cast3_test.bar, "dynamic");
    new (ClassOfint())().test(true, function_subtype_cast3_test.bar, "int");
    new (ClassOfbool())().test(false, function_subtype_cast3_test.bar, "bool");
  };
  dart.fn(function_subtype_cast3_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_cast3_test = function_subtype_cast3_test;
});
