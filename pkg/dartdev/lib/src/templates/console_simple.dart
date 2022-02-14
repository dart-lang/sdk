// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../templates.dart';
import 'common.dart' as common;

/// A generator for a simple command-line application.
class ConsoleSimpleGenerator extends DefaultGenerator {
  ConsoleSimpleGenerator()
      : super('console-simple', 'Simple Console Application',
            'A simple command-line application.',
            categories: const ['dart', 'console']) {
    addFile('.gitignore', common.gitignore);
    addFile('analysis_options.yaml', common.analysisOptions);
    addFile('CHANGELOG.md', common.changelog);
    addFile('pubspec.yaml', _pubspec);
    addFile('README.md', _readme);
    setEntrypoint(
      addFile('bin/__projectName__.dart', mainSrc),
    );
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
description: A simple command-line application.
version: 1.0.0
# homepage: https://www.example.com

environment:
  ${common.sdkConstraint}

# dependencies:
#   path: ^1.8.0

dev_dependencies:
  lints: ^1.0.0
''';

final String _readme = '''
A simple command-line application.
''';

final String mainSrc = '''
void main(List<String> arguments) {
  print('Hello world!');
}
''';
