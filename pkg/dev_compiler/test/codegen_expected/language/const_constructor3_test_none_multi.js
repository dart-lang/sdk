dart_library.library('language/const_constructor3_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_constructor3_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_constructor3_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_constructor3_test_none_multi.C = class C extends core.Object {
    new(d) {
      this.d = d;
    }
  };
  dart.setSignature(const_constructor3_test_none_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor3_test_none_multi.C, [core.double])})
  });
  const_constructor3_test_none_multi.D = class D extends const_constructor3_test_none_multi.C {
    new(d) {
      super.new(core.double._check(d));
    }
  };
  dart.setSignature(const_constructor3_test_none_multi.D, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor3_test_none_multi.D, [dart.dynamic])})
  });
  const_constructor3_test_none_multi.main = function() {
  };
  dart.fn(const_constructor3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.const_constructor3_test_none_multi = const_constructor3_test_none_multi;
});
