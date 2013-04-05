// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trace_test;

import 'dart:io';
import 'dart:uri';

import 'package:pathos/path.dart' as path;
import 'package:stack_trace/src/utils.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/unittest.dart';

String getStackTraceString() {
  try {
    throw '';
  } catch (_, stackTrace) {
    return stackTrace.toString();
  }
}

StackTrace getStackTraceObject() {
  try {
    throw '';
  } catch (_, stackTrace) {
    return stackTrace;
  }
}

Trace getCurrentTrace([int level]) => new Trace.current(level);

Trace nestedGetCurrentTrace(int level) => getCurrentTrace(level);

void main() {
  test('parses a stack trace correctly', () {
    var trace = new Trace.parse('''
#0      Foo._bar (file:///home/nweiz/code/stuff.dart:42:21)
#1      zip.<anonymous closure>.zap (dart:async:0:2)
#2      zip.<anonymous closure>.zap (http://pub.dartlang.org/thing.dart:1:100)
''');

    expect(trace.frames[0].uri,
        equals(new Uri.fromString("file:///home/nweiz/code/stuff.dart")));
    expect(trace.frames[1].uri, equals(new Uri.fromString("dart:async")));
    expect(trace.frames[2].uri,
        equals(new Uri.fromString("http://pub.dartlang.org/thing.dart")));
  });

  test('parses a real stack trace correctly', () {
    var trace = new Trace.parse(getStackTraceString());
    // TODO(nweiz): use URL-style paths when such a thing exists.
    var builder = new path.Builder(style: path.Style.posix);
    expect(builder.basename(trace.frames.first.uri.path),
        equals('trace_test.dart'));
    expect(trace.frames.first.member, equals('getStackTraceString'));
  });

  test('converts from a native stack trace correctly', () {
    var trace = new Trace.from(getStackTraceObject());
    // TODO(nweiz): use URL-style paths when such a thing exists.
    var builder = new path.Builder(style: path.Style.posix);
    expect(builder.basename(trace.frames.first.uri.path),
        equals('trace_test.dart'));
    expect(trace.frames.first.member, equals('getStackTraceObject'));
  });

  group('.current()', () {
    test('with no argument returns a trace starting at the current frame', () {
      var trace = new Trace.current();
      expect(trace.frames.first.member, equals('main.<fn>.<fn>'));
    });

    test('at level 0 returns a trace starting at the current frame', () {
      var trace = new Trace.current(0);
      expect(trace.frames.first.member, equals('main.<fn>.<fn>'));
    });

    test('at level 1 returns a trace starting at the parent frame', () {
      var trace = getCurrentTrace(1);
      expect(trace.frames.first.member, equals('main.<fn>.<fn>'));
    });

    test('at level 2 returns a trace starting at the grandparent frame', () {
      var trace = nestedGetCurrentTrace(2);
      expect(trace.frames.first.member, equals('main.<fn>.<fn>'));
    });

    test('throws an ArgumentError for negative levels', () {
      expect(() => new Trace.current(-1), throwsArgumentError);
    });
  });

  test('.toString() nicely formats the stack trace', () {
    var uri = pathToFileUri(path.join('foo', 'bar.dart'));
    var trace = new Trace.parse('''
#0      Foo._bar ($uri:42:21)
#1      zip.<anonymous closure>.zap (dart:async:0:2)
#2      zip.<anonymous closure>.zap (http://pub.dartlang.org/thing.dart:1:100)
''');

    expect(trace.toString(), equals('''
${path.join('foo', 'bar.dart')} 42:21                        Foo._bar
dart:async                                zip.<fn>.zap
http://pub.dartlang.org/thing.dart 1:100  zip.<fn>.zap
'''));
  });

  test('.stackTrace forwards to .toString()', () {
    var trace = new Trace.current();
    expect(trace.stackTrace, equals(trace.toString()));
  });

  test('.fullStackTrace forwards to .toString()', () {
    var trace = new Trace.current();
    expect(trace.fullStackTrace, equals(trace.toString()));
  });

  test('.terse folds core frames together bottom-up', () {
    var trace = new Trace.parse('''
#0 notCore (foo.dart:42:21)
#1 top (dart:async:0:2)
#2 bottom (dart:core:1:100)
#3 alsoNotCore (bar.dart:10:20)
#4 top (dart:io:5:10)
#5 bottom (dart:async-patch:9:11)
''');

    expect(trace.terse.toString(), equals('''
foo.dart 42:21  notCore
dart:core       bottom
bar.dart 10:20  alsoNotCore
dart:async      bottom
'''));
  });

  test('.foldFrames folds frames together bottom-up', () {
    var trace = new Trace.parse('''
#0 notFoo (foo.dart:42:21)
#1 fooTop (bar.dart:0:2)
#2 fooBottom (foo.dart:1:100)
#3 alsoNotFoo (bar.dart:10:20)
#4 fooTop (dart:io:5:10)
#5 fooBottom (dart:async-patch:9:11)
''');

    var folded = trace.foldFrames((frame) => frame.member.startsWith('foo'));
    expect(folded.toString(), equals('''
foo.dart 42:21    notFoo
foo.dart 1:100    fooBottom
bar.dart 10:20    alsoNotFoo
dart:async-patch  fooBottom
'''));
  });
}
