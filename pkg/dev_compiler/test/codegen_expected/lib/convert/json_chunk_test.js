dart_library.library('lib/convert/json_chunk_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__json_chunk_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const json_chunk_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfbool = () => (JSArrayOfbool = dart.constFn(_interceptors.JSArray$(core.bool)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let dynamicAnddynamicAndFnTodynamic = () => (dynamicAnddynamicAndFnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dynamicTodynamic()])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAndFnTodynamic = () => (dynamicAndFnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dynamicTodynamic()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic$ = () => (dynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  json_chunk_test.badFormat = function(e) {
    return core.FormatException.is(e);
  };
  dart.fn(json_chunk_test.badFormat, dynamicTobool());
  json_chunk_test.jsonTest = function(testName, expect, action) {
    let sink = convert.ChunkedConversionSink.withCallback(dart.fn(values => {
      let value = values[dartx.get](0);
      expect$.Expect.equals(expect, value, dart.str`${testName}:${value}`);
    }, ListTovoid()));
    let decoderSink = convert.JSON.decoder.startChunkedConversion(sink);
    dart.dcall(action, decoderSink);
  };
  dart.fn(json_chunk_test.jsonTest, dynamicAnddynamicAndFnTodynamic());
  json_chunk_test.jsonThrowsTest = function(testName, action) {
    let sink = convert.ChunkedConversionSink.withCallback(dart.fn(values => {
      expect$.Expect.fail(dart.str`Should have thrown: ${testName}`);
    }, ListTovoid()));
    let decoderSink = convert.JSON.decoder.startChunkedConversion(sink);
    expect$.Expect.throws(dart.fn(() => {
      dart.dcall(action, decoderSink);
    }, VoidTovoid()), dart.fn(e => core.FormatException.is(e), dynamicTobool()), core.String._check(testName));
  };
  dart.fn(json_chunk_test.jsonThrowsTest, dynamicAndFnTodynamic());
  json_chunk_test.main = function() {
    json_chunk_test.testNumbers();
    json_chunk_test.testStrings();
    json_chunk_test.testKeywords();
  };
  dart.fn(json_chunk_test.main, VoidTodynamic());
  json_chunk_test.testStrings = function() {
    let s = '"abc\\f\\n\\r\\t\\b\\"\\/\\\\\\u0001\\u9999\\uffff"';
    let expected = "abc\f\n\r\t\b\"/\\香￿";
    for (let i = 1; i < dart.notNull(s[dartx.length]) - 1; i++) {
      let s1 = s[dartx.substring](0, i);
      let s2 = s[dartx.substring](i);
      json_chunk_test.jsonTest(dart.str`${s1}|${s2}`, expected, dart.fn(sink => {
        dart.dsend(sink, 'add', s1);
        dart.dsend(sink, 'add', s2);
        dart.dsend(sink, 'close');
      }, dynamicTodynamic$()));
      json_chunk_test.jsonTest(dart.str`${s1}|${s2}`, expected, dart.fn(sink => {
        dart.dsend(sink, 'addSlice', s, 0, i, false);
        dart.dsend(sink, 'addSlice', s, i, s[dartx.length], true);
      }, dynamicTodynamic$()));
      for (let j = i; j < dart.notNull(s[dartx.length]) - 1; j++) {
        let s2a = s[dartx.substring](i, j);
        let s2b = s[dartx.substring](j);
        json_chunk_test.jsonTest(dart.str`${s1}|${s2a}|${s2b}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'add', s1);
          dart.dsend(sink, 'add', s2a);
          dart.dsend(sink, 'add', s2b);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
      }
    }
  };
  dart.fn(json_chunk_test.testStrings, VoidTovoid());
  json_chunk_test.testNumbers = function() {
    function testNumber(number) {
      let expected = core.num.parse(core.String._check(number));
      for (let i = 1; i < dart.notNull(core.num._check(dart.dsend(dart.dload(number, 'length'), '-', 1))); i++) {
        let p1 = dart.dsend(number, 'substring', 0, i);
        let p2 = dart.dsend(number, 'substring', i);
        json_chunk_test.jsonTest(dart.str`${p1}|${p2}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'add', p1);
          dart.dsend(sink, 'add', p2);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
        json_chunk_test.jsonTest(dart.str`${p1}|${p2}/slice`, expected, dart.fn(sink => {
          dart.dsend(sink, 'addSlice', number, 0, i, false);
          dart.dsend(sink, 'addSlice', number, i, dart.dload(number, 'length'), true);
        }, dynamicTodynamic$()));
        for (let j = i; j < dart.notNull(core.num._check(dart.dsend(dart.dload(number, 'length'), '-', 1))); j++) {
          let p2a = dart.dsend(number, 'substring', i, j);
          let p2b = dart.dsend(number, 'substring', j);
          json_chunk_test.jsonTest(dart.str`${p1}|${p2a}|${p2b}`, expected, dart.fn(sink => {
            dart.dsend(sink, 'add', p1);
            dart.dsend(sink, 'add', p2a);
            dart.dsend(sink, 'add', p2b);
            dart.dsend(sink, 'close');
          }, dynamicTodynamic$()));
        }
      }
    }
    dart.fn(testNumber, dynamicTovoid());
    for (let sign of JSArrayOfString().of(["-", ""])) {
      for (let intPart of JSArrayOfString().of(["0", "1", "99"])) {
        for (let decimalPoint of JSArrayOfString().of([".", ""])) {
          for (let decimals of dart.test(decimalPoint[dartx.isEmpty]) ? JSArrayOfString().of([""]) : JSArrayOfString().of(["0", "99"])) {
            for (let e of JSArrayOfString().of(["e", "e-", "e+", ""])) {
              for (let exp of dart.test(e[dartx.isEmpty]) ? JSArrayOfString().of([""]) : JSArrayOfString().of(["0", "2", "22", "34"])) {
                testNumber(dart.str`${sign}${intPart}${decimalPoint}${decimals}${e}${exp}`);
              }
            }
          }
        }
      }
    }
    function negativeTest(number) {
      for (let i = 1; i < dart.notNull(core.num._check(dart.dsend(dart.dload(number, 'length'), '-', 1))); i++) {
        let p1 = dart.dsend(number, 'substring', 0, i);
        let p2 = dart.dsend(number, 'substring', i);
        json_chunk_test.jsonThrowsTest(dart.str`${p1}|${p2}`, dart.fn(sink => {
          dart.dsend(sink, 'add', p1);
          dart.dsend(sink, 'add', p2);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
        json_chunk_test.jsonThrowsTest(dart.str`${p1}|${p2}/slice`, dart.fn(sink => {
          dart.dsend(sink, 'addSlice', number, 0, i, false);
          dart.dsend(sink, 'addSlice', number, i, dart.dload(number, 'length'), true);
        }, dynamicTodynamic$()));
        for (let j = i; j < dart.notNull(core.num._check(dart.dsend(dart.dload(number, 'length'), '-', 1))); j++) {
          let p2a = dart.dsend(number, 'substring', i, j);
          let p2b = dart.dsend(number, 'substring', j);
          json_chunk_test.jsonThrowsTest(dart.str`${p1}|${p2a}|${p2b}`, dart.fn(sink => {
            dart.dsend(sink, 'add', p1);
            dart.dsend(sink, 'add', p2a);
            dart.dsend(sink, 'add', p2b);
            dart.dsend(sink, 'close');
          }, dynamicTodynamic$()));
        }
      }
    }
    dart.fn(negativeTest, dynamicTovoid());
    negativeTest("+1e");
    negativeTest("-00");
    negativeTest("01");
    negativeTest(".1");
    negativeTest("0.");
    negativeTest("0.e1");
    negativeTest("1e");
    negativeTest("1e+");
    negativeTest("1e-");
  };
  dart.fn(json_chunk_test.testNumbers, VoidTovoid());
  json_chunk_test.testKeywords = function() {
    for (let expected of JSArrayOfbool().of([null, true, false])) {
      let s = dart.str`${expected}`;
      for (let i = 1; i < dart.notNull(s[dartx.length]) - 1; i++) {
        let s1 = s[dartx.substring](0, i);
        let s2 = s[dartx.substring](i);
        json_chunk_test.jsonTest(dart.str`${s1}|${s2}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'add', s1);
          dart.dsend(sink, 'add', s2);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
        json_chunk_test.jsonTest(dart.str`${s1}|${s2}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'addSlice', s, 0, i, false);
          dart.dsend(sink, 'addSlice', s, i, s[dartx.length], true);
        }, dynamicTodynamic$()));
        for (let j = i; j < dart.notNull(s[dartx.length]) - 1; j++) {
          let s2a = s[dartx.substring](i, j);
          let s2b = s[dartx.substring](j);
          json_chunk_test.jsonTest(dart.str`${s1}|${s2a}|${s2b}`, expected, dart.fn(sink => {
            dart.dsend(sink, 'add', s1);
            dart.dsend(sink, 'add', s2a);
            dart.dsend(sink, 'add', s2b);
            dart.dsend(sink, 'close');
          }, dynamicTodynamic$()));
        }
      }
    }
  };
  dart.fn(json_chunk_test.testKeywords, VoidTovoid());
  // Exports:
  exports.json_chunk_test = json_chunk_test;
});
