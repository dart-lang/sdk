// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/commands/create.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('create integration', defineCreateTests, timeout: longTimeout);
}

void defineCreateTests() {
  TestProject p;

  setUp(() => p = null);

  tearDown(() => p?.dispose());

  // Create tests for each template.
  for (String templateId in CreateCommand.legalTemplateIds) {
    test(templateId, () {
      p = project();

      ProcessResult createResult = p.runSync([
        'create',
        '--force',
        '--template',
        templateId,
        p.dir.path,
      ]);
      expect(createResult.exitCode, 0, reason: createResult.stderr);

      // Validate that the project analyzes cleanly.
      // TODO: Should we use --fatal-infos here?
      ProcessResult analyzeResult =
          p.runSync(['analyze'], workingDir: p.dir.path);
      expect(analyzeResult.exitCode, 0, reason: analyzeResult.stdout);

      // Validate that the code is well formatted.
      ProcessResult formatResult = p.runSync([
        'format',
        '--output',
        'none',
        '--set-exit-if-changed',
        p.dir.path,
      ]);
      expect(formatResult.exitCode, 0, reason: formatResult.stdout);
    });
  }
}
