dart_library.library('language/enum_index_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__enum_index_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const enum_index_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  enum_index_test.Enum = class Enum extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Enum.A",
        1: "Enum.B"
      }[this.index];
    }
  };
  enum_index_test.Enum.A = dart.const(new enum_index_test.Enum(0));
  enum_index_test.Enum.B = dart.const(new enum_index_test.Enum(1));
  enum_index_test.Enum.values = dart.constList([enum_index_test.Enum.A, enum_index_test.Enum.B], enum_index_test.Enum);
  enum_index_test.Class = class Class extends core.Object {
    new() {
      this.index = null;
    }
  };
  enum_index_test.main = function() {
    enum_index_test.test(null, new enum_index_test.Class());
    enum_index_test.test(0, enum_index_test.Enum.A);
    enum_index_test.test(1, enum_index_test.Enum.B);
  };
  dart.fn(enum_index_test.main, VoidTodynamic());
  enum_index_test.test = function(expected, object) {
    expect$.Expect.equals(expected, dart.dload(object, 'index'));
  };
  dart.fn(enum_index_test.test, dynamicAnddynamicTodynamic());
  // Exports:
  exports.enum_index_test = enum_index_test;
});
