dart_library.library('language/dynamic_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__dynamic_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const dynamic_test = Object.create(null);
  let Iface = () => (Iface = dart.constFn(dynamic_test.Iface$()))();
  let M1 = () => (M1 = dart.constFn(dynamic_test.M1$()))();
  let M2 = () => (M2 = dart.constFn(dynamic_test.M2$()))();
  let IfaceOfString$dynamic = () => (IfaceOfString$dynamic = dart.constFn(dynamic_test.Iface$(core.String, dart.dynamic)))();
  let F1 = () => (F1 = dart.constFn(dynamic_test.F1$()))();
  let IfaceOfdynamic$num = () => (IfaceOfdynamic$num = dart.constFn(dynamic_test.Iface$(dart.dynamic, core.num)))();
  let IfaceOfString$num = () => (IfaceOfString$num = dart.constFn(dynamic_test.Iface$(core.String, core.num)))();
  let IfaceOfnum$String = () => (IfaceOfnum$String = dart.constFn(dynamic_test.Iface$(core.num, core.String)))();
  let F1Ofint = () => (F1Ofint = dart.constFn(dynamic_test.F1$(core.int)))();
  let StringAndintToString = () => (StringAndintToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dynamic_test.Iface$ = dart.generic((K, V) => {
    class Iface extends core.Object {}
    dart.addTypeTests(Iface);
    return Iface;
  });
  dynamic_test.Iface = Iface();
  dynamic_test.M1$ = dart.generic((K, V) => {
    let IfaceOfK$V = () => (IfaceOfK$V = dart.constFn(dynamic_test.Iface$(K, V)))();
    class M1 extends core.Object {}
    dart.addTypeTests(M1);
    M1[dart.implements] = () => [IfaceOfK$V()];
    return M1;
  });
  dynamic_test.M1 = M1();
  dynamic_test.M2$ = dart.generic(K => {
    let IfaceOfK$dynamic = () => (IfaceOfK$dynamic = dart.constFn(dynamic_test.Iface$(K, dart.dynamic)))();
    class M2 extends core.Object {}
    dart.addTypeTests(M2);
    M2[dart.implements] = () => [IfaceOfK$dynamic()];
    return M2;
  });
  dynamic_test.M2 = M2();
  dynamic_test.M3 = class M3 extends core.Object {};
  dynamic_test.M3[dart.implements] = () => [IfaceOfString$dynamic()];
  dynamic_test.F1$ = dart.generic(T => {
    const F1 = dart.typedef('F1', () => dart.functionType(dart.dynamic, [dart.dynamic, T]));
    return F1;
  });
  dynamic_test.F1 = F1();
  dynamic_test.HasFieldDynamic = class HasFieldDynamic extends core.Object {
    new() {
      this.dynamic = "dynamic";
    }
  };
  dart.setSignature(dynamic_test.HasFieldDynamic, {
    constructors: () => ({new: dart.definiteFunctionType(dynamic_test.HasFieldDynamic, [])})
  });
  dynamic_test.HasMethodDynamic = class HasMethodDynamic extends core.Object {
    dynamic() {
      return "dynamic";
    }
  };
  dart.setSignature(dynamic_test.HasMethodDynamic, {
    methods: () => ({dynamic: dart.definiteFunctionType(dart.dynamic, [])})
  });
  dynamic_test.main = function() {
    expect$.Expect.isTrue(core.Type.is(dart.wrapType(dart.dynamic)));
    expect$.Expect.equals(dart.wrapType(dart.dynamic), dart.wrapType(dart.dynamic));
    let m1 = new dynamic_test.M1();
    expect$.Expect.isTrue(IfaceOfdynamic$num().is(m1));
    expect$.Expect.isTrue(IfaceOfString$dynamic().is(m1));
    expect$.Expect.isTrue(IfaceOfString$num().is(m1));
    expect$.Expect.isTrue(IfaceOfnum$String().is(m1));
    let m2 = new dynamic_test.M2();
    expect$.Expect.isTrue(IfaceOfdynamic$num().is(m2));
    expect$.Expect.isTrue(IfaceOfString$dynamic().is(m2));
    expect$.Expect.isTrue(IfaceOfString$num().is(m2));
    expect$.Expect.isTrue(IfaceOfnum$String().is(m2));
    let m3 = new dynamic_test.M3();
    expect$.Expect.isTrue(IfaceOfdynamic$num().is(m3));
    expect$.Expect.isTrue(IfaceOfString$dynamic().is(m3));
    expect$.Expect.isTrue(IfaceOfString$num().is(m3));
    expect$.Expect.isTrue(!IfaceOfnum$String().is(m3));
    let f1 = dart.fn((s, i) => s[dartx.get](i), StringAndintToString());
    expect$.Expect.isTrue(F1Ofint().is(f1));
    let has_field = new dynamic_test.HasFieldDynamic();
    expect$.Expect.equals("dynamic", has_field.dynamic);
    let has_method = new dynamic_test.HasMethodDynamic();
    expect$.Expect.equals("dynamic", has_method.dynamic());
    {
      let dynamic = 0;
      expect$.Expect.equals(0, dynamic);
    }
  };
  dart.fn(dynamic_test.main, VoidTodynamic());
  // Exports:
  exports.dynamic_test = dynamic_test;
});
