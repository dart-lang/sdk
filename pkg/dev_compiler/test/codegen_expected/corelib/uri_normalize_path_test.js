dart_library.library('corelib/uri_normalize_path_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_normalize_path_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_normalize_path_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let StringAndStringTodynamic = () => (StringAndStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String])))();
  let StringTodynamic = () => (StringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  uri_normalize_path_test.test = function(path, normalizedPath) {
    for (let scheme of JSArrayOfString().of(["http", "file", "unknown"])) {
      for (let auth of JSArrayOfList().of([JSArrayOfString().of([null, "hostname", null]), JSArrayOfObject().of(["userinfo", "hostname", 1234]), [null, null, null]])) {
        for (let query of JSArrayOfString().of([null, "query"])) {
          for (let fragment of JSArrayOfString().of([null, "fragment"])) {
            let base = core.Uri.new({scheme: scheme, userInfo: core.String._check(auth[dartx.get](0)), host: core.String._check(auth[dartx.get](1)), port: core.int._check(auth[dartx.get](2)), path: path, query: query, fragment: fragment});
            let expected = base.replace({path: dart.test(base.hasAuthority) && dart.test(normalizedPath[dartx.isEmpty]) ? "/" : normalizedPath});
            let actual = base.normalizePath();
            expect$.Expect.equals(expected, actual, dart.str`${base}`);
          }
        }
      }
    }
  };
  dart.fn(uri_normalize_path_test.test, StringAndStringTodynamic());
  uri_normalize_path_test.testNoChange = function(path) {
    uri_normalize_path_test.test(path, path);
  };
  dart.fn(uri_normalize_path_test.testNoChange, StringTodynamic());
  uri_normalize_path_test.main = function() {
    uri_normalize_path_test.testNoChange("foo/bar/baz");
    uri_normalize_path_test.testNoChange("/foo/bar/baz");
    uri_normalize_path_test.testNoChange("foo/bar/baz/");
    uri_normalize_path_test.test("foo/bar/..", "foo/");
    uri_normalize_path_test.test("foo/bar/.", "foo/bar/");
    uri_normalize_path_test.test("foo/./bar/../baz", "foo/baz");
    uri_normalize_path_test.test("../../foo", "foo");
    uri_normalize_path_test.test("./../foo", "foo");
    uri_normalize_path_test.test("./../", "");
    uri_normalize_path_test.test("./../.", "");
    uri_normalize_path_test.test("foo/bar/baz/../../../../qux", "/qux");
    uri_normalize_path_test.test("/foo/bar/baz/../../../../qux", "/qux");
    uri_normalize_path_test.test(".", "");
    uri_normalize_path_test.test("..", "");
    uri_normalize_path_test.test("/.", "/");
    uri_normalize_path_test.test("/..", "/");
  };
  dart.fn(uri_normalize_path_test.main, VoidTodynamic());
  // Exports:
  exports.uri_normalize_path_test = uri_normalize_path_test;
});
