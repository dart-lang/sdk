dart_library.library('language/inferrer_synthesized_super_constructor_test', null, /* Imports */[
  'dart_sdk'
], function load__inferrer_synthesized_super_constructor_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const inferrer_synthesized_super_constructor_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inferrer_synthesized_super_constructor_test.A = class A extends core.Object {
    new(a) {
      if (a === void 0) a = null;
      dart.fn(() => 42, VoidToint());
      if (a != null) dart.throw('Test failed');
    }
  };
  dart.setSignature(inferrer_synthesized_super_constructor_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_synthesized_super_constructor_test.A, [], [dart.dynamic])})
  });
  inferrer_synthesized_super_constructor_test.B = class B extends inferrer_synthesized_super_constructor_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(inferrer_synthesized_super_constructor_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_synthesized_super_constructor_test.B, [])})
  });
  inferrer_synthesized_super_constructor_test.main = function() {
    new inferrer_synthesized_super_constructor_test.B();
  };
  dart.fn(inferrer_synthesized_super_constructor_test.main, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.inferrer_synthesized_super_constructor_test = inferrer_synthesized_super_constructor_test;
  exports.compiler_annotations = compiler_annotations;
});
