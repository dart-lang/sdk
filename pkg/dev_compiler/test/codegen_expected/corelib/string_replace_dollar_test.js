dart_library.library('corelib/string_replace_dollar_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_replace_dollar_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_replace_dollar_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_replace_dollar_test.main = function() {
    let jsText = "'$'\n";
    let htmlStr = '%%DART';
    let htmlOut = htmlStr[dartx.replaceAll]("%%DART", jsText);
    expect$.Expect.equals(jsText, htmlOut);
    htmlOut = htmlStr[dartx.replaceFirst]("%%DART", jsText);
    expect$.Expect.equals(jsText, htmlOut);
    htmlOut = htmlStr[dartx.replaceAll](core.RegExp.new("%%DART"), jsText);
    expect$.Expect.equals(jsText, htmlOut);
    htmlOut = htmlStr[dartx.replaceFirst](core.RegExp.new("%%DART"), jsText);
    expect$.Expect.equals(jsText, htmlOut);
    let doubleDollar = "$'$`";
    let string = "flip-flip-flop";
    let result = string[dartx.replaceFirst]("flip", doubleDollar);
    expect$.Expect.equals("$'$`-flip-flop", result);
    result = string[dartx.replaceAll]("flip", doubleDollar);
    expect$.Expect.equals("$'$`-$'$`-flop", result);
  };
  dart.fn(string_replace_dollar_test.main, VoidTodynamic());
  // Exports:
  exports.string_replace_dollar_test = string_replace_dollar_test;
});
