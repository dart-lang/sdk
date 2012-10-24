// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for RegExp.allMatches.

class RegExpAllMatchesTest {
  static testIterator() {
    var matches = new RegExp("foo").allMatches("foo foo");
    Iterator it = matches.iterator();
    Expect.equals(true, it.hasNext);
    Expect.equals('foo', it.next().group(0));
    Expect.equals(true, it.hasNext);
    Expect.equals('foo', it.next().group(0));
    Expect.equals(false, it.hasNext);

    // Run two iterators over the same results.
    it = matches.iterator();
    Iterator it2 = matches.iterator();
    Expect.equals(true, it.hasNext);
    Expect.equals(true, it2.hasNext);
    Expect.equals('foo', it.next().group(0));
    Expect.equals('foo', it2.next().group(0));
    Expect.equals(true, it.hasNext);
    Expect.equals(true, it2.hasNext);
    Expect.equals('foo', it.next().group(0));
    Expect.equals('foo', it2.next().group(0));
    Expect.equals(false, it.hasNext);
    Expect.equals(false, it2.hasNext);
  }

  static testForEach() {
    var matches = new RegExp("foo").allMatches("foo foo");
    var strbuf = new StringBuffer();
    matches.forEach((Match m) {
      strbuf.add(m.group(0));
    });
    Expect.equals("foofoo", strbuf.toString());
  }

  static testMap() {
    var matches = new RegExp("foo?").allMatches("foo fo foo fo");
    var mapped = matches.map((Match m) => "${m.group(0)}bar");
    Expect.equals(4, mapped.length);
    var strbuf = new StringBuffer();
    for (String s in mapped) {
      strbuf.add(s);
    }
    Expect.equals("foobarfobarfoobarfobar", strbuf.toString());
  }

  static testFilter() {
    var matches = new RegExp("foo?").allMatches("foo fo foo fo");
    var filtered = matches.filter((Match m) {
      return m.group(0) == 'foo';
    });
    Expect.equals(2, filtered.length);
    var strbuf = new StringBuffer();
    for (Match m in filtered) {
      strbuf.add(m.group(0));
    }
    Expect.equals("foofoo", strbuf.toString());
  }

  static testEvery() {
    var matches = new RegExp("foo?").allMatches("foo fo foo fo");
    Expect.equals(true, matches.every((Match m) {
      return m.group(0).startsWith("fo");
    }));
    Expect.equals(false, matches.every((Match m) {
      return m.group(0).startsWith("foo");
    }));
  }

  static testSome() {
    var matches = new RegExp("foo?").allMatches("foo fo foo fo");
    Expect.equals(true, matches.some((Match m) {
      return m.group(0).startsWith("fo");
    }));
    Expect.equals(true, matches.some((Match m) {
      return m.group(0).startsWith("foo");
    }));
    Expect.equals(false, matches.some((Match m) {
      return m.group(0).startsWith("fooo");
    }));
  }

  static testIsEmpty() {
    var matches = new RegExp("foo?").allMatches("foo fo foo fo");
    Expect.equals(false, matches.isEmpty());
    matches = new RegExp("fooo").allMatches("foo fo foo fo");
    Expect.equals(true, matches.isEmpty());
  }

  static testGetCount() {
    var matches = new RegExp("foo?").allMatches("foo fo foo fo");
    Expect.equals(4, matches.length);
    matches = new RegExp("fooo").allMatches("foo fo foo fo");
    Expect.equals(0, matches.length);
  }

  static testMain() {
    testIterator();
    testForEach();
    testMap();
    testFilter();
    testEvery();
    testSome();
    testIsEmpty();
    testGetCount();
  }
}

main() {
  RegExpAllMatchesTest.testMain();
}
