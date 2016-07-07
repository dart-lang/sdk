dart_library.library('language/switch_try_catch_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__switch_try_catch_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const switch_try_catch_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  switch_try_catch_test.test_switch = function() {
    switch (0) {
      case 0:
      {
        // Unimplemented case labels: [_0:]
        core.print("_0");
        continue _5;
      }
      case 1:
      {
        // Unimplemented case labels: [_1:]
        try {
          core.print("bunny");
          continue _6;
        } catch (e) {
        }

        break;
      }
      case 5:
      {
        // Unimplemented case labels: [_5:]
        core.print("_5");
        continue _6;
      }
      case 6:
      {
        // Unimplemented case labels: [_6:]
        core.print("_6");
        dart.throw(555);
      }
    }
  };
  dart.fn(switch_try_catch_test.test_switch, VoidTodynamic());
  switch_try_catch_test.main = function() {
    expect$.Expect.throws(dart.fn(() => switch_try_catch_test.test_switch(), VoidTovoid()), dart.fn(e => dart.equals(e, 555), dynamicTobool()));
  };
  dart.fn(switch_try_catch_test.main, VoidTodynamic());
  // Exports:
  exports.switch_try_catch_test = switch_try_catch_test;
});
