// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/services/completion/dart/completion_ranking.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  CompletionRanking ranking;

  setUp(() async {
    ranking = CompletionRanking(directory);
    await ranking.start();
  });

  test('make request to isolate', () async {
    final tokens =
        tokenize('if (list == null) { return; } for (final i = 0; i < list.');
    final response = await ranking.makePredictRequest(tokens);
    expect(response['data']['length'], greaterThan(0.9));
  });
}

final directory = path.join(File.fromUri(Platform.script).parent.path, '..',
    '..', '..', '..', 'language_model', 'lexeme');

/// Tokenizes the input string.
///
/// The input is split by word boundaries and trimmed of whitespace.
List<String> tokenize(String input) =>
    input.split(RegExp(r'\b|\s')).map((t) => t.trim()).toList()
      ..removeWhere((t) => t.isEmpty);
