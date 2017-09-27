// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

testNormalizePath() {
  test(String expected, String path, {String scheme, String host}) {
    var uri = new Uri(scheme: scheme, host: host, path: path);
    Expect.equals(expected, uri.toString());
    if (scheme == null && host == null) {
      Expect.equals(expected, uri.path);
    }
  }

  var unreserved = "-._~0123456789"
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      "abcdefghijklmnopqrstuvwxyz";

  test("A", "%41");
  test("AB", "%41%42");
  test("%40AB", "%40%41%42");
  test("a", "%61");
  test("ab", "%61%62");
  test("%60ab", "%60%61%62");
  test(unreserved, unreserved);

  var x = new StringBuffer();
  for (int i = 32; i < 128; i++) {
    if (unreserved.indexOf(new String.fromCharCode(i)) != -1) {
      x.writeCharCode(i);
    } else {
      x.write("%");
      x.write(i.toRadixString(16));
    }
  }
  Expect.equals(x.toString().toUpperCase(),
      new Uri(path: x.toString()).toString().toUpperCase());

  // Normalized paths.

  // Full absolute path normalization for absolute paths.
  test("/a/b/c/", "/../a/./b/z/../c/d/..");
  test("/a/b/c/", "/./a/b/c/");
  test("/a/b/c/", "/./../a/b/c/");
  test("/a/b/c/", "/./../a/b/c/.");
  test("/a/b/c/", "/./../a/b/c/z/./..");
  test("/", "/a/..");
  // Full absolute path normalization for URIs with scheme.
  test("s:a/b/c/", "../a/./b/z/../c/d/..", scheme: "s");
  test("s:a/b/c/", "./a/b/c/", scheme: "s");
  test("s:a/b/c/", "./../a/b/c/", scheme: "s");
  test("s:a/b/c/", "./../a/b/c/.", scheme: "s");
  test("s:a/b/c/", "./../a/b/c/z/./..", scheme: "s");
  test("s:/", "/a/..", scheme: "s");
  test("s:/", "a/..", scheme: "s");
  // Full absolute path normalization for URIs with authority.
  test("//h/a/b/c/", "../a/./b/z/../c/d/..", host: "h");
  test("//h/a/b/c/", "./a/b/c/", host: "h");
  test("//h/a/b/c/", "./../a/b/c/", host: "h");
  test("//h/a/b/c/", "./../a/b/c/.", host: "h");
  test("//h/a/b/c/", "./../a/b/c/z/./..", host: "h");
  test("//h/", "/a/..", host: "h");
  test("//h/", "a/..", host: "h");
  // Partial relative normalization (allowing leading .. or ./ for current dir).
  test("../a/b/c/", "../a/./b/z/../c/d/..");
  test("a/b/c/", "./a/b/c/");
  test("../a/b/c/", "./../a/b/c/");
  test("../a/b/c/", "./../a/b/c/.");
  test("../a/b/c/", "./../a/b/c/z/./..");
  test("/", "/a/..");
  test("./", "a/..");
}

main() {
  testNormalizePath();
}
