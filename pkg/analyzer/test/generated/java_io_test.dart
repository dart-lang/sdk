// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.java_io_test;

import 'package:analyzer/src/generated/java_io.dart';
import 'package:unittest/unittest.dart';

import '../utils.dart';

main() {
  initializeTestEnvironment();
  group('JavaFile', () {
    group('toURI', () {
      test('forAbsolute', () {
        String tempPath = '/temp';
        String path = JavaFile.pathContext.join(tempPath, 'foo.dart');
        // we use an absolute path
        expect(JavaFile.pathContext.isAbsolute(path), isTrue,
            reason: '"$path" is not absolute');
        // test that toURI() returns an absolute URI
        Uri uri = new JavaFile(path).toURI();
        expect(uri.isAbsolute, isTrue);
        expect(uri.scheme, 'file');
      });
      test('forRelative', () {
        String tempPath = '/temp';
        String path = JavaFile.pathContext.join(tempPath, 'foo.dart');
        expect(JavaFile.pathContext.isAbsolute(path), isTrue,
            reason: '"$path" is not absolute');
        // prepare a relative path
        // We should not check that "relPath" is actually relative -
        // it may be not on Windows, if "temp" is on other disk.
        String relPath = JavaFile.pathContext.relative(path);
        // test that toURI() returns an absolute URI
        Uri uri = new JavaFile(relPath).toURI();
        expect(uri.isAbsolute, isTrue);
        expect(uri.scheme, 'file');
      });
    });
  });
}
