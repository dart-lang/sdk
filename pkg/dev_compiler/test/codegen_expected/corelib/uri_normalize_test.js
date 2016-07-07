dart_library.library('corelib/uri_normalize_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_normalize_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_normalize_test = Object.create(null);
  let StringAndString__Todynamic = () => (StringAndString__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String], {scheme: core.String, host: core.String})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  uri_normalize_test.testNormalizePath = function() {
    function test(expected, path, opts) {
      let scheme = opts && 'scheme' in opts ? opts.scheme : null;
      let host = opts && 'host' in opts ? opts.host : null;
      let uri = core.Uri.new({scheme: scheme, host: host, path: path});
      expect$.Expect.equals(expected, uri.toString());
      if (scheme == null && host == null) {
        expect$.Expect.equals(expected, uri.path);
      }
    }
    dart.fn(test, StringAndString__Todynamic());
    let unreserved = "-._~0123456789" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "abcdefghijklmnopqrstuvwxyz";
    test("A", "%41");
    test("AB", "%41%42");
    test("%40AB", "%40%41%42");
    test("a", "%61");
    test("ab", "%61%62");
    test("%60ab", "%60%61%62");
    test(unreserved, unreserved);
    let x = new core.StringBuffer();
    for (let i = 32; i < 128; i++) {
      if (unreserved[dartx.indexOf](core.String.fromCharCode(i)) != -1) {
        x.writeCharCode(i);
      } else {
        x.write("%");
        x.write(i[dartx.toRadixString](16));
      }
    }
    expect$.Expect.equals(x.toString()[dartx.toUpperCase](), core.Uri.new({path: x.toString()}).toString()[dartx.toUpperCase]());
    test("/a/b/c/", "/../a/./b/z/../c/d/..");
    test("/a/b/c/", "/./a/b/c/");
    test("/a/b/c/", "/./../a/b/c/");
    test("/a/b/c/", "/./../a/b/c/.");
    test("/a/b/c/", "/./../a/b/c/z/./..");
    test("/", "/a/..");
    test("s:a/b/c/", "../a/./b/z/../c/d/..", {scheme: "s"});
    test("s:a/b/c/", "./a/b/c/", {scheme: "s"});
    test("s:a/b/c/", "./../a/b/c/", {scheme: "s"});
    test("s:a/b/c/", "./../a/b/c/.", {scheme: "s"});
    test("s:a/b/c/", "./../a/b/c/z/./..", {scheme: "s"});
    test("s:/", "/a/..", {scheme: "s"});
    test("s:/", "a/..", {scheme: "s"});
    test("//h/a/b/c/", "../a/./b/z/../c/d/..", {host: "h"});
    test("//h/a/b/c/", "./a/b/c/", {host: "h"});
    test("//h/a/b/c/", "./../a/b/c/", {host: "h"});
    test("//h/a/b/c/", "./../a/b/c/.", {host: "h"});
    test("//h/a/b/c/", "./../a/b/c/z/./..", {host: "h"});
    test("//h/", "/a/..", {host: "h"});
    test("//h/", "a/..", {host: "h"});
    test("../a/b/c/", "../a/./b/z/../c/d/..");
    test("a/b/c/", "./a/b/c/");
    test("../a/b/c/", "./../a/b/c/");
    test("../a/b/c/", "./../a/b/c/.");
    test("../a/b/c/", "./../a/b/c/z/./..");
    test("/", "/a/..");
    test("./", "a/..");
  };
  dart.fn(uri_normalize_test.testNormalizePath, VoidTodynamic());
  uri_normalize_test.main = function() {
    uri_normalize_test.testNormalizePath();
  };
  dart.fn(uri_normalize_test.main, VoidTodynamic());
  // Exports:
  exports.uri_normalize_test = uri_normalize_test;
});
