dart_library.library('language/regress_19413_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__regress_19413_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_19413_test_none_multi = Object.create(null);
  const regress_19413_foo = Object.create(null);
  const regress_19413_bar = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_19413_test_none_multi.main = function() {
  };
  dart.fn(regress_19413_test_none_multi.main, VoidTodynamic());
  regress_19413_foo.f = function() {
    core.print('foo.f()');
  };
  dart.fn(regress_19413_foo.f, VoidTodynamic());
  regress_19413_bar.f = function() {
    core.print('bar.f()');
  };
  dart.fn(regress_19413_bar.f, VoidTodynamic());
  // Exports:
  exports.regress_19413_test_none_multi = regress_19413_test_none_multi;
  exports.regress_19413_foo = regress_19413_foo;
  exports.regress_19413_bar = regress_19413_bar;
});
