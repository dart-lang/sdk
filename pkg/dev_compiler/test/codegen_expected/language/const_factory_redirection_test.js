dart_library.library('language/const_factory_redirection_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_factory_redirection_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_factory_redirection_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_factory_redirection_test.C = class C extends core.Object {
    static new(x) {
      return new const_factory_redirection_test.D(x);
    }
  };
  dart.setSignature(const_factory_redirection_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(const_factory_redirection_test.C, [core.int])})
  });
  const_factory_redirection_test.D = class D extends core.Object {
    new(i) {
      this.i = i;
    }
    m() {
      return 'called m';
    }
  };
  const_factory_redirection_test.D[dart.implements] = () => [const_factory_redirection_test.C];
  dart.setSignature(const_factory_redirection_test.D, {
    constructors: () => ({new: dart.definiteFunctionType(const_factory_redirection_test.D, [core.int])}),
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
  });
  let const$;
  const_factory_redirection_test.main = function() {
    let c = const$ || (const$ = dart.const(const_factory_redirection_test.C.new(42)));
    let d = const_factory_redirection_test.D._check(c);
    expect$.Expect.equals(42, d.i);
    expect$.Expect.equals('called m', d.m());
    d = const_factory_redirection_test.D._check(const_factory_redirection_test.C.new(42));
    expect$.Expect.equals(42, d.i);
    expect$.Expect.equals('called m', d.m());
  };
  dart.fn(const_factory_redirection_test.main, VoidTodynamic());
  // Exports:
  exports.const_factory_redirection_test = const_factory_redirection_test;
});
