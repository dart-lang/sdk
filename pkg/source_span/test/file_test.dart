// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:source_span/source_span.dart';

main() {
  var file;
  setUp(() {
    file = new SourceFile("""
foo bar baz
whiz bang boom
zip zap zop""", url: "foo.dart");
  });

  group("errors", () {
    group("for span()", () {
      test("end must come after start", () {
        expect(() => file.span(10, 5), throwsArgumentError);
      });

      test("start may not be negative", () {
        expect(() => file.span(-1, 5), throwsRangeError);
      });

      test("end may not be outside the file", () {
        expect(() => file.span(10, 100), throwsRangeError);
      });
    });

    group("for location()", () {
      test("offset may not be negative", () {
        expect(() => file.location(-1), throwsRangeError);
      });

      test("offset may not be outside the file", () {
        expect(() => file.location(100), throwsRangeError);
      });
    });

    group("for getLine()", () {
      test("offset may not be negative", () {
        expect(() => file.getLine(-1), throwsRangeError);
      });

      test("offset may not be outside the file", () {
        expect(() => file.getLine(100), throwsRangeError);
      });
    });

    group("for getColumn()", () {
      test("offset may not be negative", () {
        expect(() => file.getColumn(-1), throwsRangeError);
      });

      test("offset may not be outside the file", () {
        expect(() => file.getColumn(100), throwsRangeError);
      });

      test("line may not be negative", () {
        expect(() => file.getColumn(1, line: -1), throwsRangeError);
      });

      test("line may not be outside the file", () {
        expect(() => file.getColumn(1, line: 100), throwsRangeError);
      });

      test("line must be accurate", () {
        expect(() => file.getColumn(1, line: 1), throwsRangeError);
      });
    });

    group("getOffset()", () {
      test("line may not be negative", () {
        expect(() => file.getOffset(-1), throwsRangeError);
      });

      test("column may not be negative", () {
        expect(() => file.getOffset(1, -1), throwsRangeError);
      });

      test("line may not be outside the file", () {
        expect(() => file.getOffset(100), throwsRangeError);
      });

      test("column may not be outside the file", () {
        expect(() => file.getOffset(2, 100), throwsRangeError);
      });
 
      test("column may not be outside the line", () {
        expect(() => file.getOffset(1, 20), throwsRangeError);
      });
    });

    group("for getText()", () {
      test("end must come after start", () {
        expect(() => file.getText(10, 5), throwsArgumentError);
      });

      test("start may not be negative", () {
        expect(() => file.getText(-1, 5), throwsRangeError);
      });

      test("end may not be outside the file", () {
        expect(() => file.getText(10, 100), throwsRangeError);
      });
    });

    group("for span().union()", () {
      test("source URLs must match", () {
        var other = new SourceSpan(
            new SourceLocation(10), new SourceLocation(11), "_");

        expect(() => file.span(9, 10).union(other), throwsArgumentError);
      });

      test("spans may not be disjoint", () {
        expect(() => file.span(9, 10).union(file.span(11, 12)),
            throwsArgumentError);
      });
    });

    test("for span().expand() source URLs must match", () {
      var other = new SourceFile("""
foo bar baz
whiz bang boom
zip zap zop""", url: "bar.dart").span(10, 11);

      expect(() => file.span(9, 10).expand(other), throwsArgumentError);
    });
  });

  test('fields work correctly', () {
    expect(file.url, equals(Uri.parse("foo.dart")));
    expect(file.lines, equals(3));
    expect(file.length, equals(38));
  });

  group("new SourceFile()", () {
    test("handles CRLF correctly", () {
      expect(new SourceFile("foo\r\nbar").getLine(6), equals(1));
    });

    test("handles a lone CR correctly", () {
      expect(new SourceFile("foo\rbar").getLine(5), equals(1));
    });
  });

  group("span()", () {
    test("returns a span between the given offsets", () {
      var span = file.span(5, 10);
      expect(span.start, equals(file.location(5)));
      expect(span.end, equals(file.location(10)));
    });

    test("end defaults to the end of the file", () {
      var span = file.span(5);
      expect(span.start, equals(file.location(5)));
      expect(span.end, equals(file.location(file.length - 1)));
    });
  });

  group("getLine()", () {
    test("works for a middle character on the line", () {
      expect(file.getLine(15), equals(1));
    });

    test("works for the first character of a line", () {
      expect(file.getLine(12), equals(1));
    });

    test("works for a newline character", () {
      expect(file.getLine(11), equals(0));
    });

    test("works for the last offset", () {
      expect(file.getLine(file.length), equals(2));
    });
  });

  group("getColumn()", () {
    test("works for a middle character on the line", () {
      expect(file.getColumn(15), equals(3));
    });

    test("works for the first character of a line", () {
      expect(file.getColumn(12), equals(0));
    });

    test("works for a newline character", () {
      expect(file.getColumn(11), equals(11));
    });

    test("works when line is passed as well", () {
      expect(file.getColumn(12, line: 1), equals(0));
    });

    test("works for the last offset", () {
      expect(file.getColumn(file.length), equals(11));
    });
  });

  group("getOffset()", () {
    test("works for a middle character on the line", () {
      expect(file.getOffset(1, 3), equals(15));
    });

    test("works for the first character of a line", () {
      expect(file.getOffset(1), equals(12));
    });

    test("works for a newline character", () {
      expect(file.getOffset(0, 11), equals(11));
    });

    test("works for the last offset", () {
      expect(file.getOffset(2, 11), equals(file.length));
    });
  });

  group("getText()", () {
    test("returns a substring of the source", () {
      expect(file.getText(8, 15), equals("baz\nwhi"));
    });

    test("end defaults to the end of the file", () {
      expect(file.getText(20), equals("g boom\nzip zap zop"));
    });
  });

  group("FileLocation", () {
    test("reports the correct line number", () {
      expect(file.location(15).line, equals(1));
    });

    test("reports the correct column number", () {
      expect(file.location(15).column, equals(3));
    });

    test("pointSpan() returns a FileSpan", () {
      var location = file.location(15);
      var span = location.pointSpan();
      expect(span, new isInstanceOf<FileSpan>());
      expect(span.start, equals(location));
      expect(span.end, equals(location));
      expect(span.text, isEmpty);
    });
  });

  group("FileSpan", () {
    test("text returns a substring of the source", () {
      expect(file.span(8, 15).text, equals("baz\nwhi"));
    });

    group("union()", () {
      var span;
      setUp(() {
        span = file.span(5, 12);
      });

      test("works with a preceding adjacent span", () {
        var other = file.span(0, 5);
        var result = span.union(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals("foo bar baz\n"));
      });

      test("works with a preceding overlapping span", () {
        var other = file.span(0, 8);
        var result = span.union(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals("foo bar baz\n"));
      });

      test("works with a following adjacent span", () {
        var other = file.span(12, 16);
        var result = span.union(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals("ar baz\nwhiz"));
      });

      test("works with a following overlapping span", () {
        var other = file.span(9, 16);
        var result = span.union(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals("ar baz\nwhiz"));
      });

      test("works with an internal overlapping span", () {
        var other = file.span(7, 10);
        expect(span.union(other), equals(span));
      });

      test("works with an external overlapping span", () {
        var other = file.span(0, 16);
        expect(span.union(other), equals(other));
      });

      test("returns a FileSpan for a FileSpan input", () {
        expect(span.union(file.span(0, 5)), new isInstanceOf<FileSpan>());
      });

      test("returns a base SourceSpan for a SourceSpan input", () {
        var other = new SourceSpan(
            new SourceLocation(0, sourceUrl: "foo.dart"),
            new SourceLocation(5, sourceUrl: "foo.dart"),
            "hey, ");
        var result = span.union(other);
        expect(result, isNot(new isInstanceOf<FileSpan>()));
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals("hey, ar baz\n"));
      });
    });

    group("expand()", () {
      var span;
      setUp(() {
        span = file.span(5, 12);
      });

      test("works with a preceding nonadjacent span", () {
        var other = file.span(0, 3);
        var result = span.expand(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals("foo bar baz\n"));
      });

      test("works with a preceding overlapping span", () {
        var other = file.span(0, 8);
        var result = span.expand(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals("foo bar baz\n"));
      });

      test("works with a following nonadjacent span", () {
        var other = file.span(14, 16);
        var result = span.expand(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals("ar baz\nwhiz"));
      });

      test("works with a following overlapping span", () {
        var other = file.span(9, 16);
        var result = span.expand(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals("ar baz\nwhiz"));
      });

      test("works with an internal overlapping span", () {
        var other = file.span(7, 10);
        expect(span.expand(other), equals(span));
      });

      test("works with an external overlapping span", () {
        var other = file.span(0, 16);
        expect(span.expand(other), equals(other));
      });
    });
  });
}