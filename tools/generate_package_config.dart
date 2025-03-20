// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generates the repo's ".dart_tool/package_config.json" file.
library;

// This script should not depend on any external packages, as it is run before
// any package resolution has taken place.
import 'dart:convert';
import 'dart:io';

final repoRoot = File(Platform.script.toFilePath()).parent.parent.uri;

void main(List<String> args) {
  final fluteExists =
      Directory.fromUri(repoRoot.resolve('third_party/flute')).existsSync();
  final overridesFile = File.fromUri(
    repoRoot.resolve('pubspec_overrides.yaml'),
  );
  if (fluteExists) {
    // Make a `pubspec_overrides.yaml` file that includes all existing overrides
    // and also `package:flute` and `package:characters`
    final pubspec =
        File.fromUri(repoRoot.resolve('pubspec.yaml')).readAsStringSync();
    final overrides = RegExp(
      'dependency_overrides:\n([\\S\\s]*?)^\$',
      multiLine: true,
    ).firstMatch(pubspec)![1];
    overridesFile.writeAsStringSync('''
# Created by tools/generate_package_config.dart to support flute.

dependency_overrides:
  flute:
    path: third_party/flute/framework
  engine:
    path: third_party/flute/engine
  flute_script:
    path: third_party/flute/script
  flute_benchmarks:
    path: third_party/flute/benchmarks
  material_color_utilities:
    path: third_party/pkg/material_color_utilities/dart
  characters:
    path: third_party/pkg/core/pkgs/characters/
$overrides
''');
  } else {
    // Delete the overrides file if it exists.
    if (overridesFile.existsSync()) {
      File.fromUri(
        repoRoot.resolve('pubspec_overrides.yaml'),
      ).deleteSync(recursive: true);
    }
  }

  // Invoke `dart pub get` to create a .dart_tool/package_config.json file.
  final result = Process.runSync(
    Platform.resolvedExecutable,
    ['pub', 'get'],
    workingDirectory: repoRoot.toFilePath(),
    environment: {}, // Prevent overriding eg. PUB_CACHE
  );
  if (result.exitCode != 0) {
    print('`pub get` failed');
    print(result.stderr);
    print(result.stdout);
    exit(-1);
  }
  final packageConfig = jsonDecode(
    File.fromUri(
      repoRoot.resolve('.dart_tool/package_config.json'),
    ).readAsStringSync(),
  );

  if (!fluteExists) {
    for (final package in packageConfig['packages']) {
      final rootUri = package['rootUri'];
      if (!(rootUri.startsWith('../third_party/') || // Third-party package
              rootUri.startsWith('../pkg/') || // SDK package
              rootUri.startsWith('../samples/') || // sample package
              rootUri.startsWith('../runtime/') || // VM package
              rootUri.startsWith(
                '../tools',
              ) || // A tool package for developing the sdk.
              rootUri == '../' // The main workspace package
          )) {
        print('Package ${package['name']} is imported from outside the sdk.');
        print('It has rootUri $rootUri.');
        print(
          'See https://github.com/dart-lang/sdk/blob/main/docs/Adding-and-Updating-Dependencies.md',
        );

        exit(-1);
      }
    }
  }
}
