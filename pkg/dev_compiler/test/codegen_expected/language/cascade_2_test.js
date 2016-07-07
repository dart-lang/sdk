dart_library.library('language/cascade_2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cascade_2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cascade_2_test = Object.create(null);
  let JSArrayOfElement = () => (JSArrayOfElement = dart.constFn(_interceptors.JSArray$(cascade_2_test.Element)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cascade_2_test.main = function() {
    let a = new cascade_2_test.Element(null);
    expect$.Expect.equals(1, a.path0[dartx.length]);
    expect$.Expect.equals(a, a.path0[dartx.get](0));
    expect$.Expect.equals(2, a.path1[dartx.length]);
    expect$.Expect.equals(a, a.path1[dartx.get](0));
    expect$.Expect.equals(a, a.path1[dartx.get](1));
    expect$.Expect.equals(1, a.path2[dartx.length]);
    let b = new cascade_2_test.Element(a);
    expect$.Expect.equals(2, b.path0[dartx.length]);
    expect$.Expect.equals(a, b.path0[dartx.get](0));
    expect$.Expect.equals(b, b.path0[dartx.get](1));
    expect$.Expect.equals(3, b.path1[dartx.length]);
    expect$.Expect.equals(a, b.path1[dartx.get](0));
    expect$.Expect.equals(a, b.path1[dartx.get](1));
    expect$.Expect.equals(b, b.path1[dartx.get](2));
    expect$.Expect.equals(2, b.path2[dartx.length]);
  };
  dart.fn(cascade_2_test.main, VoidTodynamic());
  cascade_2_test.Element = class Element extends core.Object {
    new(parent) {
      this.parent = parent;
    }
    get path0() {
      if (this.parent == null) {
        return JSArrayOfElement().of([this]);
      } else {
        let _ = this.parent.path0;
        _[dartx.add](this);
        return _;
      }
    }
    get path1() {
      let _ = this.parent == null ? JSArrayOfElement().of([this]) : this.parent.path1;
      _[dartx.add](this);
      return _;
    }
    get path2() {
      return this.parent == null ? JSArrayOfElement().of([this]) : (() => {
        let _ = this.parent.path2;
        _[dartx.add](this);
        return _;
      })();
    }
  };
  dart.setSignature(cascade_2_test.Element, {
    constructors: () => ({new: dart.definiteFunctionType(cascade_2_test.Element, [cascade_2_test.Element])})
  });
  // Exports:
  exports.cascade_2_test = cascade_2_test;
});
