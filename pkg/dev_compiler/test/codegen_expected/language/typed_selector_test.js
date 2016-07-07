dart_library.library('language/typed_selector_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typed_selector_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_selector_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  typed_selector_test.A = class A extends core.Object {
    get document() {
      return 42;
    }
  };
  typed_selector_test.B = class B extends core.Object {};
  typed_selector_test.C = class C extends typed_selector_test.A {};
  typed_selector_test.C[dart.implements] = () => [typed_selector_test.B];
  typed_selector_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(typed_selector_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(typed_selector_test.inscrutable, intToint());
  typed_selector_test.main = function() {
    let tab = JSArrayOfObject().of([new core.Object(), new typed_selector_test.C()]);
    let obj = tab[dartx.get](typed_selector_test.inscrutable(1));
    let res = 0;
    if (typed_selector_test.B.is(obj)) res = core.int._check(obj.document);
    expect$.Expect.equals(42, res);
  };
  dart.fn(typed_selector_test.main, VoidTovoid());
  // Exports:
  exports.typed_selector_test = typed_selector_test;
});
