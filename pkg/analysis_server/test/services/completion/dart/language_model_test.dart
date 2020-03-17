// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:analysis_server/src/services/completion/dart/language_model.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  if (sizeOf<IntPtr>() == 4) {
    // We don't yet support running tflite on 32-bit systems.
    return;
  }

  LanguageModel model;

  setUp(() {
    model = LanguageModel.load(directory);
  });

  tearDown(() {
    model.close();
  });

  test('calculates lookback', () {
    expect(model.lookback, expectedLookback);
  });

  test('predict with defaults', () {
    final tokens =
        tokenize('if (list == null) { return; } for (final i = 0; i < list.');
    final suggestions = model.predict(tokens);
    expect(suggestions.first, 'length');
  });

  test('predict with confidence scores', () {
    final tokens =
        tokenize('if (list == null) { return; } for (final i = 0; i < list.');
    final suggestions = model.predictWithScores(tokens);
    final best = suggestions.entries.first;
    expect(best.key, 'length');
    expect(best.value, greaterThan(0.9));
  });

  test('predict when no previous tokens', () {
    final tokens = <String>[];
    final suggestions = model.predict(tokens);
    expect(suggestions.first, isNotEmpty);
  });

  test('load fail', () {
    try {
      LanguageModel.load('doesnotexist');
      fail('Failure to load language model should throw an exception');
    } catch (e) {
      expect(
          e.toString(), equals('Invalid argument(s): Unable to create model.'));
    }
  });

  test('isNumber', () {
    expect(model.isNumber('0xCAb005E'), true);
    expect(model.isNumber('foo'), false);
    expect(model.isNumber('3.1415'), true);
    expect(model.isNumber('1337'), true);
    expect(model.isNumber('"four score and seven years ago"'), false);
    expect(model.isNumber('0.0'), true);
  });
}

const expectedLookback = 100;

final directory = path.join(File.fromUri(Platform.script).parent.path, '..',
    '..', '..', '..', 'language_model', 'lexeme');

/// Tokenizes the input string.
///
/// The input is split by word boundaries and trimmed of whitespace.
List<String> tokenize(String input) =>
    input.split(RegExp(r'\b|\s')).map((t) => t.trim()).toList()
      ..removeWhere((t) => t.isEmpty);
