dart_library.library('language/extends_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__extends_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const extends_test = Object.create(null);
  const extends_test_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  extends_test.A = class A extends core.Object {
    new() {
      this.y = "class A from main script";
    }
  };
  extends_test.S = class S extends extends_test.A {
    new() {
      super.new();
    }
  };
  extends_test.main = function() {
    let s = new extends_test.S();
    expect$.Expect.equals("class A from main script", s.y);
  };
  dart.fn(extends_test.main, VoidTodynamic());
  extends_test_lib.A = class A extends core.Object {
    new() {
      this.y = "class A from library";
    }
  };
  // Exports:
  exports.extends_test = extends_test;
  exports.extends_test_lib = extends_test_lib;
});
