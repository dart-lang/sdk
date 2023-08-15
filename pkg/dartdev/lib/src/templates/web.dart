// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import '../templates.dart';
import 'common.dart' as common;

/// A generator for a uber-simple web application.
class WebGenerator extends DefaultGenerator {
  WebGenerator()
      : super(
          'web',
          'Bare-bones Web App',
          'A web app that uses only core Dart libraries.',
          alternateId: 'web-simple',
          categories: const ['dart', 'web'],
        ) {
    addFile('.gitignore', common.gitignore);
    addFile('analysis_options.yaml', common.analysisOptions);
    addFile('CHANGELOG.md', common.changelog);
    addFile('pubspec.yaml', _pubspec);
    addFile('README.md', _readme);
    addFile('web/index.html', _index);
    setEntrypoint(
      addFile('web/main.dart', _main),
    );
    addFile('web/styles.css', _styles);
  }

  @override
  String getInstallInstructions(
    String directory, {
    String? scriptPath,
  }) =>
      '  cd ${p.relative(directory)}\n'
      '  dart pub global activate webdev\n'
      '  webdev serve';
}

final String _pubspec = '''
name: __projectName__
description: An absolute bare-bones web app.
version: 1.0.0
# repository: https://github.com/my_org/my_repo

environment:
  ${common.sdkConstraint}

# Add regular dependencies here.
dependencies:
  # path: ^1.8.0

dev_dependencies:
  build_runner: ^2.4.0
  build_web_compilers: ^4.0.0
  lints: ^2.1.0
''';

final String _readme = '''
An absolute bare-bones web app.
''';

final String _index = '''
<!DOCTYPE html>

<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="scaffolded-by" content="https://github.com/dart-lang/sdk">
    <title>__projectName__</title>
    <link rel="stylesheet" href="styles.css">
    <script defer src="main.dart.js"></script>
</head>

<body>

  <div id="output"></div>

</body>
</html>
''';

final String _main = '''
import 'dart:html';

void main() {
  querySelector('#output')?.text = 'Your Dart app is running.';
}
''';

final String _styles = '''
@import url(https://fonts.googleapis.com/css?family=Roboto);

html, body {
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  font-family: 'Roboto', sans-serif;
}

#output {
  padding: 20px;
  text-align: center;
}
''';
