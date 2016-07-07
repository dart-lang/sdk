dart_library.library('lib/convert/streamed_conversion_json_utf8_decode_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__streamed_conversion_json_utf8_decode_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const streamed_conversion_json_utf8_decode_test = Object.create(null);
  const json_unicode_tests = Object.create(null);
  const unicode_tests = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfintTovoid = () => (ListOfintTovoid = dart.constFn(dart.functionType(dart.void, [ListOfint()])))();
  let StreamOfObject = () => (StreamOfObject = dart.constFn(async.Stream$(core.Object)))();
  let ListOfListOfint = () => (ListOfListOfint = dart.constFn(core.List$(ListOfint())))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let ListOfList = () => (ListOfList = dart.constFn(core.List$(core.List)))();
  let JSArrayOfListOfList = () => (JSArrayOfListOfList = dart.constFn(_interceptors.JSArray$(ListOfList())))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfListOfList = () => (ListOfListOfList = dart.constFn(core.List$(ListOfList())))();
  let JSArrayOfListOfListOfList = () => (JSArrayOfListOfListOfList = dart.constFn(_interceptors.JSArray$(ListOfListOfList())))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ListOfListOfintToStreamOfObject = () => (ListOfListOfintToStreamOfObject = dart.constFn(dart.definiteFunctionType(StreamOfObject(), [ListOfListOfint()])))();
  let ListOfintToStreamOfObject = () => (ListOfintToStreamOfObject = dart.constFn(dart.definiteFunctionType(StreamOfObject(), [ListOfint()])))();
  let ListOfintAndintToStreamOfObject = () => (ListOfintAndintToStreamOfObject = dart.constFn(dart.definiteFunctionType(StreamOfObject(), [ListOfint(), core.int])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicToIterable = () => (dynamicToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [dart.dynamic])))();
  let ListOfObjectToListOfObject = () => (ListOfObjectToListOfObject = dart.constFn(dart.definiteFunctionType(ListOfObject(), [ListOfObject()])))();
  let VoidToListOfList = () => (VoidToListOfList = dart.constFn(dart.definiteFunctionType(ListOfList(), [])))();
  dart.defineLazy(streamed_conversion_json_utf8_decode_test, {
    get JSON_UTF8() {
      return convert.JSON.fuse(convert.UTF8);
    }
  });
  streamed_conversion_json_utf8_decode_test.expectJsonEquals = function(o1, o2, path) {
    if (path === void 0) path = "result";
    if (dart.equals(o1, o2)) return;
    if (core.List.is(o1) && core.List.is(o2)) {
      expect$.Expect.equals(o1[dartx.length], o2[dartx.length], dart.str`${path}.length`);
      for (let i = 0; i < dart.notNull(o1[dartx.length]); i++) {
        streamed_conversion_json_utf8_decode_test.expectJsonEquals(o1[dartx.get](i), o2[dartx.get](i), dart.str`${path}[${i}]`);
      }
      return;
    }
    if (core.Map.is(o1) && core.Map.is(o2)) {
      expect$.Expect.equals(o1[dartx.length], o2[dartx.length], dart.str`${path}.length`);
      for (let key of o1[dartx.keys]) {
        expect$.Expect.isTrue(typeof key == 'string', dart.str`${path}:key = ${key}`);
        expect$.Expect.isTrue(o2[dartx.containsKey](key), dart.str`${path}[${key}] missing in ${o2}`);
        streamed_conversion_json_utf8_decode_test.expectJsonEquals(o1[dartx.get](key), o2[dartx.get](key), dart.str`${path}[${key}]`);
      }
      return;
    }
    expect$.Expect.equals(o1, o2);
  };
  dart.fn(streamed_conversion_json_utf8_decode_test.expectJsonEquals, dynamicAnddynamic__Tovoid());
  streamed_conversion_json_utf8_decode_test.createStream = function(chunks) {
    let controller = null;
    controller = async.StreamController.new({onListen: dart.fn(() => {
        chunks[dartx.forEach](ListOfintTovoid()._check(dart.dload(controller, 'add')));
        dart.dsend(controller, 'close');
      }, VoidTovoid())});
    return StreamOfObject()._check(dart.dsend(dart.dload(controller, 'stream'), 'transform', streamed_conversion_json_utf8_decode_test.JSON_UTF8.decoder));
  };
  dart.fn(streamed_conversion_json_utf8_decode_test.createStream, ListOfListOfintToStreamOfObject());
  streamed_conversion_json_utf8_decode_test.decode = function(bytes) {
    return streamed_conversion_json_utf8_decode_test.createStream(JSArrayOfListOfint().of([bytes]));
  };
  dart.fn(streamed_conversion_json_utf8_decode_test.decode, ListOfintToStreamOfObject());
  streamed_conversion_json_utf8_decode_test.decodeChunked = function(bytes, chunkSize) {
    let chunked = JSArrayOfListOfint().of([]);
    let i = 0;
    while (dart.notNull(i) < dart.notNull(bytes[dartx.length])) {
      if (dart.notNull(i) + dart.notNull(chunkSize) <= dart.notNull(bytes[dartx.length])) {
        chunked[dartx.add](bytes[dartx.sublist](i, dart.notNull(i) + dart.notNull(chunkSize)));
      } else {
        chunked[dartx.add](bytes[dartx.sublist](i));
      }
      i = dart.notNull(i) + dart.notNull(chunkSize);
    }
    return streamed_conversion_json_utf8_decode_test.createStream(chunked);
  };
  dart.fn(streamed_conversion_json_utf8_decode_test.decodeChunked, ListOfintAndintToStreamOfObject());
  streamed_conversion_json_utf8_decode_test.checkIsJsonEqual = function(expected, stream) {
    async_helper$.asyncStart();
    dart.dsend(dart.dload(stream, 'single'), 'then', dart.fn(o => {
      streamed_conversion_json_utf8_decode_test.expectJsonEquals(expected, o);
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(streamed_conversion_json_utf8_decode_test.checkIsJsonEqual, dynamicAnddynamicTovoid());
  streamed_conversion_json_utf8_decode_test.main = function() {
    for (let test of core.Iterable._check(json_unicode_tests.JSON_UNICODE_TESTS)) {
      let bytes = dart.dindex(test, 0);
      let o = dart.dindex(test, 1);
      streamed_conversion_json_utf8_decode_test.checkIsJsonEqual(o, streamed_conversion_json_utf8_decode_test.decode(ListOfint()._check(bytes)));
      streamed_conversion_json_utf8_decode_test.checkIsJsonEqual(o, streamed_conversion_json_utf8_decode_test.decodeChunked(ListOfint()._check(bytes), 1));
      streamed_conversion_json_utf8_decode_test.checkIsJsonEqual(o, streamed_conversion_json_utf8_decode_test.decodeChunked(ListOfint()._check(bytes), 2));
      streamed_conversion_json_utf8_decode_test.checkIsJsonEqual(o, streamed_conversion_json_utf8_decode_test.decodeChunked(ListOfint()._check(bytes), 3));
      streamed_conversion_json_utf8_decode_test.checkIsJsonEqual(o, streamed_conversion_json_utf8_decode_test.decodeChunked(ListOfint()._check(bytes), 4));
      streamed_conversion_json_utf8_decode_test.checkIsJsonEqual(o, streamed_conversion_json_utf8_decode_test.decodeChunked(ListOfint()._check(bytes), 5));
    }
  };
  dart.fn(streamed_conversion_json_utf8_decode_test.main, VoidTodynamic());
  json_unicode_tests._QUOTE = 34;
  json_unicode_tests._COLON = 58;
  json_unicode_tests._COMMA = 44;
  json_unicode_tests._BRACE_OPEN = 123;
  json_unicode_tests._BRACE_CLOSE = 125;
  json_unicode_tests._BRACKET_OPEN = 91;
  json_unicode_tests._BRACKET_CLOSE = 93;
  json_unicode_tests._expandUnicodeTests = function() {
    return unicode_tests.UNICODE_TESTS[dartx.expand](dart.dynamic)(dart.fn(test => {
      dart.assert(!dart.test(dart.dsend(test, 'contains', '"')));
      let bytes = dart.dindex(test, 0);
      let string = dart.dindex(test, 1);
      let expanded = [];
      let inQuotesBytes = [];
      inQuotesBytes[dartx.add](json_unicode_tests._QUOTE);
      inQuotesBytes[dartx.addAll](core.Iterable._check(bytes));
      inQuotesBytes[dartx.add](json_unicode_tests._QUOTE);
      expanded[dartx.add]([inQuotesBytes, string]);
      let listExpected = JSArrayOfListOfList().of([JSArrayOfList().of([[string]])]);
      let inListBytes = [];
      inListBytes[dartx.addAll](JSArrayOfint().of([json_unicode_tests._BRACKET_OPEN, json_unicode_tests._BRACKET_OPEN, json_unicode_tests._BRACKET_OPEN]));
      inListBytes[dartx.addAll](inQuotesBytes);
      inListBytes[dartx.addAll](JSArrayOfint().of([json_unicode_tests._BRACKET_CLOSE, json_unicode_tests._BRACKET_CLOSE, json_unicode_tests._BRACKET_CLOSE]));
      expanded[dartx.add](JSArrayOfList().of([inListBytes, listExpected]));
      let listLongerExpected = JSArrayOfListOfListOfList().of([listExpected, listExpected, listExpected]);
      let listLongerBytes = [];
      listLongerBytes[dartx.add](json_unicode_tests._BRACKET_OPEN);
      listLongerBytes[dartx.addAll](inListBytes);
      listLongerBytes[dartx.add](json_unicode_tests._COMMA);
      listLongerBytes[dartx.addAll](inListBytes);
      listLongerBytes[dartx.add](json_unicode_tests._COMMA);
      listLongerBytes[dartx.addAll](inListBytes);
      listLongerBytes[dartx.add](json_unicode_tests._BRACKET_CLOSE);
      expanded[dartx.add](JSArrayOfList().of([listLongerBytes, listLongerExpected]));
      let mapExpected = core.Map.new();
      mapExpected[dartx.set](string, listLongerExpected);
      let mapBytes = [];
      mapBytes[dartx.add](json_unicode_tests._BRACE_OPEN);
      mapBytes[dartx.addAll](inQuotesBytes);
      mapBytes[dartx.add](json_unicode_tests._COLON);
      mapBytes[dartx.addAll](listLongerBytes);
      mapBytes[dartx.add](json_unicode_tests._BRACE_CLOSE);
      expanded[dartx.add](JSArrayOfObject().of([mapBytes, mapExpected]));
      return expanded;
    }, dynamicToIterable()))[dartx.toList]();
  };
  dart.fn(json_unicode_tests._expandUnicodeTests, VoidTodynamic());
  dart.defineLazy(json_unicode_tests, {
    get JSON_UNICODE_TESTS() {
      return json_unicode_tests._expandUnicodeTests();
    }
  });
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
  exports.streamed_conversion_json_utf8_decode_test = streamed_conversion_json_utf8_decode_test;
  exports.json_unicode_tests = json_unicode_tests;
  exports.unicode_tests = unicode_tests;
});
