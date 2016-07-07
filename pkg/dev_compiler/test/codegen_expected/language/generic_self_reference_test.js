dart_library.library('language/generic_self_reference_test', null, /* Imports */[
  'dart_sdk'
], function load__generic_self_reference_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const generic_self_reference_test = Object.create(null);
  let Bar = () => (Bar = dart.constFn(generic_self_reference_test.Bar$()))();
  let Foo = () => (Foo = dart.constFn(generic_self_reference_test.Foo$()))();
  let FooOfint = () => (FooOfint = dart.constFn(generic_self_reference_test.Foo$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  generic_self_reference_test.Bar$ = dart.generic(T => {
    class Bar extends core.Object {}
    dart.addTypeTests(Bar);
    return Bar;
  });
  generic_self_reference_test.Bar = Bar();
  generic_self_reference_test.Foo$ = dart.generic(T => {
    class Foo extends generic_self_reference_test.Bar {}
    dart.setBaseClass(Foo, generic_self_reference_test.Bar$(Foo));
    return Foo;
  });
  generic_self_reference_test.Foo = Foo();
  generic_self_reference_test.main = function() {
    core.print(new (FooOfint())());
  };
  dart.fn(generic_self_reference_test.main, VoidTovoid());
  // Exports:
  exports.generic_self_reference_test = generic_self_reference_test;
});
