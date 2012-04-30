// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('uriTest');

#import('../../lib/uri/uri.dart');

testUri(String uri, bool isAbsolute) {
  Expect.equals(isAbsolute, new Uri.fromString(uri).isAbsolute());
  Expect.stringEquals(uri, new Uri.fromString(uri).toString());
}

main() {
  testUri("http:", true);
  testUri("file://", true);
  testUri("file", false);
  testUri("http://user@example.com:80/fisk?query=89&hest=silas", true);
  testUri("http://user@example.com:80/fisk?query=89&hest=silas#fragment",
          false);
  Expect.stringEquals("http://user@example.com:80/a/b/c?query#fragment",
                      const Uri("http", "user", "example.com", 80, "/a/b/c",
                                "query", "fragment").toString());
  Expect.stringEquals("null://null@null/a/b/c/?null#null",
                      const Uri(null, null, null, 0, "/a/b/c/",
                                null, null).toString());
  Expect.stringEquals("file://", new Uri.fromString("file:").toString());
  Expect.stringEquals("/a/g", removeDotSegments("/a/b/c/./../../g"));
  Expect.stringEquals("mid/6", removeDotSegments("mid/content=5/../6"));
  Expect.stringEquals("a/b/e", removeDotSegments("a/b/c/d/../../e"));
  Expect.stringEquals("a/b/e", removeDotSegments("../a/b/c/d/../../e"));
  Expect.stringEquals("a/b/e", removeDotSegments("./a/b/c/d/../../e"));
  Expect.stringEquals("a/b/e", removeDotSegments("../a/b/./c/d/../../e"));
  Expect.stringEquals("a/b/e", removeDotSegments("./a/b/./c/d/../../e"));
  Expect.stringEquals("a/b/e/", removeDotSegments("./a/b/./c/d/../../e/."));
  Expect.stringEquals("a/b/e/", removeDotSegments("./a/b/./c/d/../../e/./."));
  Expect.stringEquals("a/b/e/", removeDotSegments("./a/b/./c/d/../../e/././."));

  // From RFC 3986.
  Uri base = new Uri.fromString("http://a/b/c/d;p?q");
  Expect.stringEquals("g:h", base.resolve("g:h").toString());
  Expect.stringEquals("http://a/b/c/g", base.resolve("g").toString());
  Expect.stringEquals("http://a/b/c/g", base.resolve("./g").toString());
  Expect.stringEquals("http://a/b/c/g/", base.resolve("g/").toString());
  Expect.stringEquals("http://a/g", base.resolve("/g").toString());
  Expect.stringEquals("http://g", base.resolve("//g").toString());
  Expect.stringEquals("http://a/b/c/d;p?y", base.resolve("?y").toString());
  Expect.stringEquals("http://a/b/c/g?y", base.resolve("g?y").toString());
  Expect.stringEquals("http://a/b/c/d;p?q#s", base.resolve("#s").toString());
  Expect.stringEquals("http://a/b/c/g#s", base.resolve("g#s").toString());
  Expect.stringEquals("http://a/b/c/g?y#s", base.resolve("g?y#s").toString());
  Expect.stringEquals("http://a/b/c/;x", base.resolve(";x").toString());
  Expect.stringEquals("http://a/b/c/g;x", base.resolve("g;x").toString());
  Expect.stringEquals("http://a/b/c/g;x?y#s",
                      base.resolve("g;x?y#s").toString());
  Expect.stringEquals("http://a/b/c/d;p?q", base.resolve("").toString());
  Expect.stringEquals("http://a/b/c/", base.resolve(".").toString());
  Expect.stringEquals("http://a/b/c/", base.resolve("./").toString());
  Expect.stringEquals("http://a/b/", base.resolve("..").toString());
  Expect.stringEquals("http://a/b/", base.resolve("../").toString());
  Expect.stringEquals("http://a/b/g", base.resolve("../g").toString());
  Expect.stringEquals("http://a/", base.resolve("../..").toString());
  Expect.stringEquals("http://a/", base.resolve("../../").toString());
  Expect.stringEquals("http://a/g", base.resolve("../../g").toString());
  Expect.stringEquals("http://a/g", base.resolve("../../../g").toString());
  Expect.stringEquals("http://a/g", base.resolve("../../../../g").toString());
  Expect.stringEquals("http://a/g", base.resolve("/./g").toString());
  Expect.stringEquals("http://a/g", base.resolve("/../g").toString());
  Expect.stringEquals("http://a/b/c/g.", base.resolve("g.").toString());
  Expect.stringEquals("http://a/b/c/.g", base.resolve(".g").toString());
  Expect.stringEquals("http://a/b/c/g..", base.resolve("g..").toString());
  Expect.stringEquals("http://a/b/c/..g", base.resolve("..g").toString());
  Expect.stringEquals("http://a/b/g", base.resolve("./../g").toString());
  Expect.stringEquals("http://a/b/c/g/", base.resolve("./g/.").toString());
  Expect.stringEquals("http://a/b/c/g/h", base.resolve("g/./h").toString());
  Expect.stringEquals("http://a/b/c/h", base.resolve("g/../h").toString());
  Expect.stringEquals("http://a/b/c/g;x=1/y",
                      base.resolve("g;x=1/./y").toString());
  Expect.stringEquals("http://a/b/c/y", base.resolve("g;x=1/../y").toString());
  Expect.stringEquals("http://a/b/c/g?y/./x",
                      base.resolve("g?y/./x").toString());
  Expect.stringEquals("http://a/b/c/g?y/../x",
                      base.resolve("g?y/../x").toString());
  Expect.stringEquals("http://a/b/c/g#s/./x",
                      base.resolve("g#s/./x").toString());
  Expect.stringEquals("http://a/b/c/g#s/../x",
                      base.resolve("g#s/../x").toString());
  Expect.stringEquals("http:g", base.resolve("http:g").toString());

  // Additional tests (not from RFC 3986).
  Expect.stringEquals("http://a/b/g;p/h;s",
                      base.resolve("../g;p/h;s").toString());
}
