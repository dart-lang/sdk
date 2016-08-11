dart_library.library('language/cyclic_import_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cyclic_import_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cyclic_import_test = Object.create(null);
  const sub__sub = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_import_test.value = 42;
  cyclic_import_test.main = function() {
    sub__sub.subMain();
  };
  dart.fn(cyclic_import_test.main, VoidTodynamic());
  sub__sub.subMain = function() {
    expect$.Expect.equals(42, cyclic_import_test.value);
  };
  dart.fn(sub__sub.subMain, VoidTodynamic());
  // Exports:
  exports.cyclic_import_test = cyclic_import_test;
  exports.sub__sub = sub__sub;
});
