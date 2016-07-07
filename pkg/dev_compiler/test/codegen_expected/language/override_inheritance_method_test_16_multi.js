dart_library.library('language/override_inheritance_method_test_16_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_method_test_16_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_method_test_16_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_method_test_16_multi.A = class A extends core.Object {
    method16(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
      return null;
    }
  };
  dart.setSignature(override_inheritance_method_test_16_multi.A, {
    methods: () => ({method16: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic})})
  });
  override_inheritance_method_test_16_multi.B = class B extends override_inheritance_method_test_16_multi.A {};
  override_inheritance_method_test_16_multi.I = class I extends core.Object {};
  override_inheritance_method_test_16_multi.J = class J extends core.Object {};
  override_inheritance_method_test_16_multi.Class = class Class extends override_inheritance_method_test_16_multi.B {
    method16(opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      let a = opts && 'a' in opts ? opts.a : null;
      return null;
    }
  };
  override_inheritance_method_test_16_multi.Class[dart.implements] = () => [override_inheritance_method_test_16_multi.I, override_inheritance_method_test_16_multi.J];
  dart.setSignature(override_inheritance_method_test_16_multi.Class, {
    methods: () => ({method16: dart.definiteFunctionType(dart.dynamic, [], {b: dart.dynamic, a: dart.dynamic})})
  });
  override_inheritance_method_test_16_multi.SubClass = class SubClass extends override_inheritance_method_test_16_multi.Class {};
  override_inheritance_method_test_16_multi.main = function() {
    new override_inheritance_method_test_16_multi.SubClass();
  };
  dart.fn(override_inheritance_method_test_16_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_method_test_16_multi = override_inheritance_method_test_16_multi;
});
