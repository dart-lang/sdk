dart_library.library('language/assign_op_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__assign_op_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const assign_op_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  assign_op_test.AssignOpTest = class AssignOpTest extends core.Object {
    new() {
      this.instf = null;
    }
    static testMain() {
      let b = 0;
      b = b + 1;
      expect$.Expect.equals(1, b);
      b = b * 5;
      expect$.Expect.equals(5, b);
      b = b - 1;
      expect$.Expect.equals(4, b);
      b = (b / 2)[dartx.truncate]();
      expect$.Expect.equals(2, b);
      assign_op_test.AssignOpTest.f = 0;
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '+', 1);
      expect$.Expect.equals(1, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '*', 5);
      expect$.Expect.equals(5, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '-', 1);
      expect$.Expect.equals(4, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '~/', 2);
      expect$.Expect.equals(2, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '/', 4);
      expect$.Expect.equals(0.5, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = 0;
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '+', 1);
      expect$.Expect.equals(1, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '*', 5);
      expect$.Expect.equals(5, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '-', 1);
      expect$.Expect.equals(4, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '~/', 2);
      expect$.Expect.equals(2, assign_op_test.AssignOpTest.f);
      assign_op_test.AssignOpTest.f = dart.dsend(assign_op_test.AssignOpTest.f, '/', 4);
      expect$.Expect.equals(0.5, assign_op_test.AssignOpTest.f);
      let o = new assign_op_test.AssignOpTest();
      o.instf = 0;
      o.instf = dart.dsend(o.instf, '+', 1);
      expect$.Expect.equals(1, o.instf);
      o.instf = dart.dsend(o.instf, '*', 5);
      expect$.Expect.equals(5, o.instf);
      o.instf = dart.dsend(o.instf, '-', 1);
      expect$.Expect.equals(4, o.instf);
      o.instf = dart.dsend(o.instf, '~/', 2);
      expect$.Expect.equals(2, o.instf);
      o.instf = dart.dsend(o.instf, '/', 4);
      expect$.Expect.equals(0.5, o.instf);
      let x = 255;
      x = x[dartx['>>']](3);
      expect$.Expect.equals(31, x);
      x = x << 3 >>> 0;
      expect$.Expect.equals(248, x);
      x = (x | 3840) >>> 0;
      expect$.Expect.equals(4088, x);
      x = x & 240;
      expect$.Expect.equals(240, x);
      x = (x ^ 17) >>> 0;
      expect$.Expect.equals(225, x);
      let y = 100;
      y = y + (1 << 3);
      expect$.Expect.equals(108, y);
      y = y * (2 + 1);
      expect$.Expect.equals(324, y);
      y = y - (3 - 2);
      expect$.Expect.equals(323, y);
      y = y + 3 * 4;
      expect$.Expect.equals(335, y);
      let a = JSArrayOfint().of([1, 2, 3]);
      let ix = 0;
      a[dartx.set](ix, (dart.notNull(a[dartx.get](ix)) | 12) >>> 0);
      expect$.Expect.equals(13, a[dartx.get](ix));
    }
  };
  dart.setSignature(assign_op_test.AssignOpTest, {
    constructors: () => ({new: dart.definiteFunctionType(assign_op_test.AssignOpTest, [])}),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  assign_op_test.AssignOpTest.f = null;
  assign_op_test.main = function() {
    for (let i = 0; i < 20; i++) {
      assign_op_test.AssignOpTest.testMain();
    }
  };
  dart.fn(assign_op_test.main, VoidTodynamic());
  // Exports:
  exports.assign_op_test = assign_op_test;
});
