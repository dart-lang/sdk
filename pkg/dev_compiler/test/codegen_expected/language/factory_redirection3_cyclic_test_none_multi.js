dart_library.library('language/factory_redirection3_cyclic_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__factory_redirection3_cyclic_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const factory_redirection3_cyclic_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  factory_redirection3_cyclic_test_none_multi.A = class A extends core.Object {
    static foo() {
      return factory_redirection3_cyclic_test_none_multi.B.new();
    }
  };
  dart.setSignature(factory_redirection3_cyclic_test_none_multi.A, {
    constructors: () => ({foo: dart.definiteFunctionType(factory_redirection3_cyclic_test_none_multi.A, [])})
  });
  factory_redirection3_cyclic_test_none_multi.B = class B extends core.Object {
    static new() {
      return factory_redirection3_cyclic_test_none_multi.C.bar();
    }
  };
  factory_redirection3_cyclic_test_none_multi.B[dart.implements] = () => [factory_redirection3_cyclic_test_none_multi.A];
  dart.setSignature(factory_redirection3_cyclic_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(factory_redirection3_cyclic_test_none_multi.B, [])})
  });
  factory_redirection3_cyclic_test_none_multi.C = class C extends core.Object {
    static bar() {
      return factory_redirection3_cyclic_test_none_multi.C.foo();
    }
    static foo() {
      return new factory_redirection3_cyclic_test_none_multi.C();
    }
    new() {
    }
  };
  factory_redirection3_cyclic_test_none_multi.C[dart.implements] = () => [factory_redirection3_cyclic_test_none_multi.B];
  dart.setSignature(factory_redirection3_cyclic_test_none_multi.C, {
    constructors: () => ({
      bar: dart.definiteFunctionType(factory_redirection3_cyclic_test_none_multi.C, []),
      foo: dart.definiteFunctionType(factory_redirection3_cyclic_test_none_multi.C, []),
      new: dart.definiteFunctionType(factory_redirection3_cyclic_test_none_multi.C, [])
    })
  });
  factory_redirection3_cyclic_test_none_multi.main = function() {
    factory_redirection3_cyclic_test_none_multi.A.foo();
  };
  dart.fn(factory_redirection3_cyclic_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.factory_redirection3_cyclic_test_none_multi = factory_redirection3_cyclic_test_none_multi;
});
