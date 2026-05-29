// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('pub get (no dependencies)', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      environment:
        sdk: ^3.11.0
    ''');

    final (:log) = await ws.pub(command: 'get');

    check(log).contains('Got dependencies!');

    // Check that the package_config.json file was created
    final pkgConfig = await ws.readFileAsText('.dart_tool/package_config.json');
    check(pkgConfig).isNotEmpty();
  });

  testDartWorkspace('pub get (fetch package:foo)', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dev_dependencies:
        foo:
      environment:
        sdk: ^3.11.0
    ''');

    final (:log) = await ws.pub(command: 'get');

    printOnFailure(log);
    check(
      log,
    ).matchesPattern(RegExp(r'Changed \d+ (dependencies|dependency)!'));
  });

  testDartWorkspace('pub add', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      environment:
        sdk: ^3.11.0
    ''');

    final (:log) = await ws.pub(command: 'add', args: ['foo']);

    printOnFailure(log);
    check(log).contains('Resolving dependencies...');
    check(log).contains('+ foo');

    final pubspec = await ws.readFileAsText('pubspec.yaml');
    check(pubspec).contains('foo:');
  });

  testDartWorkspace('pub upgrade', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dependencies:
        foo: any
      environment:
        sdk: ^3.11.0
    ''');

    await ws.pub(command: 'get');
    final (:log) = await ws.pub(command: 'upgrade');

    printOnFailure(log);
    check(log).contains('Resolving dependencies...');
  });

  testDartWorkspace('pub downgrade', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dependencies:
        foo: any
      environment:
        sdk: ^3.11.0
    ''');

    await ws.pub(command: 'get');
    final (:log) = await ws.pub(command: 'downgrade');

    printOnFailure(log);
    check(log).contains('Resolving dependencies...');
  });

  testDartWorkspace('pub get (package not found)', (ws) async {
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dev_dependencies:
        foo_bar_package_that_does_not_exist:
      environment:
        sdk: ^3.11.0
    ''');

    await check(ws.pub(command: 'get')).throws<PubException>(
      (e) => e.message.contains(
        'could not find package foo_bar_package_that_does_not_exist',
      ),
    );

    // TODO(jonasfj): Enable this when pub has stopped using globals, currently
    //                this will hang, but it clearly shouldn't!
    //                See: https://github.com/dart-lang/pub/issues/4808
    // await check(ws.pub(command: 'get')).throws<PubException>(
    //   (e) => e.message.contains(
    //     'could not find package foo_bar_package_that_does_not_exist',
    //   ),
    // );
  });
}
