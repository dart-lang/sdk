dart_library.library('language/cascade_precedence_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cascade_precedence_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cascade_precedence_test = Object.create(null);
  let VoidToFunction = () => (VoidToFunction = dart.constFn(dart.definiteFunctionType(core.Function, [])))();
  let VoidToA = () => (VoidToA = dart.constFn(dart.definiteFunctionType(cascade_precedence_test.A, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cascade_precedence_test.A = class A extends core.Object {
    new(value) {
      this.value = value;
    }
    set(value) {
      this.value = value;
    }
    get() {
      return this.value;
    }
    get(index) {
      return dart.notNull(this.value) + dart.notNull(index);
    }
    set(index, newValue) {
      this.value = dart.notNull(this.value) + (-dart.notNull(index) + dart.notNull(newValue));
      return newValue;
    }
    test(expected) {
      expect$.Expect.equals(expected, this.value);
    }
    limp(n) {
      if (n == 0) return dart.bind(this, 'set');
      return dart.fn(() => this.limp(dart.notNull(n) - 1), VoidToFunction());
    }
    get self() {
      return this;
    }
    ['+'](other) {
      this.value = dart.notNull(this.value) + dart.notNull(other.value);
      return this;
    }
  };
  dart.setSignature(cascade_precedence_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(cascade_precedence_test.A, [core.int])}),
    methods: () => ({
      set: dart.definiteFunctionType(dart.void, [core.int]),
      get: dart.definiteFunctionType(core.int, []),
      get: dart.definiteFunctionType(core.int, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, core.int]),
      test: dart.definiteFunctionType(dart.void, [core.int]),
      limp: dart.definiteFunctionType(core.Function, [core.int]),
      '+': dart.definiteFunctionType(cascade_precedence_test.A, [cascade_precedence_test.A])
    })
  });
  cascade_precedence_test.Box = class Box extends core.Object {
    new(value) {
      this.value = value;
    }
    get(pos) {
      return this.value;
    }
    set(pos, a) {
      this.value = a;
      return a;
    }
    get x() {
      return this.value;
    }
    set x(a) {
      this.value = a;
    }
  };
  dart.setSignature(cascade_precedence_test.Box, {
    constructors: () => ({new: dart.definiteFunctionType(cascade_precedence_test.Box, [cascade_precedence_test.A])}),
    methods: () => ({
      get: dart.definiteFunctionType(cascade_precedence_test.A, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, cascade_precedence_test.A])
    })
  });
  cascade_precedence_test.main = function() {
    let a = new cascade_precedence_test.A(42);
    let original = a;
    let b = new cascade_precedence_test.A(87);
    function fa() {
      return a;
    }
    dart.fn(fa, VoidToA());
    let box = new cascade_precedence_test.Box(a);
    expect$.Expect.equals(a, ((() => {
      a.set(37);
      a.get();
      return a;
    })()));
    a.test(37);
    expect$.Expect.equals(a, (() => {
      let _ = fa();
      _.set(42);
      _.get();
      return _;
    })());
    a.test(42);
    expect$.Expect.equals(a, (() => {
      let _ = box.x;
      _.set(37);
      _.get();
      return _;
    })());
    a.test(37);
    expect$.Expect.equals(b, (() => {
      let _ = b['+'](a);
      _.test(124);
      _.set(117);
      _.get();
      return _;
    })());
    b.test(117);
    a.test(37);
    (a.value == 37 ? a : b).set(42);
    a.test(42);
    let c = new cascade_precedence_test.A(21);
    a.set(c.get());
    c = a;
    expect$.Expect.equals(a, c);
    expect$.Expect.equals(original, a);
    a.test(21);
    c = null;
    box.x = c = a;
    box.x.test(21);
    c.test(21);
    c = null;
    box.x = ((() => {
      a.test(21);
      return c = a;
    })());
    box.x.test(21);
    c.test(21);
    c = null;
    box.x = ((() => {
      a.test(21);
      return c = a;
    })());
    box.x.test(21);
    c.test(21);
    ((() => {
      a.set(42);
      return a;
    })()).test(42);
    a.set(21);
    a.test(21);
    c = null;
    let originalBox = box;
    box.x = a.value == 21 ? b : c;
    box.x.test(117);
    box = box;
    expect$.Expect.equals(originalBox, box);
    expect$.Expect.equals(box.value, b);
    box.x = ((() => {
      a.set(42);
      a.test(42);
      return a;
    })());
    box.x.test(42);
  };
  dart.fn(cascade_precedence_test.main, VoidTodynamic());
  // Exports:
  exports.cascade_precedence_test = cascade_precedence_test;
});
