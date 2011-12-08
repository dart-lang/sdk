// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests for dartdoc.
#library('dartdoc_tests');

#import('../dartdoc.dart');

// TODO(rnystrom): Better path to unittest.
#import('../../../client/testing/unittest/unittest_node.dart');

main() {
  group('countOccurrences', () {
    test('empty text returns 0', () {
      expect(countOccurrences('', 'needle')).equals(0);
    });

    test('one occurrence', () {
      expect(countOccurrences('bananarama', 'nara')).equals(1);
    });

    test('multiple occurrences', () {
      expect(countOccurrences('bananarama', 'a')).equals(5);
    });

    test('overlapping matches do not count', () {
      expect(countOccurrences('bananarama', 'ana')).equals(1);
    });
  });

  group('repeat', () {
    test('zero times returns an empty string', () {
      expect(repeat('ba', 0)).equals('');
    });

    test('one time returns the string', () {
      expect(repeat('ba', 1)).equals('ba');
    });

    test('multiple times', () {
      expect(repeat('ba', 3)).equals('bababa');
    });

    test('multiple times with a separator', () {
      expect(repeat('ba', 3, separator: ' ')).equals('ba ba ba');
    });
  });

  group('relativePath', () {
    test('from root to root', () {
      startFile('root.html');
      expect(relativePath('other.html')).equals('other.html');
    });

    test('from root to directory', () {
      startFile('root.html');
      expect(relativePath('dir/file.html')).equals('dir/file.html');
    });

    test('from root to nested', () {
      startFile('root.html');
      expect(relativePath('dir/sub/file.html')).equals('dir/sub/file.html');
    });

    test('from directory to root', () {
      startFile('dir/file.html');
      expect(relativePath('root.html')).equals('../root.html');
    });

    test('from nested to root', () {
      startFile('dir/sub/file.html');
      expect(relativePath('root.html')).equals('../../root.html');
    });

    test('from dir to dir with different path', () {
      startFile('dir/file.html');
      expect(relativePath('other/file.html')).equals('../other/file.html');
    });

    test('from nested to nested with different path', () {
      startFile('dir/sub/file.html');
      expect(relativePath('other/sub/file.html')).equals(
          '../../other/sub/file.html');
    });

    test('from nested to directory with different path', () {
      startFile('dir/sub/file.html');
      expect(relativePath('other/file.html')).equals(
          '../../other/file.html');
    });
  });
}
