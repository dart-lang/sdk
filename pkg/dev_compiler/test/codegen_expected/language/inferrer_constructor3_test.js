dart_library.library('language/inferrer_constructor3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inferrer_constructor3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inferrer_constructor3_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  inferrer_constructor3_test.A = class A extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(inferrer_constructor3_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_constructor3_test.A, [dart.dynamic])})
  });
  dart.defineLazy(inferrer_constructor3_test, {
    get c() {
      return dart.fn(() => core.List.new(42)[dartx.get](0), VoidTodynamic());
    },
    set c(_) {}
  });
  inferrer_constructor3_test.main = function() {
    inferrer_constructor3_test.bar();
    new inferrer_constructor3_test.A(inferrer_constructor3_test.c());
    inferrer_constructor3_test.doIt();
    inferrer_constructor3_test.bar();
  };
  dart.fn(inferrer_constructor3_test.main, VoidTodynamic());
  inferrer_constructor3_test.doIt = function() {
    dart.fn(() => 42, VoidToint());
    let c = new inferrer_constructor3_test.A(null);
    expect$.Expect.throws(dart.fn(() => dart.dsend(c.field, '+', 42), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(inferrer_constructor3_test.doIt, VoidTodynamic());
  inferrer_constructor3_test.bar = function() {
    dart.fn(() => 42, VoidToint());
    return inferrer_constructor3_test.inlineLevel1();
  };
  dart.fn(inferrer_constructor3_test.bar, VoidTodynamic());
  inferrer_constructor3_test.inlineLevel1 = function() {
    return inferrer_constructor3_test.inlineLevel2();
  };
  dart.fn(inferrer_constructor3_test.inlineLevel1, VoidTodynamic());
  inferrer_constructor3_test.inlineLevel2 = function() {
    return inferrer_constructor3_test.inlineLevel3();
  };
  dart.fn(inferrer_constructor3_test.inlineLevel2, VoidTodynamic());
  inferrer_constructor3_test.inlineLevel3 = function() {
    return inferrer_constructor3_test.inlineLevel4();
  };
  dart.fn(inferrer_constructor3_test.inlineLevel3, VoidTodynamic());
  inferrer_constructor3_test.inlineLevel4 = function() {
    return new inferrer_constructor3_test.A(42);
  };
  dart.fn(inferrer_constructor3_test.inlineLevel4, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.inferrer_constructor3_test = inferrer_constructor3_test;
  exports.compiler_annotations = compiler_annotations;
});
