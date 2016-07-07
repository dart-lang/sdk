dart_library.library('language/inference_mixin_field_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inference_mixin_field_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inference_mixin_field_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inference_mixin_field_test.Mixin = class Mixin extends core.Object {
    new() {
      this.field = null;
    }
    createIt() {
      if (this.field == null) this.field = 42;
    }
  };
  dart.setSignature(inference_mixin_field_test.Mixin, {
    methods: () => ({createIt: dart.definiteFunctionType(dart.dynamic, [])})
  });
  inference_mixin_field_test.A = class A extends core.Object {
    new(foo) {
    }
  };
  dart.setSignature(inference_mixin_field_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(inference_mixin_field_test.A, [dart.dynamic])})
  });
  inference_mixin_field_test.B = class B extends dart.mixin(inference_mixin_field_test.A, inference_mixin_field_test.Mixin) {
    new(foo) {
      super.new(foo);
    }
  };
  dart.setSignature(inference_mixin_field_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(inference_mixin_field_test.B, [dart.dynamic])})
  });
  inference_mixin_field_test.main = function() {
    let a = new inference_mixin_field_test.B(42);
    a.createIt();
    expect$.Expect.equals(42, a.field);
  };
  dart.fn(inference_mixin_field_test.main, VoidTodynamic());
  // Exports:
  exports.inference_mixin_field_test = inference_mixin_field_test;
});
