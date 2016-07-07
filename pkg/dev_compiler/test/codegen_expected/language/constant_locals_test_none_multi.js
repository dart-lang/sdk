dart_library.library('language/constant_locals_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constant_locals_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constant_locals_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  constant_locals_test_none_multi.main = function() {
    let c2 = 0;
    let c5 = constant_locals_test_none_multi.constField;
    let c8 = const$ || (const$ = dart.const(new constant_locals_test_none_multi.Class()));
  };
  dart.fn(constant_locals_test_none_multi.main, VoidTovoid());
  constant_locals_test_none_multi.field = 0;
  constant_locals_test_none_multi.finalField = 0;
  constant_locals_test_none_multi.constField = 0;
  constant_locals_test_none_multi.method = function() {
    return 0;
  };
  dart.fn(constant_locals_test_none_multi.method, VoidTodynamic());
  constant_locals_test_none_multi.Class = class Class extends core.Object {
    new() {
    }
  };
  dart.setSignature(constant_locals_test_none_multi.Class, {
    constructors: () => ({new: dart.definiteFunctionType(constant_locals_test_none_multi.Class, [])})
  });
  // Exports:
  exports.constant_locals_test_none_multi = constant_locals_test_none_multi;
});
