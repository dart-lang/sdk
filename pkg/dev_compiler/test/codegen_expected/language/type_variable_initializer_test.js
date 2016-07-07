dart_library.library('language/type_variable_initializer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_variable_initializer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_variable_initializer_test = Object.create(null);
  let A = () => (A = dart.constFn(type_variable_initializer_test.A$()))();
  let B = () => (B = dart.constFn(type_variable_initializer_test.B$()))();
  let BOfint = () => (BOfint = dart.constFn(type_variable_initializer_test.B$(core.int)))();
  let MapOfint$int = () => (MapOfint$int = dart.constFn(core.Map$(core.int, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_variable_initializer_test.A$ = dart.generic(T => {
    let MapOfT$T = () => (MapOfT$T = dart.constFn(core.Map$(T, T)))();
    class A extends core.Object {
      new() {
        this.map = MapOfT$T().new();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(type_variable_initializer_test.A$(T), [])})
    });
    return A;
  });
  type_variable_initializer_test.A = A();
  type_variable_initializer_test.B$ = dart.generic(T => {
    class B extends type_variable_initializer_test.A$(T) {
      new() {
        super.new();
      }
    }
    return B;
  });
  type_variable_initializer_test.B = B();
  type_variable_initializer_test.main = function() {
    expect$.Expect.isTrue(MapOfint$int().is(new (BOfint())().map));
  };
  dart.fn(type_variable_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.type_variable_initializer_test = type_variable_initializer_test;
});
