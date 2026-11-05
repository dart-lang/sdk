// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testFlutterWorkspace('pub get (fetch package:foo)', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dependencies:
        flutter:
          sdk: flutter
      dev_dependencies:
        foo:
      environment:
        sdk: '>=3.12.0 <4.0.0'
    ''');

    final (:log) = await ws.pub(command: 'get');

    printOnFailure(log);
    check(
      log,
    ).matchesPattern(RegExp(r'Changed \d+ (dependencies|dependency)!'));
  });

  testFlutterWorkspace('pub get (packages from sdk)', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dependencies:
        flutter:
          sdk: flutter
        flutter_localizations:
          sdk: flutter
        flutter_web_plugins:
          sdk: flutter
        flutter_test:
          sdk: flutter
        integration_test:
          sdk: flutter
        flutter_driver:
          sdk: flutter
      environment:
        sdk: '>=3.12.0 <4.0.0'
    ''');

    final (:log) = await ws.pub(command: 'get');

    printOnFailure(log);
    check(
      log,
    ).matchesPattern(RegExp(r'Changed \d+ (dependencies|dependency)!'));
  });

  testFlutterWorkspace('pub enforces pinned versions in flutter/pubspec.yaml', (
    ws,
  ) async {
    await serverClient.addPackage({
      'pubspec.yaml': '''{
          "name": "material_ui",
          "version": "1.99.0",
          "environment": {"sdk": "^3.10.0"}
        }''',
      'lib/material_ui.dart': '',
    });
    await serverClient.addPackage({
      'pubspec.yaml': '''{
          "name": "vector_math",
          "version": "2.99.0",
          "environment": {"sdk": "^3.10.0"}
        }''',
      'lib/vector_math.dart': '',
    });

    await ws.writeFileFromText('pubspec.yaml', '''
        name: myapp
        publish_to: none
        dependencies:
          flutter:
            sdk: flutter
          material_ui: ^1.1.0
          vector_math: ^2.4.0
        environment:
          sdk: '>=3.12.0 <4.0.0'
      ''');

    final (:log) = await ws.pub(command: 'get');
    printOnFailure(log);

    final pkgConfig = await ws.readFileAsText('.dart_tool/package_config.json');
    check(pkgConfig)
      ..contains('material_ui-')
      ..not(.it()..contains('material_ui-1.99.0'))
      ..contains('vector_math-')
      ..not(.it()..contains('vector_math-2.99.0'));

    // Requesting version ^1.99.0 (which exists on serverClient!) must fail
    // solver because flutter from sdk pins material_ui.
    await ws.writeFileFromText('pubspec.yaml', '''
        name: myapp
        publish_to: none
        dependencies:
          flutter:
            sdk: flutter
          material_ui: ^1.99.0
        environment:
          sdk: '>=3.12.0 <4.0.0'
      ''');

    await check(ws.pub(command: 'get')).throws<PubCommandFailedException>(
      .it()
        ..has((e) => e.message, 'message').contains(
          'Because myapp depends on flutter from sdk '
          'which depends on material_ui',
        ),
    );
  });
}
