dart_library.library('language/type_hoisting_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_hoisting_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_hoisting_test = Object.create(null);
  let A = () => (A = dart.constFn(type_hoisting_test.A$()))();
  let ToVoid = () => (ToVoid = dart.constFn(type_hoisting_test.ToVoid$()))();
  let Id = () => (Id = dart.constFn(type_hoisting_test.Id$()))();
  let AOfString = () => (AOfString = dart.constFn(type_hoisting_test.A$(core.String)))();
  let AOfint = () => (AOfint = dart.constFn(type_hoisting_test.A$(core.int)))();
  let ToVoidOfString = () => (ToVoidOfString = dart.constFn(type_hoisting_test.ToVoid$(core.String)))();
  let IdOfString = () => (IdOfString = dart.constFn(type_hoisting_test.Id$(core.String)))();
  let ToVoidOfint = () => (ToVoidOfint = dart.constFn(type_hoisting_test.ToVoid$(core.int)))();
  let IdOfint = () => (IdOfint = dart.constFn(type_hoisting_test.Id$(core.int)))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let intAndintToB = () => (intAndintToB = dart.constFn(dart.definiteFunctionType(type_hoisting_test.B, [core.int, core.int])))();
  let VoidToB = () => (VoidToB = dart.constFn(dart.definiteFunctionType(type_hoisting_test.B, [])))();
  let intAndintToC = () => (intAndintToC = dart.constFn(dart.definiteFunctionType(type_hoisting_test.C, [core.int, core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  type_hoisting_test.A$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(type_hoisting_test.A$(T)))();
    let TTovoid = () => (TTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [T])))();
    let TAndTToAOfT = () => (TAndTToAOfT = dart.constFn(dart.definiteFunctionType(AOfT(), [T, T])))();
    let VoidToAOfT = () => (VoidToAOfT = dart.constFn(dart.definiteFunctionType(AOfT(), [])))();
    class A extends core.Object {
      new(x, z) {
        this.x = x;
      }
      make() {
        this.x = null;
      }
      f(x) {
        T._check(x);
      }
      static g(x) {
        return x;
      }
    }
    dart.addTypeTests(A);
    dart.defineNamedConstructor(A, 'make');
    dart.setSignature(A, {
      constructors: () => ({
        new: TAndTToAOfT(),
        make: VoidToAOfT()
      }),
      methods: () => ({f: TTovoid()}),
      statics: () => ({g: StringToString()}),
      names: ['g']
    });
    return A;
  });
  type_hoisting_test.A = A();
  type_hoisting_test.B = class B extends type_hoisting_test.A$(core.int) {
    new(x, z) {
      super.new(x, z);
    }
    make() {
      super.make();
    }
    f(x) {}
    static g(x) {
      return x;
    }
  };
  dart.addSimpleTypeTests(type_hoisting_test.B);
  dart.defineNamedConstructor(type_hoisting_test.B, 'make');
  dart.setSignature(type_hoisting_test.B, {
    constructors: () => ({
      new: intAndintToB(),
      make: VoidToB()
    }),
    methods: () => ({f: intTovoid()}),
    statics: () => ({g: intToint()}),
    names: ['g']
  });
  type_hoisting_test.C = class C extends core.Object {
    new(x, z) {
      this.x = x;
    }
    f(x) {}
    static g(x) {
      return x;
    }
  };
  dart.setSignature(type_hoisting_test.C, {
    constructors: () => ({new: intAndintToC()}),
    methods: () => ({f: intTovoid()}),
    statics: () => ({g: intToint()}),
    names: ['g']
  });
  type_hoisting_test.ToVoid$ = dart.generic(T => {
    const ToVoid = dart.typedef('ToVoid', () => dart.functionType(dart.void, [T]));
    return ToVoid;
  });
  type_hoisting_test.ToVoid = ToVoid();
  type_hoisting_test.Id$ = dart.generic(T => {
    const Id = dart.typedef('Id', () => dart.functionType(T, [T]));
    return Id;
  });
  type_hoisting_test.Id = Id();
  type_hoisting_test.main = function() {
    {
      let a = new (AOfString())("hello", "world");
      expect$.Expect.isTrue(!AOfint().is(new (AOfString()).make()));
      expect$.Expect.isTrue(type_hoisting_test.A.is(new type_hoisting_test.A.make()));
      expect$.Expect.isTrue(!AOfint().is(a));
      expect$.Expect.isTrue(AOfString().is(a));
      expect$.Expect.isTrue(ToVoidOfString().is(dart.bind(a, 'f')));
      expect$.Expect.isTrue(IdOfString().is(type_hoisting_test.A.g));
    }
    {
      let b = new type_hoisting_test.B(0, 1);
      expect$.Expect.isTrue(type_hoisting_test.B.is(new type_hoisting_test.B.make()));
      expect$.Expect.isTrue(AOfint().is(new type_hoisting_test.B.make()));
      expect$.Expect.isTrue(type_hoisting_test.B.is(b));
      expect$.Expect.isTrue(ToVoidOfint().is(dart.bind(b, 'f')));
      expect$.Expect.isTrue(IdOfint().is(type_hoisting_test.B.g));
    }
    {
      let c = new type_hoisting_test.C(0, 1);
      expect$.Expect.isTrue(type_hoisting_test.C.is(c));
      expect$.Expect.isTrue(ToVoidOfint().is(dart.bind(c, 'f')));
      expect$.Expect.isTrue(IdOfint().is(type_hoisting_test.C.g));
    }
  };
  dart.fn(type_hoisting_test.main, VoidTovoid());
  // Exports:
  exports.type_hoisting_test = type_hoisting_test;
});
