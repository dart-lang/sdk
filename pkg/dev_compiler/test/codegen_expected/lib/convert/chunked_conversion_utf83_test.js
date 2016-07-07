dart_library.library('lib/convert/chunked_conversion_utf83_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__chunked_conversion_utf83_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const chunked_conversion_utf83_test = Object.create(null);
  let SinkOfString = () => (SinkOfString = dart.constFn(core.Sink$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfintAndintToString = () => (ListOfintAndintToString = dart.constFn(dart.definiteFunctionType(core.String, [ListOfint(), core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  chunked_conversion_utf83_test.decode = function(bytes, chunkSize) {
    let buffer = new core.StringBuffer();
    let stringSink = convert.StringConversionSink.fromStringSink(buffer);
    let byteSink = new convert.Utf8Decoder().startChunkedConversion(SinkOfString()._check(stringSink));
    let i = 0;
    while (i < dart.notNull(bytes[dartx.length])) {
      let nextChunk = [];
      for (let j = 0; j < dart.notNull(chunkSize); j++) {
        if (i < dart.notNull(bytes[dartx.length])) {
          nextChunk[dartx.add](bytes[dartx.get](i));
          i++;
        }
      }
      byteSink.add(ListOfint()._check(nextChunk));
    }
    byteSink.close();
    return buffer.toString();
  };
  dart.fn(chunked_conversion_utf83_test.decode, ListOfintAndintToString());
  chunked_conversion_utf83_test.decodeAllowMalformed = function(bytes, chunkSize) {
    let buffer = new core.StringBuffer();
    let stringSink = convert.StringConversionSink.fromStringSink(buffer);
    let decoder = new convert.Utf8Decoder({allowMalformed: true});
    let byteSink = decoder.startChunkedConversion(SinkOfString()._check(stringSink));
    let i = 0;
    while (i < dart.notNull(bytes[dartx.length])) {
      let nextChunk = [];
      for (let j = 0; j < dart.notNull(chunkSize); j++) {
        if (i < dart.notNull(bytes[dartx.length])) {
          nextChunk[dartx.add](bytes[dartx.get](i));
          i++;
        }
      }
      byteSink.add(ListOfint()._check(nextChunk));
    }
    byteSink.close();
    return buffer.toString();
  };
  dart.fn(chunked_conversion_utf83_test.decodeAllowMalformed, ListOfintAndintToString());
  chunked_conversion_utf83_test.main = function() {
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191, 97]), 1));
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191, 97]), 2));
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191, 97]), 3));
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191, 97]), 4));
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191, 97]), 1));
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191, 97]), 2));
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191, 97]), 3));
    expect$.Expect.equals("a", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191, 97]), 4));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191]), 1));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191]), 2));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191]), 3));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decode(JSArrayOfint().of([239, 187, 191]), 4));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191]), 1));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191]), 2));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191]), 3));
    expect$.Expect.equals("", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([239, 187, 191]), 4));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decode(JSArrayOfint().of([97, 239, 187, 191]), 1));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decode(JSArrayOfint().of([97, 239, 187, 191]), 2));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decode(JSArrayOfint().of([97, 239, 187, 191]), 3));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decode(JSArrayOfint().of([97, 239, 187, 191]), 4));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([97, 239, 187, 191]), 1));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([97, 239, 187, 191]), 2));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([97, 239, 187, 191]), 3));
    expect$.Expect.equals("a﻿", chunked_conversion_utf83_test.decodeAllowMalformed(JSArrayOfint().of([97, 239, 187, 191]), 4));
  };
  dart.fn(chunked_conversion_utf83_test.main, VoidTodynamic());
  // Exports:
  exports.chunked_conversion_utf83_test = chunked_conversion_utf83_test;
});
