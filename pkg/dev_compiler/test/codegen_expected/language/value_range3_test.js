dart_library.library('language/value_range3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__value_range3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const value_range3_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  value_range3_test.A = class A extends core.Object {
    copy(array, index1, index2) {
      if (dart.test(dart.dsend(index1, '<', dart.dsend(index2, '+', index2)))) {
        return dart.dindex(array, index1);
      }
    }
  };
  dart.setSignature(value_range3_test.A, {
    methods: () => ({copy: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])})
  });
  value_range3_test.main = function() {
    expect$.Expect.throws(dart.fn(() => new value_range3_test.A().copy(core.List.new(0), 0, 1), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(value_range3_test.main, VoidTodynamic());
  // Exports:
  exports.value_range3_test = value_range3_test;
});
