#!/usr/bin/env dart

/// Generates the repo's ".dart_tool/package_config.json" file.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

final repoRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
final configFilePath = p.join(repoRoot, '.dart_tool/package_config.json');

void main(List<String> args) {
  var packageDirs = [
    ...listSubdirectories('pkg'),
    ...listSubdirectories('third_party/pkg'),
    ...listSubdirectories('third_party/pkg_tested'),
    ...listSubdirectories('third_party/pkg/test/pkgs'),
    packageDirectory('runtime/observatory'),
    packageDirectory(
        'runtime/observatory/tests/service/observatory_test_package'),
    packageDirectory('sdk/lib/_internal/sdk_library_metadata'),
    packageDirectory('sdk/lib/_internal/js_runtime'),
    packageDirectory('third_party/pkg/protobuf/protobuf'),
  ];

  var cfePackageDirs = [
    packageDirectory('pkg/front_end/testcases/agnostic/'),
    packageDirectory('pkg/front_end/testcases/general_nnbd_opt_out/'),
    packageDirectory('pkg/front_end/testcases/late_lowering/'),
    packageDirectory('pkg/front_end/testcases/nnbd/'),
    packageDirectory('pkg/front_end/testcases/nnbd_mixed/'),
    packageDirectory('pkg/front_end/testcases/nonfunction_type_aliases/'),
  ];

  var packages = [
    ...makePackageConfigs(packageDirs),
    ...makeCfePackageConfigs(cfePackageDirs)
  ];
  packages.sort((a, b) => a["name"].compareTo(b["name"]));

  var year = DateTime.now().year;
  var config = <String, dynamic>{
    'copyright': [
      'Copyright (c) $year, the Dart project authors. Please see the AUTHORS ',
      'file for details. All rights reserved. Use of this source code is ',
      'governed by a BSD-style license that can be found in the LICENSE file.'
    ],
    'comment': [
      'Package configuration for all packages in /pkg, and checked out by DEPS',
      'into /third_party/pkg and /third_party/pkg_tested.',
      'If you add a package to DEPS or /pkg or change a package\'s SDK',
      'constraint, update this by running tools/generate_package_config.dart.'
    ],
    'configVersion': 2,
    'generated': DateTime.now().toIso8601String(),
    'generator': 'tools/generate_package_config.dart',
    'packages': packages,
  };

  // TODO(rnystrom): Consider using package_config_v2 to generate this instead.
  var json = JsonEncoder.withIndent('  ').convert(config);
  File(p.join(repoRoot, '.dart_tool', 'package_config.json'))
      .writeAsStringSync(json);
  print('Generated .dart_tool/package_config.dart containing '
      '${packages.length} packages.');
}

/// Generates package configurations for each package in [packageDirs].
Iterable<Map<String, String>> makePackageConfigs(
    List<String> packageDirs) sync* {
  for (var packageDir in packageDirs) {
    var version = pubspecLanguageVersion(packageDir);
    var hasLibDirectory = Directory(p.join(packageDir, 'lib')).existsSync();

    // TODO(rnystrom): Currently, the pre-built SDK does not allow language
    // version 2.9.0. Until that's fixed, if we see that version, just write
    // no version at all so that implementations use the current language
    // version.
    if (version.toString() == '2.9.0') version = null;

    yield {
      'name': p.basename(packageDir),
      'rootUri': p
          .toUri(p.relative(packageDir, from: p.dirname(configFilePath)))
          .toString(),
      if (hasLibDirectory) 'packageUri': 'lib/',
      if (version != null)
        'languageVersion': '${version.major}.${version.minor}'
    };
  }
}

/// Generates package configurations for the special pseudo-packages used by
/// the CFE unit tests (`pkg/front_end/test/unit_test_suites.dart`).
Iterable<Map<String, String>> makeCfePackageConfigs(
    List<String> packageDirs) sync* {
  for (var packageDir in packageDirs) {
    yield {
      'name': 'front_end_${p.basename(packageDir)}',
      'rootUri': p
          .toUri(p.relative(packageDir, from: p.dirname(configFilePath)))
          .toString(),
      'packageUri': '.nonexisting/',
    };
  }
}

/// Generates a path to [relativePath] within the repo.
String packageDirectory(String relativePath) => p.join(repoRoot, relativePath);

/// Finds the paths of the immediate subdirectories of [packagesDir] that
/// contain pubspecs.
Iterable<String> listSubdirectories(String packagesDir) sync* {
  for (var entry in Directory(p.join(repoRoot, packagesDir)).listSync()) {
    if (entry is! Directory) continue;
    if (!File(p.join(entry.path, 'pubspec.yaml')).existsSync()) continue;
    yield entry.path;
  }
}

/// Infers the language version from the SDK constraint in the pubspec for
/// [packageDir].
///
/// Returns `null` if there is no pubspec or no SDK constraint.
Version pubspecLanguageVersion(String packageDir) {
  var pubspecFile = File(p.join(packageDir, 'pubspec.yaml'));

  if (!pubspecFile.existsSync()) return null;

  var pubspec =
      loadYaml(pubspecFile.readAsStringSync()) as Map<dynamic, dynamic>;
  if (!pubspec.containsKey('environment')) return null;

  var environment = pubspec['environment'] as Map<dynamic, dynamic>;
  if (!environment.containsKey('sdk')) return null;

  var sdkConstraint = VersionConstraint.parse(environment['sdk'] as String);
  if (sdkConstraint is VersionRange) return sdkConstraint.min;

  return null;
}
