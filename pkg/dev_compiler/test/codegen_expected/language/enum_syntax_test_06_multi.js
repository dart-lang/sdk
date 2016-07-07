dart_library.library('language/enum_syntax_test_06_multi', null, /* Imports */[
  'dart_sdk'
], function load__enum_syntax_test_06_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const enum_syntax_test_06_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  enum_syntax_test_06_multi.Color = class Color extends core.Object {
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
  enum_syntax_test_06_multi.Color.red = dart.const(new enum_syntax_test_06_multi.Color(0));
  enum_syntax_test_06_multi.Color.orange = dart.const(new enum_syntax_test_06_multi.Color(1));
  enum_syntax_test_06_multi.Color.yellow = dart.const(new enum_syntax_test_06_multi.Color(2));
  enum_syntax_test_06_multi.Color.green = dart.const(new enum_syntax_test_06_multi.Color(3));
  enum_syntax_test_06_multi.Color.values = dart.constList([enum_syntax_test_06_multi.Color.red, enum_syntax_test_06_multi.Color.orange, enum_syntax_test_06_multi.Color.yellow, enum_syntax_test_06_multi.Color.green], enum_syntax_test_06_multi.Color);
  enum_syntax_test_06_multi.Veggies = class Veggies extends core.Object {
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
  enum_syntax_test_06_multi.Veggies.carrot = dart.const(new enum_syntax_test_06_multi.Veggies(0));
  enum_syntax_test_06_multi.Veggies.bean = dart.const(new enum_syntax_test_06_multi.Veggies(1));
  enum_syntax_test_06_multi.Veggies.broccolo = dart.const(new enum_syntax_test_06_multi.Veggies(2));
  enum_syntax_test_06_multi.Veggies.values = dart.constList([enum_syntax_test_06_multi.Veggies.carrot, enum_syntax_test_06_multi.Veggies.bean, enum_syntax_test_06_multi.Veggies.broccolo], enum_syntax_test_06_multi.Veggies);
  enum_syntax_test_06_multi.ComeAgain = class ComeAgain extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "ComeAgain.ahau",
        1: "ComeAgain.knust",
        2: "ComeAgain.zipfel",
        3: "ComeAgain.ComeAgain"
      }[this.index];
    }
  };
  enum_syntax_test_06_multi.ComeAgain.ahau = dart.const(new enum_syntax_test_06_multi.ComeAgain(0));
  enum_syntax_test_06_multi.ComeAgain.knust = dart.const(new enum_syntax_test_06_multi.ComeAgain(1));
  enum_syntax_test_06_multi.ComeAgain.zipfel = dart.const(new enum_syntax_test_06_multi.ComeAgain(2));
  enum_syntax_test_06_multi.ComeAgain.ComeAgain = dart.const(new enum_syntax_test_06_multi.ComeAgain(3));
  enum_syntax_test_06_multi.ComeAgain.values = dart.constList([enum_syntax_test_06_multi.ComeAgain.ahau, enum_syntax_test_06_multi.ComeAgain.knust, enum_syntax_test_06_multi.ComeAgain.zipfel, enum_syntax_test_06_multi.ComeAgain.ComeAgain], enum_syntax_test_06_multi.ComeAgain);
  enum_syntax_test_06_multi.topLevelFunction = function() {
    return null;
  };
  dart.fn(enum_syntax_test_06_multi.topLevelFunction, VoidTodynamic());
  enum_syntax_test_06_multi.C = class C extends core.Object {};
  enum_syntax_test_06_multi.zzTop = null;
  enum_syntax_test_06_multi.main = function() {
    let x = enum_syntax_test_06_multi.ComeAgain.zipfel;
  };
  dart.fn(enum_syntax_test_06_multi.main, VoidTodynamic());
  // Exports:
  exports.enum_syntax_test_06_multi = enum_syntax_test_06_multi;
});
