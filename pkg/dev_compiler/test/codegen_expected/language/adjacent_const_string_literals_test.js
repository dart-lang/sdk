dart_library.library('language/adjacent_const_string_literals_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__adjacent_const_string_literals_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const adjacent_const_string_literals_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  adjacent_const_string_literals_test.Conster = class Conster extends core.Object {
    new(value) {
      this.value = value;
    }
    toString() {
      return dart.toString(this.value);
    }
  };
  dart.setSignature(adjacent_const_string_literals_test.Conster, {
    constructors: () => ({new: dart.definiteFunctionType(adjacent_const_string_literals_test.Conster, [dart.dynamic])})
  });
  adjacent_const_string_literals_test.main = function() {
    adjacent_const_string_literals_test.testEmpty();
    adjacent_const_string_literals_test.testInterpolation();
    adjacent_const_string_literals_test.testMultiline();
  };
  dart.fn(adjacent_const_string_literals_test.main, VoidTodynamic());
  let const$;
  let const$0;
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
  adjacent_const_string_literals_test.testEmpty = function() {
    expect$.Expect.equals("", (const$ || (const$ = dart.const(new adjacent_const_string_literals_test.Conster("" + "" + "")))).toString());
    expect$.Expect.equals("", (const$0 || (const$0 = dart.const(new adjacent_const_string_literals_test.Conster("" + '' + "")))).toString());
    expect$.Expect.equals("", (const$1 || (const$1 = dart.const(new adjacent_const_string_literals_test.Conster("" + "" + "")))).toString());
    expect$.Expect.equals("a", (const$2 || (const$2 = dart.const(new adjacent_const_string_literals_test.Conster("a" + "")))).toString());
    expect$.Expect.equals("a", (const$3 || (const$3 = dart.const(new adjacent_const_string_literals_test.Conster("a" + '')))).toString());
    expect$.Expect.equals("a", (const$4 || (const$4 = dart.const(new adjacent_const_string_literals_test.Conster("a" + '')))).toString());
    expect$.Expect.equals("b", (const$5 || (const$5 = dart.const(new adjacent_const_string_literals_test.Conster('b' + "")))).toString());
    expect$.Expect.equals("b", (const$6 || (const$6 = dart.const(new adjacent_const_string_literals_test.Conster('b' + '')))).toString());
    expect$.Expect.equals("b", (const$7 || (const$7 = dart.const(new adjacent_const_string_literals_test.Conster('b' + '')))).toString());
    expect$.Expect.equals("c", (const$8 || (const$8 = dart.const(new adjacent_const_string_literals_test.Conster('c' + "")))).toString());
    expect$.Expect.equals("c", (const$9 || (const$9 = dart.const(new adjacent_const_string_literals_test.Conster('c' + '')))).toString());
    expect$.Expect.equals("c", (const$10 || (const$10 = dart.const(new adjacent_const_string_literals_test.Conster('c' + '')))).toString());
    expect$.Expect.equals("a", (const$11 || (const$11 = dart.const(new adjacent_const_string_literals_test.Conster("" + "a")))).toString());
    expect$.Expect.equals("a", (const$12 || (const$12 = dart.const(new adjacent_const_string_literals_test.Conster("" + 'a')))).toString());
    expect$.Expect.equals("a", (const$13 || (const$13 = dart.const(new adjacent_const_string_literals_test.Conster("" + 'a')))).toString());
    expect$.Expect.equals("b", (const$14 || (const$14 = dart.const(new adjacent_const_string_literals_test.Conster('' + "b")))).toString());
    expect$.Expect.equals("b", (const$15 || (const$15 = dart.const(new adjacent_const_string_literals_test.Conster('' + 'b')))).toString());
    expect$.Expect.equals("b", (const$16 || (const$16 = dart.const(new adjacent_const_string_literals_test.Conster('' + 'b')))).toString());
    expect$.Expect.equals("c", (const$17 || (const$17 = dart.const(new adjacent_const_string_literals_test.Conster('' + "c")))).toString());
    expect$.Expect.equals("c", (const$18 || (const$18 = dart.const(new adjacent_const_string_literals_test.Conster('' + 'c')))).toString());
    expect$.Expect.equals("c", (const$19 || (const$19 = dart.const(new adjacent_const_string_literals_test.Conster('' + 'c')))).toString());
  };
  dart.fn(adjacent_const_string_literals_test.testEmpty, VoidTodynamic());
  adjacent_const_string_literals_test.s = "a";
  let const$20;
  let const$21;
  let const$22;
  let const$23;
  let const$24;
  let const$25;
  let const$26;
  let const$27;
  let const$28;
  let const$29;
  let const$30;
  let const$31;
  adjacent_const_string_literals_test.testInterpolation = function() {
    expect$.Expect.equals("ab", (const$20 || (const$20 = dart.const(new adjacent_const_string_literals_test.Conster(dart.str`${adjacent_const_string_literals_test.s}` + "b")))).toString());
    expect$.Expect.equals("ab", (const$21 || (const$21 = dart.const(new adjacent_const_string_literals_test.Conster(dart.str`${adjacent_const_string_literals_test.s}` + "b")))).toString());
    expect$.Expect.equals("$sb", (const$22 || (const$22 = dart.const(new adjacent_const_string_literals_test.Conster('$s' + "b")))).toString());
    expect$.Expect.equals("-a-b", (const$23 || (const$23 = dart.const(new adjacent_const_string_literals_test.Conster(dart.str`-${adjacent_const_string_literals_test.s}-` + "b")))).toString());
    expect$.Expect.equals("-a-b", (const$24 || (const$24 = dart.const(new adjacent_const_string_literals_test.Conster(dart.str`-${adjacent_const_string_literals_test.s}-` + "b")))).toString());
    expect$.Expect.equals("-$s-b", (const$25 || (const$25 = dart.const(new adjacent_const_string_literals_test.Conster('-$s-' + "b")))).toString());
    expect$.Expect.equals("ba", (const$26 || (const$26 = dart.const(new adjacent_const_string_literals_test.Conster('b' + dart.str`${adjacent_const_string_literals_test.s}`)))).toString());
    expect$.Expect.equals("ba", (const$27 || (const$27 = dart.const(new adjacent_const_string_literals_test.Conster('b' + dart.str`${adjacent_const_string_literals_test.s}`)))).toString());
    expect$.Expect.equals("b$s", (const$28 || (const$28 = dart.const(new adjacent_const_string_literals_test.Conster('b' + '$s')))).toString());
    expect$.Expect.equals("b-a-", (const$29 || (const$29 = dart.const(new adjacent_const_string_literals_test.Conster('b' + dart.str`-${adjacent_const_string_literals_test.s}-`)))).toString());
    expect$.Expect.equals("b-a-", (const$30 || (const$30 = dart.const(new adjacent_const_string_literals_test.Conster('b' + dart.str`-${adjacent_const_string_literals_test.s}-`)))).toString());
    expect$.Expect.equals("b-$s-", (const$31 || (const$31 = dart.const(new adjacent_const_string_literals_test.Conster('b' + '-$s-')))).toString());
  };
  dart.fn(adjacent_const_string_literals_test.testInterpolation, VoidTodynamic());
  let const$32;
  let const$33;
  let const$34;
  let const$35;
  let const$36;
  let const$37;
  adjacent_const_string_literals_test.testMultiline = function() {
    expect$.Expect.equals("abe", (const$32 || (const$32 = dart.const(new adjacent_const_string_literals_test.Conster("a" + "b" + "e")))).toString());
    expect$.Expect.equals("a b e", (const$33 || (const$33 = dart.const(new adjacent_const_string_literals_test.Conster("a " + "b " + "e")))).toString());
    expect$.Expect.equals("a b e", (const$34 || (const$34 = dart.const(new adjacent_const_string_literals_test.Conster("a" + " b" + " e")))).toString());
    expect$.Expect.equals("abe", (const$35 || (const$35 = dart.const(new adjacent_const_string_literals_test.Conster("a" + "b" + "e")))).toString());
    expect$.Expect.equals("a b e", (const$36 || (const$36 = dart.const(new adjacent_const_string_literals_test.Conster("a" + " b" + " e")))).toString());
    expect$.Expect.equals("abe", (const$37 || (const$37 = dart.const(new adjacent_const_string_literals_test.Conster("a" + "b" + "e")))).toString());
  };
  dart.fn(adjacent_const_string_literals_test.testMultiline, VoidTodynamic());
  // Exports:
  exports.adjacent_const_string_literals_test = adjacent_const_string_literals_test;
});
