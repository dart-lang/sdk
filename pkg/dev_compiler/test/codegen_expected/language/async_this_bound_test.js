dart_library.library('language/async_this_bound_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_this_bound_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_this_bound_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  async_this_bound_test.A = class A extends core.Object {
    new() {
      this.a = -1;
    }
    foo(ignored, val) {
      expect$.Expect.equals(val, this.a);
    }
  };
  dart.setSignature(async_this_bound_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])})
  });
  async_this_bound_test.testA = function() {
    return dart.async(function*() {
      let a = new async_this_bound_test.A();
      a.foo(yield false, -1);
      a.a = 0;
      a.foo(yield false, 0);
    }, dart.dynamic);
  };
  dart.fn(async_this_bound_test.testA, VoidTodynamic());
  async_this_bound_test.confuse = function(x) {
    return x;
  };
  dart.fn(async_this_bound_test.confuse, dynamicTodynamic());
  async_this_bound_test.B = class B extends core.Object {
    new(f) {
      this.f = f;
      this.b = 10;
    }
    bar(x) {
      return this.b;
    }
  };
  dart.setSignature(async_this_bound_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(async_this_bound_test.B, [dart.dynamic])}),
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  async_this_bound_test.foo = function(x) {
    return 499;
  };
  dart.fn(async_this_bound_test.foo, dynamicTodynamic());
  async_this_bound_test.bar = function(x) {
    return 42;
  };
  dart.fn(async_this_bound_test.bar, dynamicTodynamic());
  async_this_bound_test.change = function(x) {
    dart.dput(x, 'f', dart.fn(x => 99, dynamicToint()));
  };
  dart.fn(async_this_bound_test.change, dynamicTodynamic());
  async_this_bound_test.testB = function() {
    return dart.async(function*() {
      let b = async_this_bound_test.confuse(new async_this_bound_test.B(async_this_bound_test.foo));
      expect$.Expect.equals(99, dart.dsend(b, 'f', yield async_this_bound_test.change(b)));
      let b2 = async_this_bound_test.confuse(new async_this_bound_test.B(async_this_bound_test.bar));
      expect$.Expect.equals(10, dart.dsend(b2, 'f', yield dart.dput(b2, 'f', dart.dload(b2, 'bar'))));
    }, dart.dynamic);
  };
  dart.fn(async_this_bound_test.testB, VoidTodynamic());
  async_this_bound_test.test = function() {
    return dart.async(function*() {
      yield async_this_bound_test.testA();
      yield async_this_bound_test.testB();
    }, dart.dynamic);
  };
  dart.fn(async_this_bound_test.test, VoidTodynamic());
  async_this_bound_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_this_bound_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_this_bound_test.main, VoidTovoid());
  // Exports:
  exports.async_this_bound_test = async_this_bound_test;
});
