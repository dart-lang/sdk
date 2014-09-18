// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library frame_test;

import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/unittest.dart';

void main() {
  group('.parseVM', () {
    test('parses a stack frame with column correctly', () {
      var frame = new Frame.parseVM("#1      Foo._bar "
          "(file:///home/nweiz/code/stuff.dart:42:21)");
      expect(frame.uri,
          equals(Uri.parse("file:///home/nweiz/code/stuff.dart")));
      expect(frame.line, equals(42));
      expect(frame.column, equals(21));
      expect(frame.member, equals('Foo._bar'));
    });

    test('parses a stack frame without column correctly', () {
      var frame = new Frame.parseVM("#1      Foo._bar "
          "(file:///home/nweiz/code/stuff.dart:24)");
      expect(frame.uri,
          equals(Uri.parse("file:///home/nweiz/code/stuff.dart")));
      expect(frame.line, equals(24));
      expect(frame.column, null);
      expect(frame.member, equals('Foo._bar'));
    });

    test('converts "<anonymous closure>" to "<fn>"', () {
      String parsedMember(String member) =>
          new Frame.parseVM('#0 $member (foo:0:0)').member;

      expect(parsedMember('Foo.<anonymous closure>'), equals('Foo.<fn>'));
      expect(parsedMember('<anonymous closure>.<anonymous closure>.bar'),
          equals('<fn>.<fn>.bar'));
    });

    test('parses a folded frame correctly', () {
      var frame = new Frame.parseVM('...');

      expect(frame.member, equals('...'));
      expect(frame.uri, equals(new Uri()));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
    });

    test('throws a FormatException for malformed frames', () {
      expect(() => new Frame.parseVM(''), throwsFormatException);
      expect(() => new Frame.parseVM('#1'), throwsFormatException);
      expect(() => new Frame.parseVM('#1      Foo'), throwsFormatException);
      expect(() => new Frame.parseVM('#1      Foo (dart:async/future.dart)'),
          throwsFormatException);
      expect(() => new Frame.parseVM('#1      (dart:async/future.dart:10:15)'),
          throwsFormatException);
      expect(() => new Frame.parseVM('Foo (dart:async/future.dart:10:15)'),
          throwsFormatException);
    });
  });

  group('.parseV8', () {
    test('parses a stack frame correctly', () {
      var frame = new Frame.parseV8("    at VW.call\$0 "
          "(http://pub.dartlang.org/stuff.dart.js:560:28)");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute POSIX path correctly', () {
      var frame = new Frame.parseV8("    at VW.call\$0 "
          "(/path/to/stuff.dart.js:560:28)");
      expect(frame.uri, equals(Uri.parse("file:///path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute Windows path correctly', () {
      var frame = new Frame.parseV8("    at VW.call\$0 "
          r"(C:\path\to\stuff.dart.js:560:28)");
      expect(frame.uri, equals(Uri.parse("file:///C:/path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a Windows UNC path correctly', () {
      var frame = new Frame.parseV8("    at VW.call\$0 "
          r"(\\mount\path\to\stuff.dart.js:560:28)");
      expect(frame.uri,
          equals(Uri.parse("file://mount/path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative POSIX path correctly', () {
      var frame = new Frame.parseV8("    at VW.call\$0 "
          "(path/to/stuff.dart.js:560:28)");
      expect(frame.uri, equals(Uri.parse("path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative Windows path correctly', () {
      var frame = new Frame.parseV8("    at VW.call\$0 "
          r"(path\to\stuff.dart.js:560:28)");
      expect(frame.uri, equals(Uri.parse("path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses an anonymous stack frame correctly', () {
      var frame = new Frame.parseV8(
          "    at http://pub.dartlang.org/stuff.dart.js:560:28");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('<fn>'));
    });

    test('parses a stack frame with [as ...] correctly', () {
      // Ignore "[as ...]", since other stack trace formats don't support a
      // similar construct.
      var frame = new Frame.parseV8("    at VW.call\$0 [as call\$4] "
          "(http://pub.dartlang.org/stuff.dart.js:560:28)");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a basic eval stack frame correctly', () {
      var frame = new Frame.parseV8("    at eval (eval at <anonymous> "
          "(http://pub.dartlang.org/stuff.dart.js:560:28))");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('parses an IE10 eval stack frame correctly', () {
      var frame = new Frame.parseV8("    at eval (eval at Anonymous function "
          "(http://pub.dartlang.org/stuff.dart.js:560:28))");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('parses an eval stack frame with inner position info correctly', () {
      var frame = new Frame.parseV8("    at eval (eval at <anonymous> "
          "(http://pub.dartlang.org/stuff.dart.js:560:28), <anonymous>:3:28)");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('parses a nested eval stack frame correctly', () {
      var frame = new Frame.parseV8("    at eval (eval at <anonymous> "
          "(eval at sub (http://pub.dartlang.org/stuff.dart.js:560:28)))");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('converts "<anonymous>" to "<fn>"', () {
      String parsedMember(String member) =>
          new Frame.parseV8('    at $member (foo:0:0)').member;

      expect(parsedMember('Foo.<anonymous>'), equals('Foo.<fn>'));
      expect(parsedMember('<anonymous>.<anonymous>.bar'),
          equals('<fn>.<fn>.bar'));
    });

    test('throws a FormatException for malformed frames', () {
      expect(() => new Frame.parseV8(''), throwsFormatException);
      expect(() => new Frame.parseV8('    at'), throwsFormatException);
      expect(() => new Frame.parseV8('    at Foo'), throwsFormatException);
      expect(() => new Frame.parseV8('    at Foo (dart:async/future.dart)'),
          throwsFormatException);
      expect(() => new Frame.parseV8('    at Foo (dart:async/future.dart:10)'),
          throwsFormatException);
      expect(() => new Frame.parseV8('    at (dart:async/future.dart:10:15)'),
          throwsFormatException);
      expect(() => new Frame.parseV8('Foo (dart:async/future.dart:10:15)'),
          throwsFormatException);
      expect(() => new Frame.parseV8('    at dart:async/future.dart'),
          throwsFormatException);
      expect(() => new Frame.parseV8('    at dart:async/future.dart:10'),
          throwsFormatException);
      expect(() => new Frame.parseV8('dart:async/future.dart:10:15'),
          throwsFormatException);
    });
  });

  group('.parseFirefox/.parseSafari', () {
    test('parses a simple stack frame correctly', () {
      var frame = new Frame.parseFirefox(
          ".VW.call\$0@http://pub.dartlang.org/stuff.dart.js:560");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute POSIX path correctly', () {
      var frame = new Frame.parseFirefox(
          ".VW.call\$0@/path/to/stuff.dart.js:560");
      expect(frame.uri, equals(Uri.parse("file:///path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute Windows path correctly', () {
      var frame = new Frame.parseFirefox(
          r".VW.call$0@C:\path\to\stuff.dart.js:560");
      expect(frame.uri, equals(Uri.parse("file:///C:/path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a Windows UNC path correctly', () {
      var frame = new Frame.parseFirefox(
          r".VW.call$0@\\mount\path\to\stuff.dart.js:560");
      expect(frame.uri,
          equals(Uri.parse("file://mount/path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative POSIX path correctly', () {
      var frame = new Frame.parseFirefox(
          ".VW.call\$0@path/to/stuff.dart.js:560");
      expect(frame.uri, equals(Uri.parse("path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative Windows path correctly', () {
      var frame = new Frame.parseFirefox(
          r".VW.call$0@path\to\stuff.dart.js:560");
      expect(frame.uri, equals(Uri.parse("path/to/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a simple anonymous stack frame correctly', () {
      var frame = new Frame.parseFirefox(
          "@http://pub.dartlang.org/stuff.dart.js:560");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("<fn>"));
    });

    test('parses a nested anonymous stack frame correctly', () {
      var frame = new Frame.parseFirefox(
          ".foo/<@http://pub.dartlang.org/stuff.dart.js:560");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("foo.<fn>"));

      frame = new Frame.parseFirefox(
          ".foo/@http://pub.dartlang.org/stuff.dart.js:560");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("foo.<fn>"));
    });

    test('parses a named nested anonymous stack frame correctly', () {
      var frame = new Frame.parseFirefox(
          ".foo/.name<@http://pub.dartlang.org/stuff.dart.js:560");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("foo.<fn>"));

      frame = new Frame.parseFirefox(
          ".foo/.name@http://pub.dartlang.org/stuff.dart.js:560");
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("foo.<fn>"));
    });

    test('parses a stack frame with parameters correctly', () {
      var frame = new Frame.parseFirefox(
          '.foo(12, "@)()/<")@http://pub.dartlang.org/stuff.dart.js:560');
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("foo"));
    });

    test('parses a nested anonymous stack frame with parameters correctly', () {
      var frame = new Frame.parseFirefox(
          '.foo(12, "@)()/<")/.fn<@'
          'http://pub.dartlang.org/stuff.dart.js:560');
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("foo.<fn>"));
    });

    test('parses a deeply-nested anonymous stack frame with parameters '
        'correctly', () {
      var frame = new Frame.parseFirefox(
          '.convertDartClosureToJS/\$function</<@'
          'http://pub.dartlang.org/stuff.dart.js:560');
      expect(frame.uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.dart.js")));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals("convertDartClosureToJS.<fn>.<fn>"));
    });

    test('throws a FormatException for malformed frames', () {
      expect(() => new Frame.parseFirefox(''), throwsFormatException);
      expect(() => new Frame.parseFirefox('.foo'), throwsFormatException);
      expect(() => new Frame.parseFirefox('.foo@dart:async/future.dart'),
          throwsFormatException);
      expect(() => new Frame.parseFirefox('.foo(@dart:async/future.dart:10'),
          throwsFormatException);
      expect(() => new Frame.parseFirefox('@dart:async/future.dart'),
          throwsFormatException);
    });

    test('parses a simple stack frame correctly', () {
      var frame = new Frame.parseFirefox(
          "foo\$bar@http://dartlang.org/foo/bar.dart:10:11");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('foo\$bar'));
    });

    test('parses an anonymous stack frame correctly', () {
      var frame = new Frame.parseFirefox(
          "http://dartlang.org/foo/bar.dart:10:11");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('<fn>'));
    });

    test('parses a stack frame with no line correctly', () {
      var frame = new Frame.parseFirefox(
          "foo\$bar@http://dartlang.org/foo/bar.dart::11");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, isNull);
      expect(frame.column, equals(11));
      expect(frame.member, equals('foo\$bar'));
    });

    test('parses a stack frame with no column correctly', () {
      var frame = new Frame.parseFirefox(
          "foo\$bar@http://dartlang.org/foo/bar.dart:10:");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, equals(10));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo\$bar'));
    });

    test('parses a stack frame with no line or column correctly', () {
      var frame = new Frame.parseFirefox(
          "foo\$bar@http://dartlang.org/foo/bar.dart:10:11");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('foo\$bar'));
    });
  });

  group('.parseFriendly', () {
    test('parses a simple stack frame correctly', () {
      var frame = new Frame.parseFriendly(
          "http://dartlang.org/foo/bar.dart 10:11  Foo.<fn>.bar");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('parses a stack frame with no line or column correctly', () {
      var frame = new Frame.parseFriendly(
          "http://dartlang.org/foo/bar.dart  Foo.<fn>.bar");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('parses a stack frame with no line correctly', () {
      var frame = new Frame.parseFriendly(
          "http://dartlang.org/foo/bar.dart 10  Foo.<fn>.bar");
      expect(frame.uri, equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(frame.line, equals(10));
      expect(frame.column, isNull);
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('parses a stack frame with a relative path correctly', () {
      var frame = new Frame.parseFriendly("foo/bar.dart 10:11    Foo.<fn>.bar");
      expect(frame.uri, equals(
          path.toUri(path.absolute(path.join('foo', 'bar.dart')))));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('throws a FormatException for malformed frames', () {
      expect(() => new Frame.parseFriendly(''), throwsFormatException);
      expect(() => new Frame.parseFriendly('foo/bar.dart'),
          throwsFormatException);
      expect(() => new Frame.parseFriendly('foo/bar.dart 10:11'),
          throwsFormatException);
    });
  });

  test('only considers dart URIs to be core', () {
    bool isCore(String library) =>
      new Frame.parseVM('#0 Foo ($library:0:0)').isCore;

    expect(isCore('dart:core'), isTrue);
    expect(isCore('dart:async'), isTrue);
    expect(isCore('dart:core/uri.dart'), isTrue);
    expect(isCore('dart:async/future.dart'), isTrue);
    expect(isCore('bart:core'), isFalse);
    expect(isCore('sdart:core'), isFalse);
    expect(isCore('darty:core'), isFalse);
    expect(isCore('bart:core/uri.dart'), isFalse);
  });

  group('.library', () {
    test('returns the URI string for non-file URIs', () {
      expect(new Frame.parseVM('#0 Foo (dart:async/future.dart:0:0)').library,
          equals('dart:async/future.dart'));
      expect(new Frame.parseVM('#0 Foo '
              '(http://dartlang.org/stuff/thing.dart:0:0)').library,
          equals('http://dartlang.org/stuff/thing.dart'));
    });

    test('returns the relative path for file URIs', () {
      expect(new Frame.parseVM('#0 Foo (foo/bar.dart:0:0)').library,
          equals(path.join('foo', 'bar.dart')));
    });
  });

  group('.location', () {
    test('returns the library and line/column numbers for non-core '
        'libraries', () {
      expect(new Frame.parseVM('#0 Foo '
              '(http://dartlang.org/thing.dart:5:10)').location,
          equals('http://dartlang.org/thing.dart 5:10'));
      expect(new Frame.parseVM('#0 Foo (foo/bar.dart:1:2)').location,
          equals('${path.join('foo', 'bar.dart')} 1:2'));
    });
  });

  group('.package', () {
    test('returns null for non-package URIs', () {
      expect(new Frame.parseVM('#0 Foo (dart:async/future.dart:0:0)').package,
          isNull);
      expect(new Frame.parseVM('#0 Foo '
              '(http://dartlang.org/stuff/thing.dart:0:0)').package,
          isNull);
    });

    test('returns the package name for package: URIs', () {
      expect(new Frame.parseVM('#0 Foo (package:foo/foo.dart:0:0)').package,
          equals('foo'));
      expect(new Frame.parseVM('#0 Foo (package:foo/zap/bar.dart:0:0)').package,
          equals('foo'));
    });
  });

  group('.toString()', () {
    test('returns the library and line/column numbers for non-core '
        'libraries', () {
      expect(new Frame.parseVM('#0 Foo (http://dartlang.org/thing.dart:5:10)')
              .toString(),
          equals('http://dartlang.org/thing.dart 5:10 in Foo'));
    });

    test('converts "<anonymous closure>" to "<fn>"', () {
      expect(new Frame.parseVM('#0 Foo.<anonymous closure> '
              '(dart:core/uri.dart:5:10)').toString(),
          equals('dart:core/uri.dart 5:10 in Foo.<fn>'));
    });

    test('prints a frame without a column correctly', () {
      expect(new Frame.parseVM('#0 Foo (dart:core/uri.dart:5)').toString(),
          equals('dart:core/uri.dart 5 in Foo'));
    });

    test('prints relative paths as relative', () {
      var relative = path.normalize('relative/path/to/foo.dart');
      expect(new Frame.parseFriendly('$relative 5:10  Foo').toString(),
          equals('$relative 5:10 in Foo'));
    });
  });
}
