dart_library.library('language/nested_switch_label_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__nested_switch_label_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const nested_switch_label_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intAndListTovoid = () => (intAndListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.List])))();
  nested_switch_label_test.main = function() {
    nested_switch_label_test.doSwitch(0, JSArrayOfString().of(['0', '2:0', '1', 'default']));
    nested_switch_label_test.doSwitch(2, JSArrayOfString().of(['2:2', '2:1', '2', '1', 'default']));
  };
  dart.fn(nested_switch_label_test.main, VoidTovoid());
  nested_switch_label_test.doSwitch = function(target, expect) {
    let list = [];
    switch (target) {
      case 0:
      {
        // Unimplemented case labels: [outer0:]
        list[dartx.add]('0');
        continue outer2;
      }
      case 1:
      {
        // Unimplemented case labels: [outer1:]
        list[dartx.add]('1');
        continue outerDefault;
      }
      case 2:
      {
        // Unimplemented case labels: [outer2:]
        switch (target) {
          case 0:
          {
            // Unimplemented case labels: [inner0:]
            list[dartx.add]('2:0');
            continue outer1;
          }
          case 2:
          {
            // Unimplemented case labels: [inner2:]
            list[dartx.add]('2:2');
            continue inner1;
          }
          case 1:
          {
            // Unimplemented case labels: [inner1:]
            list[dartx.add]('2:1');
          }
        }
        list[dartx.add]('2');
        continue outer1;
      }
      default:
      {
        // Unimplemented case labels: [outerDefault:]
        list[dartx.add]('default');
      }
    }
    expect$.Expect.listEquals(expect, list);
  };
  dart.fn(nested_switch_label_test.doSwitch, intAndListTovoid());
  // Exports:
  exports.nested_switch_label_test = nested_switch_label_test;
});
