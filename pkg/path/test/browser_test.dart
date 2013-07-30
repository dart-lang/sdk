// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:path/path.dart' as path;

main() {
  useHtmlConfiguration();

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

  test('Style.platform is url', () {
    expect(path.Style.platform, path.Style.url);
  });

  test('current', () {
    expect(path.current, window.location.href);
  });
}
