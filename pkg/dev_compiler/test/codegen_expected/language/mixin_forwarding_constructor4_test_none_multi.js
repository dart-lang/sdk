dart_library.library('language/mixin_forwarding_constructor4_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_forwarding_constructor4_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_forwarding_constructor4_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_forwarding_constructor4_test_none_multi.Mixin = class Mixin extends core.Object {};
  mixin_forwarding_constructor4_test_none_multi.Base = class Base extends core.Object {
    new() {
    }
  };
  dart.setSignature(mixin_forwarding_constructor4_test_none_multi.Base, {
    constructors: () => ({new: dart.definiteFunctionType(mixin_forwarding_constructor4_test_none_multi.Base, [])})
  });
  mixin_forwarding_constructor4_test_none_multi.C = class C extends dart.mixin(mixin_forwarding_constructor4_test_none_multi.Base, mixin_forwarding_constructor4_test_none_multi.Mixin) {
    new() {
      super.new();
    }
  };
  mixin_forwarding_constructor4_test_none_multi.main = function() {
    new mixin_forwarding_constructor4_test_none_multi.C();
  };
  dart.fn(mixin_forwarding_constructor4_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_forwarding_constructor4_test_none_multi = mixin_forwarding_constructor4_test_none_multi;
});
