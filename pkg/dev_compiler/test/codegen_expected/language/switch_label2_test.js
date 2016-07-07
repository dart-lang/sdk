dart_library.library('language/switch_label2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__switch_label2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const switch_label2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intAndListTovoid = () => (intAndListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.List])))();
  switch_label2_test.main = function() {
    switch_label2_test.doSwitch(0, JSArrayOfint().of([0, 2]));
    switch_label2_test.doSwitch(1, JSArrayOfint().of([1]));
    switch_label2_test.doSwitch(2, JSArrayOfint().of([2]));
    switch_label2_test.doSwitch(3, JSArrayOfint().of([3, 1]));
  };
  dart.fn(switch_label2_test.main, VoidTovoid());
  switch_label2_test.doSwitch = function(target, expect) {
    let list = [];
    switch (target) {
      case 0:
      {
        list[dartx.add](0);
        continue case2;
      }
      case 1:
      {
        // Unimplemented case labels: [case1:]
        list[dartx.add](1);
        break;
      }
      case 2:
      {
        // Unimplemented case labels: [case2:]
        list[dartx.add](2);
        break;
      }
      case 3:
      {
        list[dartx.add](3);
        continue case1;
      }
    }
    expect$.Expect.listEquals(expect, list);
  };
  dart.fn(switch_label2_test.doSwitch, intAndListTovoid());
  // Exports:
  exports.switch_label2_test = switch_label2_test;
});
