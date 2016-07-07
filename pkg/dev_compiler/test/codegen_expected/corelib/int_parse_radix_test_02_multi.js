dart_library.library('corelib/int_parse_radix_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int_parse_radix_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int_parse_radix_test_02_multi = Object.create(null);
  let intAndStringAndintTovoid = () => (intAndStringAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.String, core.int])))();
  let StringToint = () => (StringToint = dart.constFn(dart.definiteFunctionType(core.int, [core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StringAndintTovoid = () => (StringAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, core.int])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let StringAndintTodynamic = () => (StringAndintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.int])))();
  int_parse_radix_test_02_multi.main = function() {
    let checkedMode = false;
    dart.assert(checkedMode = true);
    let oneByteWhiteSpace = "\t\n\v\f\r " + " ";
    let whiteSpace = dart.str`${oneByteWhiteSpace} ᠎` + "           " + "\u2028\u2029  　﻿";
    let digits = "0123456789abcdefghijklmnopqrstuvwxyz";
    let zeros = "0"[dartx['*']](64);
    for (let i = 0; i < dart.notNull(whiteSpace[dartx.length]); i++) {
      let ws = whiteSpace[dartx.get](i);
      expect$.Expect.equals(0, core.int.parse(dart.str`${ws}0${ws}`, {radix: 2}));
    }
    function testParse(result, radixString, radix) {
      let m = dart.str`${radixString}/${radix}->${result}`;
      expect$.Expect.equals(result, core.int.parse(radixString[dartx.toLowerCase](), {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(radixString[dartx.toUpperCase](), {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str` ${radixString}`, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str`${radixString} `, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str` ${radixString} `, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str`+${radixString}`, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str` +${radixString}`, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str`+${radixString} `, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str` +${radixString} `, {radix: radix}), m);
      expect$.Expect.equals(-dart.notNull(result), core.int.parse(dart.str`-${radixString}`, {radix: radix}), m);
      expect$.Expect.equals(-dart.notNull(result), core.int.parse(dart.str` -${radixString}`, {radix: radix}), m);
      expect$.Expect.equals(-dart.notNull(result), core.int.parse(dart.str`-${radixString} `, {radix: radix}), m);
      expect$.Expect.equals(-dart.notNull(result), core.int.parse(dart.str` -${radixString} `, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str`${oneByteWhiteSpace}${radixString}${oneByteWhiteSpace}`, {radix: radix}), m);
      expect$.Expect.equals(-dart.notNull(result), core.int.parse(dart.str`${oneByteWhiteSpace}-${radixString}${oneByteWhiteSpace}`, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str`${whiteSpace}${radixString}${whiteSpace}`, {radix: radix}), m);
      expect$.Expect.equals(-dart.notNull(result), core.int.parse(dart.str`${whiteSpace}-${radixString}${whiteSpace}`, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str`${zeros}${radixString}`, {radix: radix}), m);
      expect$.Expect.equals(result, core.int.parse(dart.str`+${zeros}${radixString}`, {radix: radix}), m);
      expect$.Expect.equals(-dart.notNull(result), core.int.parse(dart.str`-${zeros}${radixString}`, {radix: radix}), m);
    }
    dart.fn(testParse, intAndStringAndintTovoid());
    for (let r = 2; r <= 36; r++) {
      for (let i = 0; i <= r * r; i++) {
        let radixString = i[dartx.toRadixString](r);
        testParse(i, radixString, r);
      }
    }
    for (let i = 2; i <= 36; i++) {
      let digit = digits[dartx.get](i - 1);
      testParse(dart.asInt(dart.notNull(math.pow(i, 64)) - 1), digit[dartx['*']](64), i);
      testParse(0, zeros, i);
    }
    expect$.Expect.equals(43981, core.int.parse("ABCD", {radix: 16}));
    expect$.Expect.equals(43981, core.int.parse("abcd", {radix: 16}));
    expect$.Expect.equals(15628859, core.int.parse("09azAZ", {radix: 36}));
    expect$.Expect.equals(24197857161011715162171839636988778104, core.int.parse("0x1234567812345678" + "1234567812345678"));
    expect$.Expect.equals(1, core.int.parse(" 1", {radix: 2}));
    expect$.Expect.equals(1, core.int.parse("1 ", {radix: 2}));
    expect$.Expect.equals(1, core.int.parse(" 1 ", {radix: 2}));
    expect$.Expect.equals(1, core.int.parse("\n1", {radix: 2}));
    expect$.Expect.equals(1, core.int.parse("1\n", {radix: 2}));
    expect$.Expect.equals(1, core.int.parse("\n1\n", {radix: 2}));
    expect$.Expect.equals(1, core.int.parse("+1", {radix: 2}));
    function testFails(source, radix) {
      expect$.Expect.throws(dart.fn(() => {
        dart.throw(core.int.parse(source, {radix: radix, onError: dart.fn(s => {
            dart.throw("FAIL");
          }, StringToint())}));
      }, VoidTovoid()), int_parse_radix_test_02_multi.isFail, dart.str`${source}/${radix}`);
      expect$.Expect.equals(-999, core.int.parse(source, {radix: radix, onError: dart.fn(s => -999, StringToint())}));
    }
    dart.fn(testFails, StringAndintTovoid());
    for (let i = 2; i < 36; i++) {
      let char = i[dartx.toRadixString](36);
      testFails(char[dartx.toLowerCase](), i);
      testFails(char[dartx.toUpperCase](), i);
    }
    testFails("", 2);
    testFails("+ 1", 2);
    testFails("- 1", 2);
    testFails("0x", null);
    for (let i = 2; i <= 33; i++) {
      testFails("0x10", i);
    }
    function testBadTypes(source, radix) {
      if (!checkedMode) {
        expect$.Expect.throws(dart.fn(() => core.int.parse(core.String._check(source), {radix: core.int._check(radix), onError: dart.fn(s => 0, StringToint())}), VoidToint()));
        return;
      }
      expect$.Expect.throws(dart.fn(() => core.int.parse(core.String._check(source), {radix: core.int._check(radix), onError: dart.fn(s => 0, StringToint())}), VoidToint()), dart.fn(e => core.TypeError.is(e) || core.CastError.is(e), dynamicTobool()));
    }
    dart.fn(testBadTypes, dynamicAnddynamicTodynamic());
    testBadTypes(9, 10);
    testBadTypes(true, 10);
    testBadTypes("0", true);
    testBadTypes("0", "10");
    function testBadArguments(source, radix) {
      expect$.Expect.throws(dart.fn(() => core.int.parse(source, {radix: radix, onError: dart.fn(s => 0, StringToint())}), VoidToint()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    }
    dart.fn(testBadArguments, StringAndintTodynamic());
    testBadArguments("0", -1);
    testBadArguments("0", 0);
    testBadArguments("0", 1);
    testBadArguments("0", 37);
  };
  dart.fn(int_parse_radix_test_02_multi.main, VoidTovoid());
  int_parse_radix_test_02_multi.isFail = function(e) {
    return dart.equals(e, "FAIL");
  };
  dart.fn(int_parse_radix_test_02_multi.isFail, dynamicTobool());
  // Exports:
  exports.int_parse_radix_test_02_multi = int_parse_radix_test_02_multi;
});
