// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:source_span/source_span.dart';
import 'package:source_span/src/colors.dart' as colors;

main() {
  var span;
  setUp(() {
    span = new SourceSpan(
        new SourceLocation(5, sourceUrl: "foo.dart"),
        new SourceLocation(12, sourceUrl: "foo.dart"),
        "foo bar");
  });

  group('errors', () {
    group('for new SourceSpan()', () {
      test('source URLs must match', () {
        var start = new SourceLocation(0, sourceUrl: "foo.dart");
        var end = new SourceLocation(1, sourceUrl: "bar.dart");
        expect(() => new SourceSpan(start, end, "_"), throwsArgumentError);
      });

      test('end must come after start', () {
        var start = new SourceLocation(1);
        var end = new SourceLocation(0);
        expect(() => new SourceSpan(start, end, "_"), throwsArgumentError);
      });

      test('text must be the right length', () {
        var start = new SourceLocation(0);
        var end = new SourceLocation(1);
        expect(() => new SourceSpan(start, end, "abc"), throwsArgumentError);
      });
    });

    group('for union()', () {
      test('source URLs must match', () {
        var other = new SourceSpan(
            new SourceLocation(12, sourceUrl: "bar.dart"),
            new SourceLocation(13, sourceUrl: "bar.dart"),
            "_");

        expect(() => span.union(other), throwsArgumentError);
      });

      test('spans may not be disjoint', () {
        var other = new SourceSpan(
            new SourceLocation(13, sourceUrl: 'foo.dart'),
            new SourceLocation(14, sourceUrl: 'foo.dart'),
            "_");

        expect(() => span.union(other), throwsArgumentError);
      });
    });

    test('for compareTo() source URLs must match', () {
      var other = new SourceSpan(
          new SourceLocation(12, sourceUrl: "bar.dart"),
          new SourceLocation(13, sourceUrl: "bar.dart"),
          "_");

      expect(() => span.compareTo(other), throwsArgumentError);
    });
  });

  test('fields work correctly', () {
    expect(span.start, equals(new SourceLocation(5, sourceUrl: "foo.dart")));
    expect(span.end, equals(new SourceLocation(12, sourceUrl: "foo.dart")));
    expect(span.sourceUrl, equals(Uri.parse("foo.dart")));
    expect(span.length, equals(7));
  });

  group("union()", () {
    test("works with a preceding adjacent span", () {
      var other = new SourceSpan(
          new SourceLocation(0, sourceUrl: "foo.dart"),
          new SourceLocation(5, sourceUrl: "foo.dart"),
          "hey, ");

      var result = span.union(other);
      expect(result.start, equals(other.start));
      expect(result.end, equals(span.end));
      expect(result.text, equals("hey, foo bar"));
    });

    test("works with a preceding overlapping span", () {
      var other = new SourceSpan(
          new SourceLocation(0, sourceUrl: "foo.dart"),
          new SourceLocation(8, sourceUrl: "foo.dart"),
          "hey, foo");

      var result = span.union(other);
      expect(result.start, equals(other.start));
      expect(result.end, equals(span.end));
      expect(result.text, equals("hey, foo bar"));
    });

    test("works with a following adjacent span", () {
      var other = new SourceSpan(
          new SourceLocation(12, sourceUrl: "foo.dart"),
          new SourceLocation(16, sourceUrl: "foo.dart"),
          " baz");

      var result = span.union(other);
      expect(result.start, equals(span.start));
      expect(result.end, equals(other.end));
      expect(result.text, equals("foo bar baz"));
    });

    test("works with a following overlapping span", () {
      var other = new SourceSpan(
          new SourceLocation(9, sourceUrl: "foo.dart"),
          new SourceLocation(16, sourceUrl: "foo.dart"),
          "bar baz");

      var result = span.union(other);
      expect(result.start, equals(span.start));
      expect(result.end, equals(other.end));
      expect(result.text, equals("foo bar baz"));
    });

    test("works with an internal overlapping span", () {
      var other = new SourceSpan(
          new SourceLocation(7, sourceUrl: "foo.dart"),
          new SourceLocation(10, sourceUrl: "foo.dart"),
          "o b");

      expect(span.union(other), equals(span));
    });

    test("works with an external overlapping span", () {
      var other = new SourceSpan(
          new SourceLocation(0, sourceUrl: "foo.dart"),
          new SourceLocation(16, sourceUrl: "foo.dart"),
          "hey, foo bar baz");

      expect(span.union(other), equals(other));
    });
  });

  group("message()", () {
    test("prints the text being described", () {
      expect(span.message("oh no"), equals("""
line 1, column 6 of foo.dart: oh no
foo bar
^^^^^^^"""));
    });

    test("gracefully handles a missing source URL", () {
      var span = new SourceSpan(
          new SourceLocation(5), new SourceLocation(12), "foo bar");

      expect(span.message("oh no"), equalsIgnoringWhitespace("""
line 1, column 6: oh no
foo bar
^^^^^^^"""));
    });

    test("gracefully handles empty text", () {
      var span = new SourceSpan(
          new SourceLocation(5), new SourceLocation(5), "");

      expect(span.message("oh no"),
          equals("line 1, column 6: oh no"));
    });

    test("doesn't colorize if color is false", () {
      expect(span.message("oh no", color: false), equals("""
line 1, column 6 of foo.dart: oh no
foo bar
^^^^^^^"""));
    });

    test("colorizes if color is true", () {
      expect(span.message("oh no", color: true),
          equals("""
line 1, column 6 of foo.dart: oh no
${colors.RED}foo bar
^^^^^^^${colors.NONE}"""));
    });

    test("uses the given color if it's passed", () {
      expect(span.message("oh no", color: colors.YELLOW), equals("""
line 1, column 6 of foo.dart: oh no
${colors.YELLOW}foo bar
^^^^^^^${colors.NONE}"""));
    });
  });

  group("compareTo()", () {
    test("sorts by start location first", () {
      var other = new SourceSpan(
          new SourceLocation(6, sourceUrl: "foo.dart"),
          new SourceLocation(14, sourceUrl: "foo.dart"),
          "oo bar b");

      expect(span.compareTo(other), lessThan(0));
      expect(other.compareTo(span), greaterThan(0));
    });

    test("sorts by length second", () {
      var other = new SourceSpan(
          new SourceLocation(5, sourceUrl: "foo.dart"),
          new SourceLocation(14, sourceUrl: "foo.dart"),
          "foo bar b");

      expect(span.compareTo(other), lessThan(0));
      expect(other.compareTo(span), greaterThan(0));
    });

    test("considers equal spans equal", () {
      expect(span.compareTo(span), equals(0));
    });
  });

  group("equality", () {
    test("two spans with the same locations are equal", () {
      var other = new SourceSpan(
          new SourceLocation(5, sourceUrl: "foo.dart"),
          new SourceLocation(12, sourceUrl: "foo.dart"),
          "foo bar");

      expect(span, equals(other));
    });

    test("a different start isn't equal", () {
      var other = new SourceSpan(
          new SourceLocation(0, sourceUrl: "foo.dart"),
          new SourceLocation(12, sourceUrl: "foo.dart"),
          "hey, foo bar");

      expect(span, isNot(equals(other)));
    });

    test("a different end isn't equal", () {
      var other = new SourceSpan(
          new SourceLocation(5, sourceUrl: "foo.dart"),
          new SourceLocation(16, sourceUrl: "foo.dart"),
          "foo bar baz");

      expect(span, isNot(equals(other)));
    });

    test("a different source URL isn't equal", () {
      var other = new SourceSpan(
          new SourceLocation(5, sourceUrl: "bar.dart"),
          new SourceLocation(12, sourceUrl: "bar.dart"),
          "foo bar");

      expect(span, isNot(equals(other)));
    });
  });
}
