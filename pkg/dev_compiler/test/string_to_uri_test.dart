// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dev_compiler/src/command/command.dart';
import 'package:test/test.dart';

void main(List<String> args) {
  late String currentDir;
  setUpAll(() {
    currentDir = Directory.current.path.replaceAll(r'\', r'/');
    if (!currentDir.startsWith(r'/')) currentDir = '/$currentDir';
  });

  group('sourcePathToUri', () {
    test('various URL schemes', () {
      expect(sourcePathToUri('dart:io').toString(), 'dart:io');
      expect(sourcePathToUri('package:expect/expect.dart').toString(),
          'package:expect/expect.dart');
      expect(sourcePathToUri('foobar:whatnot').toString(), 'foobar:whatnot');
    });

    test('full Windows path', () {
      expect(
          sourcePathToUri('C:\\full\\windows\\path.foo', windows: true)
              .toString(),
          'file:///C:/full/windows/path.foo');
      expect(
          sourcePathToUri('C:/full/windows/path.foo', windows: true).toString(),
          'file:///C:/full/windows/path.foo');
    });

    test('relative Windows path', () {
      expect(
          sourcePathToUri('partial\\windows\\path.foo', windows: true)
              .toString(),
          'file://$currentDir/partial/windows/path.foo');
    });

    test('full unix path', () {
      expect(
          sourcePathToUri('/full/path/to/foo.bar', windows: false).toString(),
          'file:///full/path/to/foo.bar');
    });

    test('relative unix path', () {
      expect(
          sourcePathToUri('partial/path/to/foo.bar', windows: false).toString(),
          'file://$currentDir/partial/path/to/foo.bar');
    });
  });

  group('sourcePathToRelativeUri', () {
    test('various URL schemes', () {
      expect(sourcePathToRelativeUri('dart:io').toString(), 'dart:io');
      expect(sourcePathToRelativeUri('package:expect/expect.dart').toString(),
          'package:expect/expect.dart');
      expect(sourcePathToRelativeUri('foobar:whatnot').toString(),
          'foobar:whatnot');
    });

    test('full Windows path', () {
      expect(
          sourcePathToRelativeUri('C:\\full\\windows\\path.foo', windows: true)
              .toString(),
          'file:///C:/full/windows/path.foo');
      expect(
          sourcePathToRelativeUri('C:/full/windows/path.foo', windows: true)
              .toString(),
          'file:///C:/full/windows/path.foo');
    });

    test('relative Windows path', () {
      expect(
          sourcePathToRelativeUri('partial\\windows\\path.foo', windows: true)
              .toString(),
          'partial/windows/path.foo');
    });

    test('full unix path', () {
      expect(
          sourcePathToRelativeUri('/full/path/to/foo.bar', windows: false)
              .toString(),
          'file:///full/path/to/foo.bar');
    });

    test('relative unix path', () {
      expect(
          sourcePathToRelativeUri('partial/path/to/foo.bar', windows: false)
              .toString(),
          'partial/path/to/foo.bar');
    });
  });
}
