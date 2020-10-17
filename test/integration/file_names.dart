// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('file_names', () {
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

    test('bad', () async {
      await cli.run(['test/_data/file_names/a-b.dart', '--rules=file_names']);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'a-b.dart 1:1 [lint] Name source files using `lowercase_with_underscores`.'
          ]));
      expect(exitCode, 1);
    });

    test('ok', () async {
      await cli.run(
          ['test/_data/file_names/non-strict.css.dart', '--rules=file_names']);
      expect(exitCode, 0);
    });
  });
}
