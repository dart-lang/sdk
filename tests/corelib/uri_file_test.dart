// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

testFileUri() {
  final unsupported = new UnsupportedError("");

  var tests = [
    ["", "", ""],
    ["relative", "relative", "relative"],
    ["relative/", "relative/", "relative\\"],
    ["a%20b", "a b", "a b"],
    ["a%20b/", "a b/", "a b\\"],
    ["a/b", "a/b", "a\\b"],
    ["a/b/", "a/b/", "a\\b\\"],
    ["a%20b/c%20d", "a b/c d", "a b\\c d"],
    ["a%20b/c%20d/", "a b/c d/", "a b\\c d\\"],
    ["file:///absolute", "/absolute", "\\absolute"],
    ["file:///absolute", "/absolute", "\\absolute"],
    ["file:///a/b", "/a/b", "\\a\\b"],
    ["file:///a/b", "/a/b", "\\a\\b"],
    ["file://server/a/b", unsupported, "\\\\server\\a\\b"],
    ["file://server/a/b/", unsupported, "\\\\server\\a\\b\\"],
    ["file:///C:/", "/C:/", "C:\\"],
    ["file:///C:/a/b", "/C:/a/b", "C:\\a\\b"],
    ["file:///C:/a/b/", "/C:/a/b/", "C:\\a\\b\\"],
    ["http:/a/b", unsupported, unsupported],
    ["https:/a/b", unsupported, unsupported],
    ["urn:a:b", unsupported, unsupported],
  ];

  void check(String s, filePath, bool windows) {
    Uri uri = Uri.parse(s);
    if (filePath is Error) {
      if (filePath is UnsupportedError) {
        Expect.throws(() => uri.toFilePath(windows: windows),
            (e) => e is UnsupportedError);
      } else {
        Expect.throws(() => uri.toFilePath(windows: windows));
      }
    } else {
      Expect.equals(filePath, uri.toFilePath(windows: windows));
      Expect.equals(s, new Uri.file(filePath, windows: windows).toString());
    }
  }

  for (var test in tests) {
    check(test[0], test[1], false);
    check(test[0], test[2], true);
  }

  Uri uri;
  uri = Uri.parse("file:a");
  Expect.equals("/a", uri.toFilePath(windows: false));
  Expect.equals("\\a", uri.toFilePath(windows: true));
  uri = Uri.parse("file:a/");
  Expect.equals("/a/", uri.toFilePath(windows: false));
  Expect.equals("\\a\\", uri.toFilePath(windows: true));
}

testFileUriWindowsSlash() {
  var tests = [
    ["", "", ""],
    ["relative", "relative", "relative"],
    ["relative/", "relative/", "relative\\"],
    ["a%20b", "a b", "a b"],
    ["a%20b/", "a b/", "a b\\"],
    ["a/b", "a/b", "a\\b"],
    ["a/b/", "a/b/", "a\\b\\"],
    ["a%20b/c%20d", "a b/c d", "a b\\c d"],
    ["a%20b/c%20d/", "a b/c d/", "a b\\c d\\"],
    ["file:///absolute", "/absolute", "\\absolute"],
    ["file:///absolute", "/absolute", "\\absolute"],
    ["file:///a/b", "/a/b", "\\a\\b"],
    ["file:///a/b", "/a/b", "\\a\\b"],
    ["file://server/a/b", "//server/a/b", "\\\\server\\a\\b"],
    ["file://server/a/b/", "//server/a/b/", "\\\\server\\a\\b\\"],
    ["file:///C:/", "C:/", "C:\\"],
    ["file:///C:/a/b", "C:/a/b", "C:\\a\\b"],
    ["file:///C:/a/b/", "C:/a/b/", "C:\\a\\b\\"],
    ["file:///C:/xxx/yyy", "C:\\xxx\\yyy", "C:\\xxx\\yyy"],
  ];

  for (var test in tests) {
    Uri uri = new Uri.file(test[1], windows: true);
    Expect.equals(test[0], uri.toString());
    Expect.equals(test[2], uri.toFilePath(windows: true));
    bool couldBeDir = uri.path.isEmpty || uri.path.endsWith('\\');
    Uri dirUri = new Uri.directory(test[1], windows: true);
    Expect.isTrue(dirUri.path.isEmpty || dirUri.path.endsWith('/'));
    if (couldBeDir) {
      Expect.equals(uri, dirUri);
    }
  }
}

testFileUriWindowsWin32Namespace() {
  var tests = [
    ["\\\\?\\C:\\", "file:///C:/", "C:\\"],
    ["\\\\?\\C:\\", "file:///C:/", "C:\\"],
    [
      "\\\\?\\UNC\\server\\share\\file",
      "file://server/share/file",
      "\\\\server\\share\\file"
    ],
  ];

  for (var test in tests) {
    Uri uri = new Uri.file(test[0], windows: true);
    Expect.equals(test[1], uri.toString());
    Expect.equals(test[2], uri.toFilePath(windows: true));
  }

  Expect.throws(() => new Uri.file("\\\\?\\file", windows: true),
      (e) => e is ArgumentError);
  Expect.throws(
      () => new Uri.file("\\\\?\\UNX\\server\\share\\file", windows: true),
      (e) => e is ArgumentError);
  Expect.throws(() => new Uri.directory("\\\\?\\file", windows: true),
      (e) => e is ArgumentError);
  Expect.throws(
      () => new Uri.directory("\\\\?\\UNX\\server\\share\\file", windows: true),
      (e) => e is ArgumentError);
}

testFileUriDriveLetter() {
  check(String s, String nonWindows, String windows) {
    Uri uri;
    uri = Uri.parse(s);
    Expect.equals(nonWindows, uri.toFilePath(windows: false));
    if (windows != null) {
      Expect.equals(windows, uri.toFilePath(windows: true));
    } else {
      Expect.throws(
          () => uri.toFilePath(windows: true), (e) => e is UnsupportedError);
    }
  }

  check("file:///C:", "/C:", "C:\\");
  check("file:///C:/", "/C:/", "C:\\");
  check("file:///C:a", "/C:a", null);
  check("file:///C:a/", "/C:a/", null);

  Expect.throws(
      () => new Uri.file("C:", windows: true), (e) => e is ArgumentError);
  Expect.throws(
      () => new Uri.file("C:a", windows: true), (e) => e is ArgumentError);
  Expect.throws(
      () => new Uri.file("C:a\b", windows: true), (e) => e is ArgumentError);
  Expect.throws(
      () => new Uri.directory("C:", windows: true), (e) => e is ArgumentError);
  Expect.throws(
      () => new Uri.directory("C:a", windows: true), (e) => e is ArgumentError);
  Expect.throws(() => new Uri.directory("C:a\b", windows: true),
      (e) => e is ArgumentError);
}

testFileUriResolve() {
  var tests = [
    ["file:///a", "/a", "", "\\a", ""],
    ["file:///a/", "/a/", "", "\\a\\", ""],
    ["file:///b", "/a", "b", "\\a", "b"],
    ["file:///b/", "/a", "b/", "\\a", "b\\"],
    ["file:///a/b", "/a/", "b", "\\a\\", "b"],
    ["file:///a/b/", "/a/", "b/", "\\a\\", "b\\"],
    ["file:///a/c/d", "/a/b", "c/d", "\\a\\b", "c\\d"],
    ["file:///a/c/d/", "/a/b", "c/d/", "\\a\\b", "c\\d\\"],
    ["file:///a/b/c/d", "/a/b/", "c/d", "\\a\\b\\", "c\\d"],
    ["file:///a/b/c/d/", "/a/b/", "c/d/", "\\a\\b\\", "c\\d\\"],
  ];

  check(String s, String absolute, String relative, bool windows) {
    Uri absoluteUri = new Uri.file(absolute, windows: windows);
    Uri relativeUri = new Uri.file(relative, windows: windows);
    String relativeString = windows ? relative.replaceAll("\\", "/") : relative;
    Expect.equals(s, absoluteUri.resolve(relativeString).toString());
    Expect.equals(s, absoluteUri.resolveUri(relativeUri).toString());
  }

  for (var test in tests) {
    check(test[0], test[1], test[2], false);
    check(test[0], test[1], test[2], true);
    check(test[0], test[1], test[4], true);
    check(test[0], test[3], test[2], true);
    check(test[0], test[3], test[4], true);
  }
}

testFileUriIllegalCharacters() {
  // Slash is an invalid character in file names on both non-Windows
  // and Windows.
  Uri uri = Uri.parse("file:///a%2Fb");
  Expect.throws(
      () => uri.toFilePath(windows: false), (e) => e is UnsupportedError);
  Expect.throws(
      () => uri.toFilePath(windows: true), (e) => e is UnsupportedError);

  // Illegal characters in windows file names.
  var illegalWindowsPaths = [
    "a<b",
    "a>b",
    "a:b",
    "a\"b",
    "a|b",
    "a?b",
    "a*b",
    "\\\\?\\c:\\a/b"
  ];

  for (var test in illegalWindowsPaths) {
    Expect.throws(
        () => new Uri.file(test, windows: true), (e) => e is ArgumentError);
    Expect.throws(() => new Uri.file("\\$test", windows: true),
        (e) => e is ArgumentError);
    Expect.throws(() => new Uri.directory(test, windows: true),
        (e) => e is ArgumentError);
    Expect.throws(() => new Uri.directory("\\$test", windows: true),
        (e) => e is ArgumentError);

    // It is possible to create non-Windows URIs, but not Windows URIs.
    Uri uri = new Uri.file(test, windows: false);
    Uri absoluteUri = new Uri.file("/$test", windows: false);
    Uri dirUri = new Uri.directory(test, windows: false);
    Uri dirAbsoluteUri = new Uri.directory("/$test", windows: false);
    Expect.throws(
        () => new Uri.file(test, windows: true), (e) => e is ArgumentError);
    Expect.throws(() => new Uri.file("\\$test", windows: true),
        (e) => e is ArgumentError);
    Expect.throws(() => new Uri.directory(test, windows: true),
        (e) => e is ArgumentError);
    Expect.throws(() => new Uri.directory("\\$test", windows: true),
        (e) => e is ArgumentError);

    // It is possible to extract non-Windows file path, but not
    // Windows file path.
    Expect.equals(test, uri.toFilePath(windows: false));
    Expect.equals("/$test", absoluteUri.toFilePath(windows: false));
    Expect.equals("$test/", dirUri.toFilePath(windows: false));
    Expect.equals("/$test/", dirAbsoluteUri.toFilePath(windows: false));
    Expect.throws(
        () => uri.toFilePath(windows: true), (e) => e is UnsupportedError);
    Expect.throws(() => absoluteUri.toFilePath(windows: true),
        (e) => e is UnsupportedError);
    Expect.throws(
        () => dirUri.toFilePath(windows: true), (e) => e is UnsupportedError);
    Expect.throws(() => dirAbsoluteUri.toFilePath(windows: true),
        (e) => e is UnsupportedError);
  }

  // Backslash
  illegalWindowsPaths = ["a\\b", "a\\b\\"];
  for (var test in illegalWindowsPaths) {
    // It is possible to create both non-Windows URIs, and Windows URIs.
    Uri uri = new Uri.file(test, windows: false);
    Uri absoluteUri = new Uri.file("/$test", windows: false);
    Uri dirUri = new Uri.directory(test, windows: false);
    Uri dirAbsoluteUri = new Uri.directory("/$test", windows: false);
    new Uri.file(test, windows: true);
    new Uri.file("\\$test", windows: true);

    // It is possible to extract non-Windows file path, but not
    // Windows file path from the non-Windows URI (it has a backslash
    // in a path segment).
    Expect.equals(test, uri.toFilePath(windows: false));
    Expect.equals("/$test", absoluteUri.toFilePath(windows: false));
    Expect.equals("$test/", dirUri.toFilePath(windows: false));
    Expect.equals("/$test/", dirAbsoluteUri.toFilePath(windows: false));
    Expect.throws(
        () => uri.toFilePath(windows: true), (e) => e is UnsupportedError);
    Expect.throws(() => absoluteUri.toFilePath(windows: true),
        (e) => e is UnsupportedError);
    Expect.throws(
        () => dirUri.toFilePath(windows: true), (e) => e is UnsupportedError);
    Expect.throws(() => dirAbsoluteUri.toFilePath(windows: true),
        (e) => e is UnsupportedError);
  }
}

testFileUriIllegalDriveLetter() {
  Expect.throws(
      () => new Uri.file("1:\\", windows: true), (e) => e is ArgumentError);
  Expect.throws(() => new Uri.directory("1:\\", windows: true),
      (e) => e is ArgumentError);
  Uri uri = new Uri.file("1:\\", windows: false);
  Uri dirUri = new Uri.directory("1:\\", windows: false);
  Expect.equals("1:\\", uri.toFilePath(windows: false));
  Expect.equals("1:\\/", dirUri.toFilePath(windows: false));
  Expect.throws(
      () => uri.toFilePath(windows: true), (e) => e is UnsupportedError);
  Expect.throws(
      () => dirUri.toFilePath(windows: true), (e) => e is UnsupportedError);
}

testAdditionalComponents() {
  check(String s, {bool windowsOk: false}) {
    Uri uri = Uri.parse(s);
    Expect.throws(
        () => uri.toFilePath(windows: false), (e) => e is UnsupportedError);
    if (windowsOk) {
      Expect.isTrue(uri.toFilePath(windows: true) is String);
    } else {
      Expect.throws(
          () => uri.toFilePath(windows: true), (e) => e is UnsupportedError);
    }
  }

  check("file:///path?query");
  check("file:///path#fragment");
  check("file:///path?query#fragment");
  check("file://host/path", windowsOk: true);
  check("file://user:password@host/path", windowsOk: true);
}

main() {
  testFileUri();
  testFileUriWindowsSlash();
  testFileUriDriveLetter();
  testFileUriWindowsWin32Namespace();
  testFileUriResolve();
  testFileUriIllegalCharacters();
  testFileUriIllegalDriveLetter();
  testAdditionalComponents();
}
