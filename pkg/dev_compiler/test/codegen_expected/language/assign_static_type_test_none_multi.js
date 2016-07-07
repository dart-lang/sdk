dart_library.library('language/assign_static_type_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__assign_static_type_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const assign_static_type_test_none_multi = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  assign_static_type_test_none_multi.A = class A extends core.Object {
    new() {
    }
    method(g) {
      if (g === void 0) g = "String";
      return g;
    }
  };
  dart.setSignature(assign_static_type_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(assign_static_type_test_none_multi.A, [])}),
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])})
  });
  assign_static_type_test_none_multi.main = function() {
    let x = null;
    let v = new assign_static_type_test_none_multi.A();
  };
  dart.fn(assign_static_type_test_none_multi.main, VoidToint());
  // Exports:
  exports.assign_static_type_test_none_multi = assign_static_type_test_none_multi;
});
