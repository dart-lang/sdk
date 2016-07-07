dart_library.library('language/scanner_test', null, /* Imports */[
  'dart_sdk'
], function load__scanner_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const scanner_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  scanner_test.ScannerTest = class ScannerTest extends core.Object {
    static testMain() {
      let s = "Hello\tmy\tfriend\n";
      return s;
    }
  };
  dart.setSignature(scanner_test.ScannerTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  scanner_test.main = function() {
    scanner_test.ScannerTest.testMain();
  };
  dart.fn(scanner_test.main, VoidTodynamic());
  // Exports:
  exports.scanner_test = scanner_test;
});
