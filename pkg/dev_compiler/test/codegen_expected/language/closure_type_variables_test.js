dart_library.library('language/closure_type_variables_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_type_variables_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_type_variables_test = Object.create(null);
  let A = () => (A = dart.constFn(closure_type_variables_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(closure_type_variables_test.A$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_type_variables_test.A$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(closure_type_variables_test.A$(T)))();
    class A extends core.Object {
      new() {
      }
      bar() {
        function g() {
          new (AOfT())();
        }
        dart.fn(g, VoidTodynamic());
        g();
      }
      foo() {
        function g() {
          return new (AOfT())();
        }
        dart.fn(g, VoidTodynamic());
        return g();
      }
    }
    dart.addTypeTests(A);
    dart.defineNamedConstructor(A, 'bar');
    dart.setSignature(A, {
      constructors: () => ({
        new: dart.definiteFunctionType(closure_type_variables_test.A$(T), []),
        bar: dart.definiteFunctionType(closure_type_variables_test.A$(T), [])
      }),
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  closure_type_variables_test.A = A();
  closure_type_variables_test.main = function() {
    expect$.Expect.isTrue(AOfint().is(new (AOfint())().foo()));
    expect$.Expect.isTrue(AOfint().is(new (AOfint()).bar().foo()));
  };
  dart.fn(closure_type_variables_test.main, VoidTodynamic());
  // Exports:
  exports.closure_type_variables_test = closure_type_variables_test;
});
