dart_library.library('language/closure_type_variable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_type_variable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_type_variable_test = Object.create(null);
  let A = () => (A = dart.constFn(closure_type_variable_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(closure_type_variable_test.A$(core.int)))();
  let VoidToType = () => (VoidToType = dart.constFn(dart.definiteFunctionType(core.Type, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_type_variable_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo() {
        function bar() {
          return dart.wrapType(T);
        }
        dart.fn(bar, VoidToType());
        return bar();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  closure_type_variable_test.A = A();
  closure_type_variable_test.main = function() {
    expect$.Expect.equals(new (AOfint())().foo(), dart.wrapType(core.int));
  };
  dart.fn(closure_type_variable_test.main, VoidTodynamic());
  // Exports:
  exports.closure_type_variable_test = closure_type_variable_test;
});
