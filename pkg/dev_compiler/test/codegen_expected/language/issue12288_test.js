dart_library.library('language/issue12288_test', null, /* Imports */[
  'dart_sdk'
], function load__issue12288_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue12288_test = Object.create(null);
  let JSArrayOfElement = () => (JSArrayOfElement = dart.constFn(_interceptors.JSArray$(issue12288_test.Element)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue12288_test.main = function() {
    let parent = new issue12288_test.Element(null);
    let child = new issue12288_test.Element(parent);
    let result = child.path0[dartx.length];
    if (result != 2) {
      dart.throw(dart.str`Expected 2, but child.path0.length was ${result}`);
    }
  };
  dart.fn(issue12288_test.main, VoidTodynamic());
  issue12288_test.Element = class Element extends core.Object {
    new(parent) {
      this.parent = parent;
    }
    get path0() {
      if (this.parent == null) {
        return JSArrayOfElement().of([this]);
      } else {
        let list = this.parent.path0;
        list[dartx.add](this);
        return list;
      }
    }
  };
  dart.setSignature(issue12288_test.Element, {
    constructors: () => ({new: dart.definiteFunctionType(issue12288_test.Element, [issue12288_test.Element])})
  });
  // Exports:
  exports.issue12288_test = issue12288_test;
});
