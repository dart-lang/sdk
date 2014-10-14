// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lock_file_test;

import 'package:unittest/unittest.dart';

import '../lib/src/ascii_tree.dart' as tree;
import '../lib/src/utils.dart';

main() {
  runningAsTest = true;

  group('tree.fromFiles', () {
    test('no files', () {
      expect(tree.fromFiles([]), equals(""));
    });

    test('up to ten files in one directory are shown', () {
      var files = [
          "dir/a.dart",
          "dir/b.dart",
          "dir/c.dart",
          "dir/d.dart",
          "dir/e.dart",
          "dir/f.dart",
          "dir/g.dart",
          "dir/h.dart",
          "dir/i.dart",
          "dir/j.dart"];
      expect(tree.fromFiles(files), equals("""
'-- dir
    |-- a.dart
    |-- b.dart
    |-- c.dart
    |-- d.dart
    |-- e.dart
    |-- f.dart
    |-- g.dart
    |-- h.dart
    |-- i.dart
    '-- j.dart
"""));
    });

    test('files are elided if there are more than ten', () {
      var files = [
          "dir/a.dart",
          "dir/b.dart",
          "dir/c.dart",
          "dir/d.dart",
          "dir/e.dart",
          "dir/f.dart",
          "dir/g.dart",
          "dir/h.dart",
          "dir/i.dart",
          "dir/j.dart",
          "dir/k.dart"];
      expect(tree.fromFiles(files), equals("""
'-- dir
    |-- a.dart
    |-- b.dart
    |-- c.dart
    | (5 more...)
    |-- i.dart
    |-- j.dart
    '-- k.dart
"""));
    });

    test('files are not elided at the top level', () {
      var files = [
          "a.dart",
          "b.dart",
          "c.dart",
          "d.dart",
          "e.dart",
          "f.dart",
          "g.dart",
          "h.dart",
          "i.dart",
          "j.dart",
          "k.dart"];
      expect(tree.fromFiles(files), equals("""
|-- a.dart
|-- b.dart
|-- c.dart
|-- d.dart
|-- e.dart
|-- f.dart
|-- g.dart
|-- h.dart
|-- i.dart
|-- j.dart
'-- k.dart
"""));
    });

    test('a complex example', () {
      var files = [
          "TODO",
          "example/console_example.dart",
          "example/main.dart",
          "example/web copy/web_example.dart",
          "test/absolute_test.dart",
          "test/basename_test.dart",
          "test/dirname_test.dart",
          "test/extension_test.dart",
          "test/is_absolute_test.dart",
          "test/is_relative_test.dart",
          "test/join_test.dart",
          "test/normalize_test.dart",
          "test/relative_test.dart",
          "test/split_test.dart",
          ".gitignore",
          "README.md",
          "lib/path.dart",
          "pubspec.yaml",
          "test/all_test.dart",
          "test/path_posix_test.dart",
          "test/path_windows_test.dart"];

      expect(tree.fromFiles(files), equals("""
|-- .gitignore
|-- README.md
|-- TODO
|-- example
|   |-- console_example.dart
|   |-- main.dart
|   '-- web copy
|       '-- web_example.dart
|-- lib
|   '-- path.dart
|-- pubspec.yaml
'-- test
    |-- absolute_test.dart
    |-- all_test.dart
    |-- basename_test.dart
    | (7 more...)
    |-- path_windows_test.dart
    |-- relative_test.dart
    '-- split_test.dart
"""));
    });
  });

  group('treeFromMap', () {
    test('empty map', () {
      expect(tree.fromMap({}), equals(""));
    });

    test('a complex example', () {
      var map = {
        ".gitignore": {},
        "README.md": {},
        "TODO": {},
        "example": {
          "console_example.dart": {},
          "main.dart": {},
          "web copy": {
            "web_example.dart": {}
          },
        },
        "lib": {
          "path.dart": {}
        },
        "pubspec.yaml": {},
        "test": {
          "absolute_test.dart": {},
          "basename_test.dart": {},
          "dirname_test.dart": {},
          "extension_test.dart": {},
          "is_absolute_test.dart": {},
          "is_relative_test.dart": {},
          "join_test.dart": {},
          "normalize_test.dart": {},
          "relative_test.dart": {},
          "split_test.dart": {}
        }
      };

      expect(tree.fromMap(map), equals("""
|-- .gitignore
|-- README.md
|-- TODO
|-- example
|   |-- console_example.dart
|   |-- main.dart
|   '-- web copy
|       '-- web_example.dart
|-- lib
|   '-- path.dart
|-- pubspec.yaml
'-- test
    |-- absolute_test.dart
    |-- basename_test.dart
    |-- dirname_test.dart
    |-- extension_test.dart
    |-- is_absolute_test.dart
    |-- is_relative_test.dart
    |-- join_test.dart
    |-- normalize_test.dart
    |-- relative_test.dart
    '-- split_test.dart
"""));
    });
  });

  test('does not elide children if showAllChildren is true', () {
    var map = {
      'dir': {
        'a.dart': {},
        'b.dart': {},
        'c.dart': {},
        'd.dart': {},
        'e.dart': {},
        'f.dart': {},
        'g.dart': {},
        'h.dart': {},
        'i.dart': {},
        'j.dart': {},
        'k.dart': {},
        'l.dart': {},
      }
    };
    expect(tree.fromMap(map, showAllChildren: true), equals("""
'-- dir
    |-- a.dart
    |-- b.dart
    |-- c.dart
    |-- d.dart
    |-- e.dart
    |-- f.dart
    |-- g.dart
    |-- h.dart
    |-- i.dart
    |-- j.dart
    |-- k.dart
    '-- l.dart
"""));
  });

}
