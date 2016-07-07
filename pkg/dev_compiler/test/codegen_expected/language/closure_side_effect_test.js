dart_library.library('language/closure_side_effect_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_side_effect_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_side_effect_test = Object.create(null);
  let JSArrayOfC = () => (JSArrayOfC = dart.constFn(_interceptors.JSArray$(closure_side_effect_test.C)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_side_effect_test.b = null;
  dart.defineLazy(closure_side_effect_test, {
    get a() {
      return dart.fn(() => {
        closure_side_effect_test.b = 42;
      }, VoidTodynamic());
    },
    set a(_) {}
  });
  dart.defineLazy(closure_side_effect_test, {
    get c() {
      return JSArrayOfC().of([new closure_side_effect_test.C()]);
    },
    set c(_) {}
  });
  closure_side_effect_test.C = class C extends core.Object {
    nonInlinable1() {
      closure_side_effect_test.a();
    }
    nonInlinable2() {
      let a = dart.fn(() => {
        closure_side_effect_test.b = 42;
      }, VoidTodynamic());
      a();
    }
  };
  dart.setSignature(closure_side_effect_test.C, {
    methods: () => ({
      nonInlinable1: dart.definiteFunctionType(dart.dynamic, []),
      nonInlinable2: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  closure_side_effect_test.testClosureInStaticField = function() {
    let temp = closure_side_effect_test.c[dartx.get](0);
    expect$.Expect.isNull(closure_side_effect_test.b);
    temp.nonInlinable1();
    expect$.Expect.equals(42, closure_side_effect_test.b);
    closure_side_effect_test.b = null;
  };
  dart.fn(closure_side_effect_test.testClosureInStaticField, VoidTodynamic());
  closure_side_effect_test.testLocalClosure = function() {
    let temp = closure_side_effect_test.c[dartx.get](0);
    expect$.Expect.isNull(closure_side_effect_test.b);
    temp.nonInlinable2();
    expect$.Expect.equals(42, closure_side_effect_test.b);
  };
  dart.fn(closure_side_effect_test.testLocalClosure, VoidTodynamic());
  closure_side_effect_test.main = function() {
    closure_side_effect_test.testClosureInStaticField();
    closure_side_effect_test.testLocalClosure();
  };
  dart.fn(closure_side_effect_test.main, VoidTodynamic());
  // Exports:
  exports.closure_side_effect_test = closure_side_effect_test;
});
