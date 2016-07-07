dart_library.library('language/function_type_alias4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_alias4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_alias4_test = Object.create(null);
  let F = () => (F = dart.constFn(function_type_alias4_test.F$()))();
  let A = () => (A = dart.constFn(function_type_alias4_test.A$()))();
  let FOfbool = () => (FOfbool = dart.constFn(function_type_alias4_test.F$(core.bool)))();
  let FOfint = () => (FOfint = dart.constFn(function_type_alias4_test.F$(core.int)))();
  let AOfbool = () => (AOfbool = dart.constFn(function_type_alias4_test.A$(core.bool)))();
  let AOfint = () => (AOfint = dart.constFn(function_type_alias4_test.A$(core.int)))();
  let boolTobool = () => (boolTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.bool])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_alias4_test.F$ = dart.generic(bool => {
    const F = dart.typedef('F', () => dart.functionType(bool, [bool]));
    return F;
  });
  function_type_alias4_test.F = F();
  function_type_alias4_test.bar = function(a) {
  };
  dart.fn(function_type_alias4_test.bar, boolTobool());
  function_type_alias4_test.baz = function(a) {
  };
  dart.fn(function_type_alias4_test.baz, intToint());
  function_type_alias4_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo(a) {
        T._check(a);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(T, [T])})
    });
    return A;
  });
  function_type_alias4_test.A = A();
  function_type_alias4_test.main = function() {
    expect$.Expect.isTrue(function_type_alias4_test.F.is(function_type_alias4_test.bar));
    expect$.Expect.isTrue(function_type_alias4_test.F.is(function_type_alias4_test.baz));
    expect$.Expect.isTrue(FOfbool().is(function_type_alias4_test.bar));
    expect$.Expect.isTrue(FOfint().is(function_type_alias4_test.baz));
    expect$.Expect.isTrue(!FOfint().is(function_type_alias4_test.bar));
    expect$.Expect.isTrue(!FOfbool().is(function_type_alias4_test.baz));
    let b = new (AOfbool())();
    let i = new (AOfint())();
    expect$.Expect.isTrue(function_type_alias4_test.F.is(dart.bind(b, 'foo')));
    expect$.Expect.isTrue(function_type_alias4_test.F.is(dart.bind(i, 'foo')));
    expect$.Expect.isTrue(FOfbool().is(dart.bind(b, 'foo')));
    expect$.Expect.isTrue(FOfint().is(dart.bind(i, 'foo')));
    expect$.Expect.isTrue(!FOfint().is(dart.bind(b, 'foo')));
    expect$.Expect.isTrue(!FOfbool().is(dart.bind(i, 'foo')));
  };
  dart.fn(function_type_alias4_test.main, VoidTodynamic());
  // Exports:
  exports.function_type_alias4_test = function_type_alias4_test;
});
