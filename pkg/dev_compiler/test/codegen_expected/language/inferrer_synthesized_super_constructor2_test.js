dart_library.library('language/inferrer_synthesized_super_constructor2_test', null, /* Imports */[
  'dart_sdk'
], function load__inferrer_synthesized_super_constructor2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const inferrer_synthesized_super_constructor2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inferrer_synthesized_super_constructor2_test.inConstructor = false;
  inferrer_synthesized_super_constructor2_test.A = class A extends core.Object {
    _() {
      inferrer_synthesized_super_constructor2_test.inConstructor = true;
    }
  };
  dart.defineNamedConstructor(inferrer_synthesized_super_constructor2_test.A, '_');
  dart.setSignature(inferrer_synthesized_super_constructor2_test.A, {
    constructors: () => ({_: dart.definiteFunctionType(inferrer_synthesized_super_constructor2_test.A, [])})
  });
  inferrer_synthesized_super_constructor2_test.B = class B extends inferrer_synthesized_super_constructor2_test.A {
    new() {
      super._();
    }
  };
  dart.setSignature(inferrer_synthesized_super_constructor2_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_synthesized_super_constructor2_test.B, [])})
  });
  inferrer_synthesized_super_constructor2_test.main = function() {
    new inferrer_synthesized_super_constructor2_test.B();
    if (!dart.test(inferrer_synthesized_super_constructor2_test.inConstructor)) dart.throw('Test failed');
  };
  dart.fn(inferrer_synthesized_super_constructor2_test.main, VoidTodynamic());
  // Exports:
  exports.inferrer_synthesized_super_constructor2_test = inferrer_synthesized_super_constructor2_test;
});
