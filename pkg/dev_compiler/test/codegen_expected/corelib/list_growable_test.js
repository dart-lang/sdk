dart_library.library('corelib/list_growable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_growable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_growable_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_growable_test.main = function() {
    let a = null;
    a = core.List.new();
    dart.dsend(a, 'add', 499);
    expect$.Expect.equals(1, dart.dload(a, 'length'));
    expect$.Expect.equals(499, dart.dindex(a, 0));
    dart.dsend(a, 'clear');
    expect$.Expect.equals(0, dart.dload(a, 'length'));
    expect$.Expect.throws(dart.fn(() => dart.dindex(a, 0), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    a = core.List.new(42)[dartx.toList]();
    expect$.Expect.equals(42, dart.dload(a, 'length'));
    dart.dsend(a, 'add', 499);
    expect$.Expect.equals(43, dart.dload(a, 'length'));
    expect$.Expect.equals(499, dart.dindex(a, 42));
    expect$.Expect.equals(null, dart.dindex(a, 23));
    dart.dsend(a, 'clear');
    expect$.Expect.equals(0, dart.dload(a, 'length'));
    expect$.Expect.throws(dart.fn(() => dart.dindex(a, 0), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    a = ListOfint().new(42)[dartx.toList]();
    expect$.Expect.equals(42, dart.dload(a, 'length'));
    dart.dsend(a, 'add', 499);
    expect$.Expect.equals(43, dart.dload(a, 'length'));
    expect$.Expect.equals(499, dart.dindex(a, 42));
    for (let i = 0; i < 42; i++) {
      expect$.Expect.equals(null, dart.dindex(a, i));
    }
    dart.dsend(a, 'clear');
    expect$.Expect.equals(0, dart.dload(a, 'length'));
    expect$.Expect.throws(dart.fn(() => dart.dindex(a, 0), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(list_growable_test.main, VoidTodynamic());
  // Exports:
  exports.list_growable_test = list_growable_test;
});
