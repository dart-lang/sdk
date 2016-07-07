dart_library.library('language/super_conditional_operator_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__super_conditional_operator_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const super_conditional_operator_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_conditional_operator_test_none_multi.B = class B extends core.Object {
    new() {
      this.field = 1;
    }
    namedConstructor() {
      this.field = 1;
    }
    method() {
      return 1;
    }
  };
  dart.defineNamedConstructor(super_conditional_operator_test_none_multi.B, 'namedConstructor');
  dart.setSignature(super_conditional_operator_test_none_multi.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(super_conditional_operator_test_none_multi.B, []),
      namedConstructor: dart.definiteFunctionType(super_conditional_operator_test_none_multi.B, [])
    }),
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_conditional_operator_test_none_multi.C = class C extends super_conditional_operator_test_none_multi.B {
    new() {
      super.new();
    }
    test() {}
  };
  dart.setSignature(super_conditional_operator_test_none_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(super_conditional_operator_test_none_multi.C, [])}),
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_conditional_operator_test_none_multi.main = function() {
    new super_conditional_operator_test_none_multi.C().test();
  };
  dart.fn(super_conditional_operator_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.super_conditional_operator_test_none_multi = super_conditional_operator_test_none_multi;
});
