dart_library.library('language/duplicate_interface_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__duplicate_interface_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const duplicate_interface_test = Object.create(null);
  const duplicate_interface_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  duplicate_interface_test.InterfB = class InterfB extends core.Object {};
  duplicate_interface_test.Foo = class Foo extends core.Object {};
  duplicate_interface_test.Foo[dart.implements] = () => [duplicate_interface_test.InterfB, duplicate_interface_lib.InterfB];
  duplicate_interface_test.main = function() {
    expect$.Expect.isTrue(duplicate_interface_test.InterfB.is(new duplicate_interface_test.Foo()));
    expect$.Expect.isTrue(duplicate_interface_lib.InterfB.is(new duplicate_interface_test.Foo()));
  };
  dart.fn(duplicate_interface_test.main, VoidTodynamic());
  duplicate_interface_lib.InterfA = class InterfA extends core.Object {};
  duplicate_interface_lib.InterfB = class InterfB extends core.Object {};
  // Exports:
  exports.duplicate_interface_test = duplicate_interface_test;
  exports.duplicate_interface_lib = duplicate_interface_lib;
});
