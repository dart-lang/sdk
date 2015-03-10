// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.integration;

import 'package:analyzer/src/generated/error.dart';
import 'package:linter/src/formatter.dart';
import 'package:linter/src/linter.dart';
import 'package:mockito/mockito.dart';
import 'package:unittest/unittest.dart';

import '../bin/linter.dart' as dartlint;
import 'mocks.dart';
import 'package:linter/src/io.dart';
import 'dart:io';

main() {
  groupSep = ' | ';

  defineTests();
}

defineTests() {
  group('integration', () {
    group('p2', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() => outSink = collectingOut);
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
      });
      group('config', () {
        test('excludes', () {
          dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig.yaml']);
          expect(collectingOut.trim(),
              endsWith('4 files analyzed, 1 issue found (2 filtered).'));
        });
        test('overrrides', () {
          dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig2.yaml']);
          expect(collectingOut.trim(),
              endsWith('4 files analyzed, 0 issues found.'));
        });
      });
    });
  });
}
