dart_library.library('corelib/symbol_reserved_word_test_06_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__symbol_reserved_word_test_06_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const symbol_reserved_word_test_06_multi = Object.create(null);
  let VoidToSymbol = () => (VoidToSymbol = dart.constFn(dart.definiteFunctionType(core.Symbol, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  symbol_reserved_word_test_06_multi.checkBadSymbol = function(s) {
    expect$.Expect.throws(dart.fn(() => core.Symbol.new(s), VoidToSymbol()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
  };
  dart.fn(symbol_reserved_word_test_06_multi.checkBadSymbol, StringTovoid());
  symbol_reserved_word_test_06_multi.main = function() {
    let x = null;
    symbol_reserved_word_test_06_multi.checkBadSymbol('void.foo');
  };
  dart.fn(symbol_reserved_word_test_06_multi.main, VoidTodynamic());
  // Exports:
  exports.symbol_reserved_word_test_06_multi = symbol_reserved_word_test_06_multi;
});
