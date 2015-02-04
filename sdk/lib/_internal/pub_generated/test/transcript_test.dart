// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library version_test;

import 'package:unittest/unittest.dart';
import 'test_pub.dart';
import '../lib/src/transcript.dart';

main() {
  initConfig();

  test("discards from the middle once it reaches the maximum", () {
    var transcript = new Transcript<String>(4);
    forEachToString() {
      var result = "";
      transcript.forEach((entry) => result += entry, (n) => result += "[$n]");
      return result;
    }

    expect(forEachToString(), equals(""));
    transcript.add("a");
    expect(forEachToString(), equals("a"));
    transcript.add("b");
    expect(forEachToString(), equals("ab"));
    transcript.add("c");
    expect(forEachToString(), equals("abc"));
    transcript.add("d");
    expect(forEachToString(), equals("abcd"));
    transcript.add("e");
    expect(forEachToString(), equals("ab[1]de"));
    transcript.add("f");
    expect(forEachToString(), equals("ab[2]ef"));
  });

  test("does not discard if it doesn't reach the maximum", () {
    var transcript = new Transcript<String>(40);
    forEachToString() {
      var result = "";
      transcript.forEach((entry) => result += entry, (n) => result += "[$n]");
      return result;
    }

    expect(forEachToString(), equals(""));
    transcript.add("a");
    expect(forEachToString(), equals("a"));
    transcript.add("b");
    expect(forEachToString(), equals("ab"));
    transcript.add("c");
    expect(forEachToString(), equals("abc"));
    transcript.add("d");
    expect(forEachToString(), equals("abcd"));
    transcript.add("e");
    expect(forEachToString(), equals("abcde"));
    transcript.add("f");
    expect(forEachToString(), equals("abcdef"));
  });

}
