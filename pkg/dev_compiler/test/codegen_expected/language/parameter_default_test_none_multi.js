dart_library.library('language/parameter_default_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__parameter_default_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const parameter_default_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  parameter_default_test_none_multi.C = class C extends core.Object {
    foo(a) {
      core.print(a);
    }
    static bar(a) {
      core.print(a);
    }
  };
  dart.setSignature(parameter_default_test_none_multi.C, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])}),
    statics: () => ({bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])}),
    names: ['bar']
  });
  parameter_default_test_none_multi.baz = function(a) {
    core.print(a);
  };
  dart.fn(parameter_default_test_none_multi.baz, dynamicTodynamic());
  parameter_default_test_none_multi.main = function() {
    function foo(a) {
      core.print(a);
    }
    dart.fn(foo, dynamicTodynamic());
    foo(1);
    new parameter_default_test_none_multi.C().foo(2);
    parameter_default_test_none_multi.C.bar(3);
    parameter_default_test_none_multi.baz(4);
  };
  dart.fn(parameter_default_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.parameter_default_test_none_multi = parameter_default_test_none_multi;
});
