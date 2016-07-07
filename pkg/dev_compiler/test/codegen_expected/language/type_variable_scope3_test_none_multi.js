dart_library.library('language/type_variable_scope3_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_variable_scope3_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_variable_scope3_test_none_multi = Object.create(null);
  let Foo = () => (Foo = dart.constFn(type_variable_scope3_test_none_multi.Foo$()))();
  let FooOfString = () => (FooOfString = dart.constFn(type_variable_scope3_test_none_multi.Foo$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_variable_scope3_test_none_multi.Foo$ = dart.generic(T => {
    class Foo extends core.Object {}
    dart.addTypeTests(Foo);
    return Foo;
  });
  type_variable_scope3_test_none_multi.Foo = Foo();
  type_variable_scope3_test_none_multi.main = function() {
    new (FooOfString())();
  };
  dart.fn(type_variable_scope3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.type_variable_scope3_test_none_multi = type_variable_scope3_test_none_multi;
});
