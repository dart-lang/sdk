dart_library.library('language/abstract_object_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__abstract_object_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const abstract_object_method_test = Object.create(null);
  let JSArrayOfC = () => (JSArrayOfC = dart.constFn(_interceptors.JSArray$(abstract_object_method_test.C)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  abstract_object_method_test.A = class A extends core.Object {
    noSuchMethod(_) {
      expect$.Expect.fail('Should not reach here');
    }
  };
  abstract_object_method_test.B = class B extends abstract_object_method_test.A {};
  abstract_object_method_test.C = class C extends abstract_object_method_test.B {};
  dart.defineLazy(abstract_object_method_test, {
    get a() {
      return JSArrayOfC().of([new abstract_object_method_test.C()]);
    },
    set a(_) {}
  });
  abstract_object_method_test.main = function() {
    let c = abstract_object_method_test.a[dartx.get](0);
    abstract_object_method_test.a[dartx.add](c);
    expect$.Expect.isTrue(dart.equals(c, abstract_object_method_test.a[dartx.get](1)));
  };
  dart.fn(abstract_object_method_test.main, VoidTodynamic());
  // Exports:
  exports.abstract_object_method_test = abstract_object_method_test;
});
