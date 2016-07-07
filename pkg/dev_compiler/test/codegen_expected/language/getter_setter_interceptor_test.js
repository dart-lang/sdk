dart_library.library('language/getter_setter_interceptor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getter_setter_interceptor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getter_setter_interceptor_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getter_setter_interceptor_test.A = class A extends core.Object {
    new() {
      this.length = 0;
    }
  };
  getter_setter_interceptor_test.B = class B extends core.Object {
    new() {
      this.length = 0;
    }
    foo(receiver) {
      this.length = dart.notNull(this.length) + 1;
      let x = dart.dload(receiver, 'length');
      dart.dput(receiver, 'length', dart.dsend(x, '+', 1));
      return x;
    }
    bar(receiver) {
      this.length = dart.notNull(this.length) + 1;
      return dart.dput(receiver, 'length', dart.dsend(dart.dload(receiver, 'length'), '+', 1));
    }
  };
  dart.setSignature(getter_setter_interceptor_test.B, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  getter_setter_interceptor_test.main = function() {
    let a = new getter_setter_interceptor_test.A();
    let b = new getter_setter_interceptor_test.B();
    let c = JSArrayOfint().of([1, 2, 3]);
    expect$.Expect.equals(3, b.foo(c));
    expect$.Expect.equals(5, b.bar(c));
    expect$.Expect.equals(5, c[dartx.length]);
    expect$.Expect.equals(0, b.foo(a));
    expect$.Expect.equals(2, b.bar(a));
    expect$.Expect.equals(2, a.length);
    expect$.Expect.equals(4, b.length);
  };
  dart.fn(getter_setter_interceptor_test.main, VoidTodynamic());
  // Exports:
  exports.getter_setter_interceptor_test = getter_setter_interceptor_test;
});
