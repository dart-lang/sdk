dart_library.library('language/call_operator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__call_operator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const call_operator_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  call_operator_test.A1 = dart.callableClass(function A1(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A1 extends core.Object {
    call() {
      return 42;
    }
  });
  dart.setSignature(call_operator_test.A1, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [])})
  });
  call_operator_test.A2 = dart.callableClass(function A2(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A2 extends core.Object {
    call() {
      return 35;
    }
  });
  dart.setSignature(call_operator_test.A2, {
    methods: () => ({call: dart.definiteFunctionType(core.int, [])})
  });
  call_operator_test.B = dart.callableClass(function B(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class B extends core.Object {
    call() {
      return 28;
    }
  });
  dart.setSignature(call_operator_test.B, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [])})
  });
  call_operator_test.C = dart.callableClass(function C(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class C extends core.Object {
    call(arg) {
      return 7 * dart.notNull(core.num._check(arg));
    }
  });
  dart.setSignature(call_operator_test.C, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  call_operator_test.D = dart.callableClass(function D(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class D extends core.Object {
    call(arg) {
      if (arg === void 0) arg = 6;
      return 7 * dart.notNull(core.num._check(arg));
    }
  });
  dart.setSignature(call_operator_test.D, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])})
  });
  call_operator_test.E = dart.callableClass(function E(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class E extends core.Object {
    call(str, opts) {
      let count = opts && 'count' in opts ? opts.count : 1;
      let buffer = new core.StringBuffer();
      for (let i = 0; i < dart.notNull(count); i++) {
        buffer.write(str);
        if (i < dart.notNull(count) - 1) {
          buffer.write(":");
        }
      }
      return buffer.toString();
    }
  });
  dart.setSignature(call_operator_test.E, {
    methods: () => ({call: dart.definiteFunctionType(core.String, [core.String], {count: core.int})})
  });
  call_operator_test.main = function() {
    let a1 = new call_operator_test.A1();
    expect$.Expect.equals(42, a1());
    expect$.Expect.equals(42, a1.call());
    let a2 = new call_operator_test.A2();
    expect$.Expect.equals(35, a2());
    expect$.Expect.equals(35, a2.call());
    let b = new call_operator_test.B();
    expect$.Expect.equals(28, b());
    expect$.Expect.equals(28, b.call());
    let c = new call_operator_test.C();
    expect$.Expect.equals(42, dart.dcall(c, 6));
    expect$.Expect.equals(42, c.call(6));
    let d = new call_operator_test.D();
    expect$.Expect.equals(42, dart.dcall(d));
    expect$.Expect.equals(7, dart.dcall(d, 1));
    expect$.Expect.equals(14, dart.dcall(d, 2));
    expect$.Expect.equals(42, d.call());
    expect$.Expect.equals(7, d.call(1));
    expect$.Expect.equals(14, d.call(2));
    let e = new call_operator_test.E();
    expect$.Expect.equals("foo", e("foo"));
    expect$.Expect.equals("foo:foo", e("foo", {count: 2}));
    expect$.Expect.equals("foo:foo:foo", e("foo", {count: 3}));
    expect$.Expect.equals("foo", e.call("foo"));
    expect$.Expect.equals("foo:foo", e.call("foo", {count: 2}));
    expect$.Expect.equals("foo:foo:foo", e.call("foo", {count: 3}));
    expect$.Expect.isTrue(core.Function.is(a1));
    expect$.Expect.isTrue(core.Function.is(e));
  };
  dart.fn(call_operator_test.main, VoidTodynamic());
  // Exports:
  exports.call_operator_test = call_operator_test;
});
