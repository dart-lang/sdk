dart_library.library('language/mixin_type_parameter1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_type_parameter1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_type_parameter1_test = Object.create(null);
  let Mixin1 = () => (Mixin1 = dart.constFn(mixin_type_parameter1_test.Mixin1$()))();
  let Mixin2 = () => (Mixin2 = dart.constFn(mixin_type_parameter1_test.Mixin2$()))();
  let MyTypedef = () => (MyTypedef = dart.constFn(mixin_type_parameter1_test.MyTypedef$()))();
  let B = () => (B = dart.constFn(mixin_type_parameter1_test.B$()))();
  let BOfnum$String = () => (BOfnum$String = dart.constFn(mixin_type_parameter1_test.B$(core.num, core.String)))();
  let Mixin1Ofnum = () => (Mixin1Ofnum = dart.constFn(mixin_type_parameter1_test.Mixin1$(core.num)))();
  let Mixin1OfString = () => (Mixin1OfString = dart.constFn(mixin_type_parameter1_test.Mixin1$(core.String)))();
  let Mixin2OfString = () => (Mixin2OfString = dart.constFn(mixin_type_parameter1_test.Mixin2$(core.String)))();
  let Mixin2Ofnum = () => (Mixin2Ofnum = dart.constFn(mixin_type_parameter1_test.Mixin2$(core.num)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_type_parameter1_test.Mixin1$ = dart.generic(T => {
    class Mixin1 extends core.Object {}
    dart.addTypeTests(Mixin1);
    return Mixin1;
  });
  mixin_type_parameter1_test.Mixin1 = Mixin1();
  mixin_type_parameter1_test.Mixin2$ = dart.generic(T => {
    class Mixin2 extends core.Object {}
    dart.addTypeTests(Mixin2);
    return Mixin2;
  });
  mixin_type_parameter1_test.Mixin2 = Mixin2();
  mixin_type_parameter1_test.A = class A extends core.Object {};
  mixin_type_parameter1_test.MyTypedef$ = dart.generic((K, V) => {
    class MyTypedef extends dart.mixin(mixin_type_parameter1_test.A, mixin_type_parameter1_test.Mixin1$(K), mixin_type_parameter1_test.Mixin2$(V)) {
      new() {
        super.new();
      }
    }
    return MyTypedef;
  });
  mixin_type_parameter1_test.MyTypedef = MyTypedef();
  mixin_type_parameter1_test.B$ = dart.generic((K, V) => {
    class B extends mixin_type_parameter1_test.MyTypedef$(K, V) {}
    return B;
  });
  mixin_type_parameter1_test.B = B();
  mixin_type_parameter1_test.main = function() {
    let b = new (BOfnum$String())();
    expect$.Expect.isTrue(Mixin1Ofnum().is(b));
    expect$.Expect.isTrue(!Mixin1OfString().is(b));
    expect$.Expect.isTrue(Mixin2OfString().is(b));
    expect$.Expect.isTrue(!Mixin2Ofnum().is(b));
  };
  dart.fn(mixin_type_parameter1_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_type_parameter1_test = mixin_type_parameter1_test;
});
