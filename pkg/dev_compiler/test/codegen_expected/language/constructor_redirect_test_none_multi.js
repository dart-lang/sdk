dart_library.library('language/constructor_redirect_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor_redirect_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_redirect_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_redirect_test_none_multi.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
    named(x, y) {
      A.prototype.new.call(this, dart.dsend(x, '+', y));
    }
    named2(x, y, z) {
      A.prototype.named.call(this, constructor_redirect_test_none_multi.A.staticFun(x, y), core.int._check(z));
    }
    static staticFun(v1, v2) {
      return dart.notNull(v1) * dart.notNull(v2);
    }
  };
  dart.defineNamedConstructor(constructor_redirect_test_none_multi.A, 'named');
  dart.defineNamedConstructor(constructor_redirect_test_none_multi.A, 'named2');
  dart.setSignature(constructor_redirect_test_none_multi.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_redirect_test_none_multi.A, [dart.dynamic]),
      named: dart.definiteFunctionType(constructor_redirect_test_none_multi.A, [dart.dynamic, core.int]),
      named2: dart.definiteFunctionType(constructor_redirect_test_none_multi.A, [core.int, core.int, dart.dynamic])
    }),
    statics: () => ({staticFun: dart.definiteFunctionType(core.int, [core.int, core.int])}),
    names: ['staticFun']
  });
  constructor_redirect_test_none_multi.B = class B extends constructor_redirect_test_none_multi.A {
    new(y) {
      super.new(dart.dsend(y, '+', 1));
    }
    named(y) {
      super.named(y, core.int._check(dart.dsend(y, '+', 1)));
    }
  };
  dart.defineNamedConstructor(constructor_redirect_test_none_multi.B, 'named');
  dart.setSignature(constructor_redirect_test_none_multi.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_redirect_test_none_multi.B, [dart.dynamic]),
      named: dart.definiteFunctionType(constructor_redirect_test_none_multi.B, [dart.dynamic])
    })
  });
  constructor_redirect_test_none_multi.C = class C extends core.Object {
    new(x) {
      this.x = x;
    }
    named(x, y) {
      C.prototype.new.call(this, dart.dsend(x, '+', y));
    }
  };
  dart.defineNamedConstructor(constructor_redirect_test_none_multi.C, 'named');
  dart.setSignature(constructor_redirect_test_none_multi.C, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_redirect_test_none_multi.C, [dart.dynamic]),
      named: dart.definiteFunctionType(constructor_redirect_test_none_multi.C, [dart.dynamic, core.int])
    })
  });
  constructor_redirect_test_none_multi.D = class D extends constructor_redirect_test_none_multi.C {
    new(y) {
      super.new(dart.dsend(y, '+', 1));
    }
    named(y) {
      super.named(y, core.int._check(dart.dsend(y, '+', 1)));
    }
  };
  dart.defineNamedConstructor(constructor_redirect_test_none_multi.D, 'named');
  dart.setSignature(constructor_redirect_test_none_multi.D, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_redirect_test_none_multi.D, [dart.dynamic]),
      named: dart.definiteFunctionType(constructor_redirect_test_none_multi.D, [dart.dynamic])
    })
  });
  let const$;
  let const$0;
  let const$1;
  let const$2;
  constructor_redirect_test_none_multi.ConstructorRedirectTest = class ConstructorRedirectTest extends core.Object {
    static testMain() {
      let a = new constructor_redirect_test_none_multi.A(499);
      expect$.Expect.equals(499, a.x);
      a = new constructor_redirect_test_none_multi.A.named(349, 499);
      expect$.Expect.equals(349 + 499, a.x);
      a = new constructor_redirect_test_none_multi.A.named2(11, 42, 99);
      expect$.Expect.equals(11 * 42 + 99, a.x);
      let b = new constructor_redirect_test_none_multi.B(498);
      expect$.Expect.equals(499, b.x);
      b = new constructor_redirect_test_none_multi.B.named(249);
      expect$.Expect.equals(499, b.x);
      let c = const$ || (const$ = dart.const(new constructor_redirect_test_none_multi.C(499)));
      expect$.Expect.equals(499, c.x);
      c = const$0 || (const$0 = dart.const(new constructor_redirect_test_none_multi.C.named(249, 250)));
      expect$.Expect.equals(499, c.x);
      let d = const$1 || (const$1 = dart.const(new constructor_redirect_test_none_multi.D(498)));
      expect$.Expect.equals(499, d.x);
      d = const$2 || (const$2 = dart.const(new constructor_redirect_test_none_multi.D.named(249)));
      expect$.Expect.equals(499, d.x);
    }
  };
  dart.setSignature(constructor_redirect_test_none_multi.ConstructorRedirectTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  constructor_redirect_test_none_multi.main = function() {
    constructor_redirect_test_none_multi.ConstructorRedirectTest.testMain();
  };
  dart.fn(constructor_redirect_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor_redirect_test_none_multi = constructor_redirect_test_none_multi;
});
