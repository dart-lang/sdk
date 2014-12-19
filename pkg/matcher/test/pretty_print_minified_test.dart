// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is for pretty-print tests that rely on the names of various Dart
// types. These tests normally fail when run in minified dart2js, since the
// names will be mangled. This version of the file is modified to expect
// minified names.

library matcher.print_minified_test;

import 'dart:collection';

import 'package:matcher/matcher.dart';
import 'package:matcher/src/pretty_print.dart';
import 'package:unittest/unittest.dart' show test, group;

class DefaultToString {}

class CustomToString {
  String toString() => "string representation";
}

class _PrivateName {
  String toString() => "string representation";
}

class _PrivateNameIterable extends IterableMixin {
  Iterator get iterator => [1, 2, 3].iterator;
}

// A regexp fragment matching a minified name.
final _minifiedName = r"[A-Za-z0-9]{1,3}";

void main() {
  group('with an object', () {
    test('with a default [toString]', () {
      expect(prettyPrint(new DefaultToString()),
          matches(r"<Instance of '" + _minifiedName + r"'>"));
    });

    test('with a custom [toString]', () {
      expect(prettyPrint(new CustomToString()),
          matches(_minifiedName + r':<string representation>'));
    });

    test('with a custom [toString] and a private name', () {
      expect(prettyPrint(new _PrivateName()),
          matches(_minifiedName + r':<string representation>'));
    });
  });

  group('with an iterable', () {
    test("that's not a list", () {
      expect(prettyPrint([1, 2, 3, 4].map((n) => n * 2)),
          matches(_minifiedName + r":\[2, 4, 6, 8\]"));
    });

    test("that's not a list and has a private name", () {
      expect(prettyPrint(new _PrivateNameIterable()),
          matches(_minifiedName + r":\[1, 2, 3\]"));
    });
  });
}
