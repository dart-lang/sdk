dart_library.library('language/regress_14105_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_14105_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_14105_test = Object.create(null);
  let A = () => (A = dart.constFn(regress_14105_test.A$()))();
  let AOfClassOnlyForRti = () => (AOfClassOnlyForRti = dart.constFn(regress_14105_test.A$(regress_14105_test.ClassOnlyForRti)))();
  let AOfint = () => (AOfint = dart.constFn(regress_14105_test.A$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_14105_test.UsedAsFieldType = dart.typedef('UsedAsFieldType', () => dart.functionType(dart.dynamic, []));
  regress_14105_test.ClassOnlyForRti = class ClassOnlyForRti extends core.Object {
    new() {
      this.field = null;
    }
  };
  regress_14105_test.A$ = dart.generic(T => {
    class A extends core.Object {
      new() {
        this.field = null;
      }
    }
    dart.addTypeTests(A);
    return A;
  });
  regress_14105_test.A = A();
  regress_14105_test.use = function(a) {
    return dart.dput(a, 'field', "");
  };
  dart.fn(regress_14105_test.use, dynamicTodynamic());
  regress_14105_test.useFieldSetter = regress_14105_test.use;
  regress_14105_test.main = function() {
    let a = new (AOfClassOnlyForRti())();
    dart.dcall(regress_14105_test.useFieldSetter, a);
    core.print(AOfint().is(a));
  };
  dart.fn(regress_14105_test.main, VoidTodynamic());
  // Exports:
  exports.regress_14105_test = regress_14105_test;
});
