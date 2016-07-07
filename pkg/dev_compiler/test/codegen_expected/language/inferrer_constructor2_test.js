dart_library.library('language/inferrer_constructor2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inferrer_constructor2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inferrer_constructor2_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  inferrer_constructor2_test.A = class A extends core.Object {
    new() {
      this.foo = null;
      this.bar = null;
      this.bar = dart.fn(() => 42, VoidToint());
      this.foo = 54;
    }
    inline() {
      this.foo = null;
      this.bar = null;
    }
  };
  dart.defineNamedConstructor(inferrer_constructor2_test.A, 'inline');
  dart.setSignature(inferrer_constructor2_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(inferrer_constructor2_test.A, []),
      inline: dart.definiteFunctionType(inferrer_constructor2_test.A, [])
    })
  });
  inferrer_constructor2_test.main = function() {
    new inferrer_constructor2_test.A();
    inferrer_constructor2_test.bar();
    new inferrer_constructor2_test.A();
  };
  dart.fn(inferrer_constructor2_test.main, VoidTodynamic());
  inferrer_constructor2_test.B = class B extends core.Object {
    new() {
      this.bar = null;
      this.closure = null;
      this.closure = dart.fn(() => 42, VoidToint());
      this.bar = new inferrer_constructor2_test.A().foo;
    }
  };
  dart.setSignature(inferrer_constructor2_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_constructor2_test.B, [])})
  });
  inferrer_constructor2_test.bar = function() {
    new inferrer_constructor2_test.B();
    expect$.Expect.throws(dart.fn(() => dart.dsend(new inferrer_constructor2_test.A.inline().foo, '+', 42), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    inferrer_constructor2_test.codegenLast();
    new inferrer_constructor2_test.B();
  };
  dart.fn(inferrer_constructor2_test.bar, VoidTodynamic());
  inferrer_constructor2_test.codegenLast = function() {
    new inferrer_constructor2_test.A().foo = new inferrer_constructor2_test.B().bar;
    new inferrer_constructor2_test.B().closure = dart.fn(() => 42, VoidToint());
  };
  dart.fn(inferrer_constructor2_test.codegenLast, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.inferrer_constructor2_test = inferrer_constructor2_test;
  exports.compiler_annotations = compiler_annotations;
});
