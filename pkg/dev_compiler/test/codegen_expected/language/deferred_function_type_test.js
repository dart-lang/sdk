dart_library.library('language/deferred_function_type_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deferred_function_type_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deferred_function_type_test = Object.create(null);
  const deferred_function_type_lib = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_function_type_test.main = function() {
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      deferred_function_type_lib.runTest();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_function_type_test.main, VoidTodynamic());
  deferred_function_type_lib.T = class T extends core.Object {
    foo(x) {}
  };
  dart.setSignature(deferred_function_type_lib.T, {
    methods: () => ({foo: dart.definiteFunctionType(deferred_function_type_lib.A, [core.int])})
  });
  deferred_function_type_lib.A = class A extends core.Object {};
  deferred_function_type_lib.F = dart.typedef('F', () => dart.functionType(deferred_function_type_lib.A, [core.int]));
  deferred_function_type_lib.use = function(x) {
    return x;
  };
  dart.fn(deferred_function_type_lib.use, dynamicTodynamic());
  deferred_function_type_lib.runTest = function() {
    deferred_function_type_lib.use(new deferred_function_type_lib.A());
    expect$.Expect.isTrue(deferred_function_type_lib.F.is(dart.bind(new deferred_function_type_lib.T(), 'foo')));
  };
  dart.fn(deferred_function_type_lib.runTest, VoidTodynamic());
  // Exports:
  exports.deferred_function_type_test = deferred_function_type_test;
  exports.deferred_function_type_lib = deferred_function_type_lib;
});
