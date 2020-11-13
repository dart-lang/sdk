// @dart = 2.9

import 'dart:io';
import 'package:dev_compiler/src/compiler/shared_command.dart';
import 'package:test/test.dart';

void main(List<String> args) {
  String currentDir;
  setUpAll(() {
    currentDir = Directory.current.path.replaceAll(r'\', r'/');
    if (!currentDir.startsWith(r'/')) currentDir = '/$currentDir';
  });

  group('sourcePathToUri', () {
    test('various URL schemes', () {
      expect(sourcePathToUri('dart:io').toString(), 'dart:io');
      expect(sourcePathToUri('package:expect/minitest.dart').toString(),
          'package:expect/minitest.dart');
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
      expect(sourcePathToRelativeUri('package:expect/minitest.dart').toString(),
          'package:expect/minitest.dart');
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
