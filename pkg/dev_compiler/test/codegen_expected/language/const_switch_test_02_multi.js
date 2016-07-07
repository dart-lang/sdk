dart_library.library('language/const_switch_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_switch_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_switch_test_02_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let CToString = () => (CToString = dart.constFn(dart.definiteFunctionType(core.String, [const_switch_test_02_multi.C])))();
  const_switch_test_02_multi.C = class C extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(const_switch_test_02_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(const_switch_test_02_multi.C, [dart.dynamic])})
  });
  const_switch_test_02_multi.c1 = dart.const(new const_switch_test_02_multi.C(0.0));
  const_switch_test_02_multi.c2 = dart.const(new const_switch_test_02_multi.C(0));
  const_switch_test_02_multi.c3 = dart.const(new const_switch_test_02_multi.C(0.5 + 0.5));
  const_switch_test_02_multi.c4 = dart.const(new const_switch_test_02_multi.C(1));
  const_switch_test_02_multi.main = function() {
    expect$.Expect.equals('0', const_switch_test_02_multi.test(const_switch_test_02_multi.c2));
  };
  dart.fn(const_switch_test_02_multi.main, VoidTodynamic());
  let const$;
  let const$0;
  let const$1;
  let const$2;
  const_switch_test_02_multi.test = function(c) {
    switch (c) {
      case const$ || (const$ = dart.const(new const_switch_test_02_multi.C(0.0))):
      {
        return '0.0';
      }
      case const$0 || (const$0 = dart.const(new const_switch_test_02_multi.C(0))):
      {
        return '0';
      }
      case const$1 || (const$1 = dart.const(new const_switch_test_02_multi.C(1.0))):
      {
        return '1.0';
      }
      case const$2 || (const$2 = dart.const(new const_switch_test_02_multi.C(1))):
      {
        return '1';
      }
    }
    return null;
  };
  dart.fn(const_switch_test_02_multi.test, CToString());
  // Exports:
  exports.const_switch_test_02_multi = const_switch_test_02_multi;
});
