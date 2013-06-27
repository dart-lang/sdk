// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trace_test;

import 'package:pathos/path.dart' as path;
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
  group('.parse', () {
    test('.parse parses a VM stack trace correctly', () {
      var trace = new Trace.parse(
          '#0      Foo._bar (file:///home/nweiz/code/stuff.dart:42:21)\n'
          '#1      zip.<anonymous closure>.zap (dart:async/future.dart:0:2)\n'
          '#2      zip.<anonymous closure>.zap (http://pub.dartlang.org/thing.'
              'dart:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse("file:///home/nweiz/code/stuff.dart")));
      expect(trace.frames[1].uri, equals(Uri.parse("dart:async/future.dart")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.dart")));
    });

    test('parses a V8 stack trace correctly', () {
      var trace = new Trace.parse(
          'Error\n'
          '    at Foo._bar (http://pub.dartlang.org/stuff.js:42:21)\n'
          '    at http://pub.dartlang.org/stuff.js:0:2\n'
          '    at zip.<anonymous>.zap '
              '(http://pub.dartlang.org/thing.js:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.js")));
    });

    test('parses a Firefox stack trace correctly', () {
      var trace = new Trace.parse(
          'Foo._bar@http://pub.dartlang.org/stuff.js:42\n'
          'zip/<@http://pub.dartlang.org/stuff.js:0\n'
          'zip.zap(12, "@)()/<")@http://pub.dartlang.org/thing.js:1');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.js")));

      trace = new Trace.parse(
          'zip/<@http://pub.dartlang.org/stuff.js:0\n'
          'Foo._bar@http://pub.dartlang.org/stuff.js:42\n'
          'zip.zap(12, "@)()/<")@http://pub.dartlang.org/thing.js:1');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.js")));

      trace = new Trace.parse(
          'zip.zap(12, "@)()/<")@http://pub.dartlang.org/thing.js:1\n'
          'zip/<@http://pub.dartlang.org/stuff.js:0\n'
          'Foo._bar@http://pub.dartlang.org/stuff.js:42');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.js")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
    });
  });

  test('.toString() nicely formats the stack trace', () {
    var trace = new Trace.parse('''
#0      Foo._bar (foo/bar.dart:42:21)
#1      zip.<anonymous closure>.zap (dart:async/future.dart:0:2)
#2      zip.<anonymous closure>.zap (http://pub.dartlang.org/thing.dart:1:100)
''');

    expect(trace.toString(), equals('''
foo/bar.dart 42:21                        Foo._bar
dart:async/future.dart 0:2                zip.<fn>.zap
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
#1 top (dart:async/future.dart:0:2)
#2 bottom (dart:core/uri.dart:1:100)
#3 alsoNotCore (bar.dart:10:20)
#4 top (dart:io:5:10)
#5 bottom (dart:async-patch/future.dart:9:11)
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
#4 fooTop (dart:io/socket.dart:5:10)
#5 fooBottom (dart:async-patch/future.dart:9:11)
''');

    var folded = trace.foldFrames((frame) => frame.member.startsWith('foo'));
    expect(folded.toString(), equals('''
foo.dart 42:21                     notFoo
foo.dart 1:100                     fooBottom
bar.dart 10:20                     alsoNotFoo
dart:async-patch/future.dart 9:11  fooBottom
'''));
  });
}
