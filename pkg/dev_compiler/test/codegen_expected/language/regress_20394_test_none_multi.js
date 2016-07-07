dart_library.library('language/regress_20394_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__regress_20394_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_20394_test_none_multi = Object.create(null);
  const regress_20394_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_20394_test_none_multi.M = class M extends core.Object {};
  regress_20394_lib.Super = class Super extends core.Object {
    new() {
    }
    _private(arg) {
    }
  };
  dart.defineNamedConstructor(regress_20394_lib.Super, '_private');
  dart.setSignature(regress_20394_lib.Super, {
    constructors: () => ({
      new: dart.definiteFunctionType(regress_20394_lib.Super, []),
      _private: dart.definiteFunctionType(regress_20394_lib.Super, [dart.dynamic])
    })
  });
  regress_20394_test_none_multi.C = class C extends dart.mixin(regress_20394_lib.Super, regress_20394_test_none_multi.M) {
    new() {
      super.new();
    }
  };
  regress_20394_test_none_multi.main = function() {
    new regress_20394_test_none_multi.C();
  };
  dart.fn(regress_20394_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.regress_20394_test_none_multi = regress_20394_test_none_multi;
  exports.regress_20394_lib = regress_20394_lib;
});
