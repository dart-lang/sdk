dart_library.library('language/div_with_power_of_two2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__div_with_power_of_two2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const div_with_power_of_two2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(div_with_power_of_two2_test, {
    get expectedResults() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([div_with_power_of_two2_test.divBy1, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, 134217730]), JSArrayOfint().of([-134217730, -134217730]), JSArrayOfint().of([10, 10]), JSArrayOfint().of([-10, -10])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divByNeg1, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, -134217730]), JSArrayOfint().of([-134217730, 134217730]), JSArrayOfint().of([10, -10]), JSArrayOfint().of([-10, 10])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divBy2, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, 67108865]), JSArrayOfint().of([-134217730, -67108865]), JSArrayOfint().of([10, 5]), JSArrayOfint().of([-10, -5])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divByNeg2, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, -67108865]), JSArrayOfint().of([-134217730, 67108865]), JSArrayOfint().of([10, -5]), JSArrayOfint().of([-10, 5])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divBy4, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, 33554432]), JSArrayOfint().of([-134217730, -33554432]), JSArrayOfint().of([10, 2]), JSArrayOfint().of([-10, -2])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divByNeg4, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, -33554432]), JSArrayOfint().of([-134217730, 33554432]), JSArrayOfint().of([10, -2]), JSArrayOfint().of([-10, 2])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divBy134217728, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, 1]), JSArrayOfint().of([-134217730, -1]), JSArrayOfint().of([10, 0]), JSArrayOfint().of([-10, 0])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divByNeg134217728, JSArrayOfListOfint().of([JSArrayOfint().of([134217730, -1]), JSArrayOfint().of([-134217730, 1]), JSArrayOfint().of([10, 0]), JSArrayOfint().of([-10, 0])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divBy4_, JSArrayOfListOfint().of([JSArrayOfint().of([549755813990, 137438953497]), JSArrayOfint().of([-549755813990, -137438953497]), JSArrayOfint().of([288230925907525632, 72057731476881408]), JSArrayOfint().of([-288230925907525632, -72057731476881408])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divByNeg4_, JSArrayOfListOfint().of([JSArrayOfint().of([549755813990, -137438953497]), JSArrayOfint().of([-549755813990, 137438953497]), JSArrayOfint().of([288230925907525632, -72057731476881408]), JSArrayOfint().of([-288230925907525632, 72057731476881408])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divBy549755813888, JSArrayOfListOfint().of([JSArrayOfint().of([549755813990, 1]), JSArrayOfint().of([-549755813990, -1]), JSArrayOfint().of([288230925907525632, 524289]), JSArrayOfint().of([-288230925907525632, -524289])])]), JSArrayOfObject().of([div_with_power_of_two2_test.divByNeg549755813888, JSArrayOfListOfint().of([JSArrayOfint().of([549755813990, -1]), JSArrayOfint().of([-549755813990, 1]), JSArrayOfint().of([288230925907525632, -524289]), JSArrayOfint().of([-288230925907525632, 524289])])])]);
    },
    set expectedResults(_) {}
  });
  div_with_power_of_two2_test.divBy0 = function(a) {
    return dart.dsend(a, '~/', 0);
  };
  dart.fn(div_with_power_of_two2_test.divBy0, dynamicTodynamic());
  div_with_power_of_two2_test.divBy1 = function(a) {
    return dart.dsend(a, '~/', 1);
  };
  dart.fn(div_with_power_of_two2_test.divBy1, dynamicTodynamic());
  div_with_power_of_two2_test.divByNeg1 = function(a) {
    return dart.dsend(a, '~/', -1);
  };
  dart.fn(div_with_power_of_two2_test.divByNeg1, dynamicTodynamic());
  div_with_power_of_two2_test.divBy2 = function(a) {
    return dart.dsend(a, '~/', 2);
  };
  dart.fn(div_with_power_of_two2_test.divBy2, dynamicTodynamic());
  div_with_power_of_two2_test.divByNeg2 = function(a) {
    return dart.dsend(a, '~/', -2);
  };
  dart.fn(div_with_power_of_two2_test.divByNeg2, dynamicTodynamic());
  div_with_power_of_two2_test.divBy4 = function(a) {
    return dart.dsend(a, '~/', 4);
  };
  dart.fn(div_with_power_of_two2_test.divBy4, dynamicTodynamic());
  div_with_power_of_two2_test.divByNeg4 = function(a) {
    return dart.dsend(a, '~/', -4);
  };
  dart.fn(div_with_power_of_two2_test.divByNeg4, dynamicTodynamic());
  div_with_power_of_two2_test.divBy134217728 = function(a) {
    return dart.dsend(a, '~/', 134217728);
  };
  dart.fn(div_with_power_of_two2_test.divBy134217728, dynamicTodynamic());
  div_with_power_of_two2_test.divByNeg134217728 = function(a) {
    return dart.dsend(a, '~/', -134217728);
  };
  dart.fn(div_with_power_of_two2_test.divByNeg134217728, dynamicTodynamic());
  div_with_power_of_two2_test.divBy4_ = function(a) {
    return dart.dsend(a, '~/', 4);
  };
  dart.fn(div_with_power_of_two2_test.divBy4_, dynamicTodynamic());
  div_with_power_of_two2_test.divByNeg4_ = function(a) {
    return dart.dsend(a, '~/', -4);
  };
  dart.fn(div_with_power_of_two2_test.divByNeg4_, dynamicTodynamic());
  div_with_power_of_two2_test.divBy549755813888 = function(a) {
    return dart.dsend(a, '~/', 549755813888);
  };
  dart.fn(div_with_power_of_two2_test.divBy549755813888, dynamicTodynamic());
  div_with_power_of_two2_test.divByNeg549755813888 = function(a) {
    return dart.dsend(a, '~/', -549755813888);
  };
  dart.fn(div_with_power_of_two2_test.divByNeg549755813888, dynamicTodynamic());
  div_with_power_of_two2_test.main = function() {
    for (let i = 0; i < 20; i++) {
      for (let e of div_with_power_of_two2_test.expectedResults) {
        let f = core.Function._check(e[dartx.get](0));
        let values = core.List._check(e[dartx.get](1));
        for (let v of values) {
          let arg = core.int._check(dart.dindex(v, 0));
          let res = core.int._check(dart.dindex(v, 1));
          expect$.Expect.equals(res, dart.dcall(f, arg));
        }
      }
      expect$.Expect.throws(dart.fn(() => div_with_power_of_two2_test.divBy0(4), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e) || core.UnsupportedError.is(e), dynamicTobool()));
    }
  };
  dart.fn(div_with_power_of_two2_test.main, VoidTodynamic());
  // Exports:
  exports.div_with_power_of_two2_test = div_with_power_of_two2_test;
});
