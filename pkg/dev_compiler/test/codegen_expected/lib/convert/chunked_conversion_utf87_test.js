dart_library.library('lib/convert/chunked_conversion_utf87_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__chunked_conversion_utf87_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const chunked_conversion_utf87_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let SinkOfListOfint = () => (SinkOfListOfint = dart.constFn(core.Sink$(ListOfint())))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let ListOfintToListOfint = () => (ListOfintToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [ListOfint()])))();
  let ListOfintToString = () => (ListOfintToString = dart.constFn(dart.definiteFunctionType(core.String, [ListOfint()])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let ListOfintToIterable = () => (ListOfintToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [ListOfint()])))();
  let ListOfObjectToListOfObject = () => (ListOfObjectToListOfObject = dart.constFn(dart.definiteFunctionType(ListOfObject(), [ListOfObject()])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  chunked_conversion_utf87_test.decode = function(inputBytes) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let inputByteSink = stringConversionSink.asUtf8Sink(false);
    inputByteSink.add(inputBytes);
    inputByteSink.close();
    return convert.UTF8.decode(bytes);
  };
  dart.fn(chunked_conversion_utf87_test.decode, ListOfintToString());
  chunked_conversion_utf87_test.decode2 = function(inputBytes) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let inputByteSink = stringConversionSink.asUtf8Sink(false);
    inputBytes[dartx.forEach](dart.fn(b => inputByteSink.addSlice(JSArrayOfint().of([0, b, 1]), 1, 2, false), intTovoid()));
    inputByteSink.close();
    return convert.UTF8.decode(bytes);
  };
  dart.fn(chunked_conversion_utf87_test.decode2, ListOfintToString());
  chunked_conversion_utf87_test.decodeAllowMalformed = function(inputBytes) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let inputByteSink = stringConversionSink.asUtf8Sink(true);
    inputByteSink.add(inputBytes);
    inputByteSink.close();
    return convert.UTF8.decode(bytes);
  };
  dart.fn(chunked_conversion_utf87_test.decodeAllowMalformed, ListOfintToString());
  chunked_conversion_utf87_test.decodeAllowMalformed2 = function(inputBytes) {
    let bytes = null;
    let byteSink = convert.ByteConversionSink.withCallback(dart.fn(result => bytes = result, ListOfintToListOfint()));
    let stringConversionSink = new convert.Utf8Encoder().startChunkedConversion(SinkOfListOfint()._check(byteSink));
    let inputByteSink = stringConversionSink.asUtf8Sink(true);
    inputBytes[dartx.forEach](dart.fn(b => inputByteSink.addSlice(JSArrayOfint().of([0, b, 1]), 1, 2, false), intTovoid()));
    inputByteSink.close();
    return convert.UTF8.decode(bytes);
  };
  dart.fn(chunked_conversion_utf87_test.decodeAllowMalformed2, ListOfintToString());
  dart.defineLazy(chunked_conversion_utf87_test, {
    get TESTS() {
      return JSArrayOfListOfint().of([JSArrayOfint().of([195]), JSArrayOfint().of([226, 130]), JSArrayOfint().of([240, 164, 173]), JSArrayOfint().of([240, 130, 130, 172]), JSArrayOfint().of([192]), JSArrayOfint().of([193]), JSArrayOfint().of([245]), JSArrayOfint().of([246]), JSArrayOfint().of([247]), JSArrayOfint().of([248]), JSArrayOfint().of([249]), JSArrayOfint().of([250]), JSArrayOfint().of([251]), JSArrayOfint().of([252]), JSArrayOfint().of([253]), JSArrayOfint().of([254]), JSArrayOfint().of([255]), JSArrayOfint().of([192, 128]), JSArrayOfint().of([193, 128]), JSArrayOfint().of([244, 191, 191, 191])]);
    }
  });
  dart.defineLazy(chunked_conversion_utf87_test, {
    get TESTS2() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([JSArrayOfint().of([192, 128, 97]), "Xa"]), JSArrayOfObject().of([JSArrayOfint().of([193, 128, 97]), "Xa"]), JSArrayOfObject().of([JSArrayOfint().of([245, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([246, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([247, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([248, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([249, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([250, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([251, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([252, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([253, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([254, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([255, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([245, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([246, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([247, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([248, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([249, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([250, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([251, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([252, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([253, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([254, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([255, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([245, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([246, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([247, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([248, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([249, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([250, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([251, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([252, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([253, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([254, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([255, 128, 128, 97]), "XXXa"])]);
    }
  });
  chunked_conversion_utf87_test.main = function() {
    let allTests = chunked_conversion_utf87_test.TESTS[dartx.expand](dart.dynamic)(dart.fn(test => JSArrayOfListOfObject().of([JSArrayOfObject().of([test, "�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([97]));
          _[dartx.addAll](test);
          return _;
        })(), "a�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([97]));
          _[dartx.addAll](test);
          _[dartx.add](97);
          return _;
        })(), "a�a"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.add](97);
          return _;
        })(), "�a"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.addAll](test);
          return _;
        })(), "��"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.add](97);
          _[dartx.addAll](test);
          return _;
        })(), "�a�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([195, 165]));
          _[dartx.addAll](test);
          return _;
        })(), "å�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([195, 165]));
          _[dartx.addAll](test);
          _[dartx.addAll](JSArrayOfint().of([195, 165]));
          return _;
        })(), "å�å"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.addAll](JSArrayOfint().of([195, 165]));
          return _;
        })(), "�å"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.addAll](JSArrayOfint().of([195, 165]));
          _[dartx.addAll](test);
          return _;
        })(), "�å�"])]), ListOfintToIterable()));
    let allTests2 = chunked_conversion_utf87_test.TESTS2[dartx.map](ListOfObject())(dart.fn(test => {
      let expected = core.String.as(test[dartx.get](1))[dartx.replaceAll]("X", "�");
      return JSArrayOfObject().of([test[dartx.get](0), expected]);
    }, ListOfObjectToListOfObject()));
    for (let test of (() => {
      let _ = [];
      _[dartx.addAll](allTests);
      _[dartx.addAll](allTests2);
      return _;
    })()) {
      let bytes = ListOfint()._check(dart.dindex(test, 0));
      expect$.Expect.throws(dart.fn(() => chunked_conversion_utf87_test.decode(bytes), VoidToString()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => chunked_conversion_utf87_test.decode2(bytes), VoidToString()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
      let expected = core.String._check(dart.dindex(test, 1));
      expect$.Expect.equals(expected, chunked_conversion_utf87_test.decodeAllowMalformed(bytes));
      expect$.Expect.equals(expected, chunked_conversion_utf87_test.decodeAllowMalformed2(bytes));
    }
  };
  dart.fn(chunked_conversion_utf87_test.main, VoidTodynamic());
  // Exports:
  exports.chunked_conversion_utf87_test = chunked_conversion_utf87_test;
});
