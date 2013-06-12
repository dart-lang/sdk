// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:pathos/path.dart' as path;

main() {
  useHtmlConfiguration();

  group('new Builder()', () {
    test('uses the current working directory if root is omitted', () {
      var builder = new path.Builder();
      expect(builder.root, window.location.href);
    });

    test('uses URL if style is omitted', () {
      var builder = new path.Builder();
      expect(builder.style, path.Style.url);
    });
  });

  test('current', () {
    expect(path.current, window.location.href);
  });
}
