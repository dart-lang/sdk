dart_library.library('corelib/expression_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__expression_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const expression_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  expression_test.ExpressionTest = class ExpressionTest extends core.Object {
    new() {
      this.foo = null;
    }
    static testMain() {
      let test = new expression_test.ExpressionTest();
      test.testBinary();
      test.testUnary();
      test.testShifts();
      test.testBitwise();
      test.testIncrement();
      test.testMangling();
    }
    testBinary() {
      let x = 4, y = 2;
      expect$.Expect.equals(6, x + y);
      expect$.Expect.equals(2, x - y);
      expect$.Expect.equals(8, x * y);
      expect$.Expect.equals(2, x / y);
      expect$.Expect.equals(0, x[dartx['%']](y));
    }
    testUnary() {
      let x = 4, y = 2, z = -5;
      let t = true, f = false;
      expect$.Expect.equals(-4, -x);
      expect$.Expect.equals(4, ~z >>> 0);
      expect$.Expect.equals(f, !t);
    }
    testShifts() {
      let x = 4, y = 2;
      expect$.Expect.equals(y, x[dartx['>>']](1));
      expect$.Expect.equals(x, y << 1 >>> 0);
    }
    testBitwise() {
      let x = 4, y = 2;
      expect$.Expect.equals(6, (x | y) >>> 0);
      expect$.Expect.equals(0, (x & y) >>> 0);
      expect$.Expect.equals(6, (x ^ y) >>> 0);
    }
    get(index) {
      return this.foo;
    }
    set(index, value) {
      this.foo = value;
      return value;
    }
    testIncrement() {
      let x = 4, a = x++;
      expect$.Expect.equals(4, a);
      expect$.Expect.equals(5, x);
      expect$.Expect.equals(6, ++x);
      expect$.Expect.equals(6, x++);
      expect$.Expect.equals(7, x);
      expect$.Expect.equals(6, --x);
      expect$.Expect.equals(6, x--);
      expect$.Expect.equals(5, x);
      this.foo = 0;
      expect$.Expect.equals(0, (() => {
        let x = this.foo;
        this.foo = dart.notNull(x) + 1;
        return x;
      })());
      expect$.Expect.equals(1, this.foo);
      expect$.Expect.equals(2, (this.foo = dart.notNull(this.foo) + 1));
      expect$.Expect.equals(2, this.foo);
      expect$.Expect.equals(2, (() => {
        let x = this.foo;
        this.foo = dart.notNull(x) - 1;
        return x;
      })());
      expect$.Expect.equals(1, this.foo);
      expect$.Expect.equals(0, (this.foo = dart.notNull(this.foo) - 1));
      expect$.Expect.equals(0, this.foo);
      expect$.Expect.equals(0, (() => {
        let i = 0, x = this.get(i);
        this.set(i, dart.notNull(x) + 1);
        return x;
      })());
      expect$.Expect.equals(1, this.get(0));
      expect$.Expect.equals(2, (() => {
        let i = 0;
        return this.set(i, dart.notNull(this.get(i)) + 1);
      })());
      expect$.Expect.equals(2, this.get(0));
      expect$.Expect.equals(2, (() => {
        let i = 0, x = this.get(i);
        this.set(i, dart.notNull(x) - 1);
        return x;
      })());
      expect$.Expect.equals(1, this.get(0));
      expect$.Expect.equals(0, (() => {
        let i = 0;
        return this.set(i, dart.notNull(this.get(i)) - 1);
      })());
      expect$.Expect.equals(0, this.get(0));
      let $0 = 42, $1 = 87, $2 = 117;
      expect$.Expect.equals(42, $0++);
      expect$.Expect.equals(43, $0);
      expect$.Expect.equals(44, ++$0);
      expect$.Expect.equals(88, ($0 = $0 + $0));
      expect$.Expect.equals(87, $1++);
      expect$.Expect.equals(88, $1);
      expect$.Expect.equals(89, ++$1);
      expect$.Expect.equals(178, ($1 = $1 + $1));
      expect$.Expect.equals(117, $2++);
      expect$.Expect.equals(118, $2);
      expect$.Expect.equals(119, ++$2);
    }
    testMangling() {
      let $0 = 42, $1 = 87, $2 = 117;
      this.set(0, 0);
      expect$.Expect.equals(42, (() => {
        let i = 0;
        return this.set(i, dart.notNull(this.get(i)) + $0);
      })());
      expect$.Expect.equals(129, (() => {
        let i = 0;
        return this.set(i, dart.notNull(this.get(i)) + $1);
      })());
      expect$.Expect.equals(246, (() => {
        let i = 0;
        return this.set(i, dart.notNull(this.get(i)) + $2);
      })());
    }
  };
  dart.setSignature(expression_test.ExpressionTest, {
    constructors: () => ({new: dart.definiteFunctionType(expression_test.ExpressionTest, [])}),
    methods: () => ({
      testBinary: dart.definiteFunctionType(dart.dynamic, []),
      testUnary: dart.definiteFunctionType(dart.dynamic, []),
      testShifts: dart.definiteFunctionType(dart.dynamic, []),
      testBitwise: dart.definiteFunctionType(dart.dynamic, []),
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.dynamic, [core.int, core.int]),
      testIncrement: dart.definiteFunctionType(dart.dynamic, []),
      testMangling: dart.definiteFunctionType(dart.void, [])
    }),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  expression_test.main = function() {
    expression_test.ExpressionTest.testMain();
  };
  dart.fn(expression_test.main, VoidTodynamic());
  // Exports:
  exports.expression_test = expression_test;
});
