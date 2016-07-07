dart_library.library('corelib/type_hashcode_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_hashcode_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_hashcode_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  type_hashcode_test.main = function() {
    let h = "hello", w = "world";
    expect$.Expect.notEquals(dart.hashCode(h), dart.hashCode(w));
    expect$.Expect.notEquals(dart.wrapType(core.String).hashCode, dart.wrapType(core.int).hashCode);
    let c = dart.hashCode(dart.runtimeType(h));
    expect$.Expect.isTrue(typeof c == 'number');
    expect$.Expect.notEquals(c, null);
    expect$.Expect.notEquals(c, 0);
  };
  dart.fn(type_hashcode_test.main, VoidTovoid());
  // Exports:
  exports.type_hashcode_test = type_hashcode_test;
});
