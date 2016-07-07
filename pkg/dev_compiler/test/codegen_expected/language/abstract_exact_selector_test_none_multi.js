dart_library.library('language/abstract_exact_selector_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__abstract_exact_selector_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const abstract_exact_selector_test_none_multi = Object.create(null);
  const compiler_annotations = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  abstract_exact_selector_test_none_multi.Foo = class Foo extends core.Object {
    noSuchMethod(im) {
      return 42;
    }
  };
  abstract_exact_selector_test_none_multi.returnFoo = function() {
    dart.fn(() => 42, VoidToint())();
    return new abstract_exact_selector_test_none_multi.Foo();
  };
  dart.fn(abstract_exact_selector_test_none_multi.returnFoo, VoidTodynamic());
  abstract_exact_selector_test_none_multi.Bar = class Bar extends core.Object {
    ['=='](other) {
      return false;
    }
  };
  dart.defineLazy(abstract_exact_selector_test_none_multi, {
    get a() {
      return JSArrayOfObject().of([false, true, new core.Object(), new abstract_exact_selector_test_none_multi.Bar()]);
    },
    set a(_) {}
  });
  abstract_exact_selector_test_none_multi.main = function() {
    if (dart.test(abstract_exact_selector_test_none_multi.a[dartx.get](0))) {
      core.print(dart.equals(abstract_exact_selector_test_none_multi.returnFoo(), 42));
    } else {
      expect$.Expect.isFalse(dart.equals(abstract_exact_selector_test_none_multi.a[dartx.get](2), 42));
    }
  };
  dart.fn(abstract_exact_selector_test_none_multi.main, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.abstract_exact_selector_test_none_multi = abstract_exact_selector_test_none_multi;
  exports.compiler_annotations = compiler_annotations;
});
