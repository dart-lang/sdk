dart_library.library('corelib/uri_http_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_http_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_http_test = Object.create(null);
  let UriAndStringTovoid = () => (UriAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Uri, core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  uri_http_test.testHttpUri = function() {
    function check(uri, expected) {
      expect$.Expect.equals(expected, dart.toString(uri));
    }
    dart.fn(check, UriAndStringTovoid());
    check(core.Uri.http("", ""), "http:");
    check(core.Uri.http("@:", ""), "http://");
    check(core.Uri.http("@:8080", ""), "http://:8080");
    check(core.Uri.http("@host:", ""), "http://host");
    check(core.Uri.http("@host:", ""), "http://host");
    check(core.Uri.http("xxx:yyy@host:8080", ""), "http://xxx:yyy@host:8080");
    check(core.Uri.http("host", "a"), "http://host/a");
    check(core.Uri.http("host", "/a"), "http://host/a");
    check(core.Uri.http("host", "a/"), "http://host/a/");
    check(core.Uri.http("host", "/a/"), "http://host/a/");
    check(core.Uri.http("host", "a/b"), "http://host/a/b");
    check(core.Uri.http("host", "/a/b"), "http://host/a/b");
    check(core.Uri.http("host", "a/b/"), "http://host/a/b/");
    check(core.Uri.http("host", "/a/b/"), "http://host/a/b/");
    check(core.Uri.http("host", "a b"), "http://host/a%20b");
    check(core.Uri.http("host", "/a b"), "http://host/a%20b");
    check(core.Uri.http("host", "/a b/"), "http://host/a%20b/");
    check(core.Uri.http("host", "/a%2F"), "http://host/a%252F");
    check(core.Uri.http("host", "/a%2F/"), "http://host/a%252F/");
    check(core.Uri.http("host", "/a/b", dart.map({c: "d"})), "http://host/a/b?c=d");
    check(core.Uri.http("host", "/a/b", dart.map({"c=": "&d"})), "http://host/a/b?c%3D=%26d");
    check(core.Uri.http("[::]", "a"), "http://[::]/a");
    check(core.Uri.http("[::127.0.0.1]", "a"), "http://[::127.0.0.1]/a");
  };
  dart.fn(uri_http_test.testHttpUri, VoidTodynamic());
  uri_http_test.testHttpsUri = function() {
    function check(uri, expected) {
      expect$.Expect.equals(expected, dart.toString(uri));
    }
    dart.fn(check, UriAndStringTovoid());
    check(core.Uri.https("", ""), "https:");
    check(core.Uri.https("@:", ""), "https://");
    check(core.Uri.https("@:8080", ""), "https://:8080");
    check(core.Uri.https("@host:", ""), "https://host");
    check(core.Uri.https("@host:", ""), "https://host");
    check(core.Uri.https("xxx:yyy@host:8080", ""), "https://xxx:yyy@host:8080");
    check(core.Uri.https("host", "a"), "https://host/a");
    check(core.Uri.https("host", "/a"), "https://host/a");
    check(core.Uri.https("host", "a/"), "https://host/a/");
    check(core.Uri.https("host", "/a/"), "https://host/a/");
    check(core.Uri.https("host", "a/b"), "https://host/a/b");
    check(core.Uri.https("host", "/a/b"), "https://host/a/b");
    check(core.Uri.https("host", "a/b/"), "https://host/a/b/");
    check(core.Uri.https("host", "/a/b/"), "https://host/a/b/");
    check(core.Uri.https("host", "a b"), "https://host/a%20b");
    check(core.Uri.https("host", "/a b"), "https://host/a%20b");
    check(core.Uri.https("host", "/a b/"), "https://host/a%20b/");
    check(core.Uri.https("host", "/a%2F"), "https://host/a%252F");
    check(core.Uri.https("host", "/a%2F/"), "https://host/a%252F/");
    check(core.Uri.https("host", "/a/b", dart.map({c: "d"})), "https://host/a/b?c=d");
    check(core.Uri.https("host", "/a/b", dart.map({"c=": "&d"})), "https://host/a/b?c%3D=%26d");
    check(core.Uri.https("[::]", "a"), "https://[::]/a");
    check(core.Uri.https("[::127.0.0.1]", "a"), "https://[::127.0.0.1]/a");
  };
  dart.fn(uri_http_test.testHttpsUri, VoidTodynamic());
  uri_http_test.testResolveHttpScheme = function() {
    let s = "//myserver:1234/path/some/thing";
    let uri = core.Uri.parse(s);
    let http = core.Uri.new({scheme: "http"});
    let https = core.Uri.new({scheme: "https"});
    expect$.Expect.equals(dart.str`http:${s}`, dart.toString(http.resolveUri(uri)));
    expect$.Expect.equals(dart.str`https:${s}`, dart.toString(https.resolveUri(uri)));
  };
  dart.fn(uri_http_test.testResolveHttpScheme, VoidTodynamic());
  uri_http_test.main = function() {
    uri_http_test.testHttpUri();
    uri_http_test.testHttpsUri();
    uri_http_test.testResolveHttpScheme();
  };
  dart.fn(uri_http_test.main, VoidTodynamic());
  // Exports:
  exports.uri_http_test = uri_http_test;
});
