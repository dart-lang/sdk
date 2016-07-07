dart_library.library('lib/convert/streamed_conversion_utf8_encode_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__streamed_conversion_utf8_encode_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const streamed_conversion_utf8_encode_test = Object.create(null);
  const unicode_tests = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let StreamOfListOfint = () => (StreamOfListOfint = dart.constFn(async.Stream$(ListOfint())))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfList = () => (ListOfList = dart.constFn(core.List$(core.List)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StringAndintToStreamOfListOfint = () => (StringAndintToStreamOfListOfint = dart.constFn(dart.definiteFunctionType(StreamOfListOfint(), [core.String, core.int])))();
  let ListTodynamic = () => (ListTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List])))();
  let ListOfintAndStreamTovoid = () => (ListOfintAndStreamTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfint(), async.Stream])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListOfObjectToListOfObject = () => (ListOfObjectToListOfObject = dart.constFn(dart.definiteFunctionType(ListOfObject(), [ListOfObject()])))();
  let VoidToListOfList = () => (VoidToListOfList = dart.constFn(dart.definiteFunctionType(ListOfList(), [])))();
  streamed_conversion_utf8_encode_test.encode = function(string, chunkSize) {
    let controller = null;
    controller = async.StreamController.new({onListen: dart.fn(() => {
        let i = 0;
        while (dart.notNull(i) < dart.notNull(string[dartx.length])) {
          if (dart.notNull(i) + dart.notNull(chunkSize) <= dart.notNull(string[dartx.length])) {
            dart.dsend(controller, 'add', string[dartx.substring](i, dart.notNull(i) + dart.notNull(chunkSize)));
          } else {
            dart.dsend(controller, 'add', string[dartx.substring](i));
          }
          i = dart.notNull(i) + dart.notNull(chunkSize);
        }
        dart.dsend(controller, 'close');
      }, VoidTovoid())});
    return StreamOfListOfint()._check(dart.dsend(dart.dload(controller, 'stream'), 'transform', convert.UTF8.encoder));
  };
  dart.fn(streamed_conversion_utf8_encode_test.encode, StringAndintToStreamOfListOfint());
  streamed_conversion_utf8_encode_test.testUnpaused = function(expected, stream) {
    async_helper$.asyncStart();
    stream.toList().then(dart.dynamic)(dart.fn(list => {
      let combined = [];
      list[dartx.forEach](dart.bind(combined, dartx.addAll));
      expect$.Expect.listEquals(expected, combined);
      async_helper$.asyncEnd();
    }, ListTodynamic()));
  };
  dart.fn(streamed_conversion_utf8_encode_test.testUnpaused, ListOfintAndStreamTovoid());
  streamed_conversion_utf8_encode_test.testWithPauses = function(expected, stream) {
    async_helper$.asyncStart();
    let combined = [];
    let sub = null;
    sub = stream.listen(dart.fn(x => {
      combined[dartx.addAll](core.Iterable._check(x));
      dart.dsend(sub, 'pause', async.Future.delayed(core.Duration.ZERO));
    }, dynamicTovoid()), {onDone: dart.fn(() => {
        expect$.Expect.listEquals(expected, combined);
        async_helper$.asyncEnd();
      }, VoidTovoid())});
  };
  dart.fn(streamed_conversion_utf8_encode_test.testWithPauses, ListOfintAndStreamTovoid());
  streamed_conversion_utf8_encode_test.main = function() {
    for (let test of unicode_tests.UNICODE_TESTS) {
      let expected = dart.dindex(test, 0);
      let string = dart.dindex(test, 1);
      streamed_conversion_utf8_encode_test.testUnpaused(ListOfint()._check(expected), streamed_conversion_utf8_encode_test.encode(core.String._check(string), 1));
      streamed_conversion_utf8_encode_test.testWithPauses(ListOfint()._check(expected), streamed_conversion_utf8_encode_test.encode(core.String._check(string), 1));
      streamed_conversion_utf8_encode_test.testUnpaused(ListOfint()._check(expected), streamed_conversion_utf8_encode_test.encode(core.String._check(string), 2));
      streamed_conversion_utf8_encode_test.testWithPauses(ListOfint()._check(expected), streamed_conversion_utf8_encode_test.encode(core.String._check(string), 2));
    }
  };
  dart.fn(streamed_conversion_utf8_encode_test.main, VoidTodynamic());
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
  exports.streamed_conversion_utf8_encode_test = streamed_conversion_utf8_encode_test;
  exports.unicode_tests = unicode_tests;
});
