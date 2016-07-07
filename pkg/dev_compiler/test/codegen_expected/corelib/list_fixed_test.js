dart_library.library('corelib/list_fixed_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_fixed_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_fixed_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_fixed_test.main = function() {
    let a = null;
    a = core.List.new(42);
    expect$.Expect.equals(42, dart.dload(a, 'length'));
    expect$.Expect.throws(dart.fn(() => dart.dsend(a, 'add', 499), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.equals(42, dart.dload(a, 'length'));
    for (let i = 0; i < 42; i++) {
      expect$.Expect.equals(null, dart.dindex(a, i));
    }
    expect$.Expect.throws(dart.fn(() => dart.dsend(a, 'clear'), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.equals(42, dart.dload(a, 'length'));
    a = core.List.filled(42, -2);
    expect$.Expect.equals(42, dart.dload(a, 'length'));
    expect$.Expect.throws(dart.fn(() => dart.dsend(a, 'add', 499), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.equals(42, dart.dload(a, 'length'));
    for (let i = 0; i < 42; i++) {
      expect$.Expect.equals(-2, dart.dindex(a, i));
    }
    expect$.Expect.throws(dart.fn(() => dart.dsend(a, 'clear'), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.equals(42, dart.dload(a, 'length'));
  };
  dart.fn(list_fixed_test.main, VoidTodynamic());
  // Exports:
  exports.list_fixed_test = list_fixed_test;
});
