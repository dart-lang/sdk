dart_library.library('corelib/null_nosuchmethod_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_nosuchmethod_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_nosuchmethod_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_nosuchmethod_test.main = function() {
    let x = null;
    expect$.Expect.throws(dart.fn(() => dart.dsend(x, 'foo'), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dsend(x, 'noSuchMethod', "foo", []), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    let nsm = dart.noSuchMethod(x);
    expect$.Expect.notEquals(null, nsm);
    expect$.Expect.throws(dart.fn(() => dart.dcall(nsm, "foo", []), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(null_nosuchmethod_test.main, VoidTodynamic());
  // Exports:
  exports.null_nosuchmethod_test = null_nosuchmethod_test;
});
