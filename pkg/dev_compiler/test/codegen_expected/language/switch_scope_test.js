dart_library.library('language/switch_scope_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__switch_scope_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const switch_scope_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  switch_scope_test.SwitchScopeTest = class SwitchScopeTest extends core.Object {
    static testMain() {
      switch (1) {
        case 1:
        {
          let v = 1;
          break;
        }
        case 2:
        {
          let v = 2;
          expect$.Expect.equals(2, v);
          break;
        }
        default:
        {
          let v = 3;
          break;
        }
      }
    }
  };
  dart.setSignature(switch_scope_test.SwitchScopeTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  switch_scope_test.main = function() {
    switch_scope_test.SwitchScopeTest.testMain();
  };
  dart.fn(switch_scope_test.main, VoidTodynamic());
  // Exports:
  exports.switch_scope_test = switch_scope_test;
});
