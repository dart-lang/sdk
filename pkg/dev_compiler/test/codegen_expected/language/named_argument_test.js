dart_library.library('language/named_argument_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_argument_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_argument_test = Object.create(null);
  let __ToString = () => (__ToString = dart.constFn(dart.definiteFunctionType(core.String, [], {b: dart.dynamic, a: dart.dynamic})))();
  let __ToString$ = () => (__ToString$ = dart.constFn(dart.definiteFunctionType(core.String, [], {a: dart.dynamic, b: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_argument_test.main = function() {
    let c1 = dart.fn(opts => {
      let b = opts && 'b' in opts ? opts.b : null;
      let a = opts && 'a' in opts ? opts.a : null;
      return dart.str`a: ${a} b: ${b}`;
    }, __ToString());
    let c2 = dart.fn(opts => {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
      return dart.str`a: ${a} b: ${b}`;
    }, __ToString$());
    expect$.Expect.equals('a: 2 b: 1', dart.dcall(c1, {b: 1, a: 2}));
    expect$.Expect.equals('a: 1 b: 2', dart.dcall(c1, {a: 1, b: 2}));
    expect$.Expect.equals('a: 2 b: 1', dart.dcall(c2, {b: 1, a: 2}));
    expect$.Expect.equals('a: 1 b: 2', dart.dcall(c2, {a: 1, b: 2}));
  };
  dart.fn(named_argument_test.main, VoidTodynamic());
  // Exports:
  exports.named_argument_test = named_argument_test;
});
