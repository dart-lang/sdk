dart_library.library('language/if_null_assignment_static_test_22_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__if_null_assignment_static_test_22_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const if_null_assignment_static_test_22_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.copyProperties(if_null_assignment_static_test_22_multi, {
    get checkedMode() {
      let checked = false;
      dart.assert(checked = true);
      return checked;
    }
  });
  if_null_assignment_static_test_22_multi.noMethod = function(e) {
    return core.NoSuchMethodError.is(e);
  };
  dart.fn(if_null_assignment_static_test_22_multi.noMethod, dynamicTodynamic());
  if_null_assignment_static_test_22_multi.bad = function() {
    expect$.Expect.fail('Should not be executed');
  };
  dart.fn(if_null_assignment_static_test_22_multi.bad, VoidTodynamic());
  if_null_assignment_static_test_22_multi.A = class A extends core.Object {
    new() {
      this.a = null;
    }
  };
  if_null_assignment_static_test_22_multi.B = class B extends if_null_assignment_static_test_22_multi.A {
    new() {
      this.b = null;
      super.new();
    }
  };
  if_null_assignment_static_test_22_multi.C = class C extends if_null_assignment_static_test_22_multi.A {
    new() {
      this.c = null;
      super.new();
    }
  };
  dart.copyProperties(if_null_assignment_static_test_22_multi, {
    get a() {
      return null;
    },
    set a(value) {}
  });
  dart.copyProperties(if_null_assignment_static_test_22_multi, {
    get b() {
      return null;
    },
    set b(value) {}
  });
  if_null_assignment_static_test_22_multi.ClassWithStaticGetters = class ClassWithStaticGetters extends core.Object {
    static get a() {
      return null;
    }
    static set a(value) {}
    static get b() {
      return null;
    }
    static set b(value) {}
  };
  if_null_assignment_static_test_22_multi.ClassWithInstanceGetters = class ClassWithInstanceGetters extends core.Object {
    get a() {
      return null;
    }
    set a(value) {}
    get b() {
      return null;
    }
    set b(value) {}
  };
  if_null_assignment_static_test_22_multi.DerivedClass = class DerivedClass extends if_null_assignment_static_test_22_multi.ClassWithInstanceGetters {
    get a() {
      return if_null_assignment_static_test_22_multi.A._check(if_null_assignment_static_test_22_multi.bad());
    }
    set a(value) {
      if_null_assignment_static_test_22_multi.bad();
    }
    get b() {
      return if_null_assignment_static_test_22_multi.B._check(if_null_assignment_static_test_22_multi.bad());
    }
    set b(value) {
      if_null_assignment_static_test_22_multi.bad();
    }
    derivedTest() {
      if (!dart.test(if_null_assignment_static_test_22_multi.checkedMode)) {
      }
    }
  };
  dart.setSignature(if_null_assignment_static_test_22_multi.DerivedClass, {
    methods: () => ({derivedTest: dart.definiteFunctionType(dart.void, [])})
  });
  if_null_assignment_static_test_22_multi.main = function() {
    let _ = null;
    let t = _;
    t == null ? _ = null : t;
    new if_null_assignment_static_test_22_multi.DerivedClass().derivedTest();
    if (!dart.test(if_null_assignment_static_test_22_multi.checkedMode)) {
    }
    if (!dart.test(if_null_assignment_static_test_22_multi.checkedMode)) {
    }
    (() => {
      let o = new if_null_assignment_static_test_22_multi.ClassWithInstanceGetters(), t = o.a;
      return t == null ? o.a = new if_null_assignment_static_test_22_multi.A() : t;
    })().a;
    if (!dart.test(if_null_assignment_static_test_22_multi.checkedMode)) {
    }
    if (!dart.test(if_null_assignment_static_test_22_multi.checkedMode)) {
    }
    if (!dart.test(if_null_assignment_static_test_22_multi.checkedMode)) {
    }
  };
  dart.fn(if_null_assignment_static_test_22_multi.main, VoidTodynamic());
  // Exports:
  exports.if_null_assignment_static_test_22_multi = if_null_assignment_static_test_22_multi;
});
