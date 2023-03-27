// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdev/src/commands/info.dart';
import 'package:dartdev/src/core.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('info', () {
    late TestProject p;

    test('--help', () async {
      p = project();
      final result = await p.run(['info', '--help']);

      expect(result.stdout, isNotEmpty);
      expect(result.stdout,
          contains('Show diagnostic information about the installed tooling'));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
    });

    test('shows general info', () async {
      p = project(mainSrc: 'void main() {}');
      final runResult = await p.run(['info']);

      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);

      var output = runResult.stdout as String;

      expect(output, contains('## General info'));
      expect(output, contains('- Dart '));
    });

    test('shows project info', () async {
      p = project(mainSrc: 'void main() {}');
      final runResult = await p.run(['info']);

      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);

      var output = runResult.stdout as String;

      expect(output, contains('## Project info'));
      expect(output, contains('- sdk constraint: '));
      expect(output, contains('- dependencies: '));
    });

    test('getProjectInfo', () {
      p = project(
        mainSrc: 'void main() {}',
        pubspecExtras: {
          'dependencies': {'dummy_pkg': '0.0.1'},
        },
      );
      var results = getProjectInfo(Project.fromDirectory(p.dir));

      expect(results, isNotNull);
      expect(results!.sdkDependency, isNotEmpty);
      expect(results.dependencies, isNotEmpty);
      expect(results.dependencies, unorderedEquals(['dummy_pkg']));
      expect(results.devDependencies, isEmpty);
      expect(results.elidedDependencies, 0);
    });
  }, timeout: longTimeout);
}
