dart_library.library('language/instance_compound_assignment_operator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instance_compound_assignment_operator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instance_compound_assignment_operator_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _g = Symbol('_g');
  instance_compound_assignment_operator_test.A = class A extends core.Object {
    new() {
      this.f = 2;
      this[_g] = 0;
      this.gGetCount = 0;
      this.gSetCount = 0;
    }
    get(index) {
      return this.f;
    }
    set(index, value) {
      (() => {
        return this.f = value;
      })();
      return value;
    }
    get g() {
      this.gGetCount = dart.notNull(this.gGetCount) + 1;
      return this[_g];
    }
    set g(value) {
      this.gSetCount = dart.notNull(this.gSetCount) + 1;
      this[_g] = core.int._check(value);
    }
  };
  dart.setSignature(instance_compound_assignment_operator_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(instance_compound_assignment_operator_test.A, [])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])
    })
  });
  const _a = Symbol('_a');
  instance_compound_assignment_operator_test.B = class B extends core.Object {
    new() {
      this[_a] = new instance_compound_assignment_operator_test.A();
      this.count = 0;
    }
    get a() {
      this.count = dart.dsend(this.count, '+', 1);
      return this[_a];
    }
  };
  dart.setSignature(instance_compound_assignment_operator_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(instance_compound_assignment_operator_test.B, [])})
  });
  instance_compound_assignment_operator_test.globalA = null;
  instance_compound_assignment_operator_test.fooCounter = 0;
  instance_compound_assignment_operator_test.foo = function() {
    instance_compound_assignment_operator_test.fooCounter = dart.notNull(instance_compound_assignment_operator_test.fooCounter) + 1;
    return instance_compound_assignment_operator_test.globalA;
  };
  dart.fn(instance_compound_assignment_operator_test.foo, VoidTodynamic());
  instance_compound_assignment_operator_test.main = function() {
    let b = new instance_compound_assignment_operator_test.B();
    expect$.Expect.equals(0, b.count);
    expect$.Expect.equals(2, dart.dload(b.a, 'f'));
    expect$.Expect.equals(1, b.count);
    let o = b.a;
    expect$.Expect.equals(2, b.count);
    dart.dput(b.a, 'f', 1);
    expect$.Expect.equals(3, b.count);
    expect$.Expect.equals(1, dart.dload(b[_a], 'f'));
    let o$ = b.a;
    dart.dput(o$, 'f', dart.dsend(dart.dload(o$, 'f'), '+', 1));
    expect$.Expect.equals(4, b.count);
    expect$.Expect.equals(2, dart.dload(b[_a], 'f'));
    b.count = 0;
    dart.dput(b[_a], 'f', 2);
    expect$.Expect.equals(0, b.count);
    expect$.Expect.equals(2, dart.dindex(b.a, 0));
    expect$.Expect.equals(1, b.count);
    o = b.a;
    expect$.Expect.equals(2, b.count);
    dart.dsetindex(b.a, 0, 1);
    expect$.Expect.equals(3, b.count);
    expect$.Expect.equals(1, dart.dload(b[_a], 'f'));
    let o$0 = b.a, i = 0;
    dart.dsetindex(o$0, i, dart.dsend(dart.dindex(o$0, i), '+', 1));
    expect$.Expect.equals(4, b.count);
    expect$.Expect.equals(2, dart.dload(b[_a], 'f'));
    let o$1 = b[_a];
    dart.dput(o$1, 'g', dart.dsend(dart.dload(o$1, 'g'), '+', 1));
    expect$.Expect.equals(1, dart.dload(b[_a], 'gGetCount'));
    expect$.Expect.equals(1, dart.dload(b[_a], 'gSetCount'));
    expect$.Expect.equals(1, dart.dload(b[_a], _g));
    instance_compound_assignment_operator_test.globalA = b[_a];
    dart.dput(instance_compound_assignment_operator_test.globalA, 'f', 0);
    let o$2 = instance_compound_assignment_operator_test.foo();
    dart.dput(o$2, 'f', dart.dsend(dart.dload(o$2, 'f'), '+', 1));
    expect$.Expect.equals(1, instance_compound_assignment_operator_test.fooCounter);
    expect$.Expect.equals(1, dart.dload(instance_compound_assignment_operator_test.globalA, 'f'));
  };
  dart.fn(instance_compound_assignment_operator_test.main, VoidTodynamic());
  // Exports:
  exports.instance_compound_assignment_operator_test = instance_compound_assignment_operator_test;
});
