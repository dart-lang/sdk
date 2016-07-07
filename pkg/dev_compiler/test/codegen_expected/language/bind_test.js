dart_library.library('language/bind_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bind_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bind_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  bind_test.Bound = class Bound extends core.Object {
    run() {
      return 42;
    }
  };
  dart.setSignature(bind_test.Bound, {
    methods: () => ({run: dart.definiteFunctionType(dart.dynamic, [])})
  });
  bind_test.main = function() {
    let runner = dart.bind(new bind_test.Bound(), 'run');
    expect$.Expect.equals(42, runner());
  };
  dart.fn(bind_test.main, VoidTovoid());
  // Exports:
  exports.bind_test = bind_test;
});
