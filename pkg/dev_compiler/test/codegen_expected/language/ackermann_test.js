dart_library.library('language/ackermann_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__ackermann_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const ackermann_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  ackermann_test.AckermannTest = class AckermannTest extends core.Object {
    static ack(m, n) {
      return dart.equals(m, 0) ? dart.dsend(n, '+', 1) : dart.equals(n, 0) ? ackermann_test.AckermannTest.ack(dart.dsend(m, '-', 1), 1) : ackermann_test.AckermannTest.ack(dart.dsend(m, '-', 1), ackermann_test.AckermannTest.ack(m, dart.dsend(n, '-', 1)));
    }
    static testMain() {
      expect$.Expect.equals(253, ackermann_test.AckermannTest.ack(3, 5));
    }
  };
  dart.setSignature(ackermann_test.AckermannTest, {
    statics: () => ({
      ack: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['ack', 'testMain']
  });
  ackermann_test.main = function() {
    ackermann_test.AckermannTest.testMain();
  };
  dart.fn(ackermann_test.main, VoidTodynamic());
  // Exports:
  exports.ackermann_test = ackermann_test;
});
