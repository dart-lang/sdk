// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:glob/glob.dart';
import 'package:unittest/unittest.dart';

void main() {
  test("supports backslash-escaped characters", () {
    expect(r"\*[]{,}?()", contains(new Glob(r"\\\*\[\]\{\,\}\?\(\)")));
  });

  test("disallows an empty glob", () {
    expect(() => new Glob(""), throwsFormatException);
  });

  group("range", () {
    test("supports either ^ or ! for negated ranges", () {
      var bang = new Glob("fo[!a-z]");
      expect("foo", isNot(contains(bang)));
      expect("fo2", contains(bang));

      var caret = new Glob("fo[^a-z]");
      expect("foo", isNot(contains(bang)));
      expect("fo2", contains(bang));
    });

    test("supports backslash-escaped characters", () {
      var glob = new Glob(r"fo[\*\--\]]");
      expect("fo]", contains(glob));
      expect("fo-", contains(glob));
      expect("fo*", contains(glob));
    });

    test("disallows inverted ranges", () {
      expect(() => new Glob(r"[z-a]"), throwsFormatException);
    });

    test("disallows empty ranges", () {
      expect(() => new Glob(r"[]"), throwsFormatException);
    });

    test("disallows unclosed ranges", () {
      expect(() => new Glob(r"[abc"), throwsFormatException);
      expect(() => new Glob(r"[-"), throwsFormatException);
    });

    test("disallows dangling ]", () {
      expect(() => new Glob(r"abc]"), throwsFormatException);
    });

    test("disallows explicit /", () {
      expect(() => new Glob(r"[/]"), throwsFormatException);
      expect(() => new Glob(r"[ -/]"), throwsFormatException);
      expect(() => new Glob(r"[/-~]"), throwsFormatException);
    });
  });

  group("options", () {
    test("allows empty branches", () {
      var glob = new Glob("foo{,bar}");
      expect("foo", contains(glob));
      expect("foobar", contains(glob));
    });

    test("disallows empty options", () {
      expect(() => new Glob("{}"), throwsFormatException);
    });

    test("disallows single options", () {
      expect(() => new Glob("{foo}"), throwsFormatException);
    });

    test("disallows unclosed options", () {
      expect(() => new Glob("{foo,bar"), throwsFormatException);
      expect(() => new Glob("{foo,"), throwsFormatException);
    });

    test("disallows dangling }", () {
      expect(() => new Glob("foo}"), throwsFormatException);
    });

    test("disallows dangling ] in options", () {
      expect(() => new Glob(r"{abc]}"), throwsFormatException);
    });
  });

  test("disallows unescaped parens", () {
    expect(() => new Glob("foo(bar"), throwsFormatException);
    expect(() => new Glob("foo)bar"), throwsFormatException);
  });
}
