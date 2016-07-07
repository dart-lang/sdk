dart_library.library('language/enum_duplicate_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__enum_duplicate_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const enum_duplicate_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  enum_duplicate_test_none_multi.Enum1 = class Enum1 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum1.A",
        1: "Enum1.B"
      }[this.index];
    }
  };
  enum_duplicate_test_none_multi.Enum1.A = dart.const(new enum_duplicate_test_none_multi.Enum1(0));
  enum_duplicate_test_none_multi.Enum1.B = dart.const(new enum_duplicate_test_none_multi.Enum1(1));
  enum_duplicate_test_none_multi.Enum1.values = dart.constList([enum_duplicate_test_none_multi.Enum1.A, enum_duplicate_test_none_multi.Enum1.B], enum_duplicate_test_none_multi.Enum1);
  enum_duplicate_test_none_multi.Enum2 = class Enum2 extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum2.A",
        1: "Enum2.B"
      }[this.index];
    }
  };
  enum_duplicate_test_none_multi.Enum2.A = dart.const(new enum_duplicate_test_none_multi.Enum2(0));
  enum_duplicate_test_none_multi.Enum2.B = dart.const(new enum_duplicate_test_none_multi.Enum2(1));
  enum_duplicate_test_none_multi.Enum2.values = dart.constList([enum_duplicate_test_none_multi.Enum2.A, enum_duplicate_test_none_multi.Enum2.B], enum_duplicate_test_none_multi.Enum2);
  enum_duplicate_test_none_multi.main = function() {
    expect$.Expect.equals('Enum1.A,Enum1.B', enum_duplicate_test_none_multi.Enum1.values[dartx.join](','));
    expect$.Expect.equals('Enum2.A,Enum2.B', enum_duplicate_test_none_multi.Enum2.values[dartx.join](','));
  };
  dart.fn(enum_duplicate_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.enum_duplicate_test_none_multi = enum_duplicate_test_none_multi;
});
