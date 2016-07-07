dart_library.library('language/function_subtype2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype2_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype2_test.C$()))();
  let COfint$int$int = () => (COfint$int$int = dart.constFn(function_subtype2_test.C$(core.int, core.int, core.int)))();
  let COfint$double$int = () => (COfint$double$int = dart.constFn(function_subtype2_test.C$(core.int, core.double, core.int)))();
  let COfint$int$double = () => (COfint$int$double = dart.constFn(function_subtype2_test.C$(core.int, core.int, core.double)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype2_test.T1 = dart.typedef('T1', () => dart.functionType(dart.void, [core.int, core.int]));
  function_subtype2_test.T2 = dart.typedef('T2', () => dart.functionType(dart.void, [core.int], [core.int]));
  function_subtype2_test.T3 = dart.typedef('T3', () => dart.functionType(dart.void, [], [core.int, core.int]));
  function_subtype2_test.T4 = dart.typedef('T4', () => dart.functionType(dart.void, [core.int], [core.int, core.int]));
  function_subtype2_test.T5 = dart.typedef('T5', () => dart.functionType(dart.void, [], [core.int, core.int, core.int]));
  function_subtype2_test.C$ = dart.generic((T, S, U) => {
    class C extends core.Object {
      m1(a, b) {
        T._check(a);
        S._check(b);
      }
      m2(a, b) {
        T._check(a);
        if (b === void 0) b = null;
        S._check(b);
      }
      m3(a, b) {
        if (a === void 0) a = null;
        T._check(a);
        if (b === void 0) b = null;
        S._check(b);
      }
      m4(a, b, c) {
        T._check(a);
        if (b === void 0) b = null;
        S._check(b);
        if (c === void 0) c = null;
        U._check(c);
      }
      m5(a, b, c) {
        if (a === void 0) a = null;
        T._check(a);
        if (b === void 0) b = null;
        S._check(b);
        if (c === void 0) c = null;
        U._check(c);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({
        m1: dart.definiteFunctionType(dart.void, [T, S]),
        m2: dart.definiteFunctionType(dart.void, [T], [S]),
        m3: dart.definiteFunctionType(dart.void, [], [T, S]),
        m4: dart.definiteFunctionType(dart.void, [T], [S, U]),
        m5: dart.definiteFunctionType(dart.void, [], [T, S, U])
      })
    });
    return C;
  });
  function_subtype2_test.C = C();
  function_subtype2_test.main = function() {
    let c1 = new (COfint$int$int())();
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c1, 'm1')), "(int,int)->void is (int,int)->void");
    expect$.Expect.isFalse(function_subtype2_test.T2.is(dart.bind(c1, 'm1')), "(int,int)->void is not (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c1, 'm1')), "(int,int)->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c1, 'm1')), "(int,int)->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c1, 'm1')), "(int,int)->void is not ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c1, 'm2')), "(int,[int])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c1, 'm2')), "(int,[int])->void is (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c1, 'm2')), "(int,[int])->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c1, 'm2')), "(int,[int])->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c1, 'm2')), "(int,[int])->void is not ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c1, 'm3')), "([int,int])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c1, 'm3')), "([int,int])->void is (int,[int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T3.is(dart.bind(c1, 'm3')), "([int,int])->void is ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c1, 'm3')), "([int,int])->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c1, 'm3')), "([int,int])->void is not ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c1, 'm4')), "(int,[int,int])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c1, 'm4')), "(int,[int,int])->void is (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c1, 'm4')), "(int,[int,int])->void is not ([int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T4.is(dart.bind(c1, 'm4')), "(int,[int,int])->void is (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c1, 'm4')), "(int,[int,int])->void is not ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c1, 'm5')), "([int,int,int])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c1, 'm5')), "([int,int,int])->void is (int,[int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T3.is(dart.bind(c1, 'm5')), "([int,int,int])->void is ([int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T4.is(dart.bind(c1, 'm5')), "([int,int,int])->void is (int,[int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T5.is(dart.bind(c1, 'm5')), "([int,int,int])->void is ([int,int,int])->void");
    let c2 = new (COfint$double$int())();
    expect$.Expect.isFalse(function_subtype2_test.T1.is(dart.bind(c2, 'm1')), "(int,double)->void is not (int,int)->void");
    expect$.Expect.isFalse(function_subtype2_test.T2.is(dart.bind(c2, 'm1')), "(int,double)->void is not not (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c2, 'm1')), "(int,double)->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c2, 'm1')), "(int,double)->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c2, 'm1')), "(int,double)->void is not ([int,int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T1.is(dart.bind(c2, 'm2')), "(int,[double])->void is not (int,int)->void");
    expect$.Expect.isFalse(function_subtype2_test.T2.is(dart.bind(c2, 'm2')), "(int,[double])->void is not (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c2, 'm2')), "(int,[double])->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c2, 'm2')), "(int,[double])->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c2, 'm2')), "(int,[double])->void is not ([int,int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T1.is(dart.bind(c2, 'm3')), "([int,double])->void is not (int,int)->void");
    expect$.Expect.isFalse(function_subtype2_test.T2.is(dart.bind(c2, 'm3')), "([int,double])->void is not (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c2, 'm3')), "([int,double])->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c2, 'm3')), "([int,double])->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c2, 'm3')), "([int,double])->void is not ([int,int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T1.is(dart.bind(c2, 'm4')), "(int,[double,int])->void is not (int,int)->void");
    expect$.Expect.isFalse(function_subtype2_test.T2.is(dart.bind(c2, 'm4')), "(int,[double,int])->void is not (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c2, 'm4')), "(int,[double,int])->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c2, 'm4')), "(int,[double,int])->void is (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c2, 'm4')), "(int,[double,int])->void is ([int,int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T1.is(dart.bind(c2, 'm5')), "([int,double,int])->void is not (int,int)->void");
    expect$.Expect.isFalse(function_subtype2_test.T2.is(dart.bind(c2, 'm5')), "([int,double,int])->void is not (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c2, 'm5')), "([int,double,int])->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c2, 'm5')), "([int,double,int])->void is (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c2, 'm5')), "([int,double,int])->void is ([int,int,int])->void");
    let c3 = new (COfint$int$double())();
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c3, 'm1')), "(int,int)->void is (int,int)->void");
    expect$.Expect.isFalse(function_subtype2_test.T2.is(dart.bind(c3, 'm1')), "(int,int)->void is not (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c3, 'm1')), "(int,int)->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c3, 'm1')), "(int,int)->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c3, 'm1')), "(int,int)->void is not ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c3, 'm2')), "(int,[int])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c3, 'm2')), "(int,[int])->void is (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c3, 'm2')), "(int,[int])->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c3, 'm2')), "(int,[int])->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c3, 'm2')), "(int,[int])->void is not ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c3, 'm3')), "([int,int])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c3, 'm3')), "([int,int])->void is (int,[int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T3.is(dart.bind(c3, 'm3')), "([int,int])->void is ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c3, 'm3')), "([int,int])->void is not (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c3, 'm3')), "([int,int])->void is not ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c3, 'm4')), "(int,[int,double])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c3, 'm4')), "(int,[int,double])->void is (int,[int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T3.is(dart.bind(c3, 'm4')), "(int,[int,double])->void is not ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c3, 'm4')), "(int,[int,double])->void is (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c3, 'm4')), "(int,[int,double])->void is ([int,int,int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T1.is(dart.bind(c3, 'm5')), "([int,int,double])->void is (int,int)->void");
    expect$.Expect.isTrue(function_subtype2_test.T2.is(dart.bind(c3, 'm5')), "([int,int,double])->void is (int,[int])->void");
    expect$.Expect.isTrue(function_subtype2_test.T3.is(dart.bind(c3, 'm5')), "([int,int,double])->void is ([int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T4.is(dart.bind(c3, 'm5')), "([int,int,double])->void is (int,[int,int])->void");
    expect$.Expect.isFalse(function_subtype2_test.T5.is(dart.bind(c3, 'm5')), "([int,int,double])->void is ([int,int,int])->void");
  };
  dart.fn(function_subtype2_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype2_test = function_subtype2_test;
});
