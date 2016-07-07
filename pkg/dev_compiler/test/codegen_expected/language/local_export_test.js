dart_library.library('language/local_export_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__local_export_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const local_export_test = Object.create(null);
  const local_export_a = Object.create(null);
  const local_export_a_export = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  local_export_test.main = function() {
    expect$.Expect.equals(42, new local_export_a.A().method());
  };
  dart.fn(local_export_test.main, VoidTovoid());
  local_export_a.A = class A extends core.Object {
    method() {
      return 42;
    }
  };
  dart.setSignature(local_export_a.A, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [])})
  });
  local_export_a_export.A = 0;
  // Exports:
  exports.local_export_test = local_export_test;
  exports.local_export_a = local_export_a;
  exports.local_export_a_export = local_export_a_export;
});
