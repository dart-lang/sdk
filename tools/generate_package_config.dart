#!/usr/bin/env dart

/// Generates the repo's ".dart_tool/package_config.json" file.

// @dart = 2.9

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
    packageDirectory('runtime/observatory_2'),
    packageDirectory(
        'runtime/observatory_2/tests/service_2/observatory_test_package_2'),
    packageDirectory('sdk/lib/_internal/sdk_library_metadata'),
    packageDirectory('sdk/lib/_internal/js_runtime'),
    packageDirectory('third_party/pkg/protobuf/protobuf'),
    packageDirectory('tools/package_deps'),
  ];

  var cfePackageDirs = [
    packageDirectory('pkg/front_end/testcases/'),
  ];

  var feAnalyzerSharedPackageDirs = [
    packageDirectory(
        'pkg/_fe_analyzer_shared/test/flow_analysis/assigned_variables/'),
    packageDirectory(
        'pkg/_fe_analyzer_shared/test/flow_analysis/definite_assignment/'),
    packageDirectory(
        'pkg/_fe_analyzer_shared/test/flow_analysis/definite_unassignment/'),
    packageDirectory('pkg/_fe_analyzer_shared/test/flow_analysis/nullability/'),
    packageDirectory(
        'pkg/_fe_analyzer_shared/test/flow_analysis/reachability/'),
    packageDirectory(
        'pkg/_fe_analyzer_shared/test/flow_analysis/type_promotion/'),
    packageDirectory('pkg/_fe_analyzer_shared/test/inheritance/'),
  ];

  var packages = [
    ...makePackageConfigs(packageDirs),
    ...makeCfePackageConfigs(cfePackageDirs),
    ...makeFeAnalyzerSharedPackageConfigs(feAnalyzerSharedPackageDirs)
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

    yield {
      'name': p.basename(packageDir),
      'rootUri': p
          .toUri(p.relative(packageDir, from: p.dirname(configFilePath)))
          .toString(),
      if (hasLibDirectory) 'packageUri': 'lib/',
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

/// Generates package configurations for the special pseudo-packages used by
/// the _fe_analyzer_shared id tests.
Iterable<Map<String, String>> makeFeAnalyzerSharedPackageConfigs(
    List<String> packageDirs) sync* {
  for (var packageDir in packageDirs) {
    yield {
      'name': '_fe_analyzer_shared_${p.basename(packageDir)}',
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
  var relative = p.relative(packageDir, from: repoRoot);

  if (!pubspecFile.existsSync()) {
    print("Error: Missing pubspec for $relative.");
    exit(1);
  }

  var pubspec =
      loadYaml(pubspecFile.readAsStringSync()) as Map<dynamic, dynamic>;
  if (!pubspec.containsKey('environment')) {
    print("Error: Pubspec for $relative has no SDK constraint.");
    exit(1);
  }

  var environment = pubspec['environment'] as Map<dynamic, dynamic>;
  if (!environment.containsKey('sdk')) {
    print("Error: Pubspec for $relative has no SDK constraint.");
    exit(1);
  }

  var sdkConstraint = VersionConstraint.parse(environment['sdk'] as String);
  if (sdkConstraint is VersionRange) return sdkConstraint.min;

  print("Error: SDK constraint $relative is not a version range.");
  exit(1);
}
