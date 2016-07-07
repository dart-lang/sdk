dart_library.library('language/instance_incr_deopt_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instance_incr_deopt_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instance_incr_deopt_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  instance_incr_deopt_test.main = function() {
    let a = new instance_incr_deopt_test.A();
    let aa = new instance_incr_deopt_test.A();
    for (let i = 0; i < 20; i++) {
      a.Incr();
      instance_incr_deopt_test.myIncr(aa);
      instance_incr_deopt_test.conditionalIncr(false, a);
    }
    expect$.Expect.equals(20, a.f);
    expect$.Expect.equals(20, aa.f);
    a.f = 1.0;
    a.Incr();
    expect$.Expect.equals(2.0, a.f);
    let b = new instance_incr_deopt_test.B();
    instance_incr_deopt_test.myIncr(b);
    expect$.Expect.equals(1.0, b.f);
    let old = a.f;
    instance_incr_deopt_test.conditionalIncr(true, a);
    expect$.Expect.equals(dart.dsend(old, '+', 1), a.f);
  };
  dart.fn(instance_incr_deopt_test.main, VoidTodynamic());
  instance_incr_deopt_test.myIncr = function(a) {
    dart.dput(a, 'f', dart.dsend(dart.dload(a, 'f'), '+', 1));
  };
  dart.fn(instance_incr_deopt_test.myIncr, dynamicTodynamic());
  instance_incr_deopt_test.conditionalIncr = function(f, a) {
    if (dart.test(f)) {
      dart.dput(a, 'f', dart.dsend(dart.dload(a, 'f'), '+', 1));
    }
  };
  dart.fn(instance_incr_deopt_test.conditionalIncr, dynamicAnddynamicTodynamic());
  instance_incr_deopt_test.A = class A extends core.Object {
    new() {
      this.f = 0;
    }
    Incr() {
      this.f = dart.dsend(this.f, '+', 1);
    }
  };
  dart.setSignature(instance_incr_deopt_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(instance_incr_deopt_test.A, [])}),
    methods: () => ({Incr: dart.definiteFunctionType(dart.dynamic, [])})
  });
  instance_incr_deopt_test.B = class B extends core.Object {
    new() {
      this.f = 0;
    }
  };
  dart.setSignature(instance_incr_deopt_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(instance_incr_deopt_test.B, [])})
  });
  // Exports:
  exports.instance_incr_deopt_test = instance_incr_deopt_test;
});
