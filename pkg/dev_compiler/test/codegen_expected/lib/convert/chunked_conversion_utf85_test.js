dart_library.library('lib/convert/chunked_conversion_utf85_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__chunked_conversion_utf85_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const chunked_conversion_utf85_test = Object.create(null);
  const unicode_tests = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let SinkOfListOfint = () => (SinkOfListOfint = dart.constFn(core.Sink$(ListOfint())))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfList = () => (ListOfList = dart.constFn(core.List$(core.List)))();
  let ListOfintToListOfint = () => (ListOfintToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [ListOfint()])))();
  let StringToListOfint = () => (StringToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [core.String])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListOfObjectToListOfObject = () => (ListOfObjectToListOfObject = dart.constFn(dart.definiteFunctionType(ListOfObject(), [ListOfObject()])))();
  let VoidToListOfList = () => (VoidToListOfList = dart.constFn(dart.definiteFunctionType(ListOfList(), [])))();
  chunked_conversion_utf85_test.encode = function(str) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    stringConversionSink.add(str);
    stringConversionSink.close();
    return bytes;
  };
  dart.fn(chunked_conversion_utf85_test.encode, StringToListOfint());
  chunked_conversion_utf85_test.encode2 = function(str) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let stringSink = stringConversionSink.asStringSink();
    stringSink.write(str);
    stringSink.close();
    return bytes;
  };
  dart.fn(chunked_conversion_utf85_test.encode2, StringToListOfint());
  chunked_conversion_utf85_test.encode3 = function(str) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let stringSink = stringConversionSink.asStringSink();
    str[dartx.codeUnits][dartx.forEach](dart.bind(stringSink, 'writeCharCode'));
    stringSink.close();
    return bytes;
  };
  dart.fn(chunked_conversion_utf85_test.encode3, StringToListOfint());
  chunked_conversion_utf85_test.encode4 = function(str) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let stringSink = stringConversionSink.asStringSink();
    str[dartx.runes].forEach(dart.bind(stringSink, 'writeCharCode'));
    stringSink.close();
    return bytes;
  };
  dart.fn(chunked_conversion_utf85_test.encode4, StringToListOfint());
  chunked_conversion_utf85_test.encode5 = function(str) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let inputByteSink = stringConversionSink.asUtf8Sink(false);
    let tmpBytes = convert.UTF8.encode(str);
    inputByteSink.add(tmpBytes);
    inputByteSink.close();
    return bytes;
  };
  dart.fn(chunked_conversion_utf85_test.encode5, StringToListOfint());
  chunked_conversion_utf85_test.encode6 = function(str) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let inputByteSink = stringConversionSink.asUtf8Sink(false);
    let tmpBytes = convert.UTF8.encode(str);
    tmpBytes[dartx.forEach](dart.fn(b => inputByteSink.addSlice(JSArrayOfint().of([0, b, 1]), 1, 2, false), intTovoid()));
    inputByteSink.close();
    return bytes;
  };
  dart.fn(chunked_conversion_utf85_test.encode6, StringToListOfint());
  chunked_conversion_utf85_test.encode7 = function(str) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    stringConversionSink.addSlice("1" + dart.notNull(str) + "2", 1, dart.notNull(str[dartx.length]) + 1, false);
    stringConversionSink.close();
    return bytes;
  };
  dart.fn(chunked_conversion_utf85_test.encode7, StringToListOfint());
  chunked_conversion_utf85_test.main = function() {
    for (let test of unicode_tests.UNICODE_TESTS) {
      let bytes = ListOfint()._check(dart.dindex(test, 0));
      let string = core.String._check(dart.dindex(test, 1));
      expect$.Expect.listEquals(bytes, chunked_conversion_utf85_test.encode(string));
      expect$.Expect.listEquals(bytes, chunked_conversion_utf85_test.encode2(string));
      expect$.Expect.listEquals(bytes, chunked_conversion_utf85_test.encode3(string));
      expect$.Expect.listEquals(bytes, chunked_conversion_utf85_test.encode4(string));
      expect$.Expect.listEquals(bytes, chunked_conversion_utf85_test.encode5(string));
      expect$.Expect.listEquals(bytes, chunked_conversion_utf85_test.encode6(string));
      expect$.Expect.listEquals(bytes, chunked_conversion_utf85_test.encode7(string));
    }
  };
  dart.fn(chunked_conversion_utf85_test.main, VoidTodynamic());
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
  exports.chunked_conversion_utf85_test = chunked_conversion_utf85_test;
  exports.unicode_tests = unicode_tests;
});
