dart_library.library('language/issue10721_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue10721_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue10721_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamic__ToString = () => (dynamic__ToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic], {arg2: core.int})))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicToFunction = () => (dynamicToFunction = dart.constFn(dart.definiteFunctionType(core.Function, [dart.dynamic])))();
  issue10721_test.main = function() {
    expect$.Expect.equals('', issue10721_test.useParameterInClosure(1));
    expect$.Expect.equals(43, dart.dcall(issue10721_test.updateParameterInClosure(1)));
  };
  dart.fn(issue10721_test.main, VoidTovoid());
  issue10721_test.useParameterInClosure = function(arg1, opts) {
    let arg2 = opts && 'arg2' in opts ? opts.arg2 : null;
    if (core.Map.is(arg1)) {
      return core.String._check(arg1[dartx.keys][dartx.map](dart.dynamic)(dart.fn(key => arg1[dartx.get](key), dynamicTodynamic()))[dartx.first]);
    } else {
      return '';
    }
  };
  dart.fn(issue10721_test.useParameterInClosure, dynamic__ToString());
  issue10721_test.updateParameterInClosure = function(arg1) {
    if (core.Map.is(arg1)) {
      return dart.fn(() => arg1 = 42, VoidToint());
    } else {
      return dart.fn(() => arg1 = dart.dsend(arg1, '+', 42), VoidTodynamic());
    }
  };
  dart.fn(issue10721_test.updateParameterInClosure, dynamicToFunction());
  // Exports:
  exports.issue10721_test = issue10721_test;
});
