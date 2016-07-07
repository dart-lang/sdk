dart_library.library('language/refine_receiver_null_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__refine_receiver_null_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const refine_receiver_null_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  refine_receiver_null_test.main = function() {
    let a = true ? null : 42;
    dart.toString(a);
    refine_receiver_null_test.foo(a);
  };
  dart.fn(refine_receiver_null_test.main, VoidTodynamic());
  refine_receiver_null_test.foo = function(a) {
    let f = dart.fn(() => 42, VoidToint());
    expect$.Expect.throws(dart.fn(() => dart.dsend(a, '+', 42), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(refine_receiver_null_test.foo, dynamicTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.refine_receiver_null_test = refine_receiver_null_test;
  exports.compiler_annotations = compiler_annotations;
});
