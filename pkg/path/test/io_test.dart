// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as path;

main() {
  group('new Builder()', () {
    test('uses the current working directory if root is omitted', () {
      var builder = new path.Builder();
      expect(builder.root, io.Directory.current.path);
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
    expect(path.current, io.Directory.current.path);
  });
}
