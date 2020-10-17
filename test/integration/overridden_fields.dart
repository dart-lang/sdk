// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('overridden_fields', () {
    final currentOut = outSink;
    final collectingOut = CollectingSink();
    setUp(() {
      exitCode = 0;
      outSink = collectingOut;
    });
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
      exitCode = 0;
    });

    // https://github.com/dart-lang/linter/issues/246
    test('overrides across libraries', () async {
      await cli.run(
          ['test/_data/overridden_fields', '--rules', 'overridden_fields']);
      expect(
          collectingOut.trim(),
          stringContainsInOrder(
              ['int public;', '2 files analyzed, 1 issue found, in']));
      expect(exitCode, 1);
    });
  });
}
