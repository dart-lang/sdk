dart_library.library('lib/convert/utf83_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__utf83_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const utf83_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  utf83_test.main = function() {
    expect$.Expect.equals("a", convert.UTF8.decode(JSArrayOfint().of([239, 187, 191, 97])));
    expect$.Expect.equals("a", convert.UTF8.decoder.convert(JSArrayOfint().of([239, 187, 191, 97])));
    expect$.Expect.equals("a", new convert.Utf8Decoder().convert(JSArrayOfint().of([239, 187, 191, 97])));
    expect$.Expect.equals("a", convert.UTF8.decode(JSArrayOfint().of([239, 187, 191, 97]), {allowMalformed: true}));
    expect$.Expect.equals("a", new convert.Utf8Codec({allowMalformed: true}).decode(JSArrayOfint().of([239, 187, 191, 97])));
    expect$.Expect.equals("a", new convert.Utf8Codec({allowMalformed: true}).decoder.convert(JSArrayOfint().of([239, 187, 191, 97])));
    expect$.Expect.equals("a", new convert.Utf8Decoder({allowMalformed: true}).convert(JSArrayOfint().of([239, 187, 191, 97])));
    expect$.Expect.equals("", convert.UTF8.decode(JSArrayOfint().of([239, 187, 191])));
    expect$.Expect.equals("", convert.UTF8.decoder.convert(JSArrayOfint().of([239, 187, 191])));
    expect$.Expect.equals("", new convert.Utf8Decoder().convert(JSArrayOfint().of([239, 187, 191])));
    expect$.Expect.equals("", convert.UTF8.decode(JSArrayOfint().of([239, 187, 191]), {allowMalformed: true}));
    expect$.Expect.equals("", new convert.Utf8Codec({allowMalformed: true}).decode(JSArrayOfint().of([239, 187, 191])));
    expect$.Expect.equals("", new convert.Utf8Codec({allowMalformed: true}).decoder.convert(JSArrayOfint().of([239, 187, 191])));
    expect$.Expect.equals("", new convert.Utf8Decoder({allowMalformed: true}).convert(JSArrayOfint().of([239, 187, 191])));
    expect$.Expect.equals("a﻿", convert.UTF8.decode(JSArrayOfint().of([97, 239, 187, 191])));
    expect$.Expect.equals("a﻿", convert.UTF8.decoder.convert(JSArrayOfint().of([97, 239, 187, 191])));
    expect$.Expect.equals("a﻿", new convert.Utf8Decoder().convert(JSArrayOfint().of([97, 239, 187, 191])));
    expect$.Expect.equals("a﻿", convert.UTF8.decode(JSArrayOfint().of([97, 239, 187, 191]), {allowMalformed: true}));
    expect$.Expect.equals("a﻿", new convert.Utf8Codec({allowMalformed: true}).decode(JSArrayOfint().of([97, 239, 187, 191])));
    expect$.Expect.equals("a﻿", new convert.Utf8Codec({allowMalformed: true}).decoder.convert(JSArrayOfint().of([97, 239, 187, 191])));
    expect$.Expect.equals("a﻿", new convert.Utf8Decoder({allowMalformed: true}).convert(JSArrayOfint().of([97, 239, 187, 191])));
  };
  dart.fn(utf83_test.main, VoidTodynamic());
  // Exports:
  exports.utf83_test = utf83_test;
});
