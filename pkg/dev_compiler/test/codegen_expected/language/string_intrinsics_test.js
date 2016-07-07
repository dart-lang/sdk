dart_library.library('language/string_intrinsics_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_intrinsics_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_intrinsics_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  string_intrinsics_test.main = function() {
    let oneByte = "Hello world";
    let empty = "";
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(11, string_intrinsics_test.testLength(oneByte));
      expect$.Expect.equals(0, string_intrinsics_test.testLength(empty));
      expect$.Expect.isFalse(string_intrinsics_test.testIsEmpty(oneByte));
      expect$.Expect.isTrue(string_intrinsics_test.testIsEmpty(empty));
    }
  };
  dart.fn(string_intrinsics_test.main, VoidTodynamic());
  string_intrinsics_test.testLength = function(s) {
    return dart.dload(s, 'length');
  };
  dart.fn(string_intrinsics_test.testLength, dynamicTodynamic());
  string_intrinsics_test.testIsEmpty = function(s) {
    return dart.dload(s, 'isEmpty');
  };
  dart.fn(string_intrinsics_test.testIsEmpty, dynamicTodynamic());
  // Exports:
  exports.string_intrinsics_test = string_intrinsics_test;
});
