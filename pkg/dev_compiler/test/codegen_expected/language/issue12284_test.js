dart_library.library('language/issue12284_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue12284_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue12284_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidToA = () => (VoidToA = dart.constFn(dart.definiteFunctionType(issue12284_test.A, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue12284_test.A = class A extends core.Object {
    new(param) {
      this.field = null;
      let bar = dart.fn(() => 42, VoidToint());
      this.field = core.int._check(dart.dsend(param, '+', 42));
    }
    redirect() {
      A.prototype.new.call(this, 'foo');
    }
  };
  dart.defineNamedConstructor(issue12284_test.A, 'redirect');
  dart.setSignature(issue12284_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(issue12284_test.A, [dart.dynamic]),
      redirect: dart.definiteFunctionType(issue12284_test.A, [])
    })
  });
  issue12284_test.main = function() {
    expect$.Expect.equals(42 + 42, new issue12284_test.A(42).field);
    expect$.Expect.throws(dart.fn(() => new issue12284_test.A.redirect(), VoidToA()), dart.fn(e => core.ArgumentError.is(e) || core.TypeError.is(e) || core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(issue12284_test.main, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.issue12284_test = issue12284_test;
  exports.compiler_annotations = compiler_annotations;
});
