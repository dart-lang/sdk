dart_library.library('corelib/uri_file_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_file_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_file_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfListOfString = () => (JSArrayOfListOfString = dart.constFn(_interceptors.JSArray$(ListOfString())))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringAnddynamicAndboolTovoid = () => (StringAnddynamicAndboolTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, dart.dynamic, core.bool])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToUri = () => (VoidToUri = dart.constFn(dart.definiteFunctionType(core.Uri, [])))();
  let StringAndStringAndStringTodynamic = () => (StringAndStringAndStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String, core.String])))();
  let StringAndStringAndString__Todynamic = () => (StringAndStringAndString__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String, core.String, core.bool])))();
  let String__Todynamic = () => (String__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String], {windowsOk: core.bool})))();
  uri_file_test.testFileUri = function() {
    let unsupported = new core.UnsupportedError("");
    let tests = JSArrayOfListOfObject().of([JSArrayOfString().of(["", "", ""]), JSArrayOfString().of(["relative", "relative", "relative"]), JSArrayOfString().of(["relative/", "relative/", "relative\\"]), JSArrayOfString().of(["a%20b", "a b", "a b"]), JSArrayOfString().of(["a%20b/", "a b/", "a b\\"]), JSArrayOfString().of(["a/b", "a/b", "a\\b"]), JSArrayOfString().of(["a/b/", "a/b/", "a\\b\\"]), JSArrayOfString().of(["a%20b/c%20d", "a b/c d", "a b\\c d"]), JSArrayOfString().of(["a%20b/c%20d/", "a b/c d/", "a b\\c d\\"]), JSArrayOfString().of(["file:///absolute", "/absolute", "\\absolute"]), JSArrayOfString().of(["file:///absolute", "/absolute", "\\absolute"]), JSArrayOfString().of(["file:///a/b", "/a/b", "\\a\\b"]), JSArrayOfString().of(["file:///a/b", "/a/b", "\\a\\b"]), JSArrayOfObject().of(["file://server/a/b", unsupported, "\\\\server\\a\\b"]), JSArrayOfObject().of(["file://server/a/b/", unsupported, "\\\\server\\a\\b\\"]), JSArrayOfString().of(["file:///C:/", "/C:/", "C:\\"]), JSArrayOfString().of(["file:///C:/a/b", "/C:/a/b", "C:\\a\\b"]), JSArrayOfString().of(["file:///C:/a/b/", "/C:/a/b/", "C:\\a\\b\\"]), JSArrayOfObject().of(["http:/a/b", unsupported, unsupported]), JSArrayOfObject().of(["https:/a/b", unsupported, unsupported]), JSArrayOfObject().of(["urn:a:b", unsupported, unsupported])]);
    function check(s, filePath, windows) {
      let uri = core.Uri.parse(s);
      if (core.Error.is(filePath)) {
        if (core.UnsupportedError.is(filePath)) {
          expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: windows}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
        } else {
          expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: windows}), VoidToString()));
        }
      } else {
        expect$.Expect.equals(filePath, uri.toFilePath({windows: windows}));
        expect$.Expect.equals(s, core.Uri.file(core.String._check(filePath), {windows: windows}).toString());
      }
    }
    dart.fn(check, StringAnddynamicAndboolTovoid());
    for (let test of tests) {
      check(core.String._check(test[dartx.get](0)), test[dartx.get](1), false);
      check(core.String._check(test[dartx.get](0)), test[dartx.get](2), true);
    }
    let uri = null;
    uri = core.Uri.parse("file:a");
    expect$.Expect.equals("/a", uri.toFilePath({windows: false}));
    expect$.Expect.equals("\\a", uri.toFilePath({windows: true}));
    uri = core.Uri.parse("file:a/");
    expect$.Expect.equals("/a/", uri.toFilePath({windows: false}));
    expect$.Expect.equals("\\a\\", uri.toFilePath({windows: true}));
  };
  dart.fn(uri_file_test.testFileUri, VoidTodynamic());
  uri_file_test.testFileUriWindowsSlash = function() {
    let tests = JSArrayOfListOfString().of([JSArrayOfString().of(["", "", ""]), JSArrayOfString().of(["relative", "relative", "relative"]), JSArrayOfString().of(["relative/", "relative/", "relative\\"]), JSArrayOfString().of(["a%20b", "a b", "a b"]), JSArrayOfString().of(["a%20b/", "a b/", "a b\\"]), JSArrayOfString().of(["a/b", "a/b", "a\\b"]), JSArrayOfString().of(["a/b/", "a/b/", "a\\b\\"]), JSArrayOfString().of(["a%20b/c%20d", "a b/c d", "a b\\c d"]), JSArrayOfString().of(["a%20b/c%20d/", "a b/c d/", "a b\\c d\\"]), JSArrayOfString().of(["file:///absolute", "/absolute", "\\absolute"]), JSArrayOfString().of(["file:///absolute", "/absolute", "\\absolute"]), JSArrayOfString().of(["file:///a/b", "/a/b", "\\a\\b"]), JSArrayOfString().of(["file:///a/b", "/a/b", "\\a\\b"]), JSArrayOfString().of(["file://server/a/b", "//server/a/b", "\\\\server\\a\\b"]), JSArrayOfString().of(["file://server/a/b/", "//server/a/b/", "\\\\server\\a\\b\\"]), JSArrayOfString().of(["file:///C:/", "C:/", "C:\\"]), JSArrayOfString().of(["file:///C:/a/b", "C:/a/b", "C:\\a\\b"]), JSArrayOfString().of(["file:///C:/a/b/", "C:/a/b/", "C:\\a\\b\\"])]);
    for (let test of tests) {
      let uri = core.Uri.file(test[dartx.get](1), {windows: true});
      expect$.Expect.equals(test[dartx.get](0), uri.toString());
      expect$.Expect.equals(test[dartx.get](2), uri.toFilePath({windows: true}));
      let couldBeDir = dart.test(uri.path[dartx.isEmpty]) || dart.test(uri.path[dartx.endsWith]('\\'));
      let dirUri = core.Uri.directory(test[dartx.get](1), {windows: true});
      expect$.Expect.isTrue(dart.test(dirUri.path[dartx.isEmpty]) || dart.test(dirUri.path[dartx.endsWith]('/')));
      if (couldBeDir) {
        expect$.Expect.equals(uri, dirUri);
      }
    }
  };
  dart.fn(uri_file_test.testFileUriWindowsSlash, VoidTodynamic());
  uri_file_test.testFileUriWindowsWin32Namespace = function() {
    let tests = JSArrayOfListOfString().of([JSArrayOfString().of(["\\\\?\\C:\\", "file:///C:/", "C:\\"]), JSArrayOfString().of(["\\\\?\\C:\\", "file:///C:/", "C:\\"]), JSArrayOfString().of(["\\\\?\\UNC\\server\\share\\file", "file://server/share/file", "\\\\server\\share\\file"])]);
    for (let test of tests) {
      let uri = core.Uri.file(test[dartx.get](0), {windows: true});
      expect$.Expect.equals(test[dartx.get](1), uri.toString());
      expect$.Expect.equals(test[dartx.get](2), uri.toFilePath({windows: true}));
    }
    expect$.Expect.throws(dart.fn(() => core.Uri.file("\\\\?\\file", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.file("\\\\?\\UNX\\server\\share\\file", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.directory("\\\\?\\file", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.directory("\\\\?\\UNX\\server\\share\\file", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
  };
  dart.fn(uri_file_test.testFileUriWindowsWin32Namespace, VoidTodynamic());
  uri_file_test.testFileUriDriveLetter = function() {
    function check(s, nonWindows, windows) {
      let uri = null;
      uri = core.Uri.parse(s);
      expect$.Expect.equals(nonWindows, uri.toFilePath({windows: false}));
      if (windows != null) {
        expect$.Expect.equals(windows, uri.toFilePath({windows: true}));
      } else {
        expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      }
    }
    dart.fn(check, StringAndStringAndStringTodynamic());
    check("file:///C:", "/C:", "C:\\");
    check("file:///C:/", "/C:/", "C:\\");
    check("file:///C:a", "/C:a", null);
    check("file:///C:a/", "/C:a/", null);
    expect$.Expect.throws(dart.fn(() => core.Uri.file("C:", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.file("C:a", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.file("C:a\b", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.directory("C:", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.directory("C:a", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.directory("C:a\b", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
  };
  dart.fn(uri_file_test.testFileUriDriveLetter, VoidTodynamic());
  uri_file_test.testFileUriResolve = function() {
    let tests = JSArrayOfListOfString().of([JSArrayOfString().of(["file:///a", "/a", "", "\\a", ""]), JSArrayOfString().of(["file:///a/", "/a/", "", "\\a\\", ""]), JSArrayOfString().of(["file:///b", "/a", "b", "\\a", "b"]), JSArrayOfString().of(["file:///b/", "/a", "b/", "\\a", "b\\"]), JSArrayOfString().of(["file:///a/b", "/a/", "b", "\\a\\", "b"]), JSArrayOfString().of(["file:///a/b/", "/a/", "b/", "\\a\\", "b\\"]), JSArrayOfString().of(["file:///a/c/d", "/a/b", "c/d", "\\a\\b", "c\\d"]), JSArrayOfString().of(["file:///a/c/d/", "/a/b", "c/d/", "\\a\\b", "c\\d\\"]), JSArrayOfString().of(["file:///a/b/c/d", "/a/b/", "c/d", "\\a\\b\\", "c\\d"]), JSArrayOfString().of(["file:///a/b/c/d/", "/a/b/", "c/d/", "\\a\\b\\", "c\\d\\"])]);
    function check(s, absolute, relative, windows) {
      let absoluteUri = core.Uri.file(absolute, {windows: windows});
      let relativeUri = core.Uri.file(relative, {windows: windows});
      let relativeString = dart.test(windows) ? relative[dartx.replaceAll]("\\", "/") : relative;
      expect$.Expect.equals(s, dart.toString(absoluteUri.resolve(relativeString)));
      expect$.Expect.equals(s, dart.toString(absoluteUri.resolveUri(relativeUri)));
    }
    dart.fn(check, StringAndStringAndString__Todynamic());
    for (let test of tests) {
      check(test[dartx.get](0), test[dartx.get](1), test[dartx.get](2), false);
      check(test[dartx.get](0), test[dartx.get](1), test[dartx.get](2), true);
      check(test[dartx.get](0), test[dartx.get](1), test[dartx.get](4), true);
      check(test[dartx.get](0), test[dartx.get](3), test[dartx.get](2), true);
      check(test[dartx.get](0), test[dartx.get](3), test[dartx.get](4), true);
    }
  };
  dart.fn(uri_file_test.testFileUriResolve, VoidTodynamic());
  uri_file_test.testFileUriIllegalCharacters = function() {
    let uri = core.Uri.parse("file:///a%2Fb");
    expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: false}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    let illegalWindowsPaths = JSArrayOfString().of(["a<b", "a>b", "a:b", "a\"b", "a|b", "a?b", "a*b", "\\\\?\\c:\\a/b"]);
    for (let test of illegalWindowsPaths) {
      expect$.Expect.throws(dart.fn(() => core.Uri.file(test, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => core.Uri.file(dart.str`\\${test}`, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => core.Uri.directory(test, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => core.Uri.directory(dart.str`\\${test}`, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      let uri = core.Uri.file(test, {windows: false});
      let absoluteUri = core.Uri.file(dart.str`/${test}`, {windows: false});
      let dirUri = core.Uri.directory(test, {windows: false});
      let dirAbsoluteUri = core.Uri.directory(dart.str`/${test}`, {windows: false});
      expect$.Expect.throws(dart.fn(() => core.Uri.file(test, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => core.Uri.file(dart.str`\\${test}`, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => core.Uri.directory(test, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => core.Uri.directory(dart.str`\\${test}`, {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
      expect$.Expect.equals(test, uri.toFilePath({windows: false}));
      expect$.Expect.equals(dart.str`/${test}`, absoluteUri.toFilePath({windows: false}));
      expect$.Expect.equals(dart.str`${test}/`, dirUri.toFilePath({windows: false}));
      expect$.Expect.equals(dart.str`/${test}/`, dirAbsoluteUri.toFilePath({windows: false}));
      expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => absoluteUri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dirUri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dirAbsoluteUri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    }
    illegalWindowsPaths = JSArrayOfString().of(["a\\b", "a\\b\\"]);
    for (let test of illegalWindowsPaths) {
      let uri = core.Uri.file(test, {windows: false});
      let absoluteUri = core.Uri.file(dart.str`/${test}`, {windows: false});
      let dirUri = core.Uri.directory(test, {windows: false});
      let dirAbsoluteUri = core.Uri.directory(dart.str`/${test}`, {windows: false});
      core.Uri.file(test, {windows: true});
      core.Uri.file(dart.str`\\${test}`, {windows: true});
      expect$.Expect.equals(test, uri.toFilePath({windows: false}));
      expect$.Expect.equals(dart.str`/${test}`, absoluteUri.toFilePath({windows: false}));
      expect$.Expect.equals(dart.str`${test}/`, dirUri.toFilePath({windows: false}));
      expect$.Expect.equals(dart.str`/${test}/`, dirAbsoluteUri.toFilePath({windows: false}));
      expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => absoluteUri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dirUri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dirAbsoluteUri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    }
  };
  dart.fn(uri_file_test.testFileUriIllegalCharacters, VoidTodynamic());
  uri_file_test.testFileUriIllegalDriveLetter = function() {
    expect$.Expect.throws(dart.fn(() => core.Uri.file("1:\\", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.Uri.directory("1:\\", {windows: true}), VoidToUri()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    let uri = core.Uri.file("1:\\", {windows: false});
    let dirUri = core.Uri.directory("1:\\", {windows: false});
    expect$.Expect.equals("1:\\", uri.toFilePath({windows: false}));
    expect$.Expect.equals("1:\\/", dirUri.toFilePath({windows: false}));
    expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dirUri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(uri_file_test.testFileUriIllegalDriveLetter, VoidTodynamic());
  uri_file_test.testAdditionalComponents = function() {
    function check(s, opts) {
      let windowsOk = opts && 'windowsOk' in opts ? opts.windowsOk : false;
      let uri = core.Uri.parse(s);
      expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: false}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      if (dart.test(windowsOk)) {
        expect$.Expect.isTrue(typeof uri.toFilePath({windows: true}) == 'string');
      } else {
        expect$.Expect.throws(dart.fn(() => uri.toFilePath({windows: true}), VoidToString()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      }
    }
    dart.fn(check, String__Todynamic());
    check("file:///path?query");
    check("file:///path#fragment");
    check("file:///path?query#fragment");
    check("file://host/path", {windowsOk: true});
    check("file://user:password@host/path", {windowsOk: true});
  };
  dart.fn(uri_file_test.testAdditionalComponents, VoidTodynamic());
  uri_file_test.main = function() {
    uri_file_test.testFileUri();
    uri_file_test.testFileUriWindowsSlash();
    uri_file_test.testFileUriDriveLetter();
    uri_file_test.testFileUriWindowsWin32Namespace();
    uri_file_test.testFileUriResolve();
    uri_file_test.testFileUriIllegalCharacters();
    uri_file_test.testFileUriIllegalDriveLetter();
    uri_file_test.testAdditionalComponents();
  };
  dart.fn(uri_file_test.main, VoidTodynamic());
  // Exports:
  exports.uri_file_test = uri_file_test;
});
