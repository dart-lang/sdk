dart_library.library('language/throwing_lazy_variable_test', null, /* Imports */[
  'dart_sdk'
], function load__throwing_lazy_variable_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const throwing_lazy_variable_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(throwing_lazy_variable_test, {
    get a() {
      return throwing_lazy_variable_test.foo();
    },
    set a(_) {}
  });
  throwing_lazy_variable_test.foo = function() {
    dart.fn(() => 42, VoidToint());
    if (true) dart.throw('Sorry');
    return 42;
  };
  dart.fn(throwing_lazy_variable_test.foo, VoidTodynamic());
  throwing_lazy_variable_test.main = function() {
    try {
      throwing_lazy_variable_test.a;
    } catch (e) {
    }

    if (typeof throwing_lazy_variable_test.a == 'number') dart.throw('Test failed');
  };
  dart.fn(throwing_lazy_variable_test.main, VoidTodynamic());
  // Exports:
  exports.throwing_lazy_variable_test = throwing_lazy_variable_test;
});
