// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../templates.dart';
import 'common.dart' as common;

/// A generator for a simple command-line application.
class PackageSimpleGenerator extends DefaultGenerator {
  PackageSimpleGenerator()
      : super('package-simple', 'Dart Package',
            'A starting point for Dart libraries or applications.',
            categories: const ['dart']) {
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
    String directory,
    String scriptPath,
  ) =>
      super.getInstallInstructions(
        directory,
        'example/${scriptPath}_example',
      );
}

final String _gitignore = '''
# Files and directories created by pub.
.dart_tool/
.packages

# Conventional directory for build outputs.
build/

# Omit committing pubspec.lock for library packages; see
# https://dart.dev/guides/libraries/private-files#pubspeclock.
pubspec.lock
''';

final String _pubspec = '''
name: __projectName__
description: A starting point for Dart libraries or applications.
version: 1.0.0
# homepage: https://www.example.com

environment:
  sdk: '>=2.12.0 <3.0.0'

# dependencies:
#   path: ^1.8.0

dev_dependencies:
  lints: ^1.0.0
  test: ^1.16.0
''';

final String _readme = '''
A library for Dart developers.

## Usage

A simple usage example:

```dart
import 'package:__projectName__/__projectName__.dart';

main() {
  var awesome = new Awesome();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
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
library __projectName__;

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
