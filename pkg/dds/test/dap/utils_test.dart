// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/src/dap/utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

main() {
  group('isResolvableUri', () {
    test('false for files', () async {
      expect(isResolvableUri(Uri.parse('file:///foo/bar.dart')), isFalse);
      expect(isResolvableUri(Uri.parse('file:///c:/foo/bar.dart')), isFalse);
    });
    test('false for http(s)', () async {
      expect(isResolvableUri(Uri.parse('http://example.org')), isFalse);
      expect(isResolvableUri(Uri.parse('https://example.org')), isFalse);
    });
    test('true for dart:foo', () async {
      expect(isResolvableUri(Uri.parse('dart:async')), isTrue);
      expect(isResolvableUri(Uri.parse('dart:async/foo')), isTrue);
    });
    test('true for package:foo', () async {
      expect(isResolvableUri(Uri.parse('package:foo')), isTrue);
      expect(isResolvableUri(Uri.parse('package:foo/foo')), isTrue);
    });
    test('false for foo:', () async {
      expect(isResolvableUri(Uri.parse('foo:')), isFalse);
    });
  });

  group('parseDartStackFrame', () {
    void expectFrames(
      List<String> inputs,
      Uri uri, [
      int? line,
      int? col,
    ]) {
      for (var input in inputs) {
        var frame = parseDartStackFrame(input);
        expect(frame, isNotNull, reason: 'Failed to parse "$input"');
        expect(frame!.uri, uri, reason: 'Failed to parse URI from "$input"');
        expect(frame.line, line, reason: 'Failed to parse line from "$input"');
        expect(frame.column, col, reason: 'Failed to parse col from "$input"');
      }
    }

    test('returns null for non-stack frames', () {
      expect(parseDartStackFrame(''), isNull);
      expect(parseDartStackFrame('1'), isNull);
      expect(parseDartStackFrame('test'), isNull);
      expect(parseDartStackFrame('foo.dart2'), isNull);
      expect(parseDartStackFrame('foo.darty'), isNull);
      expect(parseDartStackFrame('.dart'), isNull);
    });

    group('package URIs', () {
      test('without line/col', () {
        expectFrames(
          [
            'package:foo/bar/baz.dart',
            '(package:foo/bar/baz.dart)',
            'package:foo/bar/baz.dart',
            '#1        package:foo/bar/baz.dart',
            '#1        package:foo/bar/baz.dart 1 2 3 4 5',
            '#1        A.b (package:foo/bar/baz.dart) 123',
            'flutter: #1        A.b (package:foo/bar/baz.dart)',
          ],
          Uri.parse('package:foo/bar/baz.dart'),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            '(package:foo/bar/baz.dart:1:2)',
            '#1        package:foo/bar/baz.dart:1:2',
            '#1        package:foo/bar/baz.dart:1:2 1 2 3 4 5',
            '#1        A.b (package:foo/bar/baz.dart:1:2) 123',
            'flutter: #1        A.b (package:foo/bar/baz.dart:1:2)',
            '(package:foo/bar/baz.dart 1:2)',
            '#1        package:foo/bar/baz.dart 1:2',
            '#1        package:foo/bar/baz.dart 1:2 1 2 3 4 5',
            '#1        A.b (package:foo/bar/baz.dart 1:2) 123',
            'flutter: #1        A.b (package:foo/bar/baz.dart     1:2)',
          ],
          Uri.parse('package:foo/bar/baz.dart'),
          1,
          2,
        );
      });
    });

    group('dart URIs', () {
      test('without line/col', () {
        expectFrames(
          [
            '#1      _delayEntrypointInvocation.<anonymous closure> (dart:isolate-patch/isolate_patch.dart)',
          ],
          Uri.parse('dart:isolate-patch/isolate_patch.dart'),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            '#1      _delayEntrypointInvocation.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:1:2)',
            '#1      _delayEntrypointInvocation.<anonymous closure> (dart:isolate-patch/isolate_patch.dart 1:2)',
          ],
          Uri.parse('dart:isolate-patch/isolate_patch.dart'),
          1,
          2,
        );
      });
    });

    group('Posix file URIs', () {
      test('without line/col', () {
        expectFrames(
          [
            '#1        A.b (file:///a/b/c/d.dart)',
            'flutter: #1        A.b (file:///a/b/c/d.dart)',
          ],
          Uri.parse('file:///a/b/c/d.dart'),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            '#1        A.b (file:///a/b/c/d.dart:1:2)',
            'flutter: #1        A.b (file:///a/b/c/d.dart:1:2)',
            'flutter: #1        A.b (file:///a/b/c/d.dart   1:2)',
          ],
          Uri.parse('file:///a/b/c/d.dart'),
          1,
          2,
        );
      });
    });

    group('Posix dart-macro+file URIs', () {
      test('without line/col', () {
        expectFrames(
          [
            '#1        A.b (dart-macro+file:///a/b/c/d.dart)',
            'flutter: #1        A.b (dart-macro+file:///a/b/c/d.dart)',
          ],
          Uri.parse('dart-macro+file:///a/b/c/d.dart'),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            '#1        A.b (dart-macro+file:///a/b/c/d.dart:1:2)',
            'flutter: #1        A.b (dart-macro+file:///a/b/c/d.dart:1:2)',
          ],
          Uri.parse('dart-macro+file:///a/b/c/d.dart'),
          1,
          2,
        );
      });
    });

    group('Posix relative paths', () {
      test('without line/col', () {
        expectFrames(
          [
            'foo       a/b/c/d.dart',
            '#1        A.b (a/b/c/d.dart)',
            'flutter: #1        A.b (a/b/c/d.dart)',
          ],
          Uri.file(path.join(Directory.current.path, 'a/b/c/d.dart')),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            'foo       a/b/c/d.dart:1:2',
            '#1        A.b (a/b/c/d.dart:1:2)',
            'flutter: #1        A.b (a/b/c/d.dart:1:2)',
            'flutter: #1        A.b (a/b/c/d.dart   1:2)',
          ],
          Uri.file(path.join(Directory.current.path, 'a/b/c/d.dart')),
          1,
          2,
        );
      });

      test('with dots in path', () {
        expectFrames(
          [
            'foo       a.b.c/d.dart',
            '#1        A.b (a.b.c/d.dart)',
            'flutter: #1        A.b (a.b.c/d.dart)',
          ],
          Uri.file(path.join(Directory.current.path, 'a.b.c/d.dart')),
        );
      });
    }, skip: Platform.isWindows);

    group('Windows file URIs', () {
      test('without line/col', () {
        expectFrames(
          [
            '#1        A.b (file:///a:/b/c/d.dart)',
            'flutter: #1        A.b (file:///a:/b/c/d.dart)',
          ],
          Uri.parse('file:///a:/b/c/d.dart'),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            '#1        A.b (file:///a:/b/c/d.dart:1:2)',
            'flutter: #1        A.b (file:///a:/b/c/d.dart:1:2)',
          ],
          Uri.parse('file:///a:/b/c/d.dart'),
          1,
          2,
        );
      });
    });

    group('Windows dart-macro+file URIs', () {
      test('without line/col', () {
        expectFrames(
          [
            '#1        A.b (dart-macro+file:///a:/b/c/d.dart)',
            'flutter: #1        A.b (dart-macro+file:///a:/b/c/d.dart)',
          ],
          Uri.parse('dart-macro+file:///a:/b/c/d.dart'),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            '#1        A.b (dart-macro+file:///a:/b/c/d.dart:1:2)',
            'flutter: #1        A.b (dart-macro+file:///a:/b/c/d.dart:1:2)',
          ],
          Uri.parse('dart-macro+file:///a:/b/c/d.dart'),
          1,
          2,
        );
      });
    });

    group('Windows relative paths', () {
      test('without line/col', () {
        expectFrames(
          [
            r'foo       a\b\c\d.dart',
            r'#1        A.b (a\b\c\d.dart)',
            r'flutter: #1        A.b (a\b\c\d.dart)',
          ],
          Uri.file(path.join(Directory.current.path, 'a/b/c/d.dart')),
        );
      });

      test('with line/col', () {
        expectFrames(
          [
            r'foo       a\b\c\d.dart:1:2',
            r'#1        A.b (a\b\c\d.dart:1:2)',
            r'flutter: #1        A.b (a\b\c\d.dart:1:2)',
            r'flutter: #1        A.b (a\b\c\d.dart   1:2)',
          ],
          Uri.file(path.join(Directory.current.path, 'a/b/c/d.dart')),
          1,
          2,
        );
      });

      test('with dots in path', () {
        expectFrames(
          [
            r'foo       a.b.c\d.dart',
            r'#1        A.b (a.b.c\d.dart)',
            r'flutter: #1        A.b (a.b.c\d.dart)',
          ],
          Uri.file(path.join(Directory.current.path, 'a.b.c/d.dart')),
        );
      });
    }, skip: !Platform.isWindows);
  });
}
