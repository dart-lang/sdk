dart_library.library('corelib/null_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_test.main = function() {
    let x = null;
    expect$.Expect.isTrue(core.Object.is(x));
    expect$.Expect.isTrue(dart.dynamic.is(x));
    expect$.Expect.isTrue(!(typeof x == 'string'));
    expect$.Expect.isTrue(!(typeof x == 'number'));
    dart.runtimeType(x);
    dart.toString(x);
    dart.hashCode(x);
    expect$.Expect.isTrue(core.identical(x, null));
    expect$.Expect.isTrue(x == null);
    let ts = dart.toString(x);
    expect$.Expect.equals(dart.toString(null), dart.dcall(ts));
  };
  dart.fn(null_test.main, VoidTodynamic());
  // Exports:
  exports.null_test = null_test;
});
