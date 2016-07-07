dart_library.library('corelib/symbol_reserved_word_test_12_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__symbol_reserved_word_test_12_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const symbol_reserved_word_test_12_multi = Object.create(null);
  let VoidToSymbol = () => (VoidToSymbol = dart.constFn(dart.definiteFunctionType(core.Symbol, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  symbol_reserved_word_test_12_multi.checkBadSymbol = function(s) {
    expect$.Expect.throws(dart.fn(() => core.Symbol.new(s), VoidToSymbol()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
  };
  dart.fn(symbol_reserved_word_test_12_multi.checkBadSymbol, StringTovoid());
  symbol_reserved_word_test_12_multi.main = function() {
    let x = null;
    symbol_reserved_word_test_12_multi.checkBadSymbol('assert');
    symbol_reserved_word_test_12_multi.checkBadSymbol('break');
    symbol_reserved_word_test_12_multi.checkBadSymbol('case');
    symbol_reserved_word_test_12_multi.checkBadSymbol('catch');
    symbol_reserved_word_test_12_multi.checkBadSymbol('class');
    symbol_reserved_word_test_12_multi.checkBadSymbol('const');
    symbol_reserved_word_test_12_multi.checkBadSymbol('continue');
    symbol_reserved_word_test_12_multi.checkBadSymbol('default');
    symbol_reserved_word_test_12_multi.checkBadSymbol('do');
    symbol_reserved_word_test_12_multi.checkBadSymbol('else');
    symbol_reserved_word_test_12_multi.checkBadSymbol('enum');
    symbol_reserved_word_test_12_multi.checkBadSymbol('extends');
    symbol_reserved_word_test_12_multi.checkBadSymbol('false');
    symbol_reserved_word_test_12_multi.checkBadSymbol('final');
    symbol_reserved_word_test_12_multi.checkBadSymbol('finally');
    symbol_reserved_word_test_12_multi.checkBadSymbol('for');
    symbol_reserved_word_test_12_multi.checkBadSymbol('if');
    symbol_reserved_word_test_12_multi.checkBadSymbol('in');
    symbol_reserved_word_test_12_multi.checkBadSymbol('is');
    symbol_reserved_word_test_12_multi.checkBadSymbol('new');
    symbol_reserved_word_test_12_multi.checkBadSymbol('null');
    symbol_reserved_word_test_12_multi.checkBadSymbol('rethrow');
    symbol_reserved_word_test_12_multi.checkBadSymbol('return');
    symbol_reserved_word_test_12_multi.checkBadSymbol('super');
    symbol_reserved_word_test_12_multi.checkBadSymbol('switch');
    symbol_reserved_word_test_12_multi.checkBadSymbol('this');
    symbol_reserved_word_test_12_multi.checkBadSymbol('throw');
    symbol_reserved_word_test_12_multi.checkBadSymbol('true');
    symbol_reserved_word_test_12_multi.checkBadSymbol('try');
    symbol_reserved_word_test_12_multi.checkBadSymbol('var');
    symbol_reserved_word_test_12_multi.checkBadSymbol('while');
    symbol_reserved_word_test_12_multi.checkBadSymbol('with');
  };
  dart.fn(symbol_reserved_word_test_12_multi.main, VoidTodynamic());
  // Exports:
  exports.symbol_reserved_word_test_12_multi = symbol_reserved_word_test_12_multi;
});
