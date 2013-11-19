// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as path;

main() {
  group('new Context()', () {
    test('uses the current directory if root and style are omitted', () {
      var context = new path.Context();
      expect(context.current, io.Directory.current.path);
    });

    test('uses "." if root is omitted', () {
      var context = new path.Context(style: path.Style.platform);
      expect(context.current, ".");
    });

    test('uses the host platform if style is omitted', () {
      var context = new path.Context();
      expect(context.style, path.Style.platform);
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

  test('registers changes to the working directory', () {
    var dir = io.Directory.current.path;
    try {
      expect(path.absolute('foo/bar'), equals(path.join(dir, 'foo/bar')));

      io.Directory.current = path.dirname(dir);
      expect(path.normalize(path.absolute('foo/bar')),
          equals(path.normalize(path.join(dir, '../foo/bar'))));
    } finally {
      io.Directory.current = dir;
    }
  });
}
