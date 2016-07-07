dart_library.library('corelib/bool_hashcode_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bool_hashcode_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bool_hashcode_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bool_hashcode_test.BoolHashCodeTest = class BoolHashCodeTest extends core.Object {
    static testMain() {
      expect$.Expect.notEquals(dart.hashCode(true), dart.hashCode(false));
    }
  };
  dart.setSignature(bool_hashcode_test.BoolHashCodeTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  bool_hashcode_test.main = function() {
    bool_hashcode_test.BoolHashCodeTest.testMain();
  };
  dart.fn(bool_hashcode_test.main, VoidTodynamic());
  // Exports:
  exports.bool_hashcode_test = bool_hashcode_test;
});
