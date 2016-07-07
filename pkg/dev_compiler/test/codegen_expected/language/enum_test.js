dart_library.library('language/enum_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__enum_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const enum_test = Object.create(null);
  let JSArrayOfEnum1 = () => (JSArrayOfEnum1 = dart.constFn(_interceptors.JSArray$(enum_test.Enum1)))();
  let JSArrayOfEnum2 = () => (JSArrayOfEnum2 = dart.constFn(_interceptors.JSArray$(enum_test.Enum2)))();
  let JSArrayOfEnum3 = () => (JSArrayOfEnum3 = dart.constFn(_interceptors.JSArray$(enum_test.Enum3)))();
  let JSArrayOfEnum4 = () => (JSArrayOfEnum4 = dart.constFn(_interceptors.JSArray$(enum_test.Enum4)))();
  let JSArrayOfEnum5 = () => (JSArrayOfEnum5 = dart.constFn(_interceptors.JSArray$(enum_test.Enum5)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let Enum1Todynamic = () => (Enum1Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [enum_test.Enum1])))();
  let Enum2Todynamic = () => (Enum2Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [enum_test.Enum2])))();
  let Enum3Todynamic = () => (Enum3Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [enum_test.Enum3])))();
  let Enum4Todynamic = () => (Enum4Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [enum_test.Enum4])))();
  let Enum5Todynamic = () => (Enum5Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [enum_test.Enum5])))();
  enum_test.Enum1 = class Enum1 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum1._"
      }[this.index];
    }
  };
  enum_test.Enum1._ = dart.const(new enum_test.Enum1(0));
  enum_test.Enum1.values = dart.constList([enum_test.Enum1._], enum_test.Enum1);
  enum_test.Enum2 = class Enum2 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum2.A"
      }[this.index];
    }
  };
  enum_test.Enum2.A = dart.const(new enum_test.Enum2(0));
  enum_test.Enum2.values = dart.constList([enum_test.Enum2.A], enum_test.Enum2);
  enum_test.Enum3 = class Enum3 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum3.B",
        1: "Enum3.C"
      }[this.index];
    }
  };
  enum_test.Enum3.B = dart.const(new enum_test.Enum3(0));
  enum_test.Enum3.C = dart.const(new enum_test.Enum3(1));
  enum_test.Enum3.values = dart.constList([enum_test.Enum3.B, enum_test.Enum3.C], enum_test.Enum3);
  enum_test.Enum4 = class Enum4 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum4.D",
        1: "Enum4.E"
      }[this.index];
    }
  };
  enum_test.Enum4.D = dart.const(new enum_test.Enum4(0));
  enum_test.Enum4.E = dart.const(new enum_test.Enum4(1));
  enum_test.Enum4.values = dart.constList([enum_test.Enum4.D, enum_test.Enum4.E], enum_test.Enum4);
  enum_test.Enum5 = class Enum5 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum5.F",
        1: "Enum5.G",
        2: "Enum5.H"
      }[this.index];
    }
  };
  enum_test.Enum5.F = dart.const(new enum_test.Enum5(0));
  enum_test.Enum5.G = dart.const(new enum_test.Enum5(1));
  enum_test.Enum5.H = dart.const(new enum_test.Enum5(2));
  enum_test.Enum5.values = dart.constList([enum_test.Enum5.F, enum_test.Enum5.G, enum_test.Enum5.H], enum_test.Enum5);
  enum_test.main = function() {
    expect$.Expect.equals('Enum1._', enum_test.Enum1._.toString());
    expect$.Expect.equals(0, enum_test.Enum1._.index);
    expect$.Expect.listEquals(JSArrayOfEnum1().of([enum_test.Enum1._]), enum_test.Enum1.values);
    enum_test.Enum1.values[dartx.forEach](enum_test.test1);
    expect$.Expect.equals('Enum2.A', enum_test.Enum2.A.toString());
    expect$.Expect.equals(0, enum_test.Enum2.A.index);
    expect$.Expect.listEquals(JSArrayOfEnum2().of([enum_test.Enum2.A]), enum_test.Enum2.values);
    enum_test.Enum2.values[dartx.forEach](enum_test.test2);
    expect$.Expect.equals('Enum3.B', enum_test.Enum3.B.toString());
    expect$.Expect.equals('Enum3.C', enum_test.Enum3.C.toString());
    expect$.Expect.equals(0, enum_test.Enum3.B.index);
    expect$.Expect.equals(1, enum_test.Enum3.C.index);
    expect$.Expect.listEquals(JSArrayOfEnum3().of([enum_test.Enum3.B, enum_test.Enum3.C]), enum_test.Enum3.values);
    enum_test.Enum3.values[dartx.forEach](enum_test.test3);
    expect$.Expect.equals('Enum4.D', enum_test.Enum4.D.toString());
    expect$.Expect.equals('Enum4.E', enum_test.Enum4.E.toString());
    expect$.Expect.equals(0, enum_test.Enum4.D.index);
    expect$.Expect.equals(1, enum_test.Enum4.E.index);
    expect$.Expect.listEquals(JSArrayOfEnum4().of([enum_test.Enum4.D, enum_test.Enum4.E]), enum_test.Enum4.values);
    enum_test.Enum4.values[dartx.forEach](enum_test.test4);
    expect$.Expect.equals('Enum5.F', enum_test.Enum5.F.toString());
    expect$.Expect.equals('Enum5.G', enum_test.Enum5.G.toString());
    expect$.Expect.equals('Enum5.H', enum_test.Enum5.H.toString());
    expect$.Expect.equals(0, enum_test.Enum5.F.index);
    expect$.Expect.equals(1, enum_test.Enum5.G.index);
    expect$.Expect.equals(2, enum_test.Enum5.H.index);
    expect$.Expect.listEquals(JSArrayOfEnum5().of([enum_test.Enum5.F, enum_test.Enum5.G, enum_test.Enum5.H]), enum_test.Enum5.values);
    enum_test.Enum5.values[dartx.forEach](enum_test.test5);
  };
  dart.fn(enum_test.main, VoidTodynamic());
  enum_test.test1 = function(e) {
    let index = null;
    switch (e) {
      case enum_test.Enum1._:
      {
        index = 0;
        break;
      }
    }
    expect$.Expect.equals(e.index, index);
  };
  dart.fn(enum_test.test1, Enum1Todynamic());
  enum_test.test2 = function(e) {
    let index = null;
    switch (e) {
      case enum_test.Enum2.A:
      {
        index = 0;
        break;
      }
    }
    expect$.Expect.equals(e.index, index);
  };
  dart.fn(enum_test.test2, Enum2Todynamic());
  enum_test.test3 = function(e) {
    let index = null;
    switch (e) {
      case enum_test.Enum3.C:
      {
        index = 1;
        break;
      }
      case enum_test.Enum3.B:
      {
        index = 0;
        break;
      }
    }
    expect$.Expect.equals(e.index, index);
  };
  dart.fn(enum_test.test3, Enum3Todynamic());
  enum_test.test4 = function(e) {
    let index = null;
    switch (e) {
      case enum_test.Enum4.D:
      {
        index = 0;
        break;
      }
      case enum_test.Enum4.E:
      {
        index = 1;
        break;
      }
    }
    expect$.Expect.equals(e.index, index);
  };
  dart.fn(enum_test.test4, Enum4Todynamic());
  enum_test.test5 = function(e) {
    let index = null;
    switch (e) {
      case enum_test.Enum5.H:
      {
        index = 2;
        break;
      }
      case enum_test.Enum5.F:
      {
        index = 0;
        break;
      }
      case enum_test.Enum5.G:
      {
        index = 1;
        break;
      }
    }
    expect$.Expect.equals(e.index, index);
  };
  dart.fn(enum_test.test5, Enum5Todynamic());
  // Exports:
  exports.enum_test = enum_test;
});
