dart_library.library('language/issue13673_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue13673_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue13673_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue13673_test.Bar = class Bar extends core.Object {
    new(field) {
      this.field = field;
    }
    foo() {
      return this.field;
    }
  };
  dart.setSignature(issue13673_test.Bar, {
    constructors: () => ({new: dart.definiteFunctionType(issue13673_test.Bar, [core.Type])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  dart.defineLazy(issue13673_test, {
    get topLevel() {
      return new issue13673_test.Bar(dart.wrapType(core.String)).foo();
    },
    set topLevel(_) {}
  });
  issue13673_test.main = function() {
    expect$.Expect.isTrue(core.Type.is(issue13673_test.topLevel));
  };
  dart.fn(issue13673_test.main, VoidTodynamic());
  // Exports:
  exports.issue13673_test = issue13673_test;
});
