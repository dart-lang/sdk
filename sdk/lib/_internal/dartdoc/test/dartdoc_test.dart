// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests for doc.
library dartdocTests;

// TODO(rnystrom): Use "package:" URL (#4968).
import '../lib/dartdoc.dart' as dd;
import '../lib/markdown.dart' as md;

// TODO(rnystrom): Better path to unittest.
import '../../../pkg/unittest/lib/unittest.dart';

main() {
  group('countOccurrences', () {
    test('empty text returns 0', () {
      expect(dd.countOccurrences('', 'needle'), equals(0));
    });

    test('one occurrence', () {
      expect(dd.countOccurrences('bananarama', 'nara'), equals(1));
    });

    test('multiple occurrences', () {
      expect(dd.countOccurrences('bananarama', 'a'), equals(5));
    });

    test('overlapping matches do not count', () {
      expect(dd.countOccurrences('bananarama', 'ana'), equals(1));
    });
  });

  group('repeat', () {
    test('zero times returns an empty string', () {
      expect(dd.repeat('ba', 0), isEmpty);
    });

    test('one time returns the string', () {
      expect(dd.repeat('ba', 1), equals('ba'));
    });

    test('multiple times', () {
      expect(dd.repeat('ba', 3), equals('bababa'));
    });

    test('multiple times with a separator', () {
      expect(dd.repeat('ba', 3, separator: ' '), equals('ba ba ba'));
    });
  });

  group('isAbsolute', () {
    final doc = new dd.Dartdoc();

    test('returns false if there is no scheme', () {
      expect(doc.isAbsolute('index.html'), isFalse);
      expect(doc.isAbsolute('foo/index.html'), isFalse);
      expect(doc.isAbsolute('foo/bar/index.html'), isFalse);
    });

    test('returns true if there is a scheme', () {
      expect(doc.isAbsolute('http://google.com'), isTrue);
      expect(doc.isAbsolute('hTtPs://google.com'), isTrue);
      expect(doc.isAbsolute('mailto:fake@email.com'), isTrue);
    });
  });

  group('relativePath', () {
    final doc = new dd.Dartdoc();

    test('absolute path is unchanged', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('http://foo.com'), equals('http://foo.com'));
    });

    test('from root to root', () {
      doc.startFile('root.html');
      expect(doc.relativePath('other.html'), equals('other.html'));
    });

    test('from root to directory', () {
      doc.startFile('root.html');
      expect(doc.relativePath('dir/file.html'), equals('dir/file.html'));
    });

    test('from root to nested', () {
      doc.startFile('root.html');
      expect(doc.relativePath('dir/sub/file.html'), equals(
          'dir/sub/file.html'));
    });

    test('from directory to root', () {
      doc.startFile('dir/file.html');
      expect(doc.relativePath('root.html'), equals('../root.html'));
    });

    test('from nested to root', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('root.html'), equals('../../root.html'));
    });

    test('from dir to dir with different path', () {
      doc.startFile('dir/file.html');
      expect(doc.relativePath('other/file.html'), equals('../other/file.html'));
    });

    test('from nested to nested with different path', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('other/sub/file.html'), equals(
          '../../other/sub/file.html'));
    });

    test('from nested to directory with different path', () {
      doc.startFile('dir/sub/file.html');
      expect(doc.relativePath('other/file.html'), equals(
          '../../other/file.html'));
    });
  });
}
