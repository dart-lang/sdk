dart_library.library('language/infinite_switch_label_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__infinite_switch_label_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const infinite_switch_label_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  infinite_switch_label_test.main = function() {
    expect$.Expect.throws(dart.fn(() => infinite_switch_label_test.doSwitch(0), VoidTovoid()), dart.fn(list => {
      expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]), core.List._check(list));
      return true;
    }, dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => infinite_switch_label_test.doSwitch(2), VoidTovoid()), dart.fn(list => {
      expect$.Expect.listEquals(JSArrayOfint().of([2, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]), core.List._check(list));
      return true;
    }, dynamicTobool()));
  };
  dart.fn(infinite_switch_label_test.main, VoidTovoid());
  infinite_switch_label_test.doSwitch = function(target) {
    let list = [];
    switch (target) {
      case 0:
      {
        // Unimplemented case labels: [l0:]
        if (dart.notNull(list[dartx.length]) > 10) dart.throw(list);
        list[dartx.add](0);
        continue l1;
      }
      case 1:
      {
        // Unimplemented case labels: [l1:]
        if (dart.notNull(list[dartx.length]) > 10) dart.throw(list);
        list[dartx.add](1);
        continue l0;
      }
      default:
      {
        list[dartx.add](2);
        continue l1;
      }
    }
  };
  dart.fn(infinite_switch_label_test.doSwitch, intTovoid());
  // Exports:
  exports.infinite_switch_label_test = infinite_switch_label_test;
});
