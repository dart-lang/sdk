dart_library.library('language/closure_parameter_types_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_parameter_types_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_parameter_types_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _do = Symbol('_do');
  closure_parameter_types_test.A = class A extends core.Object {
    new(f) {
      this.f = f;
    }
    [_do]() {
      return dart.dcall(this.f, 1);
    }
  };
  dart.setSignature(closure_parameter_types_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(closure_parameter_types_test.A, [core.Function])}),
    methods: () => ({[_do]: dart.definiteFunctionType(dart.dynamic, [])})
  });
  closure_parameter_types_test.main = function() {
    let invokeCount = 0;
    function closure(a) {
      if (invokeCount++ == 1) {
        expect$.Expect.isTrue(typeof a == 'number');
      }
    }
    dart.fn(closure, dynamicTodynamic());
    closure('s');
    new closure_parameter_types_test.A(closure)[_do]();
    expect$.Expect.equals(2, invokeCount);
  };
  dart.fn(closure_parameter_types_test.main, VoidTodynamic());
  // Exports:
  exports.closure_parameter_types_test = closure_parameter_types_test;
});
