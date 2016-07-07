dart_library.library('language/type_parameter_literal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_parameter_literal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_parameter_literal_test = Object.create(null);
  let D = () => (D = dart.constFn(type_parameter_literal_test.D$()))();
  let DOfint = () => (DOfint = dart.constFn(type_parameter_literal_test.D$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_parameter_literal_test.D$ = dart.generic(T => {
    class D extends core.Object {
      getT() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(D);
    dart.setSignature(D, {
      methods: () => ({getT: dart.definiteFunctionType(core.Type, [])})
    });
    return D;
  });
  type_parameter_literal_test.D = D();
  type_parameter_literal_test.main = function() {
    expect$.Expect.equals(dart.wrapType(core.int), new (DOfint())().getT());
  };
  dart.fn(type_parameter_literal_test.main, VoidTodynamic());
  // Exports:
  exports.type_parameter_literal_test = type_parameter_literal_test;
});
