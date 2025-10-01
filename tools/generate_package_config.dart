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

void main() {
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
      r'^dependency_overrides:$([^]*?)(\r\n|\n)$',
      multiLine: true,
    ).firstMatch(pubspec)![1]!;
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
    path: third_party/pkg/core/pkgs/characters/'''
  "$overrides");
  } else {
    // Delete the overrides file if it exists.
    if (overridesFile.existsSync()) {
      overridesFile.deleteSync();
    }
  }

  // Invoke `dart pub get` to create a .dart_tool/package_config.json file.
  final result = Process.runSync(
    Platform.resolvedExecutable,
    ['pub', 'get'],
    workingDirectory: repoRoot.toFilePath(),
    // Solve pretending we are running [currentSDKVersion].
    environment: {
      '_PUB_TEST_SDK_VERSION': currentSDKVersion()
    }, // Prevent overriding, e.g., PUB_CACHE
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
  ) as Map<String, Object?>;

  if (!fluteExists) {
    final packages = packageConfig['packages'] as List<Object?>;
    for (final (package as Map<String, Object?>) in packages) {
      final rootUri = package['rootUri'] as String;
      if (!(rootUri.startsWith('../third_party/') || // Third-party package
              rootUri.startsWith('../pkg/') || // SDK package
              rootUri.startsWith('../samples/') || // sample package
              rootUri.startsWith('../runtime/') || // VM package
              rootUri.startsWith('../tests/ffi') || // FFI tests
              rootUri.startsWith(
                '../tools',
              ) || // A tool package for developing the SDK.
              rootUri.startsWith('../utils' ) || // Utils for building the SDK.
              rootUri == '../' // The main workspace package
          )) {
        print('Package ${package['name']} is imported from outside the SDK.');
        print('It has rootUri $rootUri.');
        print(
          'See https://github.com/dart-lang/sdk/blob/main/docs/Adding-and-Updating-Dependencies.md',
        );

        exit(-1);
      }
    }
  }
}

String currentSDKVersion() {
  final versionContents =
      File.fromUri(repoRoot.resolve('tools/VERSION')).readAsStringSync();
  final lines = LineSplitter.split(versionContents);
  final versionParts = {
    for (var line in lines)
      if (line.isNotEmpty && !line.startsWith('#'))
        if (line.split(' ') case [final key, final value]) key: value
  };
  return '${versionParts['MAJOR']}.${versionParts['MINOR']}.${versionParts['PATCH']}';
}
