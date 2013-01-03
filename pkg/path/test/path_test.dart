// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library all_test;

import 'dart:io' as io;

import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as path;

main() {
  group('path.Style', () {
    test('name', () {
      expect(path.Style.posix.name, 'posix');
      expect(path.Style.windows.name, 'windows');
    });

    test('separator', () {
      expect(path.Style.posix.separator, '/');
      expect(path.Style.windows.separator, '\\');
    });

    test('toString()', () {
      expect(path.Style.posix.toString(), 'posix');
      expect(path.Style.windows.toString(), 'windows');
    });
  });

  group('new Builder()', () {
    test('uses the given root directory', () {
      var builder = new path.Builder(root: '/a/b/c');
      expect(builder.root, '/a/b/c');
    });

    test('uses the given style', () {
      var builder = new path.Builder(style: path.Style.windows);
      expect(builder.style, path.Style.windows);
    });

    test('uses the current working directory if root is omitted', () {
      var builder = new path.Builder();
      expect(builder.root, new io.Directory.current().path);
    });

    test('uses the host OS if style is omitted', () {
      var builder = new path.Builder();
      if (io.Platform.operatingSystem == 'windows') {
        expect(builder.style, path.Style.windows);
      } else {
        expect(builder.style, path.Style.posix);
      }
    });
  });

  test('current', () {
    expect(path.current, new io.Directory.current().path);
  });
}
