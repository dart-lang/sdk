dart_library.library('language/regress_13462_1_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_13462_1_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_13462_1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  regress_13462_1_test.main = function() {
    let name = mirrors.MirrorSystem.getName(const$ || (const$ = dart.const(core.Symbol.new('foo'))));
    if (name != 'foo') dart.throw(dart.str`Wrong name: ${name} != foo`);
  };
  dart.fn(regress_13462_1_test.main, VoidTodynamic());
  // Exports:
  exports.regress_13462_1_test = regress_13462_1_test;
});
