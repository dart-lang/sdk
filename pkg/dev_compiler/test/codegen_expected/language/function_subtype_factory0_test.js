dart_library.library('language/function_subtype_factory0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_factory0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_factory0_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_factory0_test.Foo$()))();
  let C = () => (C = dart.constFn(function_subtype_factory0_test.C$()))();
  let COfString = () => (COfString = dart.constFn(function_subtype_factory0_test.C$(core.String)))();
  let COfbool = () => (COfbool = dart.constFn(function_subtype_factory0_test.C$(core.bool)))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  function_subtype_factory0_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [T]));
    return Foo;
  });
  function_subtype_factory0_test.Foo = Foo();
  function_subtype_factory0_test.C$ = dart.generic(T => {
    let FooOfT = () => (FooOfT = dart.constFn(function_subtype_factory0_test.Foo$(T)))();
    let COfT = () => (COfT = dart.constFn(function_subtype_factory0_test.C$(T)))();
    class C extends core.Object {
      static new(foo) {
        if (FooOfT().is(foo)) {
          return new (COfT()).internal();
        }
        return null;
      }
      internal() {
      }
    }
    dart.addTypeTests(C);
    dart.defineNamedConstructor(C, 'internal');
    dart.setSignature(C, {
      constructors: () => ({
        new: dart.definiteFunctionType(function_subtype_factory0_test.C$(T), [dart.dynamic]),
        internal: dart.definiteFunctionType(function_subtype_factory0_test.C$(T), [])
      })
    });
    return C;
  });
  function_subtype_factory0_test.C = C();
  function_subtype_factory0_test.method = function(s) {
  };
  dart.fn(function_subtype_factory0_test.method, StringTovoid());
  function_subtype_factory0_test.main = function() {
    expect$.Expect.isNotNull(COfString().new(function_subtype_factory0_test.method));
    expect$.Expect.isNull(COfbool().new(function_subtype_factory0_test.method));
  };
  dart.fn(function_subtype_factory0_test.main, VoidTovoid());
  // Exports:
  exports.function_subtype_factory0_test = function_subtype_factory0_test;
});
