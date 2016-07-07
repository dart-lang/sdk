dart_library.library('corelib/uri_scheme_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_scheme_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_scheme_test = Object.create(null);
  let VoidToUri = () => (VoidToUri = dart.constFn(dart.definiteFunctionType(core.Uri, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StringAndStringAndStringTodynamic = () => (StringAndStringAndStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String, core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  uri_scheme_test.testInvalidArguments = function() {
    expect$.Expect.throws(dart.fn(() => core.Uri.new({scheme: "_"}), VoidToUri()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.new({scheme: "http_s"}), VoidToUri()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.new({scheme: "127.0.0.1:80"}), VoidToUri()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
  };
  dart.fn(uri_scheme_test.testInvalidArguments, VoidTovoid());
  uri_scheme_test.testScheme = function() {
    function test(expectedScheme, expectedUri, scheme) {
      let uri = core.Uri.new({scheme: scheme});
      expect$.Expect.equals(expectedScheme, uri.scheme);
      expect$.Expect.equals(expectedUri, dart.toString(uri));
      uri = core.Uri.parse(dart.str`${scheme}:`);
      expect$.Expect.equals(expectedScheme, uri.scheme);
      expect$.Expect.equals(expectedUri, dart.toString(uri));
    }
    dart.fn(test, StringAndStringAndStringTodynamic());
    test("http", "http:", "http");
    test("http", "http:", "HTTP");
    test("http", "http:", "hTTP");
    test("http", "http:", "Http");
    test("http+ssl", "http+ssl:", "HTTP+ssl");
    test("urn", "urn:", "urn");
    test("urn", "urn:", "UrN");
    test("a123.432", "a123.432:", "a123.432");
  };
  dart.fn(uri_scheme_test.testScheme, VoidTovoid());
  uri_scheme_test.main = function() {
    uri_scheme_test.testInvalidArguments();
    uri_scheme_test.testScheme();
  };
  dart.fn(uri_scheme_test.main, VoidTodynamic());
  // Exports:
  exports.uri_scheme_test = uri_scheme_test;
});
