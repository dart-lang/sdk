dart_library.library('lib/convert/json_utf8_chunk_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__json_utf8_chunk_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const json_utf8_chunk_test = Object.create(null);
  const unicode_tests = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfbool = () => (JSArrayOfbool = dart.constFn(_interceptors.JSArray$(core.bool)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let ListOfList = () => (ListOfList = dart.constFn(core.List$(core.List)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic$ = () => (dynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAndFn__Tovoid = () => (dynamicAnddynamicAndFn__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dynamicTodynamic()], [core.bool])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let dynamicAnddynamicAnddynamic__Tovoid = () => (dynamicAnddynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic], [core.bool])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicAndFnTovoid = () => (dynamicAnddynamicAndFnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dynamicTodynamic()])))();
  let dynamicAnddynamicAnddynamicTovoid = () => (dynamicAnddynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let StringAndStringTovoid = () => (StringAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, core.String])))();
  let ListOfObjectToListOfObject = () => (ListOfObjectToListOfObject = dart.constFn(dart.definiteFunctionType(ListOfObject(), [ListOfObject()])))();
  let VoidToListOfList = () => (VoidToListOfList = dart.constFn(dart.definiteFunctionType(ListOfList(), [])))();
  json_utf8_chunk_test.badFormat = function(e) {
    return core.FormatException.is(e);
  };
  dart.fn(json_utf8_chunk_test.badFormat, dynamicTobool());
  json_utf8_chunk_test.main = function() {
    json_utf8_chunk_test.testNumbers();
    json_utf8_chunk_test.testStrings();
    json_utf8_chunk_test.testKeywords();
    json_utf8_chunk_test.testAll();
    json_utf8_chunk_test.testMalformed();
    json_utf8_chunk_test.testUnicodeTests();
  };
  dart.fn(json_utf8_chunk_test.main, VoidTodynamic());
  json_utf8_chunk_test.jsonTest = function(testName, expect, action, allowMalformed) {
    if (allowMalformed === void 0) allowMalformed = false;
    json_utf8_chunk_test.jsonParse(testName, dart.fn(value => {
      expect$.Expect.equals(expect, value, dart.str`${testName}:${value}`);
    }, dynamicTodynamic$()), action, allowMalformed);
  };
  dart.fn(json_utf8_chunk_test.jsonTest, dynamicAnddynamicAndFn__Tovoid());
  json_utf8_chunk_test.jsonParse = function(testName, check, action, allowMalformed) {
    if (allowMalformed === void 0) allowMalformed = false;
    let sink = convert.ChunkedConversionSink.withCallback(dart.fn(values => {
      let value = values[dartx.get](0);
      dart.dcall(check, value);
    }, ListTovoid()));
    let decoderSink = convert.JSON.decoder.startChunkedConversion(sink).asUtf8Sink(allowMalformed);
    try {
      dart.dcall(action, decoderSink);
    } catch (e) {
      if (core.FormatException.is(e)) {
        let s = dart.stackTrace(e);
        core.print(dart.str`Source: ${e.source} @ ${e.offset}`);
        expect$.Expect.fail(dart.str`Unexpected throw(${testName}): ${e}\n${s}`);
      } else
        throw e;
    }

  };
  dart.fn(json_utf8_chunk_test.jsonParse, dynamicAnddynamicAnddynamic__Tovoid());
  json_utf8_chunk_test.testStrings = function() {
    let s = '"abc\\f\\ndef\\r\\t\\b\\"\\/\\\\\\u0001\\u9999\\uffff' + 'Âß¿à ï¿¿' + 'ðô¿¿"';
    let expected = "abc\f\ndef\r\t\b\"/\\香￿" + "߿ࠀ￿" + "𐀀􏿿";
    for (let i = 1; i < dart.notNull(s[dartx.length]) - 1; i++) {
      let s1 = s[dartx.substring](0, i);
      let s2 = s[dartx.substring](i);
      json_utf8_chunk_test.jsonTest(dart.str`${s1}|${s2}-${i}`, expected, dart.fn(sink => {
        dart.dsend(sink, 'add', s1[dartx.codeUnits]);
        dart.dsend(sink, 'add', s2[dartx.codeUnits]);
        dart.dsend(sink, 'close');
      }, dynamicTodynamic$()));
      json_utf8_chunk_test.jsonTest(dart.str`${s1}|${s2}-${i}-slice`, expected, dart.fn(sink => {
        dart.dsend(sink, 'addSlice', s[dartx.codeUnits], 0, i, false);
        dart.dsend(sink, 'addSlice', s[dartx.codeUnits], i, s[dartx.length], true);
      }, dynamicTodynamic$()));
      for (let j = i; j < dart.notNull(s[dartx.length]) - 1; j++) {
        let s2a = s[dartx.substring](i, j);
        let s2b = s[dartx.substring](j);
        json_utf8_chunk_test.jsonTest(dart.str`${s1}|${s2a}|${s2b}-${i}-${j}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'add', s1[dartx.codeUnits]);
          dart.dsend(sink, 'add', s2a[dartx.codeUnits]);
          dart.dsend(sink, 'add', s2b[dartx.codeUnits]);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
      }
    }
  };
  dart.fn(json_utf8_chunk_test.testStrings, VoidTovoid());
  json_utf8_chunk_test.testNumbers = function() {
    for (let number of JSArrayOfString().of(["-0.12e-12", "-34.12E+12", "0.0e0", "9.9E9", "0", "9" + "1234.56789123456701418035663664340972900390625", "1.2345678912345671e-14", "99999999999999999999"])) {
      let expected = core.num.parse(number);
      for (let i = 1; i < dart.notNull(number[dartx.length]) - 1; i++) {
        let p1 = number[dartx.substring](0, i);
        let p2 = number[dartx.substring](i);
        json_utf8_chunk_test.jsonTest(dart.str`${p1}|${p2}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'add', p1[dartx.codeUnits]);
          dart.dsend(sink, 'add', p2[dartx.codeUnits]);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
        json_utf8_chunk_test.jsonTest(dart.str`${p1}|${p2}/slice`, expected, dart.fn(sink => {
          dart.dsend(sink, 'addSlice', number[dartx.codeUnits], 0, i, false);
          dart.dsend(sink, 'addSlice', number[dartx.codeUnits], i, number[dartx.length], true);
        }, dynamicTodynamic$()));
        for (let j = i; j < dart.notNull(number[dartx.length]) - 1; j++) {
          let p2a = number[dartx.substring](i, j);
          let p2b = number[dartx.substring](j);
          json_utf8_chunk_test.jsonTest(dart.str`${p1}|${p2a}|${p2b}`, expected, dart.fn(sink => {
            dart.dsend(sink, 'add', p1[dartx.codeUnits]);
            dart.dsend(sink, 'add', p2a[dartx.codeUnits]);
            dart.dsend(sink, 'add', p2b[dartx.codeUnits]);
            dart.dsend(sink, 'close');
          }, dynamicTodynamic$()));
        }
      }
    }
  };
  dart.fn(json_utf8_chunk_test.testNumbers, VoidTovoid());
  json_utf8_chunk_test.testKeywords = function() {
    for (let expected of JSArrayOfbool().of([null, true, false])) {
      let s = dart.str`${expected}`;
      for (let i = 1; i < dart.notNull(s[dartx.length]) - 1; i++) {
        let s1 = s[dartx.substring](0, i);
        let s2 = s[dartx.substring](i);
        json_utf8_chunk_test.jsonTest(dart.str`${s1}|${s2}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'add', s1[dartx.codeUnits]);
          dart.dsend(sink, 'add', s2[dartx.codeUnits]);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
        json_utf8_chunk_test.jsonTest(dart.str`${s1}|${s2}`, expected, dart.fn(sink => {
          dart.dsend(sink, 'addSlice', s[dartx.codeUnits], 0, i, false);
          dart.dsend(sink, 'addSlice', s[dartx.codeUnits], i, s[dartx.length], true);
        }, dynamicTodynamic$()));
        for (let j = i; j < dart.notNull(s[dartx.length]) - 1; j++) {
          let s2a = s[dartx.substring](i, j);
          let s2b = s[dartx.substring](j);
          json_utf8_chunk_test.jsonTest(dart.str`${s1}|${s2a}|${s2b}`, expected, dart.fn(sink => {
            dart.dsend(sink, 'add', s1[dartx.codeUnits]);
            dart.dsend(sink, 'add', s2a[dartx.codeUnits]);
            dart.dsend(sink, 'add', s2b[dartx.codeUnits]);
            dart.dsend(sink, 'close');
          }, dynamicTodynamic$()));
        }
      }
    }
  };
  dart.fn(json_utf8_chunk_test.testKeywords, VoidTovoid());
  json_utf8_chunk_test.testAll = function() {
    let s = '{"":[true,false,42, -33e-3,null,"\\u0080"], "z": 0}';
    function check(o) {
      if (core.Map.is(o)) {
        expect$.Expect.equals(2, o[dartx.length]);
        expect$.Expect.equals(0, o[dartx.get]("z"));
        let v = o[dartx.get]("");
        if (core.List.is(v)) {
          expect$.Expect.listEquals(JSArrayOfObject().of([true, false, 42, -0.033, null, ""]), v);
        } else {
          expect$.Expect.fail(dart.str`Expected list, found ${dart.runtimeType(v)}`);
        }
      } else {
        expect$.Expect.fail(dart.str`Expected map, found ${dart.runtimeType(o)}`);
      }
    }
    dart.fn(check, dynamicTobool());
    for (let i = 1; i < dart.notNull(s[dartx.length]) - 1; i++) {
      let s1 = s[dartx.substring](0, i);
      let s2 = s[dartx.substring](i);
      json_utf8_chunk_test.jsonParse(dart.str`${s1}|${s2}-${i}`, check, dart.fn(sink => {
        dart.dsend(sink, 'add', s1[dartx.codeUnits]);
        dart.dsend(sink, 'add', s2[dartx.codeUnits]);
        dart.dsend(sink, 'close');
      }, dynamicTodynamic$()));
      json_utf8_chunk_test.jsonParse(dart.str`${s1}|${s2}-${i}-slice`, check, dart.fn(sink => {
        dart.dsend(sink, 'addSlice', s[dartx.codeUnits], 0, i, false);
        dart.dsend(sink, 'addSlice', s[dartx.codeUnits], i, s[dartx.length], true);
      }, dynamicTodynamic$()));
      for (let j = i; j < dart.notNull(s[dartx.length]) - 1; j++) {
        let s2a = s[dartx.substring](i, j);
        let s2b = s[dartx.substring](j);
        json_utf8_chunk_test.jsonParse(dart.str`${s1}|${s2a}|${s2b}-${i}-${j}`, check, dart.fn(sink => {
          dart.dsend(sink, 'add', s1[dartx.codeUnits]);
          dart.dsend(sink, 'add', s2a[dartx.codeUnits]);
          dart.dsend(sink, 'add', s2b[dartx.codeUnits]);
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
      }
    }
  };
  dart.fn(json_utf8_chunk_test.testAll, VoidTovoid());
  json_utf8_chunk_test.jsonMalformedTest = function(name, expect, codes) {
    function test(name, expect, action) {
      let tag = dart.str`Malform:${name}-${expect}`;
      {
        let sink = convert.ChunkedConversionSink.withCallback(dart.fn(values => {
          let value = values[dartx.get](0);
          expect$.Expect.equals(expect, value, tag);
        }, ListTovoid()));
        let decoderSink = convert.JSON.decoder.startChunkedConversion(sink).asUtf8Sink(true);
        try {
          dart.dcall(action, decoderSink);
        } catch (e) {
          let s = dart.stackTrace(e);
          expect$.Expect.fail(dart.str`Unexpected throw (${tag}): ${e}\n${s}`);
        }

      }
      {
        let sink = convert.ChunkedConversionSink.withCallback(dart.fn(values => {
          expect$.Expect.fail(tag);
        }, ListTovoid()));
        let decoderSink = convert.JSON.decoder.startChunkedConversion(sink).asUtf8Sink(false);
        expect$.Expect.throws(dart.fn(() => {
          dart.dcall(action, decoderSink);
        }, VoidTovoid()), null, tag);
      }
    }
    dart.fn(test, dynamicAnddynamicAndFnTovoid());
    for (let i = 1; i < dart.notNull(core.num._check(dart.dsend(dart.dload(codes, 'length'), '-', 1))); i++) {
      test(dart.str`${name}:${i}`, expect, dart.fn(sink => {
        dart.dsend(sink, 'add', dart.dsend(codes, 'sublist', 0, i));
        dart.dsend(sink, 'add', dart.dsend(codes, 'sublist', i));
        dart.dsend(sink, 'close');
      }, dynamicTodynamic$()));
      test(dart.str`${name}:${i}-slice`, expect, dart.fn(sink => {
        dart.dsend(sink, 'addSlice', codes, 0, i, false);
        dart.dsend(sink, 'addSlice', codes, i, dart.dload(codes, 'length'), true);
      }, dynamicTodynamic$()));
      for (let j = i; j < dart.notNull(core.num._check(dart.dsend(dart.dload(codes, 'length'), '-', 1))); j++) {
        test(dart.str`${name}:${i}|${j}`, expect, dart.fn(sink => {
          dart.dsend(sink, 'add', dart.dsend(codes, 'sublist', 0, i));
          dart.dsend(sink, 'add', dart.dsend(codes, 'sublist', i, j));
          dart.dsend(sink, 'add', dart.dsend(codes, 'sublist', j));
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
      }
    }
  };
  dart.fn(json_utf8_chunk_test.jsonMalformedTest, dynamicAnddynamicAnddynamicTovoid());
  json_utf8_chunk_test.jsonThrows = function(name, codeString) {
    function testJsonThrows(tag, action) {
      let sink = convert.ChunkedConversionSink.withCallback(dart.fn(values => {
        expect$.Expect.fail(core.String._check(tag));
      }, ListTovoid()));
      let decoderSink = convert.JSON.decoder.startChunkedConversion(sink).asUtf8Sink(true);
      expect$.Expect.throws(dart.fn(() => {
        dart.dcall(action, decoderSink);
      }, VoidTovoid()), null, core.String._check(tag));
    }
    dart.fn(testJsonThrows, dynamicAnddynamicTodynamic());
    let codes = codeString[dartx.codeUnits];
    for (let i = 1; i < dart.notNull(codes[dartx.length]) - 1; i++) {
      testJsonThrows(dart.str`${name}:${i}`, dart.fn(sink => {
        dart.dsend(sink, 'add', codes[dartx.sublist](0, i));
        dart.dsend(sink, 'add', codes[dartx.sublist](i));
        dart.dsend(sink, 'close');
      }, dynamicTodynamic$()));
      testJsonThrows(dart.str`${name}:${i}-slice`, dart.fn(sink => {
        dart.dsend(sink, 'addSlice', codes, 0, i, false);
        dart.dsend(sink, 'addSlice', codes, i, codes[dartx.length], true);
      }, dynamicTodynamic$()));
      for (let j = i; j < dart.notNull(codes[dartx.length]) - 1; j++) {
        testJsonThrows(dart.str`${name}:${i}|${j}`, dart.fn(sink => {
          dart.dsend(sink, 'add', codes[dartx.sublist](0, i));
          dart.dsend(sink, 'add', codes[dartx.sublist](i, j));
          dart.dsend(sink, 'add', codes[dartx.sublist](j));
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
      }
    }
  };
  dart.fn(json_utf8_chunk_test.jsonThrows, StringAndStringTovoid());
  json_utf8_chunk_test.testMalformed = function() {
    json_utf8_chunk_test.jsonMalformedTest("overlong-0-2", "@�@", JSArrayOfint().of([34, 64, 192, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-0-3", "@�@", JSArrayOfint().of([34, 64, 224, 128, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-0-4", "@�@", JSArrayOfint().of([34, 64, 240, 128, 128, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-7f-2", "@�@", JSArrayOfint().of([34, 64, 193, 191, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-7f-3", "@�@", JSArrayOfint().of([34, 64, 224, 129, 191, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-7f-4", "@�@", JSArrayOfint().of([34, 64, 240, 128, 129, 191, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-80-3", "@�@", JSArrayOfint().of([34, 64, 224, 130, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-80-4", "@�@", JSArrayOfint().of([34, 64, 240, 128, 130, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-7ff-3", "@�@", JSArrayOfint().of([34, 64, 224, 159, 191, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-7ff-4", "@�@", JSArrayOfint().of([34, 64, 240, 128, 159, 191, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-800-4", "@�@", JSArrayOfint().of([34, 64, 240, 128, 160, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("overlong-ffff-4", "@�@", JSArrayOfint().of([34, 64, 240, 143, 191, 191, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-2-normal", "@�@", JSArrayOfint().of([34, 64, 192, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-3-normal", "@�@", JSArrayOfint().of([34, 64, 224, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-4-normal", "@�@", JSArrayOfint().of([34, 64, 240, 128, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-2-multi", "@�@", JSArrayOfint().of([34, 64, 192, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-3-multi", "@�@", JSArrayOfint().of([34, 64, 224, 128, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-4-multi", "@�@", JSArrayOfint().of([34, 64, 240, 128, 128, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-2-escape", "@�\n@", JSArrayOfint().of([34, 64, 192, 92, 110, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-3-escape", "@�\n@", JSArrayOfint().of([34, 64, 224, 128, 92, 110, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-4-escape", "@�\n@", JSArrayOfint().of([34, 64, 240, 128, 128, 92, 110, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-2-end", "@�", JSArrayOfint().of([34, 64, 192, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-3-end", "@�", JSArrayOfint().of([34, 64, 224, 128, 34]));
    json_utf8_chunk_test.jsonMalformedTest("unterminated-4-end", "@�", JSArrayOfint().of([34, 64, 240, 128, 128, 34]));
    json_utf8_chunk_test.jsonMalformedTest("continuation-normal", "@�@", JSArrayOfint().of([34, 64, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("continuation-continuation-2", "@�@", JSArrayOfint().of([34, 64, 194, 128, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("continuation-continuation-3", "@ࠀ�@", JSArrayOfint().of([34, 64, 224, 160, 128, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("continuation-continuation-4", "@𐀀�@", JSArrayOfint().of([34, 64, 240, 144, 128, 128, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("continuation-twice", "@���@", JSArrayOfint().of([34, 64, 128, 128, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("continuation-start", "�@", JSArrayOfint().of([34, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("leading-2", "@�@", JSArrayOfint().of([34, 64, 192, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("leading-3-1", "@�@", JSArrayOfint().of([34, 64, 224, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("leading-3-2", "@�@", JSArrayOfint().of([34, 64, 224, 128, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("leading-4-1", "@�@", JSArrayOfint().of([34, 64, 240, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("leading-4-2", "@�@", JSArrayOfint().of([34, 64, 240, 128, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonMalformedTest("leading-4-3", "@�@", JSArrayOfint().of([34, 64, 240, 128, 128, 194, 128, 64, 34]));
    json_utf8_chunk_test.jsonThrows("number-1", "À«0.0e-0");
    json_utf8_chunk_test.jsonThrows("number-2", "-À°.0e-0");
    json_utf8_chunk_test.jsonThrows("number-3", "-0À®0e-0");
    json_utf8_chunk_test.jsonThrows("number-4", "-0.À°e-0");
    json_utf8_chunk_test.jsonThrows("number-5", "-0.0Á¥-0");
    json_utf8_chunk_test.jsonThrows("number-6", "-0.0eÀ«0");
    json_utf8_chunk_test.jsonThrows("number-7", "-0.0e-À°");
    json_utf8_chunk_test.jsonThrows("true-1", "Á´rue");
    json_utf8_chunk_test.jsonThrows("true-2", "tÁ²ue");
    json_utf8_chunk_test.jsonThrows("true-3", "trÁµe");
    json_utf8_chunk_test.jsonThrows("true-4", "truÁ¥");
    json_utf8_chunk_test.jsonThrows("false-1", "Á¦alse");
    json_utf8_chunk_test.jsonThrows("false-2", "fÁ¡lse");
    json_utf8_chunk_test.jsonThrows("false-3", "faÁ¬se");
    json_utf8_chunk_test.jsonThrows("false-4", "falÁ³e");
    json_utf8_chunk_test.jsonThrows("false-5", "falsÁ¥");
    json_utf8_chunk_test.jsonThrows("null-1", "Á®ull");
    json_utf8_chunk_test.jsonThrows("null-2", "nÁµll");
    json_utf8_chunk_test.jsonThrows("null-3", "nuÁ¬l");
    json_utf8_chunk_test.jsonThrows("null-4", "nulÁ¬");
    json_utf8_chunk_test.jsonThrows("array-1", "Á0,0]");
    json_utf8_chunk_test.jsonThrows("array-2", "[0,0Á");
    json_utf8_chunk_test.jsonThrows("array-2", "[0À¬0]");
    json_utf8_chunk_test.jsonThrows("object-1", 'Á»"x":0}');
    json_utf8_chunk_test.jsonThrows("object-2", '{"x":0Á½');
    json_utf8_chunk_test.jsonThrows("object-2", '{"xÀº0}');
    json_utf8_chunk_test.jsonThrows("string-1", 'À¢x"');
    json_utf8_chunk_test.jsonThrows("string-1", '"xÀ¢');
    json_utf8_chunk_test.jsonThrows("whitespace-1", "À 1");
  };
  dart.fn(json_utf8_chunk_test.testMalformed, VoidTovoid());
  json_utf8_chunk_test.testUnicodeTests = function() {
    for (let pair of unicode_tests.UNICODE_TESTS) {
      let bytes = dart.dindex(pair, 0);
      let string = dart.dindex(pair, 1);
      let step = 1;
      if (dart.test(dart.dsend(dart.dload(bytes, 'length'), '>', 100))) step = core.int._check(dart.dsend(dart.dload(bytes, 'length'), '~/', 13));
      for (let i = 1; dart.notNull(i) < dart.notNull(core.num._check(dart.dsend(dart.dload(bytes, 'length'), '-', 1))); i = dart.notNull(i) + dart.notNull(step)) {
        json_utf8_chunk_test.jsonTest(dart.str`${string}:${i}`, string, dart.fn(sink => {
          dart.dsend(sink, 'add', JSArrayOfint().of([34]));
          dart.dsend(sink, 'add', dart.dsend(bytes, 'sublist', 0, i));
          dart.dsend(sink, 'add', dart.dsend(bytes, 'sublist', i));
          dart.dsend(sink, 'add', JSArrayOfint().of([34]));
          dart.dsend(sink, 'close');
        }, dynamicTodynamic$()));
        json_utf8_chunk_test.jsonTest(dart.str`${string}:${i}-slice`, string, dart.fn(sink => {
          dart.dsend(sink, 'addSlice', JSArrayOfint().of([34]), 0, 1, false);
          dart.dsend(sink, 'addSlice', bytes, 0, i, false);
          dart.dsend(sink, 'addSlice', bytes, i, dart.dload(bytes, 'length'), false);
          dart.dsend(sink, 'addSlice', JSArrayOfint().of([34]), 0, 1, true);
        }, dynamicTodynamic$()));
        let skip = 1;
        if (dart.test(dart.dsend(dart.dload(bytes, 'length'), '>', 25))) skip = core.int._check(dart.dsend(dart.dload(bytes, 'length'), '~/', 17));
        for (let j = i; dart.notNull(j) < dart.notNull(core.num._check(dart.dsend(dart.dload(bytes, 'length'), '-', 1))); j = dart.notNull(j) + dart.notNull(skip)) {
          json_utf8_chunk_test.jsonTest(dart.str`${string}:${i}|${j}`, string, dart.fn(sink => {
            dart.dsend(sink, 'add', JSArrayOfint().of([34]));
            dart.dsend(sink, 'add', dart.dsend(bytes, 'sublist', 0, i));
            dart.dsend(sink, 'add', dart.dsend(bytes, 'sublist', i, j));
            dart.dsend(sink, 'add', dart.dsend(bytes, 'sublist', j));
            dart.dsend(sink, 'add', JSArrayOfint().of([34]));
            dart.dsend(sink, 'close');
          }, dynamicTodynamic$()));
        }
      }
    }
  };
  dart.fn(json_utf8_chunk_test.testUnicodeTests, VoidTovoid());
  unicode_tests.INTER_BYTES = dart.constList([195, 142, 195, 177, 197, 163, 195, 169, 114, 195, 177, 195, 165, 197, 163, 195, 174, 195, 182, 195, 177, 195, 165, 196, 188, 195, 174, 197, 190, 195, 165, 197, 163, 195, 174, 225, 187, 157, 195, 177], core.int);
  unicode_tests.INTER_STRING = "Îñţérñåţîöñåļîžåţîờñ";
  unicode_tests.BLUEBERRY_BYTES = dart.constList([98, 108, 195, 165, 98, 195, 166, 114, 103, 114, 195, 184, 100], core.int);
  unicode_tests.BLUEBERRY_STRING = "blåbærgrød";
  unicode_tests.SIVA_BYTES1 = dart.constList([224, 174, 154, 224, 174, 191, 224, 174, 181, 224, 174, 190, 32, 224, 174, 133, 224, 174, 163, 224, 174, 190, 224, 174, 174, 224, 174, 190, 224, 175, 136, 224, 174, 178], core.int);
  unicode_tests.SIVA_STRING1 = "சிவா அணாமாைல";
  unicode_tests.SIVA_BYTES2 = dart.constList([224, 164, 191, 224, 164, 184, 224, 164, 181, 224, 164, 190, 32, 224, 164, 133, 224, 164, 163, 224, 164, 190, 224, 164, 174, 224, 164, 190, 224, 164, 178, 224, 165, 136], core.int);
  unicode_tests.SIVA_STRING2 = "िसवा अणामालै";
  unicode_tests.BEE_BYTES = dart.constList([240, 144, 144, 146], core.int);
  unicode_tests.BEE_STRING = "𐐒";
  unicode_tests.DIGIT_BYTES = dart.constList([53], core.int);
  unicode_tests.DIGIT_STRING = "5";
  unicode_tests.ASCII_BYTES = dart.constList([97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122], core.int);
  unicode_tests.ASCII_STRING = "abcdefghijklmnopqrstuvwxyz";
  unicode_tests.BIGGEST_ASCII_BYTES = dart.constList([127], core.int);
  unicode_tests.BIGGEST_ASCII_STRING = "";
  unicode_tests.SMALLEST_2_UTF8_UNIT_BYTES = dart.constList([194, 128], core.int);
  unicode_tests.SMALLEST_2_UTF8_UNIT_STRING = "";
  unicode_tests.BIGGEST_2_UTF8_UNIT_BYTES = dart.constList([223, 191], core.int);
  unicode_tests.BIGGEST_2_UTF8_UNIT_STRING = "߿";
  unicode_tests.SMALLEST_3_UTF8_UNIT_BYTES = dart.constList([224, 160, 128], core.int);
  unicode_tests.SMALLEST_3_UTF8_UNIT_STRING = "ࠀ";
  unicode_tests.BIGGEST_3_UTF8_UNIT_BYTES = dart.constList([239, 191, 191], core.int);
  unicode_tests.BIGGEST_3_UTF8_UNIT_STRING = "￿";
  unicode_tests.SMALLEST_4_UTF8_UNIT_BYTES = dart.constList([240, 144, 128, 128], core.int);
  unicode_tests.SMALLEST_4_UTF8_UNIT_STRING = "𐀀";
  unicode_tests.BIGGEST_4_UTF8_UNIT_BYTES = dart.constList([244, 143, 191, 191], core.int);
  unicode_tests.BIGGEST_4_UTF8_UNIT_STRING = "􏿿";
  unicode_tests._TEST_PAIRS = dart.constList([dart.constList([dart.constList([], dart.dynamic), ""], core.Object), dart.constList([unicode_tests.INTER_BYTES, unicode_tests.INTER_STRING], core.Object), dart.constList([unicode_tests.BLUEBERRY_BYTES, unicode_tests.BLUEBERRY_STRING], core.Object), dart.constList([unicode_tests.SIVA_BYTES1, unicode_tests.SIVA_STRING1], core.Object), dart.constList([unicode_tests.SIVA_BYTES2, unicode_tests.SIVA_STRING2], core.Object), dart.constList([unicode_tests.BEE_BYTES, unicode_tests.BEE_STRING], core.Object), dart.constList([unicode_tests.DIGIT_BYTES, unicode_tests.DIGIT_STRING], core.Object), dart.constList([unicode_tests.ASCII_BYTES, unicode_tests.ASCII_STRING], core.Object), dart.constList([unicode_tests.BIGGEST_ASCII_BYTES, unicode_tests.BIGGEST_ASCII_STRING], core.Object), dart.constList([unicode_tests.SMALLEST_2_UTF8_UNIT_BYTES, unicode_tests.SMALLEST_2_UTF8_UNIT_STRING], core.Object), dart.constList([unicode_tests.BIGGEST_2_UTF8_UNIT_BYTES, unicode_tests.BIGGEST_2_UTF8_UNIT_STRING], core.Object), dart.constList([unicode_tests.SMALLEST_3_UTF8_UNIT_BYTES, unicode_tests.SMALLEST_3_UTF8_UNIT_STRING], core.Object), dart.constList([unicode_tests.BIGGEST_3_UTF8_UNIT_BYTES, unicode_tests.BIGGEST_3_UTF8_UNIT_STRING], core.Object), dart.constList([unicode_tests.SMALLEST_4_UTF8_UNIT_BYTES, unicode_tests.SMALLEST_4_UTF8_UNIT_STRING], core.Object), dart.constList([unicode_tests.BIGGEST_4_UTF8_UNIT_BYTES, unicode_tests.BIGGEST_4_UTF8_UNIT_STRING], core.Object)], ListOfObject());
  unicode_tests._expandTestPairs = function() {
    dart.assert(2 == unicode_tests.BEE_STRING[dartx.length]);
    let tests = [];
    tests[dartx.addAll](unicode_tests._TEST_PAIRS);
    tests[dartx.addAll](unicode_tests._TEST_PAIRS[dartx.map](ListOfObject())(dart.fn(test => {
      let bytes = test[dartx.get](0);
      let string = test[dartx.get](1);
      let longBytes = [];
      let longString = "";
      for (let i = 0; i < 100; i++) {
        longBytes[dartx.addAll](core.Iterable._check(bytes));
        longString = dart.notNull(longString) + dart.notNull(core.String._check(string));
      }
      return JSArrayOfObject().of([longBytes, longString]);
    }, ListOfObjectToListOfObject())));
    return ListOfList()._check(tests);
  };
  dart.fn(unicode_tests._expandTestPairs, VoidToListOfList());
  dart.defineLazy(unicode_tests, {
    get UNICODE_TESTS() {
      return unicode_tests._expandTestPairs();
    }
  });
  // Exports:
  exports.json_utf8_chunk_test = json_utf8_chunk_test;
  exports.unicode_tests = unicode_tests;
});
