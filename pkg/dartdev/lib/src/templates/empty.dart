// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../templates.dart';
import 'common.dart' as common;

/// A generator for an empty Dart project.
class EmptyGenerator extends DefaultGenerator {
  EmptyGenerator()
      : super(
          'empty',
          'Empty Project',
          'An empty Dart project',
          categories: const ['dart'],
          alternateId: 'empty-project',
        ) {
    addFile('.gitignore', _gitignore);
    addFile('analysis_options.yaml', common.analysisOptions);
    addFile('pubspec.yaml', _pubspec);
  }

  @override
  String getInstallInstructions(
    String directory, {
    String? scriptPath,
  }) =>
      super.getInstallInstructions(directory);
}

final String _gitignore = '''
# https://dart.dev/guides/libraries/private-files
# Created by `dart pub`
.dart_tool/

# Avoid committing pubspec.lock for library packages; see
# https://dart.dev/guides/libraries/private-files#pubspeclock.
pubspec.lock
''';

final String _pubspec = '''
name: __projectName__
description: A starting point for Dart libraries or applications.
version: 1.0.0
# repository: https://github.com/my_org/my_repo

environment:
  ${common.sdkConstraint}

# Add regular dependencies here.
dependencies:
  # path: ^1.8.0

dev_dependencies:
  lints: ^4.0.0
  test: ^1.24.0
''';
