dart_library.library('language/mixin_only_for_rti_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_only_for_rti_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_only_for_rti_test = Object.create(null);
  let Tester = () => (Tester = dart.constFn(mixin_only_for_rti_test.Tester$()))();
  let TesterOfA = () => (TesterOfA = dart.constFn(mixin_only_for_rti_test.Tester$(mixin_only_for_rti_test.A)))();
  let TesterOfX = () => (TesterOfX = dart.constFn(mixin_only_for_rti_test.Tester$(mixin_only_for_rti_test.X)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_only_for_rti_test.Tester$ = dart.generic(T => {
    class Tester extends core.Object {
      testGenericType(x) {
        return T.is(x);
      }
    }
    dart.addTypeTests(Tester);
    dart.setSignature(Tester, {
      methods: () => ({testGenericType: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return Tester;
  });
  mixin_only_for_rti_test.Tester = Tester();
  mixin_only_for_rti_test.B = class B extends core.Object {};
  mixin_only_for_rti_test.C = class C extends core.Object {};
  mixin_only_for_rti_test.A = class A extends dart.mixin(mixin_only_for_rti_test.B, mixin_only_for_rti_test.C) {
    new() {
      super.new();
    }
  };
  mixin_only_for_rti_test.Y = class Y extends core.Object {};
  mixin_only_for_rti_test.Z = class Z extends core.Object {};
  mixin_only_for_rti_test.X = class X extends dart.mixin(mixin_only_for_rti_test.Y, mixin_only_for_rti_test.Z) {};
  mixin_only_for_rti_test.main = function() {
    expect$.Expect.isFalse(new (TesterOfA())().testGenericType(new core.Object()));
    expect$.Expect.isFalse(new (TesterOfX())().testGenericType(new core.Object()));
  };
  dart.fn(mixin_only_for_rti_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_only_for_rti_test = mixin_only_for_rti_test;
});
