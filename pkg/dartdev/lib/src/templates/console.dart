// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../templates.dart';
import 'common.dart' as common;

/// A generator for a hello world command-line application.
class ConsoleGenerator extends DefaultGenerator {
  ConsoleGenerator()
      : super(
          'console',
          'Console Application',
          'A command-line application.',
          alternateId: 'console-full',
          categories: const ['dart', 'console'],
        ) {
    addFile('.gitignore', common.gitignore);
    addFile('analysis_options.yaml', common.analysisOptions);
    addFile('CHANGELOG.md', common.changelog);
    addFile('pubspec.yaml', _pubspec);
    addFile('README.md', _readme);
    setEntrypoint(
      addFile('bin/__projectName__.dart', _mainDart),
    );
    addFile('lib/__projectName__.dart', _libDart);
    addFile('test/__projectName___test.dart', _testDart);
  }

  @override
  String getInstallInstructions(
    String directory, {
    String? scriptPath,
  }) =>
      super.getInstallInstructions(directory);
}

final String _pubspec = '''
name: __projectName__
description: A sample command-line application.
version: 1.0.0
# repository: https://github.com/my_org/my_repo

environment:
  ${common.sdkConstraint}

# Add regular dependencies here.
dependencies:
  # path: ^1.8.0

dev_dependencies:
  lints: ^2.1.0
  test: ^1.24.0
''';

final String _readme = '''
A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.
''';

final String _mainDart = r'''
import 'package:__projectName__/__projectName__.dart' as __projectName__;

void main(List<String> arguments) {
  print('Hello world: ${__projectName__.calculate()}!');
}
''';

final String _libDart = '''
int calculate() {
  return 6 * 7;
}
''';

final String _testDart = '''
import 'package:__projectName__/__projectName__.dart';
import 'package:test/test.dart';

void main() {
  test('calculate', () {
    expect(calculate(), 42);
  });
}
''';
