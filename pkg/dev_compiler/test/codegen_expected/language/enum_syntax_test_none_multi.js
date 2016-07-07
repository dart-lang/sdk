dart_library.library('language/enum_syntax_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__enum_syntax_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const enum_syntax_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  enum_syntax_test_none_multi.Color = class Color extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Color.red",
        1: "Color.orange",
        2: "Color.yellow",
        3: "Color.green"
      }[this.index];
    }
  };
  enum_syntax_test_none_multi.Color.red = dart.const(new enum_syntax_test_none_multi.Color(0));
  enum_syntax_test_none_multi.Color.orange = dart.const(new enum_syntax_test_none_multi.Color(1));
  enum_syntax_test_none_multi.Color.yellow = dart.const(new enum_syntax_test_none_multi.Color(2));
  enum_syntax_test_none_multi.Color.green = dart.const(new enum_syntax_test_none_multi.Color(3));
  enum_syntax_test_none_multi.Color.values = dart.constList([enum_syntax_test_none_multi.Color.red, enum_syntax_test_none_multi.Color.orange, enum_syntax_test_none_multi.Color.yellow, enum_syntax_test_none_multi.Color.green], enum_syntax_test_none_multi.Color);
  enum_syntax_test_none_multi.Veggies = class Veggies extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Veggies.carrot",
        1: "Veggies.bean",
        2: "Veggies.broccolo"
      }[this.index];
    }
  };
  enum_syntax_test_none_multi.Veggies.carrot = dart.const(new enum_syntax_test_none_multi.Veggies(0));
  enum_syntax_test_none_multi.Veggies.bean = dart.const(new enum_syntax_test_none_multi.Veggies(1));
  enum_syntax_test_none_multi.Veggies.broccolo = dart.const(new enum_syntax_test_none_multi.Veggies(2));
  enum_syntax_test_none_multi.Veggies.values = dart.constList([enum_syntax_test_none_multi.Veggies.carrot, enum_syntax_test_none_multi.Veggies.bean, enum_syntax_test_none_multi.Veggies.broccolo], enum_syntax_test_none_multi.Veggies);
  enum_syntax_test_none_multi.topLevelFunction = function() {
    return null;
  };
  dart.fn(enum_syntax_test_none_multi.topLevelFunction, VoidTodynamic());
  enum_syntax_test_none_multi.C = class C extends core.Object {};
  enum_syntax_test_none_multi.zzTop = null;
  enum_syntax_test_none_multi.main = function() {
  };
  dart.fn(enum_syntax_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.enum_syntax_test_none_multi = enum_syntax_test_none_multi;
});
