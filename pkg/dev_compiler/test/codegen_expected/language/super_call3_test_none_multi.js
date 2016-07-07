dart_library.library('language/super_call3_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_call3_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_call3_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_call3_test_none_multi.A = class A extends core.Object {
    new() {
      this.foo = 499;
    }
  };
  dart.setSignature(super_call3_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(super_call3_test_none_multi.A, [])})
  });
  super_call3_test_none_multi.B = class B extends super_call3_test_none_multi.A {
    new() {
      super.new();
    }
  };
  super_call3_test_none_multi.B2 = class B2 extends super_call3_test_none_multi.A {
    new() {
      this.x = null;
      super.new();
    }
    named() {
      this.x = 499;
      super.new();
    }
  };
  dart.defineNamedConstructor(super_call3_test_none_multi.B2, 'named');
  dart.setSignature(super_call3_test_none_multi.B2, {
    constructors: () => ({
      new: dart.definiteFunctionType(super_call3_test_none_multi.B2, []),
      named: dart.definiteFunctionType(super_call3_test_none_multi.B2, [])
    })
  });
  super_call3_test_none_multi.C = class C extends core.Object {
    new() {
      this.foo = 499;
    }
  };
  dart.setSignature(super_call3_test_none_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(super_call3_test_none_multi.C, [])})
  });
  super_call3_test_none_multi.D = class D extends super_call3_test_none_multi.C {
    new() {
      super.new();
    }
  };
  super_call3_test_none_multi.D2 = class D2 extends super_call3_test_none_multi.C {
    new() {
      this.x = null;
      super.new();
    }
    named() {
      this.x = 499;
      super.new();
    }
  };
  dart.defineNamedConstructor(super_call3_test_none_multi.D2, 'named');
  dart.setSignature(super_call3_test_none_multi.D2, {
    constructors: () => ({
      new: dart.definiteFunctionType(super_call3_test_none_multi.D2, []),
      named: dart.definiteFunctionType(super_call3_test_none_multi.D2, [])
    })
  });
  super_call3_test_none_multi.main = function() {
    expect$.Expect.equals(499, new super_call3_test_none_multi.B().foo);
    expect$.Expect.equals(499, new super_call3_test_none_multi.B2().foo);
    expect$.Expect.equals(499, new super_call3_test_none_multi.B2.named().foo);
    expect$.Expect.equals(499, new super_call3_test_none_multi.D().foo);
    expect$.Expect.equals(499, new super_call3_test_none_multi.D2().foo);
    expect$.Expect.equals(499, new super_call3_test_none_multi.D2.named().foo);
  };
  dart.fn(super_call3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.super_call3_test_none_multi = super_call3_test_none_multi;
});
