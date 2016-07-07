dart_library.library('language/generic_tearoff_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_tearoff_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_tearoff_test = Object.create(null);
  let TAndTToT = () => (TAndTToT = dart.constFn(dart.functionType(T => [T, [T, T]])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let Int2Int2IntTovoid = () => (Int2Int2IntTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [generic_tearoff_test.Int2Int2Int])))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [TAndTToT()])))();
  let TAndTToT$ = () => (TAndTToT$ = dart.constFn(dart.definiteFunctionType(T => [T, [T, T]])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_tearoff_test.C = class C extends core.Object {
    m(T) {
      return (x, y) => {
        return math.min(T)(x, y);
      };
    }
    m2(x, y) {
      return math.min(core.int)(x, y);
    }
  };
  dart.setSignature(generic_tearoff_test.C, {
    methods: () => ({
      m: dart.definiteFunctionType(T => [T, [T, T]]),
      m2: dart.definiteFunctionType(core.int, [core.int, core.int])
    })
  });
  generic_tearoff_test.Int2Int2Int = dart.typedef('Int2Int2Int', () => dart.functionType(core.int, [core.int, core.int]));
  generic_tearoff_test._test = function(f) {
    let y = f(123, 456);
    expect$.Expect.equals(y, 123);
    expect$.Expect.throws(dart.fn(() => dart.dgcall(f, [core.int], 123, 456), VoidTovoid()));
  };
  dart.fn(generic_tearoff_test._test, Int2Int2IntTovoid());
  generic_tearoff_test._testParam = function(minFn) {
    generic_tearoff_test._test(dart.gbind(minFn, core.int));
  };
  dart.fn(generic_tearoff_test._testParam, FnTovoid());
  generic_tearoff_test.main = function() {
    generic_tearoff_test._test(dart.gbind(math.min, core.int));
    generic_tearoff_test._test(dart.gbind(math.min, core.int));
    generic_tearoff_test._test(dart.gbind(dart.bind(new generic_tearoff_test.C(), 'm'), core.int));
    function m(T) {
      return (x, y) => {
        return math.min(T)(x, y);
      };
    }
    dart.fn(m, TAndTToT$());
    generic_tearoff_test._test(dart.gbind(m, core.int));
    let f = math.min;
    generic_tearoff_test._test(dart.gbind(f, core.int));
    generic_tearoff_test._testParam(math.min);
    expect$.Expect.equals(123, dart.dgsend(new generic_tearoff_test.C(), [core.int], 'm', 123, 456));
    expect$.Expect.throws(dart.fn(() => dart.dgsend(new generic_tearoff_test.C(), [core.int], 'm2', 123, 456), VoidTovoid()));
  };
  dart.fn(generic_tearoff_test.main, VoidTodynamic());
  // Exports:
  exports.generic_tearoff_test = generic_tearoff_test;
});
