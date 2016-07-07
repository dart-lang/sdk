dart_library.library('language/least_upper_bound_expansive_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__least_upper_bound_expansive_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const least_upper_bound_expansive_test_none_multi = Object.create(null);
  let N = () => (N = dart.constFn(least_upper_bound_expansive_test_none_multi.N$()))();
  let C1 = () => (C1 = dart.constFn(least_upper_bound_expansive_test_none_multi.C1$()))();
  let C2 = () => (C2 = dart.constFn(least_upper_bound_expansive_test_none_multi.C2$()))();
  let C1Ofint = () => (C1Ofint = dart.constFn(least_upper_bound_expansive_test_none_multi.C1$(core.int)))();
  let C1OfString = () => (C1OfString = dart.constFn(least_upper_bound_expansive_test_none_multi.C1$(core.String)))();
  let NOfC1OfString = () => (NOfC1OfString = dart.constFn(least_upper_bound_expansive_test_none_multi.N$(C1OfString())))();
  let C2Ofint = () => (C2Ofint = dart.constFn(least_upper_bound_expansive_test_none_multi.C2$(core.int)))();
  let C2OfString = () => (C2OfString = dart.constFn(least_upper_bound_expansive_test_none_multi.C2$(core.String)))();
  let NOfC2OfString = () => (NOfC2OfString = dart.constFn(least_upper_bound_expansive_test_none_multi.N$(C2OfString())))();
  let boolAndC1OfintAndNOfC1OfStringTovoid = () => (boolAndC1OfintAndNOfC1OfStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.bool, C1Ofint(), NOfC1OfString()])))();
  let boolAndC2OfintAndNOfC2OfStringTovoid = () => (boolAndC2OfintAndNOfC2OfStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.bool, C2Ofint(), NOfC2OfString()])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  least_upper_bound_expansive_test_none_multi.N$ = dart.generic(T => {
    class N extends core.Object {
      get n() {
        return null;
      }
    }
    dart.addTypeTests(N);
    return N;
  });
  least_upper_bound_expansive_test_none_multi.N = N();
  least_upper_bound_expansive_test_none_multi.C1$ = dart.generic(T => {
    class C1 extends least_upper_bound_expansive_test_none_multi.N {
      get c1() {
        return null;
      }
    }
    dart.setBaseClass(C1, least_upper_bound_expansive_test_none_multi.N$(least_upper_bound_expansive_test_none_multi.N$(C1)));
    return C1;
  });
  least_upper_bound_expansive_test_none_multi.C1 = C1();
  least_upper_bound_expansive_test_none_multi.C2$ = dart.generic(T => {
    class C2 extends least_upper_bound_expansive_test_none_multi.N {
      get c2() {
        return null;
      }
    }
    dart.setBaseClass(C2, least_upper_bound_expansive_test_none_multi.N$(least_upper_bound_expansive_test_none_multi.N$(least_upper_bound_expansive_test_none_multi.C2$(least_upper_bound_expansive_test_none_multi.N$(C2)))));
    return C2;
  });
  least_upper_bound_expansive_test_none_multi.C2 = C2();
  least_upper_bound_expansive_test_none_multi.testC1 = function(z, a, b) {
    if (dart.test(z)) {
    }
  };
  dart.fn(least_upper_bound_expansive_test_none_multi.testC1, boolAndC1OfintAndNOfC1OfStringTovoid());
  least_upper_bound_expansive_test_none_multi.testC2 = function(z, a, b) {
    if (dart.test(z)) {
    }
  };
  dart.fn(least_upper_bound_expansive_test_none_multi.testC2, boolAndC2OfintAndNOfC2OfStringTovoid());
  least_upper_bound_expansive_test_none_multi.main = function() {
    least_upper_bound_expansive_test_none_multi.testC1(false, null, null);
    least_upper_bound_expansive_test_none_multi.testC2(false, null, null);
  };
  dart.fn(least_upper_bound_expansive_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.least_upper_bound_expansive_test_none_multi = least_upper_bound_expansive_test_none_multi;
});
