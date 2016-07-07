dart_library.library('language/identical_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__identical_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const identical_closure_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  identical_closure_test.myIdentical = core.identical;
  identical_closure_test.Point = class Point extends core.Object {
    new(x, y) {
      this.x = x;
      this.y = y;
    }
  };
  dart.setSignature(identical_closure_test.Point, {
    constructors: () => ({new: dart.definiteFunctionType(identical_closure_test.Point, [core.num, core.num])})
  });
  identical_closure_test.main = function() {
    expect$.Expect.isTrue(identical_closure_test.myIdentical(42, 42));
    expect$.Expect.isFalse(identical_closure_test.myIdentical(42, 41));
    expect$.Expect.isTrue(identical_closure_test.myIdentical(42.0, 42.0));
    expect$.Expect.isFalse(identical_closure_test.myIdentical(42.0, 41.0));
    expect$.Expect.isTrue(identical_closure_test.myIdentical(35184372088832, 35184372088832));
    expect$.Expect.isFalse(identical_closure_test.myIdentical(35184372088832, 35184372088831));
    expect$.Expect.isFalse(identical_closure_test.myIdentical("hello", 41));
    let p = new identical_closure_test.Point(1, 1);
    let q = new identical_closure_test.Point(1, 1);
    expect$.Expect.isFalse(identical_closure_test.myIdentical(p, q));
    let a = "hello";
    let b = "hello";
    expect$.Expect.isTrue(identical_closure_test.myIdentical(a, b));
    expect$.Expect.isFalse(identical_closure_test.myIdentical(42, null));
    expect$.Expect.isTrue(identical_closure_test.myIdentical(null, null));
  };
  dart.fn(identical_closure_test.main, VoidTodynamic());
  // Exports:
  exports.identical_closure_test = identical_closure_test;
});
