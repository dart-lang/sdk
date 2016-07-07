dart_library.library('language/regress_13462_0_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_13462_0_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_13462_0_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  regress_13462_0_test.main = function() {
    core.print(mirrors.MirrorSystem.getName(const$ || (const$ = dart.const(core.Symbol.new('foo')))));
  };
  dart.fn(regress_13462_0_test.main, VoidTodynamic());
  // Exports:
  exports.regress_13462_0_test = regress_13462_0_test;
});
