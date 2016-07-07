dart_library.library('language/many_calls_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__many_calls_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const many_calls_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  many_calls_test.A = class A extends core.Object {
    new() {
    }
    f1() {
      return 1;
    }
    f2() {
      return 2;
    }
    f3() {
      return 3;
    }
    f4() {
      return 4;
    }
    f5() {
      return 5;
    }
    f6() {
      return 6;
    }
    f7() {
      return 7;
    }
    f8() {
      return 8;
    }
    f9() {
      return 9;
    }
    f11() {
      return 11;
    }
    f12() {
      return 12;
    }
    f13() {
      return 13;
    }
    f14() {
      return 14;
    }
    f15() {
      return 15;
    }
    f16() {
      return 16;
    }
    f17() {
      return 17;
    }
    f18() {
      return 18;
    }
    f19() {
      return 19;
    }
    f20() {
      return 20;
    }
    f21() {
      return 21;
    }
    f22() {
      return 22;
    }
    f23() {
      return 23;
    }
    f24() {
      return 24;
    }
    f25() {
      return 25;
    }
    f26() {
      return 26;
    }
    f27() {
      return 27;
    }
    f28() {
      return 28;
    }
    f29() {
      return 29;
    }
    f30() {
      return 30;
    }
    f31() {
      return 31;
    }
    f32() {
      return 32;
    }
    f33() {
      return 33;
    }
    f34() {
      return 34;
    }
    f35() {
      return 35;
    }
    f36() {
      return 36;
    }
    f37() {
      return 37;
    }
    f38() {
      return 38;
    }
    f39() {
      return 39;
    }
  };
  dart.setSignature(many_calls_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(many_calls_test.A, [])}),
    methods: () => ({
      f1: dart.definiteFunctionType(dart.dynamic, []),
      f2: dart.definiteFunctionType(dart.dynamic, []),
      f3: dart.definiteFunctionType(dart.dynamic, []),
      f4: dart.definiteFunctionType(dart.dynamic, []),
      f5: dart.definiteFunctionType(dart.dynamic, []),
      f6: dart.definiteFunctionType(dart.dynamic, []),
      f7: dart.definiteFunctionType(dart.dynamic, []),
      f8: dart.definiteFunctionType(dart.dynamic, []),
      f9: dart.definiteFunctionType(dart.dynamic, []),
      f11: dart.definiteFunctionType(dart.dynamic, []),
      f12: dart.definiteFunctionType(dart.dynamic, []),
      f13: dart.definiteFunctionType(dart.dynamic, []),
      f14: dart.definiteFunctionType(dart.dynamic, []),
      f15: dart.definiteFunctionType(dart.dynamic, []),
      f16: dart.definiteFunctionType(dart.dynamic, []),
      f17: dart.definiteFunctionType(dart.dynamic, []),
      f18: dart.definiteFunctionType(dart.dynamic, []),
      f19: dart.definiteFunctionType(dart.dynamic, []),
      f20: dart.definiteFunctionType(dart.dynamic, []),
      f21: dart.definiteFunctionType(dart.dynamic, []),
      f22: dart.definiteFunctionType(dart.dynamic, []),
      f23: dart.definiteFunctionType(dart.dynamic, []),
      f24: dart.definiteFunctionType(dart.dynamic, []),
      f25: dart.definiteFunctionType(dart.dynamic, []),
      f26: dart.definiteFunctionType(dart.dynamic, []),
      f27: dart.definiteFunctionType(dart.dynamic, []),
      f28: dart.definiteFunctionType(dart.dynamic, []),
      f29: dart.definiteFunctionType(dart.dynamic, []),
      f30: dart.definiteFunctionType(dart.dynamic, []),
      f31: dart.definiteFunctionType(dart.dynamic, []),
      f32: dart.definiteFunctionType(dart.dynamic, []),
      f33: dart.definiteFunctionType(dart.dynamic, []),
      f34: dart.definiteFunctionType(dart.dynamic, []),
      f35: dart.definiteFunctionType(dart.dynamic, []),
      f36: dart.definiteFunctionType(dart.dynamic, []),
      f37: dart.definiteFunctionType(dart.dynamic, []),
      f38: dart.definiteFunctionType(dart.dynamic, []),
      f39: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  many_calls_test.B = class B extends many_calls_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(many_calls_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(many_calls_test.B, [])})
  });
  many_calls_test.ManyCallsTest = class ManyCallsTest extends core.Object {
    static testMain() {
      let list = core.List.new(10);
      for (let i = 0; i < (dart.notNull(list[dartx.length]) / 2)[dartx.truncate](); i++) {
        list[dartx.set](i, new many_calls_test.A());
      }
      for (let i = (dart.notNull(list[dartx.length]) / 2)[dartx.truncate](); i < dart.notNull(list[dartx.length]); i++) {
        list[dartx.set](i, new many_calls_test.B());
      }
      for (let loop = 0; loop < 7; loop++) {
        for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
          expect$.Expect.equals(1, dart.dsend(list[dartx.get](i), 'f1'));
          expect$.Expect.equals(2, dart.dsend(list[dartx.get](i), 'f2'));
          expect$.Expect.equals(3, dart.dsend(list[dartx.get](i), 'f3'));
          expect$.Expect.equals(4, dart.dsend(list[dartx.get](i), 'f4'));
          expect$.Expect.equals(5, dart.dsend(list[dartx.get](i), 'f5'));
          expect$.Expect.equals(6, dart.dsend(list[dartx.get](i), 'f6'));
          expect$.Expect.equals(7, dart.dsend(list[dartx.get](i), 'f7'));
          expect$.Expect.equals(8, dart.dsend(list[dartx.get](i), 'f8'));
          expect$.Expect.equals(9, dart.dsend(list[dartx.get](i), 'f9'));
          expect$.Expect.equals(11, dart.dsend(list[dartx.get](i), 'f11'));
          expect$.Expect.equals(12, dart.dsend(list[dartx.get](i), 'f12'));
          expect$.Expect.equals(13, dart.dsend(list[dartx.get](i), 'f13'));
          expect$.Expect.equals(14, dart.dsend(list[dartx.get](i), 'f14'));
          expect$.Expect.equals(15, dart.dsend(list[dartx.get](i), 'f15'));
          expect$.Expect.equals(16, dart.dsend(list[dartx.get](i), 'f16'));
          expect$.Expect.equals(17, dart.dsend(list[dartx.get](i), 'f17'));
          expect$.Expect.equals(18, dart.dsend(list[dartx.get](i), 'f18'));
          expect$.Expect.equals(19, dart.dsend(list[dartx.get](i), 'f19'));
          expect$.Expect.equals(20, dart.dsend(list[dartx.get](i), 'f20'));
          expect$.Expect.equals(21, dart.dsend(list[dartx.get](i), 'f21'));
          expect$.Expect.equals(22, dart.dsend(list[dartx.get](i), 'f22'));
          expect$.Expect.equals(23, dart.dsend(list[dartx.get](i), 'f23'));
          expect$.Expect.equals(24, dart.dsend(list[dartx.get](i), 'f24'));
          expect$.Expect.equals(25, dart.dsend(list[dartx.get](i), 'f25'));
          expect$.Expect.equals(26, dart.dsend(list[dartx.get](i), 'f26'));
          expect$.Expect.equals(27, dart.dsend(list[dartx.get](i), 'f27'));
          expect$.Expect.equals(28, dart.dsend(list[dartx.get](i), 'f28'));
          expect$.Expect.equals(29, dart.dsend(list[dartx.get](i), 'f29'));
          expect$.Expect.equals(30, dart.dsend(list[dartx.get](i), 'f30'));
          expect$.Expect.equals(31, dart.dsend(list[dartx.get](i), 'f31'));
          expect$.Expect.equals(32, dart.dsend(list[dartx.get](i), 'f32'));
          expect$.Expect.equals(33, dart.dsend(list[dartx.get](i), 'f33'));
          expect$.Expect.equals(34, dart.dsend(list[dartx.get](i), 'f34'));
          expect$.Expect.equals(35, dart.dsend(list[dartx.get](i), 'f35'));
          expect$.Expect.equals(36, dart.dsend(list[dartx.get](i), 'f36'));
          expect$.Expect.equals(37, dart.dsend(list[dartx.get](i), 'f37'));
          expect$.Expect.equals(38, dart.dsend(list[dartx.get](i), 'f38'));
          expect$.Expect.equals(39, dart.dsend(list[dartx.get](i), 'f39'));
        }
      }
    }
  };
  dart.setSignature(many_calls_test.ManyCallsTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  many_calls_test.main = function() {
    many_calls_test.ManyCallsTest.testMain();
  };
  dart.fn(many_calls_test.main, VoidTodynamic());
  // Exports:
  exports.many_calls_test = many_calls_test;
});
