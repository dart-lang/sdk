// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.path_filter_test;

import 'package:analyzer/source/path_filter.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

main() {
  String root(String path) => context.absolute(context.normalize(path));
  group('PathFilterTest', () {
    setUp(() {});
    tearDown(() {});
    test('test_ignoreEverything', () {
      var filter = new PathFilter(root('/'), ['*'], context);
      expect(filter.ignored('a'), isTrue);
    });
    test('test_ignoreFile', () {
      var filter = new PathFilter(root('/'), ['apple'], context);
      expect(filter.ignored('apple'), isTrue);
      expect(filter.ignored('banana'), isFalse);
    });
    test('test_ignoreMultipleFiles', () {
      var filter = new PathFilter(root('/'), ['apple', 'banana'], context);
      expect(filter.ignored('apple'), isTrue);
      expect(filter.ignored('banana'), isTrue);
    });
    test('test_ignoreSubDir', () {
      var filter = new PathFilter(root('/'), ['apple/*'], context);
      expect(filter.ignored('apple/banana'), isTrue);
      expect(filter.ignored('apple/banana/cantaloupe'), isFalse);
    });
    test('test_ignoreTree', () {
      var filter = new PathFilter(root('/'), ['apple/**'], context);
      expect(filter.ignored('apple/banana'), isTrue);
      expect(filter.ignored('apple/banana/cantaloupe'), isTrue);
    });
    test('test_ignoreSdkExt', () {
      var filter = new PathFilter(root('/'), ['sdk_ext/**'], context);
      expect(filter.ignored('sdk_ext/entry.dart'), isTrue);
      expect(filter.ignored('sdk_ext/lib/src/part.dart'), isTrue);
    });
    test('test_outsideRoot', () {
      var filter =
          new PathFilter(root('/workspace/dart/sdk'), ['sdk_ext/**'], context);
      expect(filter.ignored('/'), isTrue);
      expect(filter.ignored('/workspace'), isTrue);
      expect(filter.ignored('/workspace/dart'), isTrue);
      expect(filter.ignored('/workspace/dart/sdk'), isFalse);
      expect(filter.ignored('/workspace/dart/../dart/sdk'), isFalse);
    });
    test('test_relativePaths', () {
      var filter =
          new PathFilter(root('/workspace/dart/sdk'), ['sdk_ext/**'], context);
      expect(filter.ignored('../apple'), isTrue);
      expect(filter.ignored('../sdk/main.dart'), isFalse);
      expect(filter.ignored('../sdk/sdk_ext/entry.dart'), isTrue);
    });
  });
}
