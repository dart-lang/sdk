// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() => testFlutterIntegration('flutter assets', (ctx) async {
  await ctx.server.addPackage({
    'pubspec.yaml': '''
name: my_pkg
version: 1.0.0
environment:
  sdk: ^3.12.0
''',
    'lib/my_pkg.dart': 'String pkgName() => "my_pkg";\n',
    'lib/pkg_asset.txt': 'Hello from my_pkg!',
    'assets/pkg_root_asset.txt': 'Root asset in my_pkg!',
  });

  await ctx.ws.writeFileFromText('pubspec.yaml', '''
name: myapp
environment:
  sdk: ^3.12.0
dependencies:
  flutter:
    sdk: flutter
  my_pkg: ^1.0.0
flutter:
  uses-material-design: true
''');

  await ctx.ws.writeFileFromText(
    'assets/hello.txt',
    'Hello from workspace asset!',
  );

  printOnFailure('# Running pub get');
  await ctx.ws.pub(command: 'get');

  await ctx.ws.writeFileFromText('main.dart', r'''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> verifyAssets(AssetBundle bundle) async {
  print('hello=${await bundle.loadString('assets/hello.txt')}');
  print('pkg=${await bundle.loadString('packages/my_pkg/pkg_asset.txt')}');
  print(
    'pkgRoot=${await bundle.loadString('packages/my_pkg/assets/pkg_root_asset.txt')}',
  );
  final fontManifest = await bundle.loadString('FontManifest.json');
  print('fontManifest=${fontManifest.isNotEmpty}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    unawaited(verifyAssets(DefaultAssetBundle.of(context)));
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Assets Test'))),
    );
  }
}

void main() {
  runApp(const MyApp());
}
''');

  printOnFailure('# Running code in sandbox');
  await ctx.sandbox.run('main.dart', mode: 'flutter');

  await ctx.checkConsole(.it()..equals('hello=Hello from workspace asset!'));
  await ctx.checkConsole(.it()..equals('pkg=Hello from my_pkg!'));
  await ctx.checkConsole(.it()..equals('pkgRoot=Root asset in my_pkg!'));
  await ctx.checkConsole(.it()..equals('fontManifest=true'));

  await ctx.ws.writeFileFromText(
    'assets/hello.txt',
    'Updated workspace asset!',
  );

  printOnFailure('# hotReload in sandbox');
  await ctx.sandbox.hotReload();

  await ctx.checkConsole(.it()..equals('hello=Updated workspace asset!'));
});
