dart_library.library('language/parameter_types_specialization_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__parameter_types_specialization_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const parameter_types_specialization_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  parameter_types_specialization_test.A = class A extends core.Object {
    foo(firstInvocation, a, b) {
      if (a === void 0) a = 42;
      if (b === void 0) b = 'foo';
      if (dart.test(firstInvocation)) {
        expect$.Expect.isTrue(typeof a == 'string');
        expect$.Expect.isTrue(typeof b == 'number');
      } else {
        expect$.Expect.isTrue(typeof a == 'number');
        expect$.Expect.isTrue(typeof b == 'string');
      }
    }
  };
  dart.setSignature(parameter_types_specialization_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.void, [core.bool], [dart.dynamic, dart.dynamic])})
  });
  parameter_types_specialization_test.test = function() {
    new parameter_types_specialization_test.A().foo(false);
  };
  dart.fn(parameter_types_specialization_test.test, VoidTodynamic());
  parameter_types_specialization_test.main = function() {
    parameter_types_specialization_test.test();
    new parameter_types_specialization_test.A().foo(true, 'bar', 42);
  };
  dart.fn(parameter_types_specialization_test.main, VoidTodynamic());
  // Exports:
  exports.parameter_types_specialization_test = parameter_types_specialization_test;
});
