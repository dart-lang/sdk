dart_library.library('language/identical_closure2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__identical_closure2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const identical_closure2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  identical_closure2_test.myIdentical = core.identical;
  identical_closure2_test.Point = class Point extends core.Object {
    new(x, y) {
      this.x = x;
      this.y = y;
    }
  };
  dart.setSignature(identical_closure2_test.Point, {
    constructors: () => ({new: dart.definiteFunctionType(identical_closure2_test.Point, [core.num, core.num])})
  });
  identical_closure2_test.main = function() {
    expect$.Expect.isTrue(identical_closure2_test.myIdentical(75557863725914323419136, 75557863725914323419136));
    expect$.Expect.isFalse(identical_closure2_test.myIdentical(75557863725914323419136, 75557863725914323419137));
    expect$.Expect.isFalse(identical_closure2_test.myIdentical(42, 42.0));
    expect$.Expect.isTrue(identical_closure2_test.myIdentical(core.double.NAN, core.double.NAN));
  };
  dart.fn(identical_closure2_test.main, VoidTodynamic());
  // Exports:
  exports.identical_closure2_test = identical_closure2_test;
});
