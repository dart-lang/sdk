dart_library.library('language/class_cycle_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__class_cycle_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const class_cycle_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  class_cycle_test_none_multi.Foo = class Foo extends core.Object {};
  class_cycle_test_none_multi.Foo[dart.implements] = () => [class_cycle_test_none_multi.Bar];
  class_cycle_test_none_multi.C = class C extends core.Object {};
  class_cycle_test_none_multi.Bar = class Bar extends core.Object {};
  class_cycle_test_none_multi.ImplementsC = class ImplementsC extends core.Object {};
  class_cycle_test_none_multi.ImplementsC[dart.implements] = () => [class_cycle_test_none_multi.C];
  class_cycle_test_none_multi.ExtendsC = class ExtendsC extends class_cycle_test_none_multi.C {};
  class_cycle_test_none_multi.main = function() {
    expect$.Expect.isTrue(class_cycle_test_none_multi.Foo.is(new class_cycle_test_none_multi.Foo()));
    expect$.Expect.isTrue(class_cycle_test_none_multi.C.is(new class_cycle_test_none_multi.ImplementsC()));
    expect$.Expect.isTrue(class_cycle_test_none_multi.C.is(new class_cycle_test_none_multi.ExtendsC()));
  };
  dart.fn(class_cycle_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.class_cycle_test_none_multi = class_cycle_test_none_multi;
});
