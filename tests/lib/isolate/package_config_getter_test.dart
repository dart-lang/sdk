// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'spawn_uri__package_uri__test.dart';

final executable = Platform.executable;

main() async {
  // Make a folder structure that has both ".dart_tool/package_config.json" and
  // ".packages" and ensure VM prefers to use ".packages".
  await withTempDir((String tempDir) async {
    // Setup bogus ".packages" with "foo -> ..." with invalid mapping.
    final dotPackagesPath = path.join(tempDir, '.packages');
    final dotPackagesFile = File(dotPackagesPath);
    await dotPackagesFile.writeAsString(buildDotPackages('invalid'));

    // Setup ".dart_tool/package_config.json".
    final dotDartToolDir = path.join(tempDir, '.dart_tool');
    await Directory(dotDartToolDir).create();
    final packageConfigJsonPath =
        path.join(dotDartToolDir, 'package_config.json');
    final packageConfigJsonFile = File(packageConfigJsonPath);
    await packageConfigJsonFile.writeAsString(buildPackageConfig('foo', true));

    final mainFile = path.join(tempDir, 'main.dart');
    await File(mainFile).writeAsString('''
import 'dart:io' as io;
import 'dart:isolate';

main() async {
  final uri = await Isolate.packageConfig;
  final expectedUri = Uri.parse('${packageConfigJsonFile.uri}');
  if (uri != expectedUri) {
    throw 'VM should use .packages file (but used \$uri).';
  }
}
''');

    await run(executable, [mainFile]);
  });
}
