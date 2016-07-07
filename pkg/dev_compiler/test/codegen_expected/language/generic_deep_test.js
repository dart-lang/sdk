dart_library.library('language/generic_deep_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_deep_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_deep_test = Object.create(null);
  let SOfZ = () => (SOfZ = dart.constFn(generic_deep_test.S$(generic_deep_test.Z)))();
  let S = () => (S = dart.constFn(generic_deep_test.S$()))();
  let SOfS = () => (SOfS = dart.constFn(generic_deep_test.S$(generic_deep_test.S)))();
  let SOfSOfZ = () => (SOfSOfZ = dart.constFn(generic_deep_test.S$(SOfZ())))();
  let SOfSOfSOfZ = () => (SOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfZ())))();
  let SOfSOfSOfSOfZ = () => (SOfSOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfSOfZ())))();
  let SOfSOfSOfSOfSOfZ = () => (SOfSOfSOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfSOfSOfZ())))();
  let SOfSOfSOfSOfSOfSOfZ = () => (SOfSOfSOfSOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfSOfSOfSOfZ())))();
  let SOfSOfSOfSOfSOfSOfSOfZ = () => (SOfSOfSOfSOfSOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfSOfSOfSOfSOfZ())))();
  let SOfSOfSOfSOfSOfSOfSOfSOfZ = () => (SOfSOfSOfSOfSOfSOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfSOfSOfSOfSOfSOfZ())))();
  let SOfSOfSOfSOfSOfSOfSOfSOfSOfZ = () => (SOfSOfSOfSOfSOfSOfSOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfSOfSOfSOfSOfSOfSOfZ())))();
  let SOfSOfSOfSOfSOfSOfSOfSOfSOfSOfZ = () => (SOfSOfSOfSOfSOfSOfSOfSOfSOfSOfZ = dart.constFn(generic_deep_test.S$(SOfSOfSOfSOfSOfSOfSOfSOfSOfZ())))();
  let SOfSOfS = () => (SOfSOfS = dart.constFn(generic_deep_test.S$(SOfS())))();
  let SOfSOfSOfS = () => (SOfSOfSOfS = dart.constFn(generic_deep_test.S$(SOfSOfS())))();
  let SOfSOfSOfSOfS = () => (SOfSOfSOfSOfS = dart.constFn(generic_deep_test.S$(SOfSOfSOfS())))();
  let intToN = () => (intToN = dart.constFn(dart.definiteFunctionType(generic_deep_test.N, [core.int])))();
  let NToint = () => (NToint = dart.constFn(dart.definiteFunctionType(core.int, [generic_deep_test.N])))();
  let NTobool = () => (NTobool = dart.constFn(dart.definiteFunctionType(core.bool, [generic_deep_test.N])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_deep_test.N = class N extends core.Object {};
  generic_deep_test.Z = class Z extends core.Object {
    new() {
    }
    add1() {
      return new (SOfZ())(this);
    }
    sub1() {
      dart.throw("Error: sub1(0)");
    }
  };
  generic_deep_test.Z[dart.implements] = () => [generic_deep_test.N];
  dart.setSignature(generic_deep_test.Z, {
    constructors: () => ({new: dart.definiteFunctionType(generic_deep_test.Z, [])}),
    methods: () => ({
      add1: dart.definiteFunctionType(generic_deep_test.N, []),
      sub1: dart.definiteFunctionType(generic_deep_test.N, [])
    })
  });
  generic_deep_test.S$ = dart.generic(K => {
    let SOfK = () => (SOfK = dart.constFn(generic_deep_test.S$(K)))();
    let SOfSOfK = () => (SOfSOfK = dart.constFn(generic_deep_test.S$(SOfK())))();
    class S extends core.Object {
      new(before) {
        this.before = before;
      }
      add1() {
        return new (SOfSOfK())(this);
      }
      sub1() {
        return this.before;
      }
    }
    dart.addTypeTests(S);
    S[dart.implements] = () => [generic_deep_test.N];
    dart.setSignature(S, {
      constructors: () => ({new: dart.definiteFunctionType(generic_deep_test.S$(K), [generic_deep_test.N])}),
      methods: () => ({
        add1: dart.definiteFunctionType(generic_deep_test.N, []),
        sub1: dart.definiteFunctionType(generic_deep_test.N, [])
      })
    });
    return S;
  });
  generic_deep_test.S = S();
  generic_deep_test.NFromInt = function(x) {
    if (x == 0)
      return new generic_deep_test.Z();
    else
      return generic_deep_test.NFromInt(dart.notNull(x) - 1).add1();
  };
  dart.fn(generic_deep_test.NFromInt, intToN());
  generic_deep_test.IntFromN = function(x) {
    if (generic_deep_test.Z.is(x)) return 0;
    if (generic_deep_test.S.is(x)) return dart.notNull(generic_deep_test.IntFromN(x.sub1())) + 1;
    dart.throw("Error");
  };
  dart.fn(generic_deep_test.IntFromN, NToint());
  generic_deep_test.IsEven = function(x) {
    if (generic_deep_test.Z.is(x)) return true;
    if (SOfZ().is(x)) return false;
    if (SOfS().is(x)) return generic_deep_test.IsEven(x.sub1().sub1());
    dart.throw("Error in IsEven");
  };
  dart.fn(generic_deep_test.IsEven, NTobool());
  generic_deep_test.main = function() {
    expect$.Expect.isTrue(generic_deep_test.Z.is(generic_deep_test.NFromInt(0)));
    expect$.Expect.isTrue(SOfZ().is(generic_deep_test.NFromInt(1)));
    expect$.Expect.isTrue(SOfSOfZ().is(generic_deep_test.NFromInt(2)));
    expect$.Expect.isTrue(SOfSOfSOfZ().is(generic_deep_test.NFromInt(3)));
    expect$.Expect.isTrue(SOfSOfSOfSOfSOfSOfSOfSOfSOfSOfZ().is(generic_deep_test.NFromInt(10)));
    expect$.Expect.isTrue(!generic_deep_test.S.is(generic_deep_test.NFromInt(0)));
    expect$.Expect.isTrue(!generic_deep_test.Z.is(generic_deep_test.NFromInt(1)));
    expect$.Expect.isTrue(!SOfS().is(generic_deep_test.NFromInt(1)));
    expect$.Expect.isTrue(!generic_deep_test.Z.is(generic_deep_test.NFromInt(2)));
    expect$.Expect.isTrue(!SOfZ().is(generic_deep_test.NFromInt(2)));
    expect$.Expect.isTrue(!SOfSOfS().is(generic_deep_test.NFromInt(2)));
    expect$.Expect.isTrue(SOfS().is(generic_deep_test.NFromInt(4)));
    expect$.Expect.isTrue(SOfSOfS().is(generic_deep_test.NFromInt(4)));
    expect$.Expect.isTrue(SOfSOfSOfS().is(generic_deep_test.NFromInt(4)));
    expect$.Expect.isTrue(!SOfSOfSOfSOfS().is(generic_deep_test.NFromInt(4)));
    expect$.Expect.isTrue(generic_deep_test.IsEven(generic_deep_test.NFromInt(0)));
    expect$.Expect.isFalse(generic_deep_test.IsEven(generic_deep_test.NFromInt(1)));
    expect$.Expect.isTrue(generic_deep_test.IsEven(generic_deep_test.NFromInt(2)));
    expect$.Expect.isFalse(generic_deep_test.IsEven(generic_deep_test.NFromInt(3)));
    expect$.Expect.isTrue(generic_deep_test.IsEven(generic_deep_test.NFromInt(4)));
    expect$.Expect.equals(0, generic_deep_test.IntFromN(generic_deep_test.NFromInt(0)));
    expect$.Expect.equals(1, generic_deep_test.IntFromN(generic_deep_test.NFromInt(1)));
    expect$.Expect.equals(2, generic_deep_test.IntFromN(generic_deep_test.NFromInt(2)));
    expect$.Expect.equals(50, generic_deep_test.IntFromN(generic_deep_test.NFromInt(50)));
  };
  dart.fn(generic_deep_test.main, VoidTodynamic());
  // Exports:
  exports.generic_deep_test = generic_deep_test;
});
