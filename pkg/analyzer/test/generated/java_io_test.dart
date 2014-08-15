// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.java_io_test;

import 'package:analyzer/src/generated/java_io.dart';
import 'package:unittest/unittest.dart';
import 'package:path/path.dart';
import 'dart:io';

main() {
  group('JavaFile', () {
    group('toURI', () {
      test('forAbsolute', () {
        var tempDir = Directory.systemTemp.createTempSync('java_io_test');
        try {
          String tempPath = normalize(absolute(tempDir.path));
          String path = join(tempPath, 'foo.dart');
          // we use an absolute path
          expect(isAbsolute(path), isTrue);
          // test that toURI() returns an absolute URI
          Uri uri = new JavaFile(path).toURI();
          expect(uri.isAbsolute, isTrue);
          expect(uri.scheme, 'file');
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });
      test('forRelative', () {
        var tempDir = Directory.systemTemp.createTempSync('java_io_test');
        try {
          String tempPath = normalize(absolute(tempDir.path));
          String path = join(tempPath, 'foo.dart');
          expect(isAbsolute(path), isTrue);
          // prepare a relative path
          String relPath = relative(path);
          expect(isAbsolute(relPath), isFalse);
          // test that toURI() returns an absolute URI
          Uri uri = new JavaFile(relPath).toURI();
          expect(uri.isAbsolute, isTrue);
          expect(uri.scheme, 'file');
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });
    });
  });
}
