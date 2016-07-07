dart_library.library('language/static_parameter_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__static_parameter_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const static_parameter_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_parameter_test_none_multi.foo = function(x) {
  };
  dart.fn(static_parameter_test_none_multi.foo, dynamicTodynamic());
  static_parameter_test_none_multi.C = class C extends core.Object {
    bar(x) {}
    static baz(x) {}
  };
  dart.setSignature(static_parameter_test_none_multi.C, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])}),
    statics: () => ({baz: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])}),
    names: ['baz']
  });
  static_parameter_test_none_multi.main = function() {
    static_parameter_test_none_multi.foo(1);
    new static_parameter_test_none_multi.C().bar(1);
    static_parameter_test_none_multi.C.baz(1);
  };
  dart.fn(static_parameter_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.static_parameter_test_none_multi = static_parameter_test_none_multi;
});
