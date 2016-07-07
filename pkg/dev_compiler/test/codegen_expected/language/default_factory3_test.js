dart_library.library('language/default_factory3_test', null, /* Imports */[
  'dart_sdk'
], function load__default_factory3_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const default_factory3_test = Object.create(null);
  let A = () => (A = dart.constFn(default_factory3_test.A$()))();
  let _AImpl = () => (_AImpl = dart.constFn(default_factory3_test._AImpl$()))();
  let AOfMoo = () => (AOfMoo = dart.constFn(default_factory3_test.A$(default_factory3_test.Moo)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  default_factory3_test.A$ = dart.generic(T => {
    let _AImplOfT = () => (_AImplOfT = dart.constFn(default_factory3_test._AImpl$(T)))();
    class A extends core.Object {
      static new() {
        return _AImplOfT().new();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(default_factory3_test.A$(T), [])})
    });
    return A;
  });
  default_factory3_test.A = A();
  default_factory3_test.Bar = class Bar extends core.Object {};
  default_factory3_test.Foo = class Foo extends default_factory3_test.Bar {};
  default_factory3_test.Moo = class Moo extends default_factory3_test.Foo {};
  default_factory3_test._AImpl$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(default_factory3_test.A$(T)))();
    class _AImpl extends core.Object {
      static new() {
      }
    }
    dart.addTypeTests(_AImpl);
    _AImpl[dart.implements] = () => [AOfT()];
    dart.setSignature(_AImpl, {
      constructors: () => ({new: dart.definiteFunctionType(default_factory3_test._AImpl$(T), [])})
    });
    return _AImpl;
  });
  default_factory3_test._AImpl = _AImpl();
  default_factory3_test.main = function() {
    let result = AOfMoo().new();
  };
  dart.fn(default_factory3_test.main, VoidTodynamic());
  // Exports:
  exports.default_factory3_test = default_factory3_test;
});
