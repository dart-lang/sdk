dart_library.library('language/first_class_types_literals_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__first_class_types_literals_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const first_class_types_literals_test_02_multi = Object.create(null);
  let C = () => (C = dart.constFn(first_class_types_literals_test_02_multi.C$()))();
  let JSArrayOfType = () => (JSArrayOfType = dart.constFn(_interceptors.JSArray$(core.Type)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  first_class_types_literals_test_02_multi.C$ = dart.generic((T, U, V) => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  first_class_types_literals_test_02_multi.C = C();
  first_class_types_literals_test_02_multi.D = class D extends core.Object {};
  first_class_types_literals_test_02_multi.Foo = dart.typedef('Foo', () => dart.functionType(core.int, [core.bool]));
  first_class_types_literals_test_02_multi.sameType = function(a, b) {
    expect$.Expect.equals(dart.runtimeType(a), dart.runtimeType(b));
  };
  dart.fn(first_class_types_literals_test_02_multi.sameType, dynamicAnddynamicTodynamic());
  first_class_types_literals_test_02_multi.main = function() {
    function foo(a) {
    }
    dart.fn(foo, dynamicTovoid());
    JSArrayOfType().of([dart.wrapType(core.int)]);
    JSArrayOfType().of([dart.wrapType(core.int)]);
    foo(JSArrayOfType().of([dart.wrapType(core.int)]));
    JSArrayOfType().of([dart.wrapType(core.int)])[dartx.length];
    dart.map([1, dart.wrapType(core.int)]);
    foo(dart.map([1, dart.wrapType(core.int)]));
    dart.map([1, dart.wrapType(core.int)])[dartx.keys];
    expect$.Expect.equals(dart.wrapType(core.int), dart.wrapType(core.int));
    expect$.Expect.notEquals(dart.wrapType(core.int), dart.wrapType(core.num));
    expect$.Expect.equals(dart.wrapType(first_class_types_literals_test_02_multi.Foo), dart.wrapType(first_class_types_literals_test_02_multi.Foo));
    expect$.Expect.equals(dart.wrapType(dart.dynamic), dart.wrapType(dart.dynamic));
    expect$.Expect.isTrue(core.Type.is(dart.wrapType(first_class_types_literals_test_02_multi.D).runtimeType));
    expect$.Expect.isTrue(core.Type.is(dart.runtimeType(dart.wrapType(dart.dynamic))));
    expect$.Expect.equals(dart.wrapType(core.int), dart.runtimeType(1));
    expect$.Expect.equals(dart.wrapType(core.String), dart.runtimeType('hest'));
    expect$.Expect.equals(dart.wrapType(core.double), dart.runtimeType(0.5));
    expect$.Expect.equals(dart.wrapType(core.bool), dart.runtimeType(true));
    expect$.Expect.equals(dart.wrapType(first_class_types_literals_test_02_multi.D), new first_class_types_literals_test_02_multi.D().runtimeType);
    expect$.Expect.equals(dart.wrapType(first_class_types_literals_test_02_multi.D).runtimeType, dart.runtimeType(dart.wrapType(first_class_types_literals_test_02_multi.D).runtimeType));
    expect$.Expect.equals(dart.toString(dart.wrapType(dart.dynamic)), 'dynamic');
  };
  dart.fn(first_class_types_literals_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.first_class_types_literals_test_02_multi = first_class_types_literals_test_02_multi;
});
