dart_library.library('language/setter_no_getter_call_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter_no_getter_call_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter_no_getter_call_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter_no_getter_call_test_none_multi.topLevelClosure = null;
  dart.copyProperties(setter_no_getter_call_test_none_multi, {
    get topLevel() {
      return setter_no_getter_call_test_none_multi.topLevelClosure;
    },
    set topLevel(value) {}
  });
  setter_no_getter_call_test_none_multi.initialize = function() {
    core.print("initializing");
    setter_no_getter_call_test_none_multi.topLevelClosure = dart.fn(x => dart.dsend(x, '*', 2), dynamicTodynamic());
  };
  dart.fn(setter_no_getter_call_test_none_multi.initialize, VoidTodynamic());
  setter_no_getter_call_test_none_multi.main = function() {
    setter_no_getter_call_test_none_multi.initialize();
    let x = dart.dcall(setter_no_getter_call_test_none_multi.topLevelClosure, 2);
    expect$.Expect.equals(4, x);
    x = dart.dcall(setter_no_getter_call_test_none_multi.topLevel, 3);
    expect$.Expect.equals(6, x);
  };
  dart.fn(setter_no_getter_call_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.setter_no_getter_call_test_none_multi = setter_no_getter_call_test_none_multi;
});
