// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uriNormalizePathTest;

import "package:expect/expect.dart";

test(String path, String normalizedPath) {
  for (var scheme in ["http", "file", "unknown"]) {
    for (var auth in [
      [null, "hostname", null],
      ["userinfo", "hostname", 1234],
      [null, null, null]
    ]) {
      for (var query in [null, "query"]) {
        for (var fragment in [null, "fragment"]) {
          var base = new Uri(
              scheme: scheme,
              userInfo: auth[0],
              host: auth[1],
              port: auth[2],
              path: path,
              query: query,
              fragment: fragment);
          var expected = base.replace(
              path: (base.hasAuthority && normalizedPath.isEmpty)
                  ? "/"
                  : normalizedPath);
          var actual = base.normalizePath();
          Expect.equals(expected, actual, "$base");
        }
      }
    }
  }
}

testNoChange(String path) {
  test(path, path);
}

main() {
  testNoChange("foo/bar/baz");
  testNoChange("/foo/bar/baz");
  testNoChange("foo/bar/baz/");
  test("foo/bar/..", "foo/");
  test("foo/bar/.", "foo/bar/");
  test("foo/./bar/../baz", "foo/baz");
  test("../../foo", "foo");
  test("./../foo", "foo");
  test("./../", "");
  test("./../.", "");
  test("foo/bar/baz/../../../../qux", "/qux");
  test("/foo/bar/baz/../../../../qux", "/qux");
  test(".", "");
  test("..", "");
  test("/.", "/");
  test("/..", "/");
}
