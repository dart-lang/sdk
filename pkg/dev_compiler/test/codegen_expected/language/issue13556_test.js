dart_library.library('language/issue13556_test', null, /* Imports */[
  'dart_sdk'
], function load__issue13556_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue13556_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue13556_test.A = class A extends core.Object {
    new(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      this.a = a;
    }
  };
  dart.setSignature(issue13556_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(issue13556_test.A, [], {a: dart.dynamic})})
  });
  issue13556_test.B = class B extends issue13556_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(issue13556_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(issue13556_test.B, [])})
  });
  issue13556_test.main = function() {
  };
  dart.fn(issue13556_test.main, VoidTodynamic());
  // Exports:
  exports.issue13556_test = issue13556_test;
});
