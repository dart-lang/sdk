dart_library.library('language/generic_object_type_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_object_type_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_object_type_test = Object.create(null);
  let Tester = () => (Tester = dart.constFn(generic_object_type_test.Tester$()))();
  let TesterOfObject = () => (TesterOfObject = dart.constFn(generic_object_type_test.Tester$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_object_type_test.Tester$ = dart.generic(T => {
    class Tester extends core.Object {
      testGenericType(x) {
        return T.is(x);
      }
    }
    dart.addTypeTests(Tester);
    dart.setSignature(Tester, {
      methods: () => ({testGenericType: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return Tester;
  });
  generic_object_type_test.Tester = Tester();
  generic_object_type_test.main = function() {
    expect$.Expect.isTrue(new (TesterOfObject())().testGenericType(new core.Object()));
  };
  dart.fn(generic_object_type_test.main, VoidTodynamic());
  // Exports:
  exports.generic_object_type_test = generic_object_type_test;
});
