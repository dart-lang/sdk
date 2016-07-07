dart_library.library('language/const_constructor_super_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_constructor_super_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_constructor_super_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_constructor_super_test_none_multi.A = class A extends core.Object {
    new(a) {
      this.a = a;
    }
    five() {
      this.a = 5;
    }
  };
  dart.defineNamedConstructor(const_constructor_super_test_none_multi.A, 'five');
  dart.setSignature(const_constructor_super_test_none_multi.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(const_constructor_super_test_none_multi.A, [dart.dynamic]),
      five: dart.definiteFunctionType(const_constructor_super_test_none_multi.A, [])
    })
  });
  const_constructor_super_test_none_multi.B = class B extends const_constructor_super_test_none_multi.A {
    new(x) {
      this.b = dart.dsend(x, '+', 1);
      super.new(x);
    }
  };
  dart.setSignature(const_constructor_super_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_super_test_none_multi.B, [dart.dynamic])})
  });
  const_constructor_super_test_none_multi.C = class C extends const_constructor_super_test_none_multi.A {
    new() {
      super.new(0);
    }
  };
  dart.setSignature(const_constructor_super_test_none_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_super_test_none_multi.C, [])})
  });
  const_constructor_super_test_none_multi.main = function() {
    let b1 = new const_constructor_super_test_none_multi.B(0);
  };
  dart.fn(const_constructor_super_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.const_constructor_super_test_none_multi = const_constructor_super_test_none_multi;
});
