dart_library.library('lib/convert/base64_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__base64_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const typed_data = dart_sdk.typed_data;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const base64_test_01_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let ChunkedConversionSinkOfString = () => (ChunkedConversionSinkOfString = dart.constFn(convert.ChunkedConversionSink$(core.String)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let ChunkedConversionSinkOfListOfint = () => (ChunkedConversionSinkOfListOfint = dart.constFn(convert.ChunkedConversionSink$(ListOfint())))();
  let ListOfListOfint = () => (ListOfListOfint = dart.constFn(core.List$(ListOfint())))();
  let TestSinkOfListOfint = () => (TestSinkOfListOfint = dart.constFn(base64_test_01_multi.TestSink$(ListOfint())))();
  let TestSinkOfString = () => (TestSinkOfString = dart.constFn(base64_test_01_multi.TestSink$(core.String)))();
  let TestSink = () => (TestSink = dart.constFn(base64_test_01_multi.TestSink$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListOfStringTovoid = () => (ListOfStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfString()])))();
  let ListOfListOfintTovoid = () => (ListOfListOfintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfListOfint()])))();
  let ListOfintToListOfint = () => (ListOfintToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [ListOfint()])))();
  let ListOfintAndStringTovoid = () => (ListOfintAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfint(), core.String])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToListOfint = () => (VoidToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [])))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let ListOfintTodynamic = () => (ListOfintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfint()])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  base64_test_01_multi.main = function() {
    for (let list of JSArrayOfListOfint().of([JSArrayOfint().of([]), JSArrayOfint().of([0]), JSArrayOfint().of([255, 0]), JSArrayOfint().of([255, 170, 85]), JSArrayOfint().of([0, 1, 2, 3]), IterableOfint().generate(13)[dartx.toList](), IterableOfint().generate(254)[dartx.toList](), IterableOfint().generate(255)[dartx.toList](), IterableOfint().generate(256)[dartx.toList]()])) {
      base64_test_01_multi.testRoundtrip(list, dart.str`List#${list[dartx.length]}`);
      base64_test_01_multi.testRoundtrip(typed_data.Uint8List.fromList(list), dart.str`Uint8List#${list[dartx.length]}`);
    }
    base64_test_01_multi.testErrors();
    base64_test_01_multi.testIssue25577();
    expect$.Expect.listEquals(JSArrayOfint().of([251, 255, 191, 0]), convert.BASE64.decode("-_+/AA%3D="));
    expect$.Expect.listEquals(JSArrayOfint().of([251, 255, 191, 0]), convert.BASE64.decode("-_+/AA=%3D"));
  };
  dart.fn(base64_test_01_multi.main, VoidTodynamic());
  base64_test_01_multi.testRoundtrip = function(list, name) {
    let encodedNormal = convert.BASE64.encode(list);
    let encodedPercent = encodedNormal[dartx.replaceAll]("=", "%3D");
    let uriEncoded = convert.BASE64URL.encode(list);
    let expectedUriEncoded = encodedNormal[dartx.replaceAll]("+", "-")[dartx.replaceAll]("/", "_");
    expect$.Expect.equals(expectedUriEncoded, uriEncoded);
    let result = convert.BASE64.decode(encodedNormal);
    expect$.Expect.listEquals(list, result, name);
    result = convert.BASE64.decode(encodedPercent);
    expect$.Expect.listEquals(list, result, name);
    result = convert.BASE64.decode(uriEncoded);
    expect$.Expect.listEquals(list, result, name);
    let increment = (dart.notNull(list[dartx.length]) / 7)[dartx.truncate]() + 1;
    for (let i = 0; i < dart.notNull(list[dartx.length]); i = i + increment) {
      for (let j = i; j < dart.notNull(list[dartx.length]); j = j + increment) {
        {
          let results = null;
          let sink = ChunkedConversionSinkOfString().withCallback(dart.fn(v => {
            results = v;
          }, ListOfStringTovoid()));
          let encoder = convert.BASE64.encoder.startChunkedConversion(sink);
          encoder.add(list[dartx.sublist](0, i));
          encoder.add(list[dartx.sublist](i, j));
          encoder.add(list[dartx.sublist](j, list[dartx.length]));
          encoder.close();
          let name = dart.str`0-${i}-${j}-${list[dartx.length]}: list`;
          expect$.Expect.equals(encodedNormal, dart.dsend(results, 'join', ""), name);
        }
        {
          let results = null;
          let sink = ChunkedConversionSinkOfString().withCallback(dart.fn(v => {
            results = v;
          }, ListOfStringTovoid()));
          let encoder = convert.BASE64.encoder.startChunkedConversion(sink);
          encoder.addSlice(list, 0, i, false);
          encoder.addSlice(list, i, j, false);
          encoder.addSlice(list, j, list[dartx.length], true);
          let name = dart.str`0-${i}-${j}-${list[dartx.length]}: ${list}`;
          expect$.Expect.equals(encodedNormal, dart.dsend(results, 'join', ""), name);
        }
        {
          let results = null;
          let sink = ChunkedConversionSinkOfString().withCallback(dart.fn(v => {
            results = v;
          }, ListOfStringTovoid()));
          let encoder = convert.BASE64URL.encoder.startChunkedConversion(sink);
          encoder.add(list[dartx.sublist](0, i));
          encoder.add(list[dartx.sublist](i, j));
          encoder.add(list[dartx.sublist](j, list[dartx.length]));
          encoder.close();
          let name = dart.str`0-${i}-${j}-${list[dartx.length]}: list`;
          expect$.Expect.equals(uriEncoded, dart.dsend(results, 'join', ""), name);
        }
        {
          let results = null;
          let sink = ChunkedConversionSinkOfString().withCallback(dart.fn(v => {
            results = v;
          }, ListOfStringTovoid()));
          let encoder = convert.BASE64URL.encoder.startChunkedConversion(sink);
          encoder.addSlice(list, 0, i, false);
          encoder.addSlice(list, i, j, false);
          encoder.addSlice(list, j, list[dartx.length], true);
          let name = dart.str`0-${i}-${j}-${list[dartx.length]}: ${list}`;
          expect$.Expect.equals(uriEncoded, dart.dsend(results, 'join', ""), name);
        }
      }
    }
    for (let encoded of JSArrayOfString().of([encodedNormal, encodedPercent, uriEncoded])) {
      increment = (dart.notNull(encoded[dartx.length]) / 7)[dartx.truncate]() + 1;
      for (let i = 0; i < dart.notNull(encoded[dartx.length]); i = i + increment) {
        for (let j = i; j < dart.notNull(encoded[dartx.length]); j = j + increment) {
          {
            let results = null;
            let sink = ChunkedConversionSinkOfListOfint().withCallback(dart.fn(v => {
              results = v;
            }, ListOfListOfintTovoid()));
            let decoder = convert.BASE64.decoder.startChunkedConversion(sink);
            decoder.add(encoded[dartx.substring](0, i));
            decoder.add(encoded[dartx.substring](i, j));
            decoder.add(encoded[dartx.substring](j, encoded[dartx.length]));
            decoder.close();
            let name = dart.str`0-${i}-${j}-${encoded[dartx.length]}: ${encoded}`;
            expect$.Expect.listEquals(list, results[dartx.expand](core.int)(dart.fn(x => x, ListOfintToListOfint()))[dartx.toList](), name);
          }
          {
            let results = null;
            let sink = ChunkedConversionSinkOfListOfint().withCallback(dart.fn(v => {
              results = v;
            }, ListOfListOfintTovoid()));
            let decoder = convert.BASE64.decoder.startChunkedConversion(sink);
            decoder.addSlice(encoded, 0, i, false);
            decoder.addSlice(encoded, i, j, false);
            decoder.addSlice(encoded, j, encoded[dartx.length], true);
            let name = dart.str`0-${i}-${j}-${encoded[dartx.length]}: ${encoded}`;
            expect$.Expect.listEquals(list, results[dartx.expand](core.int)(dart.fn(x => x, ListOfintToListOfint()))[dartx.toList](), name);
          }
        }
      }
    }
  };
  dart.fn(base64_test_01_multi.testRoundtrip, ListOfintAndStringTovoid());
  base64_test_01_multi.isFormatException = function(e) {
    return core.FormatException.is(e);
  };
  dart.fn(base64_test_01_multi.isFormatException, dynamicTobool());
  base64_test_01_multi.isArgumentError = function(e) {
    return core.ArgumentError.is(e);
  };
  dart.fn(base64_test_01_multi.isArgumentError, dynamicTobool());
  base64_test_01_multi.testErrors = function() {
    function badChunkDecode(list) {
      expect$.Expect.throws(dart.fn(() => {
        let sink = ChunkedConversionSinkOfListOfint().withCallback(dart.fn(v => {
          expect$.Expect.fail(dart.str`Should have thrown: chunk ${list}`);
        }, ListOfListOfintTovoid()));
        let c = convert.BASE64.decoder.startChunkedConversion(sink);
        for (let string of list) {
          c.add(string);
        }
        c.close();
      }, VoidTovoid()), base64_test_01_multi.isFormatException, dart.str`chunk ${list}`);
    }
    dart.fn(badChunkDecode, ListOfStringTovoid());
    function badDecode(string) {
      expect$.Expect.throws(dart.fn(() => convert.BASE64.decode(string), VoidToListOfint()), base64_test_01_multi.isFormatException, string);
      expect$.Expect.throws(dart.fn(() => convert.BASE64URL.decode(string), VoidToListOfint()), base64_test_01_multi.isFormatException, string);
      badChunkDecode(JSArrayOfString().of([string]));
      badChunkDecode(JSArrayOfString().of(["", string]));
      badChunkDecode(JSArrayOfString().of([string, ""]));
      badChunkDecode(JSArrayOfString().of([string, "", ""]));
      badChunkDecode(JSArrayOfString().of(["", string, ""]));
    }
    dart.fn(badDecode, StringTovoid());
    badDecode("A");
    badDecode("AA");
    badDecode("AAA");
    badDecode("AAAAA");
    badDecode("AAAAAA");
    badDecode("AAAAAAA");
    badDecode("AAAA=");
    badDecode("AAAA==");
    badDecode("AAAA===");
    badDecode("AAAA====");
    badDecode("AAAA%");
    badDecode("AAAA%3");
    badDecode("AAAA%3D");
    badDecode("AAA%3D%");
    badDecode("AAA%3D=");
    badDecode("A=");
    badDecode("A=A");
    badDecode("A==");
    badDecode("A==A");
    badDecode("A===");
    badDecode("====");
    badDecode("AA=");
    badDecode("AA%=");
    badDecode("AA%3");
    badDecode("AA%3D");
    badDecode("AA===");
    badDecode("AAA==");
    badDecode("AAA=AAAA");
    badDecode("AAA ");
    badDecode("AAA= ");
    badDecode("AAA");
    badDecode("AAAÿ");
    badDecode("AAAŁ");
    badDecode("AAA၁");
    badDecode("AAA𐁁");
    badDecode("AAŁ=");
    badDecode("AA၁=");
    badDecode("AA𐁁=");
    let alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/-_";
    let units = alphabet[dartx.codeUnits];
    for (let i = 0; i < 128; i++) {
      if (!dart.test(units[dartx.contains](i))) {
        badDecode(core.String.fromCharCode(i)[dartx['*']](4));
      }
    }
    badChunkDecode(JSArrayOfString().of(["A", "A"]));
    badChunkDecode(JSArrayOfString().of(["A", "A", "A"]));
    badChunkDecode(JSArrayOfString().of(["A", "A", "="]));
    badChunkDecode(JSArrayOfString().of(["A", "A", "=", ""]));
    badChunkDecode(JSArrayOfString().of(["A", "A", "=", "=", "="]));
    badChunkDecode(JSArrayOfString().of(["AAA", "=="]));
    badChunkDecode(JSArrayOfString().of(["A", "A", "A"]));
    badChunkDecode(JSArrayOfString().of(["AAA", ""]));
    badChunkDecode(JSArrayOfString().of(["AA=", ""]));
    badChunkDecode(JSArrayOfString().of(["AB==", ""]));
    function badChunkEncode(list) {
      for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
        for (let j = 0; j < dart.notNull(list[dartx.length]); j++) {
          expect$.Expect.throws(dart.fn(() => {
            let sink = ChunkedConversionSinkOfString().withCallback(dart.fn(v => {
              expect$.Expect.fail(dart.str`Should have thrown: chunked ${list}`);
            }, ListOfStringTovoid()));
            let c = convert.BASE64.encoder.startChunkedConversion(sink);
            c.add(list[dartx.sublist](0, i));
            c.add(list[dartx.sublist](i, j));
            c.add(list[dartx.sublist](j, list[dartx.length]));
            c.close();
          }, VoidTovoid()), base64_test_01_multi.isArgumentError, dart.str`chunk ${list}`);
        }
      }
      for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
        for (let j = 0; j < dart.notNull(list[dartx.length]); j++) {
          expect$.Expect.throws(dart.fn(() => {
            let sink = ChunkedConversionSinkOfString().withCallback(dart.fn(v => {
              expect$.Expect.fail(dart.str`Should have thrown: chunked ${list}`);
            }, ListOfStringTovoid()));
            let c = convert.BASE64.encoder.startChunkedConversion(sink);
            c.addSlice(list, 0, i, false);
            c.addSlice(list, i, j, false);
            c.addSlice(list, j, list[dartx.length], true);
          }, VoidTovoid()), base64_test_01_multi.isArgumentError, dart.str`chunk ${list}`);
        }
      }
    }
    dart.fn(badChunkEncode, ListOfintTodynamic());
    function badEncode(invalid) {
      expect$.Expect.throws(dart.fn(() => {
        convert.BASE64.encode(JSArrayOfint().of([invalid]));
      }, VoidTovoid()), base64_test_01_multi.isArgumentError, dart.str`${invalid}`);
      expect$.Expect.throws(dart.fn(() => {
        convert.BASE64.encode(JSArrayOfint().of([0, invalid, 0]));
      }, VoidTovoid()), base64_test_01_multi.isArgumentError, dart.str`${invalid}`);
      badChunkEncode(JSArrayOfint().of([invalid]));
      badChunkEncode(JSArrayOfint().of([0, invalid]));
      badChunkEncode(JSArrayOfint().of([0, 0, invalid]));
      badChunkEncode(JSArrayOfint().of([0, invalid, 0]));
      badChunkEncode(JSArrayOfint().of([invalid, 0, 0]));
    }
    dart.fn(badEncode, intTovoid());
    badEncode(-1);
    badEncode(256);
    badEncode(4096);
    badEncode(65536);
  };
  dart.fn(base64_test_01_multi.testErrors, VoidTovoid());
  base64_test_01_multi.testIssue25577 = function() {
    let decodeSink = convert.BASE64.decoder.startChunkedConversion(new (TestSinkOfListOfint())());
    let encodeSink = convert.BASE64.encoder.startChunkedConversion(new (TestSinkOfString())());
  };
  dart.fn(base64_test_01_multi.testIssue25577, VoidTovoid());
  base64_test_01_multi.TestSink$ = dart.generic(T => {
    let SinkOfT = () => (SinkOfT = dart.constFn(core.Sink$(T)))();
    class TestSink extends core.Object {
      add(value) {
        T._check(value);
      }
      close() {}
    }
    dart.addTypeTests(TestSink);
    TestSink[dart.implements] = () => [SinkOfT()];
    dart.setSignature(TestSink, {
      methods: () => ({
        add: dart.definiteFunctionType(dart.void, [T]),
        close: dart.definiteFunctionType(dart.void, [])
      })
    });
    return TestSink;
  });
  base64_test_01_multi.TestSink = TestSink();
  // Exports:
  exports.base64_test_01_multi = base64_test_01_multi;
});
