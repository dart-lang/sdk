dart_library.library('language/argument_definition_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__argument_definition_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const argument_definition_test_none_multi = Object.create(null);
  let dynamic__Toint = () => (dynamic__Toint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic], {b: dart.dynamic, c: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  argument_definition_test_none_multi.test = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
    let c = opts && 'c' in opts ? opts.c : null;
    return core.int._check(dart.dsend(dart.dsend(a, '+', b), '+', c));
  };
  dart.fn(argument_definition_test_none_multi.test, dynamic__Toint());
  argument_definition_test_none_multi.main = function() {
    expect$.Expect.equals(6, argument_definition_test_none_multi.test(1, {b: 2, c: 3}));
  };
  dart.fn(argument_definition_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.argument_definition_test_none_multi = argument_definition_test_none_multi;
});
