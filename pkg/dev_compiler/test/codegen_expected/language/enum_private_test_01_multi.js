dart_library.library('language/enum_private_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__enum_private_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const enum_private_test_01_multi = Object.create(null);
  const enum_private_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  enum_private_test_01_multi.Enum1 = class Enum1 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum1._A",
        1: "Enum1._B"
      }[this.index];
    }
  };
  enum_private_test_01_multi.Enum1._A = dart.const(new enum_private_test_01_multi.Enum1(0));
  enum_private_test_01_multi.Enum1._B = dart.const(new enum_private_test_01_multi.Enum1(1));
  enum_private_test_01_multi.Enum1.values = dart.constList([enum_private_test_01_multi.Enum1._A, enum_private_test_01_multi.Enum1._B], enum_private_test_01_multi.Enum1);
  enum_private_test_01_multi.main = function() {
    expect$.Expect.equals('Enum1._A,Enum1._B', enum_private_test_01_multi.Enum1.values[dartx.join](','));
    expect$.Expect.equals('Enum2._A,Enum2._B', enum_private_lib.Enum2.values[dartx.join](','));
  };
  dart.fn(enum_private_test_01_multi.main, VoidTodynamic());
  enum_private_lib.Enum2 = class Enum2 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum2._A",
        1: "Enum2._B"
      }[this.index];
    }
  };
  enum_private_lib.Enum2._A = dart.const(new enum_private_lib.Enum2(0));
  enum_private_lib.Enum2._B = dart.const(new enum_private_lib.Enum2(1));
  enum_private_lib.Enum2.values = dart.constList([enum_private_lib.Enum2._A, enum_private_lib.Enum2._B], enum_private_lib.Enum2);
  // Exports:
  exports.enum_private_test_01_multi = enum_private_test_01_multi;
  exports.enum_private_lib = enum_private_lib;
});
