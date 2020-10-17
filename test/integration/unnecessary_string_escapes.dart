// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('unnecessary_string_escapes', () {
    final currentOut = outSink;
    final collectingOut = CollectingSink();
    setUp(() => outSink = collectingOut);
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
    });
    test('no_closing_quote', () async {
      await cli.runLinter([
        'test/_data/unnecessary_string_escapes/no_closing_quote.dart',
        '--rules=unnecessary_string_escapes',
      ], LinterOptions());
      // No exception.
    });
  });
}
