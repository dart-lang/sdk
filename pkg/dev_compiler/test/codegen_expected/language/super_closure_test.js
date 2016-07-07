dart_library.library('language/super_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_closure_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let JSArrayOfVoidTodynamic = () => (JSArrayOfVoidTodynamic = dart.constFn(_interceptors.JSArray$(VoidTodynamic())))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_closure_test.Super = class Super extends core.Object {
    new() {
      this.superX = "super";
    }
    get x() {
      return this.superX;
    }
  };
  super_closure_test.Sub = class Sub extends super_closure_test.Super {
    new() {
      this.subX = "sub";
      super.new();
    }
    get x() {
      return this.subX;
    }
    buildClosures() {
      return JSArrayOfVoidTodynamic().of([dart.fn(() => this.x, VoidTodynamic$()), dart.fn(() => this.x, VoidTodynamic$()), dart.fn(() => super.x, VoidTodynamic$())]);
    }
  };
  dart.setSignature(super_closure_test.Sub, {
    methods: () => ({buildClosures: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_closure_test.main = function() {
    let closures = new super_closure_test.Sub().buildClosures();
    expect$.Expect.equals(3, dart.dload(closures, 'length'));
    expect$.Expect.equals("sub", dart.dcall(dart.dindex(closures, 0)));
    expect$.Expect.equals("sub", dart.dcall(dart.dindex(closures, 1)));
    expect$.Expect.equals("super", dart.dcall(dart.dindex(closures, 2)));
  };
  dart.fn(super_closure_test.main, VoidTodynamic$());
  // Exports:
  exports.super_closure_test = super_closure_test;
});
