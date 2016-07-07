dart_library.library('language/resolution_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__resolution_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const resolution_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  dart.copyProperties(resolution_test, {
    get foo() {
      return 499;
    }
  });
  resolution_test.CompileError = class CompileError extends core.Object {
    static new() {
      return new resolution_test.CompileError.internal(resolution_test.foo);
    }
    internal(x) {
      this.x = x;
    }
  };
  dart.defineNamedConstructor(resolution_test.CompileError, 'internal');
  dart.setSignature(resolution_test.CompileError, {
    constructors: () => ({
      new: dart.definiteFunctionType(resolution_test.CompileError, []),
      internal: dart.definiteFunctionType(resolution_test.CompileError, [dart.dynamic])
    })
  });
  resolution_test.main = function() {
    expect$.Expect.equals(499, resolution_test.CompileError.new().x);
  };
  dart.fn(resolution_test.main, VoidTovoid());
  // Exports:
  exports.resolution_test = resolution_test;
});
