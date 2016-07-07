dart_library.library('language/disassemble_test', null, /* Imports */[
  'dart_sdk'
], function load__disassemble_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const disassemble_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  disassemble_test.f = function(x) {
    return "foo";
  };
  dart.fn(disassemble_test.f, dynamicTodynamic());
  disassemble_test.main = function() {
    core.print(disassemble_test.f(0));
  };
  dart.fn(disassemble_test.main, VoidTodynamic());
  // Exports:
  exports.disassemble_test = disassemble_test;
});
