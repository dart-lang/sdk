dart_library.library('language/abstract_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__abstract_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const abstract_method_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(abstract_method_test, {
    get length() {
      return dart.throw("error: top-level getter called");
    }
  });
  dart.copyProperties(abstract_method_test, {
    set height(x) {
      dart.throw("error: top-level setter called");
    }
  });
  abstract_method_test.width = function() {
    dart.throw("error: top-level function called");
  };
  dart.fn(abstract_method_test.width, VoidTodynamic());
  abstract_method_test.A = class A extends core.Object {
    get useLength() {
      return this.length;
    }
    setHeight(x) {
      return this.height = x;
    }
    useWidth() {
      return this.width();
    }
  };
  dart.setSignature(abstract_method_test.A, {
    methods: () => ({
      setHeight: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      useWidth: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  abstract_method_test.A1 = class A1 extends abstract_method_test.A {
    width() {
      return 345;
    }
    new(length) {
      this.length = length;
      this.height = null;
    }
  };
  dart.setSignature(abstract_method_test.A1, {
    constructors: () => ({new: dart.definiteFunctionType(abstract_method_test.A1, [core.int])}),
    methods: () => ({width: dart.definiteFunctionType(core.int, [])})
  });
  abstract_method_test.main = function() {
    let a = new abstract_method_test.A1(123);
    expect$.Expect.equals(123, a.useLength);
    a.setHeight(234);
    expect$.Expect.equals(234, a.height);
    expect$.Expect.equals(345, a.useWidth());
    core.print([a.useLength, a.height, a.useWidth()]);
  };
  dart.fn(abstract_method_test.main, VoidTodynamic());
  // Exports:
  exports.abstract_method_test = abstract_method_test;
});
