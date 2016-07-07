dart_library.library('language/mixin_illegal_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_illegal_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_illegal_constructor_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_illegal_constructor_test_none_multi.M0 = class M0 extends core.Object {
    static new(a, b, c) {
      return null;
    }
    static named() {
      return null;
    }
  };
  dart.setSignature(mixin_illegal_constructor_test_none_multi.M0, {
    constructors: () => ({
      new: dart.definiteFunctionType(mixin_illegal_constructor_test_none_multi.M0, [dart.dynamic, dart.dynamic, dart.dynamic]),
      named: dart.definiteFunctionType(mixin_illegal_constructor_test_none_multi.M0, [])
    })
  });
  mixin_illegal_constructor_test_none_multi.M1 = class M1 extends core.Object {
    new() {
    }
  };
  dart.setSignature(mixin_illegal_constructor_test_none_multi.M1, {
    constructors: () => ({new: dart.definiteFunctionType(mixin_illegal_constructor_test_none_multi.M1, [])})
  });
  mixin_illegal_constructor_test_none_multi.M2 = class M2 extends core.Object {
    named() {
    }
  };
  dart.defineNamedConstructor(mixin_illegal_constructor_test_none_multi.M2, 'named');
  dart.setSignature(mixin_illegal_constructor_test_none_multi.M2, {
    constructors: () => ({named: dart.definiteFunctionType(mixin_illegal_constructor_test_none_multi.M2, [])})
  });
  mixin_illegal_constructor_test_none_multi.C0 = class C0 extends dart.mixin(core.Object, mixin_illegal_constructor_test_none_multi.M0) {};
  mixin_illegal_constructor_test_none_multi.D0 = class D0 extends dart.mixin(core.Object, mixin_illegal_constructor_test_none_multi.M0) {
    new() {
      super.new();
    }
  };
  mixin_illegal_constructor_test_none_multi.main = function() {
    new mixin_illegal_constructor_test_none_multi.C0();
    new mixin_illegal_constructor_test_none_multi.D0();
  };
  dart.fn(mixin_illegal_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_illegal_constructor_test_none_multi = mixin_illegal_constructor_test_none_multi;
});
