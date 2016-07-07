dart_library.library('language/incr_op_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__incr_op_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const incr_op_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  incr_op_test.A = class A extends core.Object {
    static set y(v) {
      incr_op_test.A.yy = v;
    }
    static get y() {
      return incr_op_test.A.yy;
    }
  };
  incr_op_test.A.yy = null;
  incr_op_test.IncrOpTest = class IncrOpTest extends core.Object {
    new() {
      this.x = null;
    }
    static testMain() {
      let a = 3;
      let c = a++ + 1;
      expect$.Expect.equals(4, c);
      expect$.Expect.equals(4, a);
      c = a-- + 1;
      expect$.Expect.equals(5, c);
      expect$.Expect.equals(3, a);
      c = --a + 1;
      expect$.Expect.equals(3, c);
      expect$.Expect.equals(2, a);
      c = 2 + ++a;
      expect$.Expect.equals(5, c);
      expect$.Expect.equals(3, a);
      let obj = new incr_op_test.IncrOpTest();
      obj.x = 100;
      expect$.Expect.equals(100, obj.x);
      obj.x = dart.dsend(obj.x, '+', 1);
      expect$.Expect.equals(101, obj.x);
      expect$.Expect.equals(102, (obj.x = dart.dsend(obj.x, '+', 1)));
      expect$.Expect.equals(102, (() => {
        let x = obj.x;
        obj.x = dart.dsend(x, '+', 1);
        return x;
      })());
      expect$.Expect.equals(103, obj.x);
      incr_op_test.A.y = 55;
      expect$.Expect.equals(55, (() => {
        let x = incr_op_test.A.y;
        incr_op_test.A.y = dart.dsend(x, '+', 1);
        return x;
      })());
      expect$.Expect.equals(56, incr_op_test.A.y);
      expect$.Expect.equals(57, incr_op_test.A.y = dart.dsend(incr_op_test.A.y, '+', 1));
      expect$.Expect.equals(57, incr_op_test.A.y);
      expect$.Expect.equals(56, incr_op_test.A.y = dart.dsend(incr_op_test.A.y, '-', 1));
      incr_op_test.IncrOpTest.y = 55;
      expect$.Expect.equals(55, (() => {
        let x = incr_op_test.IncrOpTest.y;
        incr_op_test.IncrOpTest.y = dart.dsend(x, '+', 1);
        return x;
      })());
      expect$.Expect.equals(56, incr_op_test.IncrOpTest.y);
      expect$.Expect.equals(57, incr_op_test.IncrOpTest.y = dart.dsend(incr_op_test.IncrOpTest.y, '+', 1));
      expect$.Expect.equals(57, incr_op_test.IncrOpTest.y);
      expect$.Expect.equals(56, incr_op_test.IncrOpTest.y = dart.dsend(incr_op_test.IncrOpTest.y, '-', 1));
      let list = core.List.new(4);
      for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
        list[dartx.set](i, i);
      }
      for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
        list[dartx.set](i, dart.dsend(list[dartx.get](i), '+', 1));
      }
      for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
        expect$.Expect.equals(i + 1, list[dartx.get](i));
        list[dartx.set](i, dart.dsend(list[dartx.get](i), '+', 1));
      }
      expect$.Expect.equals(1 + 2, list[dartx.get](1));
      expect$.Expect.equals(1 + 2, (() => {
        let i = 1, x = list[dartx.get](i);
        list[dartx.set](i, dart.dsend(x, '-', 1));
        return x;
      })());
      expect$.Expect.equals(1 + 1, list[dartx.get](1));
      expect$.Expect.equals(1 + 0, (() => {
        let i = 1;
        return list[dartx.set](i, dart.dsend(list[dartx.get](i), '-', 1));
      })());
    }
  };
  dart.setSignature(incr_op_test.IncrOpTest, {
    constructors: () => ({new: dart.definiteFunctionType(incr_op_test.IncrOpTest, [])}),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  incr_op_test.IncrOpTest.y = null;
  incr_op_test.main = function() {
    incr_op_test.IncrOpTest.testMain();
  };
  dart.fn(incr_op_test.main, VoidTodynamic());
  // Exports:
  exports.incr_op_test = incr_op_test;
});
