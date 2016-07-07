dart_library.library('language/fast_method_extraction_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__fast_method_extraction_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const fast_method_extraction_test = Object.create(null);
  let C = () => (C = dart.constFn(fast_method_extraction_test.C$()))();
  let COfX = () => (COfX = dart.constFn(fast_method_extraction_test.C$(fast_method_extraction_test.X)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  fast_method_extraction_test.A = class A extends core.Object {
    new(f) {
      this.f = f;
    }
    foo() {
      return 40 + dart.notNull(core.num._check(this.f));
    }
  };
  dart.setSignature(fast_method_extraction_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(fast_method_extraction_test.A, [dart.dynamic])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  fast_method_extraction_test.B = class B extends core.Object {
    new(f) {
      this.f = f;
    }
    foo() {
      return -40 - dart.notNull(core.num._check(this.f));
    }
  };
  dart.setSignature(fast_method_extraction_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(fast_method_extraction_test.B, [dart.dynamic])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  fast_method_extraction_test.X = class X extends core.Object {};
  fast_method_extraction_test.C$ = dart.generic(T => {
    class C extends core.Object {
      foo(v) {
        return T.is(v);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return C;
  });
  fast_method_extraction_test.C = C();
  fast_method_extraction_test.ChaA = class ChaA extends core.Object {
    new(magic) {
      this.magic = magic;
    }
    foo() {
      expect$.Expect.isTrue(fast_method_extraction_test.ChaA.is(this));
      expect$.Expect.equals("magicA", this.magic);
      return "A";
    }
    bar() {
      return dart.bind(this, 'foo');
    }
  };
  dart.setSignature(fast_method_extraction_test.ChaA, {
    constructors: () => ({new: dart.definiteFunctionType(fast_method_extraction_test.ChaA, [dart.dynamic])}),
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  fast_method_extraction_test.ChaB = class ChaB extends fast_method_extraction_test.ChaA {
    new(magic) {
      super.new(magic);
    }
    foo() {
      expect$.Expect.isTrue(fast_method_extraction_test.ChaB.is(this));
      expect$.Expect.equals("magicB", this.magic);
      return "B";
    }
  };
  dart.setSignature(fast_method_extraction_test.ChaB, {
    constructors: () => ({new: dart.definiteFunctionType(fast_method_extraction_test.ChaB, [dart.dynamic])})
  });
  fast_method_extraction_test.mono = function(a) {
    let f = dart.dload(a, 'foo');
    return dart.dcall(f);
  };
  dart.fn(fast_method_extraction_test.mono, dynamicTodynamic());
  fast_method_extraction_test.poly = function(a) {
    let f = dart.dload(a, 'foo');
    return dart.dcall(f);
  };
  dart.fn(fast_method_extraction_test.poly, dynamicTodynamic());
  fast_method_extraction_test.types = function(a, b) {
    let f = dart.dload(a, 'foo');
    expect$.Expect.isTrue(dart.dcall(f, b));
  };
  dart.fn(fast_method_extraction_test.types, dynamicAnddynamicTodynamic());
  fast_method_extraction_test.cha = function(a) {
    let f = dart.dsend(a, 'bar');
    return dart.dcall(f);
  };
  dart.fn(fast_method_extraction_test.cha, dynamicTodynamic());
  fast_method_extraction_test.extractFromNull = function() {
    let f = dart.toString(null);
    expect$.Expect.equals("null", dart.dcall(f));
  };
  dart.fn(fast_method_extraction_test.extractFromNull, VoidTodynamic());
  fast_method_extraction_test.main = function() {
    let a = new fast_method_extraction_test.A(2);
    let b = new fast_method_extraction_test.B(2);
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(42, fast_method_extraction_test.mono(a));
    }
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(42, fast_method_extraction_test.poly(a));
      expect$.Expect.equals(-42, fast_method_extraction_test.poly(b));
    }
    let c = new (COfX())();
    let x = new fast_method_extraction_test.X();
    for (let i = 0; i < 20; i++) {
      fast_method_extraction_test.types(c, x);
    }
    let chaA = new fast_method_extraction_test.ChaA("magicA");
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals("A", fast_method_extraction_test.cha(chaA));
    }
    let chaB = new fast_method_extraction_test.ChaB("magicB");
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals("B", fast_method_extraction_test.cha(chaB));
    }
    for (let i = 0; i < 20; i++) {
      fast_method_extraction_test.extractFromNull();
    }
  };
  dart.fn(fast_method_extraction_test.main, VoidTodynamic());
  // Exports:
  exports.fast_method_extraction_test = fast_method_extraction_test;
});
