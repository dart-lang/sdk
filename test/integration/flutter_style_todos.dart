// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('flutter_style_todos', () {
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

    test('on bad TODOs', () async {
      await cli.run(
          ['test/_data/flutter_style_todos', '--rules=flutter_style_todos']);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'a.dart 8:1 [lint] Use Flutter TODO format:',
            'a.dart 9:1 [lint] Use Flutter TODO format:',
            'a.dart 10:1 [lint] Use Flutter TODO format:',
            'a.dart 11:1 [lint] Use Flutter TODO format:',
            'a.dart 12:1 [lint] Use Flutter TODO format:',
            'a.dart 13:1 [lint] Use Flutter TODO format:',
            'a.dart 14:1 [lint] Use Flutter TODO format:',
            'a.dart 15:1 [lint] Use Flutter TODO format:',
            'a.dart 16:1 [lint] Use Flutter TODO format:',
            'a.dart 17:1 [lint] Use Flutter TODO format:',
            'a.dart 18:1 [lint] Use Flutter TODO format:',
            '1 file analyzed, 11 issues found, in'
          ]));
      expect(exitCode, 1);
    });
  });
}
