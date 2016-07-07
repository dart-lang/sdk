dart_library.library('language/function_type_alias2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_alias2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_alias2_test = Object.create(null);
  let f1 = () => (f1 = dart.constFn(function_type_alias2_test.f1$()))();
  let f2 = () => (f2 = dart.constFn(function_type_alias2_test.f2$()))();
  let f3 = () => (f3 = dart.constFn(function_type_alias2_test.f3$()))();
  let f4 = () => (f4 = dart.constFn(function_type_alias2_test.f4$()))();
  let A = () => (A = dart.constFn(function_type_alias2_test.A$()))();
  let f1Ofint = () => (f1Ofint = dart.constFn(function_type_alias2_test.f1$(core.int)))();
  let f3Ofint = () => (f3Ofint = dart.constFn(function_type_alias2_test.f3$(core.int)))();
  let f1Ofdouble = () => (f1Ofdouble = dart.constFn(function_type_alias2_test.f1$(core.double)))();
  let f3Ofdouble = () => (f3Ofdouble = dart.constFn(function_type_alias2_test.f3$(core.double)))();
  let AOfint = () => (AOfint = dart.constFn(function_type_alias2_test.A$(core.int)))();
  let __Toint = () => (__Toint = dart.constFn(dart.definiteFunctionType(core.int, [], [core.int, core.int, core.int])))();
  let __Toint$ = () => (__Toint$ = dart.constFn(dart.definiteFunctionType(core.int, [], {a: core.int, b: core.int, c: core.int})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_alias2_test.f1$ = dart.generic(T => {
    const f1 = dart.typedef('f1', () => dart.functionType(core.int, [], [core.int, core.int, T]));
    return f1;
  });
  function_type_alias2_test.f1 = f1();
  function_type_alias2_test.f2$ = dart.generic(T => {
    const f2 = dart.typedef('f2', () => dart.functionType(core.int, [], [core.int, core.int, T]));
    return f2;
  });
  function_type_alias2_test.f2 = f2();
  function_type_alias2_test.f3$ = dart.generic(T => {
    const f3 = dart.typedef('f3', () => dart.functionType(core.int, [], {a: core.int, b: core.int, c: T}));
    return f3;
  });
  function_type_alias2_test.f3 = f3();
  function_type_alias2_test.f4$ = dart.generic(T => {
    const f4 = dart.typedef('f4', () => dart.functionType(core.int, [], {a: core.int, b: core.int, d: T}));
    return f4;
  });
  function_type_alias2_test.f4 = f4();
  function_type_alias2_test.A$ = dart.generic(T => {
    class A extends core.Object {
      baz(a, b, c) {
        if (a === void 0) a = null;
        if (b === void 0) b = null;
        if (c === void 0) c = null;
        T._check(c);
      }
      bar(opts) {
        let a = opts && 'a' in opts ? opts.a : null;
        let b = opts && 'b' in opts ? opts.b : null;
        let c = opts && 'c' in opts ? opts.c : null;
        T._check(c);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({
        baz: dart.definiteFunctionType(core.int, [], [core.int, core.int, T]),
        bar: dart.definiteFunctionType(core.int, [], {a: core.int, b: core.int, c: T})
      })
    });
    return A;
  });
  function_type_alias2_test.A = A();
  function_type_alias2_test.baz = function(a, b, c) {
    if (a === void 0) a = null;
    if (b === void 0) b = null;
    if (c === void 0) c = null;
  };
  dart.fn(function_type_alias2_test.baz, __Toint());
  function_type_alias2_test.bar = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let b = opts && 'b' in opts ? opts.b : null;
    let c = opts && 'c' in opts ? opts.c : null;
  };
  dart.fn(function_type_alias2_test.bar, __Toint$());
  function_type_alias2_test.main = function() {
    expect$.Expect.isTrue(function_type_alias2_test.f1.is(function_type_alias2_test.baz));
    expect$.Expect.isFalse(function_type_alias2_test.f3.is(function_type_alias2_test.baz));
    expect$.Expect.isFalse(function_type_alias2_test.f1.is(function_type_alias2_test.bar));
    expect$.Expect.isTrue(function_type_alias2_test.f3.is(function_type_alias2_test.bar));
    expect$.Expect.isTrue(function_type_alias2_test.f1.is(function_type_alias2_test.baz));
    expect$.Expect.isTrue(f1Ofint().is(function_type_alias2_test.baz));
    expect$.Expect.isTrue(f3Ofint().is(function_type_alias2_test.bar));
    expect$.Expect.isFalse(f1Ofdouble().is(function_type_alias2_test.baz));
    expect$.Expect.isFalse(f3Ofdouble().is(function_type_alias2_test.bar));
    expect$.Expect.isTrue(function_type_alias2_test.f2.is(function_type_alias2_test.baz));
    expect$.Expect.isFalse(function_type_alias2_test.f4.is(function_type_alias2_test.bar));
    expect$.Expect.isTrue(f1Ofint().is(function_type_alias2_test.baz));
    expect$.Expect.isFalse(f1Ofint().is(function_type_alias2_test.bar));
    let a = new (AOfint())();
    expect$.Expect.isTrue(function_type_alias2_test.f1.is(dart.bind(a, 'baz')));
    expect$.Expect.isFalse(function_type_alias2_test.f3.is(dart.bind(a, 'baz')));
    expect$.Expect.isFalse(function_type_alias2_test.f1.is(dart.bind(a, 'bar')));
    expect$.Expect.isTrue(function_type_alias2_test.f3.is(dart.bind(a, 'bar')));
    expect$.Expect.isTrue(function_type_alias2_test.f1.is(dart.bind(a, 'baz')));
    expect$.Expect.isTrue(f1Ofint().is(dart.bind(a, 'baz')));
    expect$.Expect.isTrue(f3Ofint().is(dart.bind(a, 'bar')));
    expect$.Expect.isFalse(f1Ofdouble().is(dart.bind(a, 'baz')));
    expect$.Expect.isFalse(f3Ofdouble().is(dart.bind(a, 'bar')));
    expect$.Expect.isTrue(function_type_alias2_test.f2.is(dart.bind(a, 'baz')));
    expect$.Expect.isFalse(function_type_alias2_test.f4.is(dart.bind(a, 'bar')));
    expect$.Expect.isTrue(f1Ofint().is(dart.bind(a, 'baz')));
    expect$.Expect.isFalse(f1Ofint().is(dart.bind(a, 'bar')));
  };
  dart.fn(function_type_alias2_test.main, VoidTodynamic());
  // Exports:
  exports.function_type_alias2_test = function_type_alias2_test;
});
