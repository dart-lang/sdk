dart_library.library('language/adjacent_string_literals_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__adjacent_string_literals_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const adjacent_string_literals_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  adjacent_string_literals_test.main = function() {
    adjacent_string_literals_test.testEmpty();
    adjacent_string_literals_test.testInterpolation();
    adjacent_string_literals_test.testMultiline();
  };
  dart.fn(adjacent_string_literals_test.main, VoidTodynamic());
  adjacent_string_literals_test.testEmpty = function() {
    expect$.Expect.equals("", "" + "" + "");
    expect$.Expect.equals("", "" + '' + "");
    expect$.Expect.equals("", "" + "" + "");
    expect$.Expect.equals("a", "a" + "");
    expect$.Expect.equals("a", "a" + '');
    expect$.Expect.equals("a", "a" + '');
    expect$.Expect.equals("b", 'b' + "");
    expect$.Expect.equals("b", 'b' + '');
    expect$.Expect.equals("b", 'b' + '');
    expect$.Expect.equals("c", 'c' + "");
    expect$.Expect.equals("c", 'c' + '');
    expect$.Expect.equals("c", 'c' + '');
    expect$.Expect.equals("a", "" + "a");
    expect$.Expect.equals("a", "" + 'a');
    expect$.Expect.equals("a", "" + 'a');
    expect$.Expect.equals("b", '' + "b");
    expect$.Expect.equals("b", '' + 'b');
    expect$.Expect.equals("b", '' + 'b');
    expect$.Expect.equals("c", '' + "c");
    expect$.Expect.equals("c", '' + 'c');
    expect$.Expect.equals("c", '' + 'c');
  };
  dart.fn(adjacent_string_literals_test.testEmpty, VoidTodynamic());
  adjacent_string_literals_test.testInterpolation = function() {
    let s = "a";
    expect$.Expect.equals("ab", dart.str`${s}` + "b");
    expect$.Expect.equals("ab", dart.str`${s}` + "b");
    expect$.Expect.equals("$sb", '$s' + "b");
    expect$.Expect.equals("-a-b", dart.str`-${s}-` + "b");
    expect$.Expect.equals("-a-b", dart.str`-${s}-` + "b");
    expect$.Expect.equals("-$s-b", '-$s-' + "b");
    expect$.Expect.equals("ba", 'b' + dart.str`${s}`);
    expect$.Expect.equals("ba", 'b' + dart.str`${s}`);
    expect$.Expect.equals("b$s", 'b' + '$s');
    expect$.Expect.equals("b-a-", 'b' + dart.str`-${s}-`);
    expect$.Expect.equals("b-a-", 'b' + dart.str`-${s}-`);
    expect$.Expect.equals("b-$s-", 'b' + '-$s-');
  };
  dart.fn(adjacent_string_literals_test.testInterpolation, VoidTodynamic());
  adjacent_string_literals_test.testMultiline = function() {
    expect$.Expect.equals("abe", "a" + "b" + "e");
    expect$.Expect.equals("a b e", "a " + "b " + "e");
    expect$.Expect.equals("a b e", "a" + " b" + " e");
    expect$.Expect.equals("abe", "a" + "b" + "e");
    expect$.Expect.equals("a b e", "a" + " b" + " e");
    expect$.Expect.equals("abe", "a" + "b" + "e");
  };
  dart.fn(adjacent_string_literals_test.testMultiline, VoidTodynamic());
  // Exports:
  exports.adjacent_string_literals_test = adjacent_string_literals_test;
});
