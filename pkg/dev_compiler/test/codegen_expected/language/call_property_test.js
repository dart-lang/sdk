dart_library.library('language/call_property_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_property_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_property_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_property_test.Call = class Call extends core.Object {
    get call() {
      return 0;
    }
  };
  call_property_test.F = dart.typedef('F', () => dart.functionType(dart.void, []));
  call_property_test.main = function() {
    expect$.Expect.isFalse(core.Function.is(new call_property_test.Call()));
    expect$.Expect.isFalse(call_property_test.F.is(new call_property_test.Call()));
  };
  dart.fn(call_property_test.main, VoidTodynamic());
  // Exports:
  exports.call_property_test = call_property_test;
});
