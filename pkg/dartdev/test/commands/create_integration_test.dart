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
  TestProject? p;

  setUp(() => p = null);

  tearDown(() async => await p?.dispose());

  // Create tests for each template.
  for (String templateId in CreateCommand.legalTemplateIds) {
    test(templateId, () async {
      p = project();

      ProcessResult createResult = await p!.run([
        'create',
        '--force',
        '--template',
        templateId,
        'template_project',
      ]);
      expect(createResult.exitCode, 0, reason: createResult.stderr);

      // Validate that the project analyzes cleanly.
      // TODO: Should we use --fatal-infos here?
      ProcessResult analyzeResult =
          await p!.run(['analyze'], workingDir: p!.dir.path);
      expect(analyzeResult.exitCode, 0, reason: analyzeResult.stdout);

      // Validate that the code is well formatted.
      ProcessResult formatResult = await p!.run([
        'format',
        '--output',
        'none',
        '--set-exit-if-changed',
        'template_project',
      ]);
      expect(formatResult.exitCode, 0, reason: formatResult.stdout);
    });
  }
}
