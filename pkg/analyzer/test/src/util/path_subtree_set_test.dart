// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/path_subtree_set.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathSubtreeSetPosixTest);
    defineReflectiveTests(PathSubtreeSetWindowsTest);
  });
}

@reflectiveTest
class PathSubtreeSetPosixTest {
  final Context context = Context(style: Style.posix);

  void test_add() {
    var set = PathSubtreeSet(context, []);
    expect(set.containsSelfOrAncestor('/a/b/c.dart'), isFalse);

    set.add('/a/b');
    expect(set.containsSelfOrAncestor('/a/b/c.dart'), isTrue);
    expect(set.containsSelfOrAncestor('/a/c.dart'), isFalse);
  }

  void test_ancestor() {
    var set = PathSubtreeSet(context, ['/a/b']);
    expect(set.containsSelfOrAncestor('/a/b/c.dart'), isTrue);
    expect(set.containsSelfOrAncestor('/a/b/c/d/e.dart'), isTrue);
  }

  void test_case() {
    var set = PathSubtreeSet(context, ['/a/b']);
    expect(set.containsSelfOrAncestor('/A/b/c.dart'), isFalse);
    expect(set.containsSelfOrAncestor('/a/B/c.dart'), isFalse);
  }

  void test_descendant() {
    var set = PathSubtreeSet(context, ['/a/b/c']);
    expect(set.containsSelfOrAncestor('/a/b'), isFalse);
    expect(set.containsSelfOrAncestor('/a'), isFalse);
    expect(set.containsSelfOrAncestor('/'), isFalse);
  }

  void test_empty() {
    var set = PathSubtreeSet(context, []);
    expect(set.containsSelfOrAncestor('/a/b.dart'), isFalse);
  }

  void test_fileSystemRoot() {
    var set = PathSubtreeSet(context, ['/']);
    expect(set.containsSelfOrAncestor('/'), isTrue);
    expect(set.containsSelfOrAncestor('/a'), isTrue);
    expect(set.containsSelfOrAncestor('/a/b.dart'), isTrue);
  }

  void test_manyRoots() {
    var set = PathSubtreeSet(context, ['/a/x', '/a/y', '/b']);
    expect(set.containsSelfOrAncestor('/a/x/c.dart'), isTrue);
    expect(set.containsSelfOrAncestor('/a/y/c.dart'), isTrue);
    expect(set.containsSelfOrAncestor('/b/c.dart'), isTrue);
    expect(set.containsSelfOrAncestor('/a/z/c.dart'), isFalse);
    expect(set.containsSelfOrAncestor('/a/c.dart'), isFalse);
  }

  void test_self() {
    var set = PathSubtreeSet(context, ['/a/b.dart']);
    expect(set.containsSelfOrAncestor('/a/b.dart'), isTrue);
  }

  void test_sibling_sameNamePrefix() {
    var set = PathSubtreeSet(context, ['/a/b']);
    expect(set.containsSelfOrAncestor('/a/bc'), isFalse);
    expect(set.containsSelfOrAncestor('/a/bc/d.dart'), isFalse);
    expect(set.containsSelfOrAncestor('/a/b.dart'), isFalse);
  }
}

@reflectiveTest
class PathSubtreeSetWindowsTest {
  final Context context = Context(style: Style.windows);

  void test_ancestor() {
    var set = PathSubtreeSet(context, [r'C:\a\b']);
    expect(set.containsSelfOrAncestor(r'C:\a\b\c.dart'), isTrue);
    expect(set.containsSelfOrAncestor(r'C:\a\b\c\d\e.dart'), isTrue);
  }

  void test_case_asciiLetters() {
    var set = PathSubtreeSet(context, [r'C:\a\B']);
    expect(set.containsSelfOrAncestor(r'c:\a\b\c.dart'), isTrue);
    expect(set.containsSelfOrAncestor(r'C:\A\B\c.dart'), isTrue);
  }

  void test_case_otherLetters() {
    var set = PathSubtreeSet(context, ['C:\\a\\\u00C4']);
    expect(set.containsSelfOrAncestor('C:\\a\\\u00C4\\c.dart'), isTrue);
    expect(set.containsSelfOrAncestor('C:\\a\\\u00E4\\c.dart'), isFalse);
  }

  void test_descendant() {
    var set = PathSubtreeSet(context, [r'C:\a\b']);
    expect(set.containsSelfOrAncestor(r'C:\a'), isFalse);
    expect(set.containsSelfOrAncestor(r'C:\'), isFalse);
  }

  void test_drive() {
    var set = PathSubtreeSet(context, [r'C:\a']);
    expect(set.containsSelfOrAncestor(r'D:\a\b.dart'), isFalse);
  }

  void test_driveRoot() {
    var set = PathSubtreeSet(context, [r'C:\']);
    expect(set.containsSelfOrAncestor(r'C:\'), isTrue);
    expect(set.containsSelfOrAncestor(r'c:\a\b.dart'), isTrue);
    expect(set.containsSelfOrAncestor(r'D:\a\b.dart'), isFalse);
  }

  void test_sibling_sameNamePrefix() {
    var set = PathSubtreeSet(context, [r'C:\a\b']);
    expect(set.containsSelfOrAncestor(r'C:\a\bc\d.dart'), isFalse);
  }

  void test_unc() {
    var set = PathSubtreeSet(context, [r'\\server\share\a']);
    expect(set.containsSelfOrAncestor(r'\\server\share\a\b.dart'), isTrue);
    expect(set.containsSelfOrAncestor(r'\\SERVER\Share\a\b.dart'), isTrue);
    expect(set.containsSelfOrAncestor(r'\\server\other\a\b.dart'), isFalse);
  }

  void test_uncRoot() {
    var set = PathSubtreeSet(context, [r'\\server\share']);
    expect(set.containsSelfOrAncestor(r'\\server\share\a\b.dart'), isTrue);
    expect(set.containsSelfOrAncestor(r'\\server\other\a\b.dart'), isFalse);
  }
}
