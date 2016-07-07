dart_library.library('language/issue21079_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue21079_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const isolate = dart_sdk.isolate;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue21079_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  issue21079_test.main = function() {
    expect$.Expect.isTrue(dart.equals(mirrors.reflectClass(dart.wrapType(issue21079_test.MyException)).superclass.reflectedType, dart.wrapType(isolate.IsolateSpawnException)));
    expect$.Expect.isTrue(dart.equals(mirrors.reflectClass(dart.wrapType(isolate.IsolateSpawnException)).reflectedType, dart.wrapType(isolate.IsolateSpawnException)));
  };
  dart.fn(issue21079_test.main, VoidTovoid());
  issue21079_test.MyException = class MyException extends isolate.IsolateSpawnException {
    new() {
      super.new("Test");
    }
  };
  dart.setSignature(issue21079_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(issue21079_test.MyException, [])})
  });
  // Exports:
  exports.issue21079_test = issue21079_test;
});
