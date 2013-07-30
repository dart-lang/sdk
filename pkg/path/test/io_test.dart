// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as path;

main() {
  group('new Builder()', () {
    test('uses the current directory if root and style are omitted', () {
      var builder = new path.Builder();
      expect(builder.root, io.Directory.current.path);
    });

    test('uses "." if root is omitted', () {
      var builder = new path.Builder(style: path.Style.platform);
      expect(builder.root, ".");
    });

    test('uses the host platform if style is omitted', () {
      var builder = new path.Builder();
      expect(builder.style, path.Style.platform);
    });
  });

  test('Style.platform returns the host platform style', () {
    if (io.Platform.operatingSystem == 'windows') {
      expect(path.Style.platform, path.Style.windows);
    } else {
      expect(path.Style.platform, path.Style.posix);
    }
  });

  test('current', () {
    expect(path.current, io.Directory.current.path);
  });
}
