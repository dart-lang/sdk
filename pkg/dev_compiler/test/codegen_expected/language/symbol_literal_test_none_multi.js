dart_library.library('language/symbol_literal_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__symbol_literal_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const symbol_literal_test_none_multi = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let SymbolTodynamic = () => (SymbolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.Symbol])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  symbol_literal_test_none_multi.foo = function(a, b) {
    return expect$.Expect.isTrue(core.identical(a, b));
  };
  dart.fn(symbol_literal_test_none_multi.foo, dynamicAnddynamicTodynamic());
  symbol_literal_test_none_multi.check = symbol_literal_test_none_multi.foo;
  let const$;
  let const$0;
  symbol_literal_test_none_multi.testSwitch = function(s) {
    switch (s) {
      case const$ || (const$ = dart.const(core.Symbol.new('abc'))):
      {
        return 1;
      }
      case const$0 || (const$0 = dart.const(core.Symbol.new("def"))):
      {
        return 2;
      }
      default:
      {
        return 0;
      }
    }
  };
  dart.fn(symbol_literal_test_none_multi.testSwitch, SymbolTodynamic());
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  let const$7;
  let const$8;
  let const$9;
  let const$10;
  let const$11;
  let const$12;
  let const$13;
  let const$14;
  let const$15;
  let const$16;
  let const$17;
  let const$18;
  let const$19;
  let const$20;
  let const$21;
  let const$22;
  let const$23;
  symbol_literal_test_none_multi.main = function() {
    dart.dcall(symbol_literal_test_none_multi.check, const$1 || (const$1 = dart.const(core.Symbol.new("a"))), const$2 || (const$2 = dart.const(core.Symbol.new('a'))));
    dart.dcall(symbol_literal_test_none_multi.check, const$3 || (const$3 = dart.const(core.Symbol.new("a"))), const$4 || (const$4 = dart.const(core.Symbol.new('a'))));
    dart.dcall(symbol_literal_test_none_multi.check, const$5 || (const$5 = dart.const(core.Symbol.new("ab"))), const$6 || (const$6 = dart.const(core.Symbol.new('ab'))));
    dart.dcall(symbol_literal_test_none_multi.check, const$7 || (const$7 = dart.const(core.Symbol.new("ab"))), const$8 || (const$8 = dart.const(core.Symbol.new('ab'))));
    dart.dcall(symbol_literal_test_none_multi.check, const$9 || (const$9 = dart.const(core.Symbol.new("a.b"))), const$10 || (const$10 = dart.const(core.Symbol.new('a.b'))));
    dart.dcall(symbol_literal_test_none_multi.check, const$11 || (const$11 = dart.const(core.Symbol.new("a.b"))), const$12 || (const$12 = dart.const(core.Symbol.new('a.b'))));
    dart.dcall(symbol_literal_test_none_multi.check, const$13 || (const$13 = dart.const(core.Symbol.new("=="))), const$14 || (const$14 = dart.const(core.Symbol.new('=='))));
    dart.dcall(symbol_literal_test_none_multi.check, const$15 || (const$15 = dart.const(core.Symbol.new("=="))), const$16 || (const$16 = dart.const(core.Symbol.new('=='))));
    dart.dcall(symbol_literal_test_none_multi.check, const$17 || (const$17 = dart.const(core.Symbol.new("a.toString"))), const$18 || (const$18 = dart.const(core.Symbol.new('a.toString'))));
    expect$.Expect.equals(1, symbol_literal_test_none_multi.testSwitch(const$19 || (const$19 = dart.const(core.Symbol.new('abc')))));
    let m = const$22 || (const$22 = dart.const(dart.map([const$20 || (const$20 = dart.const(core.Symbol.new('A'))), 0, const$21 || (const$21 = dart.const(core.Symbol.new('B'))), 1], core.Symbol, core.int)));
    expect$.Expect.equals(1, m[dartx.get](const$23 || (const$23 = dart.const(core.Symbol.new('B')))));
  };
  dart.fn(symbol_literal_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.symbol_literal_test_none_multi = symbol_literal_test_none_multi;
});
