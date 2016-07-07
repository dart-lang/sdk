dart_library.library('language/interface_constants_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__interface_constants_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const interface_constants_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  interface_constants_test.Constants = class Constants extends core.Object {};
  interface_constants_test.Constants.FIVE = 5;
  interface_constants_test.InterfaceConstantsTest = class InterfaceConstantsTest extends core.Object {
    new() {
    }
    static testMain() {
      expect$.Expect.equals(5, interface_constants_test.Constants.FIVE);
    }
  };
  dart.setSignature(interface_constants_test.InterfaceConstantsTest, {
    constructors: () => ({new: dart.definiteFunctionType(interface_constants_test.InterfaceConstantsTest, [])}),
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  interface_constants_test.main = function() {
    interface_constants_test.InterfaceConstantsTest.testMain();
  };
  dart.fn(interface_constants_test.main, VoidTodynamic());
  // Exports:
  exports.interface_constants_test = interface_constants_test;
});
