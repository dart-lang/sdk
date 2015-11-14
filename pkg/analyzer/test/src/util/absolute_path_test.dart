// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analyzer.src.util.absolute_path;

import 'package:analyzer/src/util/absolute_path.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(AbsolutePathContextPosixTest);
  runReflectiveTests(AbsolutePathContextWindowsTest);
}

@reflectiveTest
class AbsolutePathContextPosixTest {
  AbsolutePathContext context = new AbsolutePathContext(r'/');

  void test_append() {
    expect(context.append(r'/path/to', r'foo.dart'), r'/path/to/foo.dart');
  }

  void test_basename() {
    expect(context.basename(r'/path/to/foo.dart'), r'foo.dart');
    expect(context.basename(r'/path/to'), r'to');
    expect(context.basename(r'/path'), r'path');
    expect(context.basename(r'/'), r'');
  }

  void test_dirname() {
    expect(context.dirname(r'/path/to/foo.dart'), r'/path/to');
    expect(context.dirname(r'/path/to'), r'/path');
    expect(context.dirname(r'/path'), r'/');
    expect(context.dirname(r'/'), r'/');
  }

  void test_isWithin() {
    expect(context.isWithin(r'/root/path', r'/root/path/a'), isTrue);
    expect(context.isWithin(r'/root/path', r'/root/other'), isFalse);
    expect(context.isWithin(r'/root/path', r'/root/path'), isFalse);
  }

  void test_split() {
    expect(context.split(r'/path/to/foo'), [r'', r'path', r'to', r'foo']);
    expect(context.split(r'/path'), [r'', r'path']);
  }

  void test_suffix() {
    expect(context.suffix(r'/root/path/a/b.dart', r'/root/path'), r'a/b.dart');
    expect(context.suffix(r'/root/other.dart', r'/root/path'), isNull);
  }
}

@reflectiveTest
class AbsolutePathContextWindowsTest {
  AbsolutePathContext context = new AbsolutePathContext(r'\');

  void test_append() {
    expect(context.append(r'C:\path\to', r'foo.dart'), r'C:\path\to\foo.dart');
  }

  void test_basename() {
    expect(context.basename(r'C:\path\to\foo.dart'), r'foo.dart');
    expect(context.basename(r'C:\path\to'), r'to');
    expect(context.basename(r'C:\path'), r'path');
    expect(context.basename(r'C:\'), r'');
  }

  void test_dirname() {
    expect(context.dirname(r'C:\path\to\foo.dart'), r'C:\path\to');
    expect(context.dirname(r'C:\path\to'), r'C:\path');
    expect(context.dirname(r'C:\path'), r'C:\');
    expect(context.dirname(r'C:\'), r'C:\');
  }

  void test_isWithin() {
    expect(context.isWithin(r'C:\root\path', r'C:\root\path\a'), isTrue);
    expect(context.isWithin(r'C:\root\path', r'C:\root\other'), isFalse);
    expect(context.isWithin(r'C:\root\path', r'C:\root\path'), isFalse);
  }

  void test_split() {
    expect(context.split(r'C:\path\to\foo'), [r'C:', r'path', r'to', r'foo']);
    expect(context.split(r'C:\path'), [r'C:', r'path']);
  }

  void test_suffix() {
    expect(
        context.suffix(r'C:\root\path\a\b.dart', r'C:\root\path'), r'a\b.dart');
    expect(context.suffix(r'C:\root\other.dart', r'C:\root\path'), isNull);
  }
}
