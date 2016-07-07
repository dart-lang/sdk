dart_library.library('language/reify_typevar_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reify_typevar_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reify_typevar_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(reify_typevar_test.Foo$()))();
  let FooOfint = () => (FooOfint = dart.constFn(reify_typevar_test.Foo$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reify_typevar_test.Foo$ = dart.generic(T => {
    class Foo extends core.Object {
      reify() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      methods: () => ({reify: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return Foo;
  });
  reify_typevar_test.Foo = Foo();
  reify_typevar_test.main = function() {
    expect$.Expect.equals(dart.wrapType(core.int), new (FooOfint())().reify());
    expect$.Expect.equals(dart.wrapType(reify_typevar_test.Foo), new reify_typevar_test.Foo().runtimeType);
  };
  dart.fn(reify_typevar_test.main, VoidTodynamic());
  // Exports:
  exports.reify_typevar_test = reify_typevar_test;
});
