dart_library.library('language/smi_type_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__smi_type_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const smi_type_test = Object.create(null);
  let ComparableOfnum = () => (ComparableOfnum = dart.constFn(core.Comparable$(core.num)))();
  let ComparableOfString = () => (ComparableOfString = dart.constFn(core.Comparable$(core.String)))();
  let ComparableOfdouble = () => (ComparableOfdouble = dart.constFn(core.Comparable$(core.double)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  smi_type_test.main = function() {
    smi_type_test.isNum([]);
    smi_type_test.isNumRaw([]);
    smi_type_test.isNotNum([]);
    smi_type_test.isNotInt([]);
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isTrue(smi_type_test.isNum(i));
      expect$.Expect.isTrue(smi_type_test.isNumRaw(i));
      expect$.Expect.isFalse(smi_type_test.isNotNum(i));
      expect$.Expect.isFalse(smi_type_test.isNotInt(i));
    }
  };
  dart.fn(smi_type_test.main, VoidTodynamic());
  smi_type_test.isNum = function(a) {
    return ComparableOfnum().is(a);
  };
  dart.fn(smi_type_test.isNum, dynamicTodynamic());
  smi_type_test.isNumRaw = function(a) {
    return core.Comparable.is(a);
  };
  dart.fn(smi_type_test.isNumRaw, dynamicTodynamic());
  smi_type_test.isNotNum = function(a) {
    return ComparableOfString().is(a);
  };
  dart.fn(smi_type_test.isNotNum, dynamicTodynamic());
  smi_type_test.isNotInt = function(a) {
    return ComparableOfdouble().is(a);
  };
  dart.fn(smi_type_test.isNotInt, dynamicTodynamic());
  // Exports:
  exports.smi_type_test = smi_type_test;
});
