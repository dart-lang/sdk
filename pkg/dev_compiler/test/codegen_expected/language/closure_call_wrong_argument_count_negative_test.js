dart_library.library('language/closure_call_wrong_argument_count_negative_test', null, /* Imports */[
  'dart_sdk'
], function load__closure_call_wrong_argument_count_negative_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const closure_call_wrong_argument_count_negative_test = Object.create(null);
  let intAndintTodynamic = () => (intAndintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_call_wrong_argument_count_negative_test.ClosureCallWrongArgumentCountNegativeTest = class ClosureCallWrongArgumentCountNegativeTest extends core.Object {
    static melke(f) {
      return core.int._check(dart.dcall(f, 1, 2, 3));
    }
    static testMain() {
      function kuh(a, b) {
        return dart.notNull(a) + dart.notNull(b);
      }
      dart.fn(kuh, intAndintTodynamic());
      closure_call_wrong_argument_count_negative_test.ClosureCallWrongArgumentCountNegativeTest.melke(kuh);
    }
  };
  dart.setSignature(closure_call_wrong_argument_count_negative_test.ClosureCallWrongArgumentCountNegativeTest, {
    statics: () => ({
      melke: dart.definiteFunctionType(core.int, [dart.dynamic]),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['melke', 'testMain']
  });
  closure_call_wrong_argument_count_negative_test.main = function() {
    closure_call_wrong_argument_count_negative_test.ClosureCallWrongArgumentCountNegativeTest.testMain();
  };
  dart.fn(closure_call_wrong_argument_count_negative_test.main, VoidTodynamic());
  // Exports:
  exports.closure_call_wrong_argument_count_negative_test = closure_call_wrong_argument_count_negative_test;
});
