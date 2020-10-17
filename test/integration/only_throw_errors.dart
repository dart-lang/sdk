// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('only_throw_errors', () {
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

    test('only throw errors', () async {
      await cli
          .run(['test/_data/only_throw_errors', '--rules=only_throw_errors']);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "throw 'hello world!'; // LINT",
            'throw null; // LINT',
            'throw 7; // LINT',
            'throw new Object(); // LINT',
            'throw returnString(); // LINT',
            '1 file analyzed, 5 issues found, in'
          ]));
      expect(exitCode, 1);
    });
  });
}
