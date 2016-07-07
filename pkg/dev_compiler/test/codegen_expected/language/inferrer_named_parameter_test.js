dart_library.library('language/inferrer_named_parameter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inferrer_named_parameter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inferrer_named_parameter_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {path: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inferrer_named_parameter_test.foo = function(opts) {
    let path = opts && 'path' in opts ? opts.path : null;
    dart.fn(() => 42, VoidToint());
    return path;
  };
  dart.fn(inferrer_named_parameter_test.foo, __Todynamic());
  inferrer_named_parameter_test.main = function() {
    inferrer_named_parameter_test.foo({path: '42'});
    expect$.Expect.isFalse(typeof inferrer_named_parameter_test.foo() == 'string');
  };
  dart.fn(inferrer_named_parameter_test.main, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.inferrer_named_parameter_test = inferrer_named_parameter_test;
  exports.compiler_annotations = compiler_annotations;
});
