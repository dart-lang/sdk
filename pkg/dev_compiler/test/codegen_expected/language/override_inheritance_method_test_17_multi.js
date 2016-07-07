dart_library.library('language/override_inheritance_method_test_17_multi', null, /* Imports */[
  'dart_sdk'
], function load__override_inheritance_method_test_17_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const override_inheritance_method_test_17_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_inheritance_method_test_17_multi.A = class A extends core.Object {
    method17(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
      let c = opts && 'c' in opts ? opts.c : null;
      return null;
    }
  };
  dart.setSignature(override_inheritance_method_test_17_multi.A, {
    methods: () => ({method17: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic, c: dart.dynamic})})
  });
  override_inheritance_method_test_17_multi.B = class B extends override_inheritance_method_test_17_multi.A {};
  override_inheritance_method_test_17_multi.I = class I extends core.Object {};
  override_inheritance_method_test_17_multi.J = class J extends core.Object {};
  override_inheritance_method_test_17_multi.Class = class Class extends override_inheritance_method_test_17_multi.B {
    method17(opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      let c = opts && 'c' in opts ? opts.c : null;
      let a = opts && 'a' in opts ? opts.a : null;
      let d = opts && 'd' in opts ? opts.d : null;
      return null;
    }
  };
  override_inheritance_method_test_17_multi.Class[dart.implements] = () => [override_inheritance_method_test_17_multi.I, override_inheritance_method_test_17_multi.J];
  dart.setSignature(override_inheritance_method_test_17_multi.Class, {
    methods: () => ({method17: dart.definiteFunctionType(dart.dynamic, [], {b: dart.dynamic, c: dart.dynamic, a: dart.dynamic, d: dart.dynamic})})
  });
  override_inheritance_method_test_17_multi.SubClass = class SubClass extends override_inheritance_method_test_17_multi.Class {};
  override_inheritance_method_test_17_multi.main = function() {
    new override_inheritance_method_test_17_multi.SubClass();
  };
  dart.fn(override_inheritance_method_test_17_multi.main, VoidTodynamic());
  // Exports:
  exports.override_inheritance_method_test_17_multi = override_inheritance_method_test_17_multi;
});
