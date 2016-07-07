dart_library.library('corelib/const_list_literal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_list_literal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_list_literal_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  const_list_literal_test.ConstListLiteralTest = class ConstListLiteralTest extends core.Object {
    static testMain() {
      let list = const$ || (const$ = dart.constList([4, 2, 3], core.int));
      expect$.Expect.equals(3, list[dartx.length]);
      let exception = null;
      try {
        list[dartx.add](4);
      } catch (e) {
        if (core.UnsupportedError.is(e)) {
          exception = e;
        } else
          throw e;
      }

      expect$.Expect.equals(true, exception != null);
      expect$.Expect.equals(3, list[dartx.length]);
      exception = null;
      exception = null;
      try {
        list[dartx.addAll](JSArrayOfint().of([4, 5]));
      } catch (e) {
        if (core.UnsupportedError.is(e)) {
          exception = e;
        } else
          throw e;
      }

      expect$.Expect.equals(true, exception != null);
      expect$.Expect.equals(3, list[dartx.length]);
      exception = null;
      try {
        list[dartx.set](0, 0);
      } catch (e) {
        if (core.UnsupportedError.is(e)) {
          exception = e;
        } else
          throw e;
      }

      expect$.Expect.equals(true, exception != null);
      expect$.Expect.equals(3, list[dartx.length]);
      exception = null;
      try {
        list[dartx.sort](dart.fn((a, b) => dart.notNull(a) - dart.notNull(b), intAndintToint()));
      } catch (e) {
        if (core.UnsupportedError.is(e)) {
          exception = e;
        } else
          throw e;
      }

      expect$.Expect.equals(true, exception != null);
      expect$.Expect.equals(3, list[dartx.length]);
      expect$.Expect.equals(4, list[dartx.get](0));
      expect$.Expect.equals(2, list[dartx.get](1));
      expect$.Expect.equals(3, list[dartx.get](2));
      exception = null;
      try {
        list[dartx.setRange](0, 1, JSArrayOfint().of([1]), 0);
      } catch (e) {
        if (core.UnsupportedError.is(e)) {
          exception = e;
        } else
          throw e;
      }

      expect$.Expect.equals(true, exception != null);
      expect$.Expect.equals(3, list[dartx.length]);
      expect$.Expect.equals(4, list[dartx.get](0));
      expect$.Expect.equals(2, list[dartx.get](1));
      expect$.Expect.equals(3, list[dartx.get](2));
      let x = 0;
      list[dartx.forEach](dart.fn(e => {
        x = dart.notNull(x) + dart.notNull(e);
      }, intTovoid()));
      expect$.Expect.equals(9, x);
    }
  };
  dart.setSignature(const_list_literal_test.ConstListLiteralTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  const_list_literal_test.main = function() {
    const_list_literal_test.ConstListLiteralTest.testMain();
  };
  dart.fn(const_list_literal_test.main, VoidTodynamic());
  // Exports:
  exports.const_list_literal_test = const_list_literal_test;
});
