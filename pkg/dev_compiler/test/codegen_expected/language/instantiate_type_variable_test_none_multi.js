dart_library.library('language/instantiate_type_variable_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__instantiate_type_variable_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const instantiate_type_variable_test_none_multi = Object.create(null);
  let Foo = () => (Foo = dart.constFn(instantiate_type_variable_test_none_multi.Foo$()))();
  let FooOfObject = () => (FooOfObject = dart.constFn(instantiate_type_variable_test_none_multi.Foo$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instantiate_type_variable_test_none_multi.Foo$ = dart.generic(T => {
    class Foo extends core.Object {
      new() {
      }
      make() {}
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      constructors: () => ({new: dart.definiteFunctionType(instantiate_type_variable_test_none_multi.Foo$(T), [])}),
      methods: () => ({make: dart.definiteFunctionType(T, [])})
    });
    return Foo;
  });
  instantiate_type_variable_test_none_multi.Foo = Foo();
  instantiate_type_variable_test_none_multi.main = function() {
    new (FooOfObject())().make();
  };
  dart.fn(instantiate_type_variable_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.instantiate_type_variable_test_none_multi = instantiate_type_variable_test_none_multi;
});
