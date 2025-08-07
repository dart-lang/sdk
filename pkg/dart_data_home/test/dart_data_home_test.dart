// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_data_home/dart_data_home.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('returns a non-empty string', () {
    final myAppHome = getDartDataHome('my_app');
    expect(myAppHome, isNotEmpty);
  });

  test('has an ancestor folder that exists', () {
    void expectAncestorExists(String path) {
      // We expect that first two segments of the path exist. This is really
      // just a dummy check that some part of the path exists.
      final ancestorPath = p.joinAll(p.split(path).take(2));
      expect(Directory(ancestorPath).existsSync(), isTrue);
    }

    final myAppHome = getDartDataHome('my_app');
    expectAncestorExists(myAppHome);
  });

  test('empty environment throws exception', () async {
    expect(
      () => getDartDataHome('some_app', environment: <String, String>{}),
      throwsA(isA<Exception>()),
    );
  });
}
