// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../templates.dart';
import 'common.dart' as common;

/// A generator for a simple command-line application.
class PackageGenerator extends DefaultGenerator {
  PackageGenerator()
      : super(
          'package',
          'Dart Package',
          'A package containing shared Dart libraries.',
          categories: const ['dart'],
          alternateId: 'package-simple',
        ) {
    addFile('.gitignore', _gitignore);
    addFile('analysis_options.yaml', common.analysisOptions);
    addFile('CHANGELOG.md', common.changelog);
    addFile('pubspec.yaml', _pubspec);
    addFile('README.md', _readme);
    addFile('example/__projectName___example.dart', _exampleDart);
    setEntrypoint(
      addFile('lib/__projectName__.dart', _libDart),
    );
    addFile('lib/src/__projectName___base.dart', _libSrcDart);
    addFile('test/__projectName___test.dart', _testDart);
  }

  @override
  String getInstallInstructions(
    String directory, {
    String? scriptPath,
  }) =>
      super.getInstallInstructions(
        directory,
        scriptPath: 'example/${scriptPath}_example',
      );
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
  lints: ^2.1.0
  test: ^1.24.0
''';

final String _readme = '''
<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
''';

final String _exampleDart = r'''
import 'package:__projectName__/__projectName__.dart';

void main() {
  var awesome = Awesome();
  print('awesome: ${awesome.isAwesome}');
}
''';

final String _libDart = '''
/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'src/__projectName___base.dart';

// TODO: Export any libraries intended for clients of this package.
''';

final String _libSrcDart = '''
// TODO: Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}
''';

final String _testDart = '''
import 'package:__projectName__/__projectName__.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}
''';
