dart_library.library('language/namer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__namer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const namer_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  namer_test.i = 'top level';
  namer_test.i0 = 'top level zero';
  namer_test.i00 = 'top level zero zero';
  namer_test.i2 = 'top level too';
  namer_test.A = class A extends core.Object {};
  namer_test.A.i = 'A';
  namer_test.j = 'top level';
  namer_test.j0 = 'top level zero';
  namer_test.j00 = 'top level zero zero';
  namer_test.j2 = 'top level too';
  namer_test.B = class B extends core.Object {};
  namer_test.B.j = 'B';
  namer_test.k = 'top level';
  namer_test.k0 = 'top level zero';
  namer_test.k00 = 'top level zero zero';
  namer_test.k2 = 'top level too';
  namer_test.C = class C extends core.Object {};
  namer_test.C.k = 'C';
  namer_test.main = function() {
    expect$.Expect.equals('top level', namer_test.i);
    expect$.Expect.equals('A', namer_test.A.i);
    expect$.Expect.equals('top level too', namer_test.i2);
    expect$.Expect.equals('top level zero zero', namer_test.i00);
    expect$.Expect.equals('top level zero', namer_test.i0);
    expect$.Expect.equals('top level zero zero', namer_test.j00);
    expect$.Expect.equals('top level', namer_test.j);
    expect$.Expect.equals('top level too', namer_test.j2);
    expect$.Expect.equals('top level zero', namer_test.j0);
    expect$.Expect.equals('B', namer_test.B.j);
    expect$.Expect.equals('top level too', namer_test.k2);
    expect$.Expect.equals('top level zero', namer_test.k0);
    expect$.Expect.equals('top level', namer_test.k);
    expect$.Expect.equals('C', namer_test.C.k);
    expect$.Expect.equals('top level zero zero', namer_test.k00);
  };
  dart.fn(namer_test.main, VoidTodynamic());
  // Exports:
  exports.namer_test = namer_test;
});
