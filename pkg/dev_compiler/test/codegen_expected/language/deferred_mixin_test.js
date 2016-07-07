dart_library.library('language/deferred_mixin_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__deferred_mixin_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const deferred_mixin_test = Object.create(null);
  const deferred_mixin_lib1 = Object.create(null);
  const deferred_mixin_shared = Object.create(null);
  const deferred_mixin_lib2 = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_mixin_test.NonDeferredMixin = class NonDeferredMixin extends core.Object {
    foo() {
      return "NonDeferredMixin";
    }
  };
  dart.setSignature(deferred_mixin_test.NonDeferredMixin, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  deferred_mixin_test.NonDeferredMixin1 = class NonDeferredMixin1 extends core.Object {
    foo() {
      return "NonDeferredMixin1";
    }
  };
  dart.setSignature(deferred_mixin_test.NonDeferredMixin1, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  deferred_mixin_test.NonDeferredMixin2 = class NonDeferredMixin2 extends core.Object {
    foo() {
      return "NonDeferredMixin2";
    }
  };
  dart.setSignature(deferred_mixin_test.NonDeferredMixin2, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  deferred_mixin_test.main = function() {
    expect$.Expect.equals("NonDeferredMixin", new deferred_mixin_test.NonDeferredMixin().foo());
    expect$.Expect.equals("NonDeferredMixin1", new deferred_mixin_test.NonDeferredMixin1().foo());
    expect$.Expect.equals("NonDeferredMixin2", new deferred_mixin_test.NonDeferredMixin2().foo());
    async_helper$.asyncStart();
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      expect$.Expect.equals("lib1.Mixin", new deferred_mixin_lib1.Mixin().foo());
      expect$.Expect.equals("A with NonDeferredMixin", new deferred_mixin_lib1.A().foo());
      expect$.Expect.equals("B with lib1.Mixin", new deferred_mixin_lib1.B().foo());
      expect$.Expect.equals("C with NonDeferredMixin1", new deferred_mixin_lib1.C().foo());
      expect$.Expect.equals("D with lib1.Mixin", new deferred_mixin_lib1.D().foo());
      expect$.Expect.equals("E with SharedMixin", new deferred_mixin_lib1.E().foo());
      loadLibrary().then(dart.dynamic)(dart.fn(_ => {
        expect$.Expect.equals("lib2.A with SharedMixin", new deferred_mixin_lib2.A().foo());
        async_helper$.asyncEnd();
      }, dynamicTodynamic()));
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_mixin_test.main, VoidTodynamic());
  deferred_mixin_lib1.Mixin = class Mixin extends core.Object {
    foo() {
      return "lib1.Mixin";
    }
  };
  dart.setSignature(deferred_mixin_lib1.Mixin, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  deferred_mixin_lib1.A = class A extends dart.mixin(core.Object, deferred_mixin_test.NonDeferredMixin) {
    foo() {
      return "A with " + dart.notNull(core.String._check(super.foo()));
    }
  };
  deferred_mixin_lib1.B = class B extends dart.mixin(core.Object, deferred_mixin_lib1.Mixin) {
    foo() {
      return "B with " + dart.notNull(core.String._check(super.foo()));
    }
  };
  deferred_mixin_lib1.C = class C extends dart.mixin(core.Object, deferred_mixin_lib1.Mixin, deferred_mixin_test.NonDeferredMixin1) {
    foo() {
      return "C with " + dart.notNull(core.String._check(super.foo()));
    }
  };
  deferred_mixin_lib1.D = class D extends dart.mixin(core.Object, deferred_mixin_test.NonDeferredMixin2, deferred_mixin_lib1.Mixin) {
    foo() {
      return "D with " + dart.notNull(core.String._check(super.foo()));
    }
  };
  deferred_mixin_shared.SharedMixin = class SharedMixin extends core.Object {
    foo() {
      return "SharedMixin";
    }
  };
  dart.setSignature(deferred_mixin_shared.SharedMixin, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  deferred_mixin_lib1.E = class E extends dart.mixin(core.Object, deferred_mixin_shared.SharedMixin) {
    foo() {
      return "E with " + dart.notNull(core.String._check(super.foo()));
    }
  };
  deferred_mixin_lib2.A = class A extends dart.mixin(core.Object, deferred_mixin_shared.SharedMixin) {
    foo() {
      return "lib2.A with " + dart.notNull(core.String._check(super.foo()));
    }
  };
  // Exports:
  exports.deferred_mixin_test = deferred_mixin_test;
  exports.deferred_mixin_lib1 = deferred_mixin_lib1;
  exports.deferred_mixin_shared = deferred_mixin_shared;
  exports.deferred_mixin_lib2 = deferred_mixin_lib2;
});
