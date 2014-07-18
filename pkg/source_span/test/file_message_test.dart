// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:source_span/source_span.dart';
import 'package:source_span/src/colors.dart' as colors;

main() {
  var file;
  setUp(() {
    file = new SourceFile("""
foo bar baz
whiz bang boom
zip zap zop
""", url: "foo.dart");
  });

  test("points to the span in the source", () {
    expect(file.span(4, 7).message("oh no"), equals("""
line 1, column 5 of foo.dart: oh no
foo bar baz
    ^^^"""));
  });

  test("gracefully handles a missing source URL", () {
    var span = new SourceFile("foo bar baz").span(4, 7);
    expect(span.message("oh no"), equals("""
line 1, column 5: oh no
foo bar baz
    ^^^"""));
  });

  test("highlights the first line of a multiline span", () {
    expect(file.span(4, 20).message("oh no"), equals("""
line 1, column 5 of foo.dart: oh no
foo bar baz
    ^^^^^^^^"""));
  });

  test("works for a point span", () {
    expect(file.location(4).pointSpan().message("oh no"), equals("""
line 1, column 5 of foo.dart: oh no
foo bar baz
    ^"""));
  });

  test("works for a point span at the end of a line", () {
    expect(file.location(11).pointSpan().message("oh no"), equals("""
line 1, column 12 of foo.dart: oh no
foo bar baz
           ^"""));
  });

  test("works for a point span at the end of the file", () {
    expect(file.location(38).pointSpan().message("oh no"), equals("""
line 3, column 12 of foo.dart: oh no
zip zap zop
           ^"""));
  });

  test("works for a point span in an empty file", () {
    expect(new SourceFile("").location(0).pointSpan().message("oh no"),
        equals("""
line 1, column 1: oh no

^"""));
  });

  test("works for a single-line file without a newline", () {
    expect(new SourceFile("foo bar").span(0, 7).message("oh no"),
        equals("""
line 1, column 1: oh no
foo bar
^^^^^^^"""));
  });

  group("colors", () {
    test("doesn't colorize if color is false", () {
      expect(file.span(4, 7).message("oh no", color: false), equals("""
line 1, column 5 of foo.dart: oh no
foo bar baz
    ^^^"""));
    });

    test("colorizes if color is true", () {
      expect(file.span(4, 7).message("oh no", color: true), equals("""
line 1, column 5 of foo.dart: oh no
foo ${colors.RED}bar${colors.NONE} baz
    ${colors.RED}^^^${colors.NONE}"""));
    });

    test("uses the given color if it's passed", () {
      expect(file.span(4, 7).message("oh no", color: colors.YELLOW), equals("""
line 1, column 5 of foo.dart: oh no
foo ${colors.YELLOW}bar${colors.NONE} baz
    ${colors.YELLOW}^^^${colors.NONE}"""));
    });
  });
}
