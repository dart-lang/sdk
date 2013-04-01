// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library frame_test;

import 'dart:io';
import 'dart:uri';

import 'package:pathos/path.dart' as path;
import 'package:stack_trace/src/utils.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/unittest.dart';

String getStackFrame() {
  try {
    throw '';
  } catch (_, stackTrace) {
    return stackTrace.toString().split("\n").first;
  }
}

Frame getCaller([int level]) {
  if (level == null) return new Frame.caller();
  return new Frame.caller(level);
}

Frame nestedGetCaller(int level) => getCaller(level);

void main() {
  test('parses a stack frame correctly', () {
    var frame = new Frame.parse("#1      Foo._bar "
        "(file:///home/nweiz/code/stuff.dart:42:21)");
    expect(frame.uri,
        equals(new Uri.fromString("file:///home/nweiz/code/stuff.dart")));
    expect(frame.line, equals(42));
    expect(frame.column, equals(21));
    expect(frame.member, equals('Foo._bar'));
  });

  test('parses a real stack frame correctly', () {
    var frame = new Frame.parse(getStackFrame());
    // TODO(nweiz): use URL-style paths when such a thing exists.
    var builder = new path.Builder(style: path.Style.posix);
    expect(builder.basename(frame.uri.path), equals('frame_test.dart'));
    expect(frame.line, equals(17));
    expect(frame.column, equals(5));
    expect(frame.member, equals('getStackFrame'));
  });

  test('converts "<anonymous closure>" to "<fn>"', () {
    String parsedMember(String member) =>
        new Frame.parse('#0 $member (foo:0:0)').member;

    expect(parsedMember('Foo.<anonymous closure>'), equals('Foo.<fn>'));
    expect(parsedMember('<anonymous closure>.<anonymous closure>.bar'),
        equals('<fn>.<fn>.bar'));
  });

  test('throws a FormatException for malformed frames', () {
    expect(() => new Frame.parse(''), throwsFormatException);
    expect(() => new Frame.parse('#1'), throwsFormatException);
    expect(() => new Frame.parse('#1      Foo'), throwsFormatException);
    expect(() => new Frame.parse('#1      Foo (dart:async)'),
        throwsFormatException);
    expect(() => new Frame.parse('#1      Foo (dart:async:10)'),
        throwsFormatException);
    expect(() => new Frame.parse('#1      (dart:async:10:15)'),
        throwsFormatException);
    expect(() => new Frame.parse('Foo (dart:async:10:15)'),
        throwsFormatException);
  });

  test('only considers dart URIs to be core', () {
    bool isCore(String library) =>
      new Frame.parse('#0 Foo ($library:0:0)').isCore;

    expect(isCore('dart:core'), isTrue);
    expect(isCore('dart:async'), isTrue);
    expect(isCore('bart:core'), isFalse);
    expect(isCore('sdart:core'), isFalse);
    expect(isCore('darty:core'), isFalse);
  });

  group('.caller()', () {
    test('with no argument returns the parent frame', () {
      expect(getCaller().member, equals('main.<fn>.<fn>'));
    });

    test('at level 0 returns the current frame', () {
      expect(getCaller(0).member, equals('getCaller'));
    });

    test('at level 1 returns the current frame', () {
      expect(getCaller(1).member, equals('main.<fn>.<fn>'));
    });

    test('at level 2 returns the grandparent frame', () {
      expect(nestedGetCaller(2).member, equals('main.<fn>.<fn>'));
    });

    test('throws an ArgumentError for negative levels', () {
      expect(() => new Frame.caller(-1), throwsArgumentError);
    });
  });

  group('.library', () {
    test('returns the URI string for non-file URIs', () {
      expect(new Frame.parse('#0 Foo (dart:async:0:0)').library,
          equals('dart:async'));
      expect(new Frame.parse('#0 Foo '
              '(http://dartlang.org/stuff/thing.dart:0:0)').library,
          equals('http://dartlang.org/stuff/thing.dart'));
    });

    test('returns the relative path for file URIs', () {
      var uri = pathToFileUri(path.join('foo', 'bar.dart'));
      expect(new Frame.parse('#0 Foo ($uri:0:0)').library,
          equals(path.join('foo', 'bar.dart')));
    });
  });

  group('.location', () {
    test('returns the library and line/column numbers for non-core '
        'libraries', () {
      expect(new Frame.parse('#0 Foo '
              '(http://dartlang.org/thing.dart:5:10)').location,
          equals('http://dartlang.org/thing.dart 5:10'));
      var uri = pathToFileUri(path.join('foo', 'bar.dart'));
      expect(new Frame.parse('#0 Foo ($uri:1:2)').location,
          equals('${path.join('foo', 'bar.dart')} 1:2'));
    });

    test('just returns the library for core libraries', () {
      expect(new Frame.parse('#0 Foo (dart:core:5:10)').location,
          equals('dart:core'));
      expect(new Frame.parse('#0 Foo (dart:async-patch:1:2)').location,
          equals('dart:async-patch'));
    });
  });

  group('.package', () {
    test('returns null for non-package URIs', () {
      expect(new Frame.parse('#0 Foo (dart:async:0:0)').package, isNull);
      expect(new Frame.parse('#0 Foo '
              '(http://dartlang.org/stuff/thing.dart:0:0)').package,
          isNull);
    });

    test('returns the package name for package: URIs', () {
      expect(new Frame.parse('#0 Foo (package:foo/foo.dart:0:0)').package,
          equals('foo'));
      expect(new Frame.parse('#0 Foo (package:foo/zap/bar.dart:0:0)').package,
          equals('foo'));
    });
  });

  group('.toString()', () {
    test('returns the library and line/column numbers for non-core '
        'libraries', () {
      expect(new Frame.parse('#0 Foo (http://dartlang.org/thing.dart:5:10)')
              .toString(),
          equals('http://dartlang.org/thing.dart 5:10 in Foo'));
    });

    test('just returns the library for core libraries', () {
      expect(new Frame.parse('#0 Foo (dart:core:5:10)').toString(),
          equals('dart:core in Foo'));
    });

    test('converts "<anonymous closure>" to "<fn>"', () {
      expect(new Frame.parse('#0 Foo.<anonymous closure> (dart:core:5:10)')
              .toString(),
          equals('dart:core in Foo.<fn>'));
    });
  });
}
