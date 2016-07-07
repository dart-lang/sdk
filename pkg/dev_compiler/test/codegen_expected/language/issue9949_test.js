dart_library.library('language/issue9949_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue9949_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue9949_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  issue9949_test.Crash = class Crash extends core.Expando$(core.String) {
    new() {
      super.new();
    }
  };
  dart.addSimpleTypeTests(issue9949_test.Crash);
  dart.setSignature(issue9949_test.Crash, {
    constructors: () => ({new: dart.definiteFunctionType(issue9949_test.Crash, [])})
  });
  issue9949_test.main = function() {
    let expando = new issue9949_test.Crash();
    expect$.Expect.isTrue(core.Expando.is(expando));
  };
  dart.fn(issue9949_test.main, VoidTovoid());
  // Exports:
  exports.issue9949_test = issue9949_test;
});
