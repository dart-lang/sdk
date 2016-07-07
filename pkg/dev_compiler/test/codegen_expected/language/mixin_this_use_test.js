dart_library.library('language/mixin_this_use_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_this_use_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_this_use_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_this_use_test.A = class A extends core.Object {
    foo() {
      return this.bar();
    }
    bar() {
      return 42;
    }
  };
  dart.setSignature(mixin_this_use_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  mixin_this_use_test.B = class B extends core.Object {};
  mixin_this_use_test.C = class C extends dart.mixin(mixin_this_use_test.B, mixin_this_use_test.A) {
    new() {
      super.new();
    }
  };
  mixin_this_use_test.D = class D extends mixin_this_use_test.C {
    bar() {
      return 54;
    }
  };
  mixin_this_use_test.E = class E extends mixin_this_use_test.A {
    bar() {
      return 68;
    }
  };
  mixin_this_use_test.main = function() {
    expect$.Expect.equals(54, new mixin_this_use_test.D().foo());
    expect$.Expect.equals(68, new mixin_this_use_test.E().foo());
  };
  dart.fn(mixin_this_use_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_this_use_test = mixin_this_use_test;
});
