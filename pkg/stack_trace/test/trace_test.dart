// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trace_test;

import 'package:path/path.dart' as path;
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
  // This just shouldn't crash.
  test('a native stack trace is parseable', () => new Trace.current());

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

      trace = new Trace.parse(
          "Exception: foo\n"
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

      trace = new Trace.parse(
          'Exception: foo\n'
          '    bar\n'
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

    test('parses a Safari 6.0 stack trace correctly', () {
      var trace = new Trace.parse(
          'Foo._bar@http://pub.dartlang.org/stuff.js:42\n'
          'zip/<@http://pub.dartlang.org/stuff.js:0\n'
          'zip.zap(12, "@)()/<")@http://pub.dartlang.org/thing.js:1\n'
          '[native code]');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.js")));
      expect(trace.frames.length, equals(3));
    });

    test('parses a Safari 6.1 stack trace correctly', () {
      var trace = new Trace.parse(
          'http://pub.dartlang.org/stuff.js:42:43\n'
          'zip@http://pub.dartlang.org/stuff.js:0:1\n'
          'zip\$zap@http://pub.dartlang.org/thing.js:1:2');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.js")));
    });

    test('parses a Safari 6.1 stack trace with an empty line correctly', () {
      var trace = new Trace.parse(
          'http://pub.dartlang.org/stuff.js:42:43\n'
          '\n'
          'zip@http://pub.dartlang.org/stuff.js:0:1\n'
          'zip\$zap@http://pub.dartlang.org/thing.js:1:2');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://pub.dartlang.org/stuff.js")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://pub.dartlang.org/thing.js")));
    });

    test('parses a package:stack_trace stack trace correctly', () {
      var trace = new Trace.parse(
          'http://dartlang.org/foo/bar.dart 10:11  Foo.<fn>.bar\n'
          'http://dartlang.org/foo/baz.dart        Foo.<fn>.bar');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://dartlang.org/foo/baz.dart")));
    });

    test('parses a package:stack_trace stack chain correctly', () {
      var trace = new Trace.parse(
          'http://dartlang.org/foo/bar.dart 10:11  Foo.<fn>.bar\n'
          'http://dartlang.org/foo/baz.dart        Foo.<fn>.bar\n'
          '===== asynchronous gap ===========================\n'
          'http://dartlang.org/foo/bang.dart 10:11  Foo.<fn>.bar\n'
          'http://dartlang.org/foo/quux.dart        Foo.<fn>.bar');

      expect(trace.frames[0].uri,
          equals(Uri.parse("http://dartlang.org/foo/bar.dart")));
      expect(trace.frames[1].uri,
          equals(Uri.parse("http://dartlang.org/foo/baz.dart")));
      expect(trace.frames[2].uri,
          equals(Uri.parse("http://dartlang.org/foo/bang.dart")));
      expect(trace.frames[3].uri,
          equals(Uri.parse("http://dartlang.org/foo/quux.dart")));
    });

    test('parses a real package:stack_trace stack trace correctly', () {
      var traceString = new Trace.current().toString();
      expect(new Trace.parse(traceString).toString(), equals(traceString));
    });

    test('parses an empty string correctly', () {
      var trace = new Trace.parse('');
      expect(trace.frames, isEmpty);
      expect(trace.toString(), equals(''));
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

  test('.vmTrace returns a native-style trace', () {
    var uri = path.toUri(path.absolute('foo'));
    var trace = new Trace([
      new Frame(uri, 10, 20, 'Foo.<fn>'),
      new Frame(Uri.parse('http://dartlang.org/foo.dart'), null, null, 'bar'),
      new Frame(Uri.parse('dart:async'), 15, null, 'baz'),
    ]);

    expect(trace.vmTrace.toString(), equals(
        '#1      Foo.<anonymous closure> ($uri:10:20)\n'
        '#2      bar (http://dartlang.org/foo.dart:0:0)\n'
        '#3      baz (dart:async:15:0)\n'));
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
