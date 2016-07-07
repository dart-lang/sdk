dart_library.library('language/string_optimizations_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_optimizations_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_optimizations_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {path: dart.dynamic})))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_optimizations_test.foo = function(opts) {
    let path = opts && 'path' in opts ? opts.path : null;
    dart.fn(() => 42, VoidToint());
    return dart.toString(path);
  };
  dart.fn(string_optimizations_test.foo, __Todynamic());
  string_optimizations_test.bar = function(opts) {
    let path = opts && 'path' in opts ? opts.path : null;
    dart.fn(() => 42, VoidToint());
    return path;
  };
  dart.fn(string_optimizations_test.bar, __Todynamic());
  string_optimizations_test.main = function() {
    let a = [string_optimizations_test.foo({path: '42'}), string_optimizations_test.foo(), 42, string_optimizations_test.bar({path: '54'})];
    expect$.Expect.isTrue(typeof a[dartx.get](1) == 'string');
    expect$.Expect.throws(dart.fn(() => dart.dsend(string_optimizations_test.bar(), 'concat', '54'), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(string_optimizations_test.main, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.string_optimizations_test = string_optimizations_test;
  exports.compiler_annotations = compiler_annotations;
});
