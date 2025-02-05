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
  web: ^0.5.1

dev_dependencies:
  build_runner: ^2.4.8
  build_web_compilers: ^4.0.9
  lints: ^5.0.0
''';

final String _readme = '''
A bare-bones Dart web app.

Uses [`package:web`](https://pub.dev/packages/web)
to interop with JS and the DOM.

## Running and building

To run the app,
activate and use [`package:webdev`](https://dart.dev/tools/webdev):

```
dart pub global activate webdev
webdev serve
```

To build a production version ready for deployment,
use the `webdev build` command:

```
webdev build
```

To learn how to interop with web APIs and other JS libraries,
check out https://dart.dev/interop/js-interop.
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
import 'package:web/web.dart' as web;

void main() {
  final now = DateTime.now();
  final element = web.document.querySelector('#output') as web.HTMLDivElement;
  element.text =
      'The time is \${now.hour}:\${now.minute} '
      'and your Dart web app is running!';
}
''';

final String _styles = '''
@import url('https://fonts.googleapis.com/css2?family=Roboto&display=swap');

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
