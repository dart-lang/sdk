// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_registry.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_runner.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_summary_builder.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:linter/src/rules.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MigrateDependencyConflictTest);
    defineReflectiveTests(MigrateLockstepTest);
    defineReflectiveTests(MigrateMultiVersionTest);
    defineReflectiveTests(MigratePackageValidationTest);
    defineReflectiveTests(MigrateProgressTest);
    defineReflectiveTests(MigrateStepsTest);
  });
}

abstract class AbstractMigrateTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    registerBuiltInFixGenerators();
    failTestOnErrorDiagnostic = false;
  }

  void writePubspecFile(
    String path,
    String content, {
    PackageConfigFileBuilder? packageConfigBuilder,
  }) {
    newFile(path, content);
    try {
      var yaml = loadYaml(content);
      if (yaml is YamlMap) {
        var name = (yaml['name'] as String?) ?? 'test';
        var environment = yaml['environment'];
        if (environment is YamlMap) {
          var sdk = environment['sdk'] as String?;
          if (sdk != null) {
            var constraint = VersionConstraint.parse(sdk);
            if (constraint is VersionRange) {
              var minVersion = constraint.min;
              if (minVersion != null) {
                writePackageConfig2(
                  pathContext.dirname(path),
                  config: packageConfigBuilder,
                  packageName: name,
                  languageVersion: '${minVersion.major}.${minVersion.minor}',
                );
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _assertMigrationResult({
    List<Uri>? uris,
    List<MigrationStep> steps = const [MigrationStep.All],
    String? targetSdk,
    Object? expectedSummary,
    String? expectedEdit,
    bool apply = false,
    ProgressToken? workDoneToken,
  }) async {
    await workspaceAnalysisComplete();
    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: uris ?? [projectFolderUri],
        apply: apply,
        steps: steps,
        targetSdk: targetSdk,
        workDoneToken: workDoneToken,
      ),
    );
    var response = await sendRequestToServer(request);

    expect(response.error, isNull);

    var result = DartMigrateResult.fromJson(
      response.result as Map<String, Object?>,
    );
    if (expectedSummary != null) {
      expect(result.summary, expectedSummary);
    }
    if (expectedEdit != null) {
      verifyEdit(result.edit!, expectedEdit);
    }
  }

  Future<void> _setupProject({
    required String pubspecContent,
    String? customPubspecFilePath,
    List<Uri>? workspaceFolders,
    PackageConfigFileBuilder? packageConfigBuilder,
  }) async {
    var pubspecPath = customPubspecFilePath ?? pubspecFilePath;
    writePubspecFile(
      pubspecPath,
      pubspecContent,
      packageConfigBuilder: packageConfigBuilder,
    );

    await initialize(workspaceFolders: workspaceFolders);
  }
}

@reflectiveTest
class MigrateDependencyConflictTest extends AbstractMigrateTest {
  Future<void> test_dart3BackwardsCompatibility() async {
    writePubspecFile(pubspecFilePath, '''
name: test
environment:
  sdk: '^3.12.0'
''');

    var depPath = convertPath('/dep_package');
    writePubspecFile(join(depPath, 'pubspec.yaml'), '''
name: dep_package
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
    newFile(join(depPath, 'lib', 'dep.dart'), '');

    var builder = PackageConfigFileBuilder();
    builder.add(
      name: 'dep_package',
      rootFolder: resourceProvider.getFolder(depPath),
    );
    writeTestPackageConfig2(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_dependencyConflict() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');

    var depPath = convertPath('/dep_package');
    writePubspecFile(join(depPath, 'pubspec.yaml'), '''
name: dep_package
environment:
  sdk: '>=3.0.0 <3.13.0'
''');
    newFile(join(depPath, 'lib', 'dep.dart'), '');

    var builder = PackageConfigFileBuilder();
    builder.add(
      name: 'dep_package',
      rootFolder: resourceProvider.getFolder(depPath),
    );
    writeTestPackageConfig2(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0: Skipped
    Incompatible dependencies:
      - dep_package''',
    );
  }

  Future<void> test_dependencyWithHigherMinSdk() async {
    writePubspecFile(pubspecFilePath, '''
name: test
environment:
  sdk: '^3.7.0'
dependencies:
  dep_package: 1.0.0
''');

    var depPath = convertPath('/dep_package');
    writePubspecFile(join(depPath, 'pubspec.yaml'), '''
name: dep_package
version: 1.0.0
environment:
  sdk: '^3.10.0'
''');
    newFile(join(depPath, 'lib', 'dep.dart'), '');

    var builder = PackageConfigFileBuilder();
    builder.add(
      name: 'dep_package',
      rootFolder: resourceProvider.getFolder(depPath),
    );
    writeTestPackageConfig2(config: builder, languageVersion: '3.7');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test:
  3.7.0 -> 3.8.0:
    SDK constraint:
      Bumped ^3.7.0 -> ^3.8.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test
environment:
  sdk: '^3.8.0'
dependencies:
  dep_package: 1.0.0
''',
    );
  }

  Future<void> test_multiple() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');

    // dep_package1: Incompatible
    var dep1Path = convertPath('/dep_package1');
    writePubspecFile(join(dep1Path, 'pubspec.yaml'), '''
name: dep_package1
environment:
  sdk: '>=3.0.0 <3.13.0'
''');
    newFile(join(dep1Path, 'lib', 'dep1.dart'), '');

    // dep_package2: Incompatible
    var dep2Path = convertPath('/dep_package2');
    writePubspecFile(join(dep2Path, 'pubspec.yaml'), '''
name: dep_package2
environment:
  sdk: '>=3.0.0 <3.13.0'
''');
    newFile(join(dep2Path, 'lib', 'dep2.dart'), '');

    // dep_package3: Compatible
    var dep3Path = convertPath('/dep_package3');
    writePubspecFile(join(dep3Path, 'pubspec.yaml'), '''
name: dep_package3
environment:
  sdk: '>=3.0.0 <4.0.0'
''');
    newFile(join(dep3Path, 'lib', 'dep3.dart'), '');

    // dep_package4: No pubspec.yaml (ignored)
    var dep4Path = convertPath('/dep_package4');
    newFile(join(dep4Path, 'lib', 'dep4.dart'), '');

    var builder = PackageConfigFileBuilder();
    builder.add(
      name: 'dep_package1',
      rootFolder: resourceProvider.getFolder(dep1Path),
    );
    builder.add(
      name: 'dep_package2',
      rootFolder: resourceProvider.getFolder(dep2Path),
    );
    builder.add(
      name: 'dep_package3',
      rootFolder: resourceProvider.getFolder(dep3Path),
    );
    builder.add(
      name: 'dep_package4',
      rootFolder: resourceProvider.getFolder(dep4Path),
    );

    writeTestPackageConfig2(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0: Skipped
    Incompatible dependencies:
      - dep_package1
      - dep_package2''',
    );
  }

  Future<void> test_transitive() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');

    // direct_dep: Compatible
    var directDepPath = convertPath('/direct_dep');
    writePubspecFile(join(directDepPath, 'pubspec.yaml'), '''
name: direct_dep
environment:
  sdk: '>=3.0.0 <4.0.0'
''');
    newFile(join(directDepPath, 'lib', 'direct_dep.dart'), '');

    // transitive_dep: Incompatible
    var transitiveDepPath = convertPath('/transitive_dep');
    writePubspecFile(join(transitiveDepPath, 'pubspec.yaml'), '''
name: transitive_dep
environment:
  sdk: '>=3.0.0 <3.13.0'
''');
    newFile(join(transitiveDepPath, 'lib', 'transitive_dep.dart'), '');

    var builder = PackageConfigFileBuilder();
    builder.add(
      name: 'direct_dep',
      rootFolder: resourceProvider.getFolder(directDepPath),
    );
    builder.add(
      name: 'transitive_dep',
      rootFolder: resourceProvider.getFolder(transitiveDepPath),
    );
    writeTestPackageConfig2(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0: Skipped
    Incompatible dependencies:
      - transitive_dep''',
    );
  }
}

@reflectiveTest
class MigrateLockstepTest extends AbstractMigrateTest {
  /// Packages joined by a dependency take each version step together.
  Future<void> test_round_interdependentPackages() async {
    var core = _createPackageFolder('core', sdkConstraint: '^3.11.0');
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['core'],
    );
    await initialize(workspaceFolders: [app, core]);

    var token = clientProvidedTestWorkDoneToken;
    var messages = _collectStageMessages(token);

    await _assertMigrationResult(
      uris: [app, core],
      targetSdk: '3.13.0',
      apply: true,
      workDoneToken: token,
      expectedEdit: '''
>>>>>>>>>> ../app/pubspec.yaml
name: app
environment:
  sdk: '^3.13.0'
dependencies:
  core:
    path: ../core
>>>>>>>>>> ../core/pubspec.yaml
name: core
environment:
  sdk: '^3.13.0'
''',
    );

    // Both packages take each version step before either starts the next, so
    // their floors are only ever equal.
    expect(messages, [
      'app: 3.11.0 -> 3.12.0 (prepare)',
      'core: 3.11.0 -> 3.12.0 (prepare)',
      'app: 3.11.0 -> 3.12.0 (bump)',
      'core: 3.11.0 -> 3.12.0 (bump)',
      'app: 3.12.0 (cleanup)',
      'core: 3.12.0 (cleanup)',
      'app: 3.12.0 -> 3.13.0 (prepare)',
      'core: 3.12.0 -> 3.13.0 (prepare)',
      'app: 3.12.0 -> 3.13.0 (bump)',
      'core: 3.12.0 -> 3.13.0 (bump)',
      'app: 3.13.0 (cleanup)',
      'core: 3.13.0 (cleanup)',
    ]);
  }

  /// A package behind the rest takes a round on its own until it catches up,
  /// after which the two move together.
  Future<void> test_round_laggingPackage() async {
    var core = _createPackageFolder('core', sdkConstraint: '^3.12.0');
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['core'],
    );
    await initialize(workspaceFolders: [app, core]);

    var token = clientProvidedTestWorkDoneToken;
    var messages = _collectStageMessages(token);

    await _assertMigrationResult(
      uris: [app, core],
      targetSdk: '3.13.0',
      apply: true,
      workDoneToken: token,
      expectedEdit: '''
>>>>>>>>>> ../app/pubspec.yaml
name: app
environment:
  sdk: '^3.13.0'
dependencies:
  core:
    path: ../core
>>>>>>>>>> ../core/pubspec.yaml
name: core
environment:
  sdk: '^3.13.0'
''',
    );

    // The first round belongs to `app` alone, which is the only package at
    // 3.11.0; once it has caught up the two move together.
    expect(messages, [
      'app: 3.11.0 -> 3.12.0 (prepare)',
      'app: 3.11.0 -> 3.12.0 (bump)',
      'app: 3.12.0 (cleanup)',
      'app: 3.12.0 -> 3.13.0 (prepare)',
      'core: 3.12.0 -> 3.13.0 (prepare)',
      'app: 3.12.0 -> 3.13.0 (bump)',
      'core: 3.12.0 -> 3.13.0 (bump)',
      'app: 3.13.0 (cleanup)',
      'core: 3.13.0 (cleanup)',
    ]);
  }

  /// A constraint carrying a patch counts as the SDK version it belongs to, so
  /// it lands in the same round as a package on that version.
  Future<void> test_round_patchVersionConstraint() async {
    var core = _createPackageFolder('core', sdkConstraint: '^3.11.0');
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.2',
      dependencies: ['core'],
    );
    await initialize(workspaceFolders: [app, core]);

    var token = clientProvidedTestWorkDoneToken;
    var messages = _collectStageMessages(token);

    await _assertMigrationResult(
      uris: [app, core],
      targetSdk: '3.13.0',
      apply: true,
      workDoneToken: token,
    );

    // Comparing declared versions would put `core` in a round of its own and
    // raise it to 3.12.0 while `app`, which depends on it, sat at 3.11.2.
    expect(messages, [
      'app: 3.11.0 -> 3.12.0 (prepare)',
      'core: 3.11.0 -> 3.12.0 (prepare)',
      'app: 3.11.0 -> 3.12.0 (bump)',
      'core: 3.11.0 -> 3.12.0 (bump)',
      'app: 3.12.0 (cleanup)',
      'core: 3.12.0 (cleanup)',
      'app: 3.12.0 -> 3.13.0 (prepare)',
      'core: 3.12.0 -> 3.13.0 (prepare)',
      'app: 3.12.0 -> 3.13.0 (bump)',
      'core: 3.12.0 -> 3.13.0 (bump)',
      'app: 3.13.0 (cleanup)',
      'core: 3.13.0 (cleanup)',
    ]);
  }

  /// A dependency cycle terminates the cascade rather than looping, since a
  /// dev dependency can point back at a package that depends on it.
  Future<void> test_stop_cyclicDevDependencies() async {
    // `app` has no package config, so its bump fails and holds back `core`,
    // whose dev dependency points back at `app`.
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['core'],
      writePackageConfig: false,
    );
    var core = _createPackageFolder(
      'core',
      sdkConstraint: '^3.11.0',
      devDependencies: ['app'],
    );
    await initialize(workspaceFolders: [app, core]);

    await _assertMigrationResult(
      uris: [app, core],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
app:
  3.11.0 -> 3.12.0: Failed
    Failed to update .dart_tool/package_config.json for "app". Try running "dart pub get" to update the package configuration, then re-run the migration.

core:
  3.11.0 -> 3.12.0: Skipped
    Held back by "app", which stopped at 3.11.0.''',
    );
  }

  /// A stopped package holds back what it depends on, so that dependency
  /// can't be left above it. A package with no edge to either is unaffected.
  Future<void> test_stop_dependencies() async {
    var core = _createPackageFolder('core', sdkConstraint: '^3.11.0');
    // `app` has no package config, so its bump fails partway through the
    // first round.
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['core'],
      writePackageConfig: false,
    );
    var unrelated = _createPackageFolder('unrelated', sdkConstraint: '^3.11.0');
    await initialize(workspaceFolders: [app, core, unrelated]);

    await _assertMigrationResult(
      uris: [app, core, unrelated],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
app:
  3.11.0 -> 3.12.0: Failed
    Failed to update .dart_tool/package_config.json for "app". Try running "dart pub get" to update the package configuration, then re-run the migration.

core:
  3.11.0 -> 3.12.0: Skipped
    Held back by "app", which stopped at 3.11.0.

unrelated:
  3.11.0 -> 3.12.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.11.0 -> ^3.12.0

    Cleanup changes:
      0 changes made in 0 files.

  3.12.0 -> 3.13.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      0 changes made in 0 files.''',
      // `core` produces no edit at all, so it keeps the floor `app` is stuck
      // at, while a package with no edge to either is untouched by the stop.
      expectedEdit: '''
>>>>>>>>>> ../unrelated/pubspec.yaml
name: unrelated
environment:
  sdk: '^3.13.0'
''',
    );
  }

  /// The same packages as [test_stop_dependencies], with the dependency
  /// requested before the package that fails.
  ///
  /// Held back or not, `core` must produce no edit: the order packages are
  /// requested in can't be what decides where their SDK floors end up.
  // TODO(kallentu): Stage edits per package and discard them when the package
  // stops, so a round produces no edits for a package held back part-way
  // through it.
  @FailingTest(
    reason:
        'The runner collects edits globally as each package finishes a step, '
        'so the bump `core` completes before `app` fails is still emitted '
        'once `core` is held back. Need to discard those edits.',
  )
  Future<void> test_stop_dependencies_requestedFirst() async {
    var core = _createPackageFolder('core', sdkConstraint: '^3.11.0');
    // `app` has no package config, so its bump fails partway through the
    // first round.
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['core'],
      writePackageConfig: false,
    );
    var unrelated = _createPackageFolder('unrelated', sdkConstraint: '^3.11.0');
    await initialize(workspaceFolders: [app, core, unrelated]);

    await _assertMigrationResult(
      uris: [core, app, unrelated],
      targetSdk: '3.13.0',
      apply: true,
      expectedEdit: '''
>>>>>>>>>> ../unrelated/pubspec.yaml
name: unrelated
environment:
  sdk: '^3.13.0'
''',
    );
  }

  /// A dependency that isn't being migrated is already fixed where it is, so
  /// a stop has nothing to hold back.
  Future<void> test_stop_dependencyOutsideMigration() async {
    var core = _createPackageFolder('core', sdkConstraint: '^3.11.0');
    // `app` has no package config, so its bump fails.
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['core'],
      writePackageConfig: false,
    );
    await initialize(workspaceFolders: [app, core]);

    // Only `app` migrates, so `core` is never scheduled and never reported.
    await _assertMigrationResult(
      uris: [app],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
app:
  3.11.0 -> 3.12.0: Failed
    Failed to update .dart_tool/package_config.json for "app". Try running "dart pub get" to update the package configuration, then re-run the migration.''',
    );
  }

  /// A stopped package leaves its dependents running, since a dependent
  /// sitting above its dependency is ordinary.
  Future<void> test_stop_dependents() async {
    // `core` has no package config, so its bump fails.
    var core = _createPackageFolder(
      'core',
      sdkConstraint: '^3.11.0',
      writePackageConfig: false,
    );
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['core'],
    );
    await initialize(workspaceFolders: [app, core]);

    // A dependent may sit above its dependency, so `app` carries on to the
    // target while `core` stays where it failed.
    await _assertMigrationResult(
      uris: [app, core],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
app:
  3.11.0 -> 3.12.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.11.0 -> ^3.12.0

    Cleanup changes:
      0 changes made in 0 files.

  3.12.0 -> 3.13.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      0 changes made in 0 files.

core:
  3.11.0 -> 3.12.0: Failed
    Failed to update .dart_tool/package_config.json for "core". Try running "dart pub get" to update the package configuration, then re-run the migration.''',
      expectedEdit: '''
>>>>>>>>>> ../app/pubspec.yaml
name: app
environment:
  sdk: '^3.13.0'
dependencies:
  core:
    path: ../core
''',
    );
  }

  /// The stop walk follows every dependency of a package, and carries on to
  /// their dependencies. A package reachable by two paths is held back once,
  /// not twice.
  Future<void> test_stop_diamondDependencies() async {
    var base = _createPackageFolder('base', sdkConstraint: '^3.11.0');
    var left = _createPackageFolder(
      'left',
      sdkConstraint: '^3.11.0',
      dependencies: ['base'],
    );
    var right = _createPackageFolder(
      'right',
      sdkConstraint: '^3.11.0',
      dependencies: ['base'],
    );
    // `app` has no package config, so its bump fails.
    var app = _createPackageFolder(
      'app',
      sdkConstraint: '^3.11.0',
      dependencies: ['left', 'right'],
      writePackageConfig: false,
    );
    await initialize(workspaceFolders: [app, left, right, base]);

    await _assertMigrationResult(
      uris: [app, left, right, base],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
app:
  3.11.0 -> 3.12.0: Failed
    Failed to update .dart_tool/package_config.json for "app". Try running "dart pub get" to update the package configuration, then re-run the migration.

left:
  3.11.0 -> 3.12.0: Skipped
    Held back by "app", which stopped at 3.11.0.

right:
  3.11.0 -> 3.12.0: Skipped
    Held back by "app", which stopped at 3.11.0.

base:
  3.11.0 -> 3.12.0: Skipped
    Held back by "app", which stopped at 3.11.0.''',
    );
  }

  /// Collects the stage messages the server reports against [token] as they
  /// arrive.
  ///
  /// The order of these messages is what shows which packages moved together.
  List<String> _collectStageMessages(ProgressToken token) {
    var messages = <String>[];
    notificationsFromServer
        .where((n) => n.method == Method.progress)
        .map((n) => ProgressParams.fromJson(n.params as Map<String, Object?>))
        .where((params) => params.token == token)
        .listen((params) {
          var value = params.value as Map<String, Object?>;
          if (value['kind'] == 'report') {
            messages.add(value['message'] as String);
          }
        });
    return messages;
  }

  /// Writes a package [name] under `/home` that declares [sdkConstraint] and
  /// path dependencies on [dependencies] and [devDependencies], and returns
  /// its directory URI for the test to open as an analysis root.
  ///
  /// Dependencies must be created first: their folders have to exist for the
  /// package config to point at them.
  ///
  /// Pass `writePackageConfig: false` to leave the package without a
  /// `.dart_tool/package_config.json`, which is what makes its bump step fail.
  Uri _createPackageFolder(
    String name, {
    required String sdkConstraint,
    List<String> dependencies = const [],
    List<String> devDependencies = const [],
    bool writePackageConfig = true,
  }) {
    var pubspec = StringBuffer('''
name: $name
environment:
  sdk: '$sdkConstraint'
''');
    for (var (section, names) in [
      ('dependencies', dependencies),
      ('dev_dependencies', devDependencies),
    ]) {
      if (names.isEmpty) continue;
      pubspec.writeln('$section:');
      for (var dependency in names) {
        pubspec.writeln('  $dependency:');
        pubspec.writeln('    path: ../$dependency');
      }
    }

    var packagePath = convertPath('/home/$name');
    var pubspecPath = join(packagePath, 'pubspec.yaml');
    if (writePackageConfig) {
      var config = PackageConfigFileBuilder();
      for (var dependency in [...dependencies, ...devDependencies]) {
        config.add(
          name: dependency,
          rootFolder: resourceProvider.getFolder(
            convertPath('/home/$dependency'),
          ),
        );
      }
      writePubspecFile(
        pubspecPath,
        pubspec.toString(),
        packageConfigBuilder: config,
      );
    } else {
      newFile(pubspecPath, pubspec.toString());
    }
    newFile(join(packagePath, 'lib', '$name.dart'), 'void f() {}\n');

    return toUri(packagePath);
  }
}

@reflectiveTest
class MigrateMultiVersionTest extends AbstractMigrateTest {
  Future<void> test_alreadyAtTargetSdk() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.13.0'
''');
    newFile(mainFilePath, '''
class C {
  new(int x);
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (Already at target SDK version 3.13.0.)''',
    );
  }

  /// A prerelease constraint counts as the version it belongs to.
  Future<void> test_alreadyAtTargetSdk_prerelease() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.13.0-dev.1'
''');
    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (Already at target SDK version 3.13.0.)''',
    );
  }

  Future<void> test_dependencyConflictIntermediateStep() async {
    var depPath = convertPath('/dep_package');
    writePubspecFile(join(depPath, 'pubspec.yaml'), '''
name: dep_package
environment:
  sdk: '>=3.0.0 <3.13.0'
''');
    newFile(join(depPath, 'lib', 'dep.dart'), '');

    var builder = PackageConfigFileBuilder();
    builder.add(
      name: 'dep_package',
      rootFolder: resourceProvider.getFolder(depPath),
    );

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.11.0'
''', packageConfigBuilder: builder);
    newFile(mainFilePath, '''
class A {
  int x;
  A(int x) : this.x = x;
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  3.11.0 -> 3.12.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.11.0 -> ^3.12.0

    Cleanup changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        prefer_initializing_formals • 1 change

  3.12.0 -> 3.13.0: Skipped
    Incompatible dependencies:
      - dep_package''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class A {
  int x;
  A(this.x);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.12.0'
''',
    );
  }

  Future<void> test_higherThanTargetSdk() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.14.0'
''');
    newFile(mainFilePath, '''
class C {
  new(int x);
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (Already at target SDK version 3.13.0.)''',
    );
  }

  Future<void> test_multiplePackages() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.11.0'
''');
    newFile(mainFilePath, '''
class A {
  int x;
  A(int x) : this.x = x;
}
''');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');
    newFile(otherFilePath, '''
class D {
  D(final int y);
}
''');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      uris: [projectFolderUri, toUri(otherPackagePath)],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  3.11.0 -> 3.12.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.11.0 -> ^3.12.0

    Cleanup changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        prefer_initializing_formals • 1 change

  3.12.0 -> 3.13.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 1 change

other_package:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      other_package/lib/other.dart
        avoid_final_parameters • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      1 change made in 1 file.

      other_package/lib/other.dart
        unnecessary_type_name_in_constructor • 1 change''',
      expectedEdit: '''
>>>>>>>>>> ../other_package/lib/other.dart
class D {
  new(int y);
}
>>>>>>>>>> ../other_package/pubspec.yaml
name: other_package
environment:
  sdk: '^3.13.0'
>>>>>>>>>> lib/main.dart
class A {
  int x;
  new(this.x);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_multiplePackages_oneAlreadyAtTarget() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.11.0'
''');
    newFile(mainFilePath, '''
class A {
  int x;
  A(int x) : this.x = x;
}
''');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.13.0'
''');
    newFile(otherFilePath, '''
class D {
  new(int y);
}
''');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      uris: [projectFolderUri, toUri(otherPackagePath)],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  3.11.0 -> 3.12.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.11.0 -> ^3.12.0

    Cleanup changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        prefer_initializing_formals • 1 change

  3.12.0 -> 3.13.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 1 change

other_package:
  Skipped (Already at target SDK version 3.13.0.)''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class A {
  int x;
  new(this.x);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_singlePackage() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.11.0'
''');
    newFile(mainFilePath, '''
class A {
  int x;
  A(int x) : this.x = x;
}

class C {
  C(final int x);
  C.name(final String s);
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  3.11.0 -> 3.12.0:
    Preparatory changes:
      0 changes made in 0 files.

    SDK constraint:
      Bumped ^3.11.0 -> ^3.12.0

    Cleanup changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        prefer_initializing_formals • 1 change

  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 2 changes

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      3 changes made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 3 changes''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class A {
  int x;
  new(this.x);
}

class C {
  new(int x);
  new name(String s);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_singlePackage_dryRun() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.11.0'
''');
    newFile(mainFilePath, '''
class A {
  int x;
  A(int x) : this.x = x;
}

class C {
  C(final int x);
  C.name(final String s);
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      targetSdk: '3.13.0',
      expectedSummary: '''
test_project:
  3.11.0 -> 3.12.0:
    Preparatory changes:
      0 changes would be made in 0 files.

    SDK constraint:
      Would bump ^3.11.0 -> ^3.12.0

    Cleanup changes:
      1 change would be made in 1 file.

      my_project/lib/main.dart
        prefer_initializing_formals • 1 change

  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes would be made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 2 changes

    SDK constraint:
      Would bump ^3.12.0 -> ^3.13.0

    Cleanup changes:
      3 changes would be made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 3 changes''',
    );
  }

  Future<void> test_unsupportedPackageSdkVersion() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^2.19.0'
''');
    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      targetSdk: '3.13.0',
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (The package SDK version "2.19.0" is not supported for migration. It must be between ${knownSdkVersions.first} and ${knownSdkVersions.last}.)''',
    );
  }
}

@reflectiveTest
class MigratePackageValidationTest extends AbstractMigrateTest {
  Future<void> test_error_directoryWithoutPubspec() async {
    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [projectFolderUri], apply: true),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "The directory '$projectFolderPath' doesn't contain a 'pubspec.yaml' "
          'file.',
        ),
      ),
    );
  }

  Future<void> test_error_fileUri() async {
    await initialize();

    newFile(mainFilePath, '');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [mainFileUri], apply: true),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "The path '$mainFilePath' doesn't refer to a package or pub workspace"
          ' directory.',
        ),
      ),
    );
  }

  Future<void> test_error_fileUri_multipleWithOneInvalid() async {
    await initialize();

    writePubspecFile(pubspecFilePath, 'name: test_project');

    var validUri = projectFolderUri;
    var invalidUri = Uri.parse('http://example.com');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [validUri, invalidUri], apply: true),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ServerErrorCodes.invalidFilePath,
        message: contains("URI scheme 'http' is not supported"),
      ),
    );
  }

  Future<void> test_error_invalidPubspec() async {
    await initialize();

    writePubspecFile(pubspecFilePath, 'invalid: [');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [projectFolderUri], apply: true),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "Failed to parse 'pubspec.yaml' at '$projectFolderPath'",
        ),
      ),
    );
  }

  Future<void> test_error_nonExistentDirectory() async {
    await initialize();

    var dirUri = Uri.file(convertPath('/non/existent/dir'));
    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [dirUri], apply: true),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains("doesn't exist"),
      ),
    );
  }

  Future<void> test_error_packageSdk_alreadyAtLatestKnownSdkVersion() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^${knownSdkVersions.last}'
''');
    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (The package is already at the latest supported SDK version (${knownSdkVersions.last}).)''',
    );
  }

  Future<void> test_error_packageSdk_unsupportedVersion() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^2.19.0'
''');
    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (The package SDK version "2.19.0" is not supported for migration. It must be between ${knownSdkVersions.first} and ${knownSdkVersions.last}.)''',
    );
  }

  Future<void>
  test_error_packageSdk_unsupportedVersion_multiplePackages() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^2.19.0'
''');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      uris: [projectFolderUri, toUri(otherPackagePath)],
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary:
          '''
test_project:
  Skipped (The package SDK version "2.19.0" is not supported for migration. It must be between ${knownSdkVersions.first} and ${knownSdkVersions.last}.)

other_package:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> ../other_package/pubspec.yaml
name: other_package
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_error_targetSdk_greaterThanServerSdk() async {
    writePubspecFile(pubspecFilePath, 'name: test_project');
    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: [projectFolderUri],
        apply: false,
        targetSdk: '99.0.0',
      ),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: allOf(
          contains(
            "Can't migrate to Dart version 99.0.0. In order to migrate, "
            'the running SDK version must be the same as or greater than '
            'the version being migrated to.',
          ),
          contains(
            'Please either update your Dart SDK first or migrate to a '
            'version that is less than the running version.',
          ),
        ),
      ),
    );
  }

  Future<void> test_error_targetSdk_invalidSemver() async {
    writePubspecFile(pubspecFilePath, 'name: test_project');
    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: [projectFolderUri],
        apply: false,
        targetSdk: 'not-a-version',
      ),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: 'The target SDK version "not-a-version" is not a valid semantic version.',
      ),
    );
  }

  Future<void> test_error_targetSdk_notMinorRelease_patch() async {
    writePubspecFile(pubspecFilePath, 'name: test_project');
    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: [projectFolderUri],
        apply: false,
        targetSdk: '3.12.5',
      ),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: 'The target SDK version "3.12.5" must be a minor release (e.g., "3.12.0").',
      ),
    );
  }

  Future<void> test_error_targetSdk_notMinorRelease_preRelease() async {
    writePubspecFile(pubspecFilePath, 'name: test_project');
    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: [projectFolderUri],
        apply: false,
        targetSdk: '3.12.0-dev.1',
      ),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: 'The target SDK version "3.12.0-dev.1" must be a minor release (e.g., "3.12.0").',
      ),
    );
  }

  Future<void> test_error_targetSdk_singleStep() async {
    writePubspecFile(pubspecFilePath, 'name: test_project');
    await initialize();
    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: [projectFolderUri],
        apply: false,
        targetSdk: '3.10.0',
        steps: [MigrationStep.Bump],
      ),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message:
            'Multi-version migration requires running all steps (--step=all).',
      ),
    );
  }

  Future<void> test_error_targetSdk_unsupportedVersion() async {
    writePubspecFile(pubspecFilePath, 'name: test_project');
    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: [projectFolderUri],
        apply: false,
        targetSdk: '2.11.0',
      ),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message:
            'The target SDK version "2.11.0" is not supported for migration. '
            'It must be between ${knownSdkVersions.first} and '
            '${knownSdkVersions.last}.',
      ),
    );
  }

  Future<void> test_error_workspacePackage() async {
    await initialize();

    writePubspecFile(pubspecFilePath, '''
name: test_project
resolution: workspace
''');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [projectFolderUri], apply: true),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "The directory '$projectFolderPath' is part of a workspace and can't "
          'be migrated independently.',
        ),
      ),
    );
  }

  Future<void> test_targetSdkAboveKnownRange() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^${knownSdkVersions.last}'
''');
    await initialize();

    var pubspecFile = resourceProvider.getFile(pubspecFilePath);
    var pubspecYaml = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    var pubspecTarget = PubspecTarget(file: pubspecFile, pubspec: pubspecYaml);

    var summaryBuilder = MigrationSummaryBuilder(
      apply: true,
      pathContext: pathContext,
      steps: [MigrationStep.All],
    );

    var targetSdk = Version(
      knownSdkVersions.last.major,
      knownSdkVersions.last.minor + 1,
      0,
    );
    var runner = MigrationRunner(
      server: server,
      pubspecTargets: [pubspecTarget],
      summaryBuilder: summaryBuilder,
      targetSdk: targetSdk,
    );

    var result = await runner.computeEdits([MigrationStep.All]);
    expect(result.isError, isFalse);
    expect(
      summaryBuilder.generate(),
      contains(
        'Skipped (The target SDK version "$targetSdk" is not supported for '
        'migration. It must be between ${knownSdkVersions.first} and '
        '${knownSdkVersions.last}.)',
      ),
    );
  }

  Future<void> test_validDirectory() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
environment:
  sdk: '^3.12.0'
''',
    );
    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }
}

@reflectiveTest
class MigrateProgressTest extends AbstractMigrateTest {
  Future<void> test_progressReporting() async {
    await _setupProject(
      pubspecContent: '''
name: test
environment:
  sdk: '>=3.11.0 <4.0.0'
''',
    );

    newFile(mainFilePath, '''
class Foo {
  Foo(final int x);
}
''');

    var token = clientProvidedTestWorkDoneToken;
    var progressNotifications = <ProgressParams>[];
    notificationsFromServer
        .where((n) => n.method == Method.progress)
        .map((n) => ProgressParams.fromJson(n.params as Map<String, Object?>))
        .where((params) => params.token == token)
        .listen(progressNotifications.add);

    await _assertMigrationResult(
      targetSdk: '3.13.0',
      apply: true,
      workDoneToken: token,
    );

    expect(progressNotifications, isNotEmpty);

    // First notification should be begin.
    var firstValue = progressNotifications.first.value as Map<String, Object?>;
    expect(firstValue['kind'], 'begin');

    // Last notification should be end.
    var lastValue = progressNotifications.last.value as Map<String, Object?>;
    expect(lastValue['kind'], 'end');

    // Intermediate notifications should be reports with stage messages.
    var reports = progressNotifications
        .sublist(1, progressNotifications.length - 1)
        .map((p) => p.value as Map<String, Object?>)
        .toList();

    expect(reports, isNotEmpty);
    for (var report in reports) {
      expect(report['kind'], 'report');
      expect(report['message'], isNotEmpty);
    }

    var messages = reports.map((r) => r['message'] as String).toList();
    expect(messages, [
      'test: 3.11.0 -> 3.12.0 (prepare)',
      'test: 3.11.0 -> 3.12.0 (bump)',
      'test: 3.12.0 (cleanup)',
      'test: 3.12.0 -> 3.13.0 (prepare)',
      'test: 3.12.0 -> 3.13.0 (bump)',
      'test: 3.13.0 (cleanup)',
    ]);
  }
}

@reflectiveTest
class MigrateStepsTest extends AbstractMigrateTest {
  Future<void> test_all() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
class C {
  C(final int x);
  C.name(final String s);
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 2 changes

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 2 changes''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class C {
  new(int x);
  new name(String s);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_all_multiplePackages() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
class C {
  C(var x);
}
''');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');
    newFile(otherFilePath, '''
class D {
  D(final int y);
}
''');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      steps: [MigrationStep.All],
      uris: [projectFolderUri, toUri(otherPackagePath)],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        var_with_no_type_annotation • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 1 change

other_package:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      other_package/lib/other.dart
        avoid_final_parameters • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      1 change made in 1 file.

      other_package/lib/other.dart
        unnecessary_type_name_in_constructor • 1 change''',
      expectedEdit: '''
>>>>>>>>>> ../other_package/lib/other.dart
class D {
  new(int y);
}
>>>>>>>>>> ../other_package/pubspec.yaml
name: other_package
environment:
  sdk: '^3.13.0'
>>>>>>>>>> lib/main.dart
class C {
  new(x);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_bump() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_bump_dryRun() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Would bump ^3.12.0 -> ^3.13.0''',
    );
  }

  Future<void> test_bump_emptyPubspec() async {
    await _setupProject(pubspecContent: '');
    await _assertMigrationResult(
      apply: true,
      steps: [MigrationStep.Bump],
      expectedSummary: '',
    );
  }

  Future<void> test_bump_error_missingPackageConfig() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0: Failed
    Failed to update .dart_tool/package_config.json for "test_project". Try running "dart pub get" to update the package configuration, then re-run the migration.''',
    );
  }

  Future<void> test_bump_error_prepareNeeded() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0: Failed
    Package "test_project" requires pre-bump fixes before the SDK constraint can be bumped.''',
    );
  }

  Future<void> test_bump_error_prepareNeeded_multiplePackages() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');
    newFile(otherFilePath, 'void f(int y) {}\n');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      uris: [projectFolderUri, toUri(otherPackagePath)],
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0: Failed
    Package "test_project" requires pre-bump fixes before the SDK constraint can be bumped.

other_package:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> ../other_package/pubspec.yaml
name: other_package
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_bump_multiplePackages() async {
    var project1Path = pathContext.join(projectFolderPath, 'project1');
    var project2Path = pathContext.join(projectFolderPath, 'project2');

    writePubspecFile(pathContext.join(project1Path, 'pubspec.yaml'), '''
name: project1
environment:
  sdk: '^3.0.0'
''');

    writePubspecFile(pathContext.join(project2Path, 'pubspec.yaml'), '''
name: project2
environment:
  sdk: '^3.2.0'
''');

    await initialize();

    await _assertMigrationResult(
      uris: [Uri.file(project1Path), Uri.file(project2Path)],
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
project1:
  3.0.0 -> 3.1.0:
    SDK constraint:
      Bumped ^3.0.0 -> ^3.1.0

project2:
  3.2.0 -> 3.3.0:
    SDK constraint:
      Bumped ^3.2.0 -> ^3.3.0''',
      expectedEdit: '''
>>>>>>>>>> project1/pubspec.yaml
name: project1
environment:
  sdk: '^3.1.0'
>>>>>>>>>> project2/pubspec.yaml
name: project2
environment:
  sdk: '^3.3.0'
''',
    );
  }

  Future<void> test_bump_noneBumped() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
''',
    );
    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (Unknown SDK version.)''',
    );
  }

  Future<void> test_bump_range() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
''',
    );
    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: contains('>=3.0.0 <4.0.0 -> >=3.1.0 <4.0.0'),
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '>=3.1.0 <4.0.0'
''',
    );
  }

  Future<void> test_bump_skipped() async {
    var otherDirPath = convertPath('/other_project');
    var otherPubspecPath = pathContext.join(otherDirPath, 'pubspec.yaml');

    await _setupProject(
      pubspecContent: '''
name: other_project
environment:
  sdk: '^3.12.0'
''',
      customPubspecFilePath: otherPubspecPath,
    );
    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      uris: [Uri.file(otherDirPath)],
      apply: true,
      expectedSummary: '''
other_project:
  3.12.0 -> 3.13.0: Skipped
    The package is not being analyzed. Add its directory to your workspace.''',
    );
  }

  Future<void> test_bumpAndCleanup() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
class C {
  C();
  C.name();
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump, MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 2 changes''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class C {
  new();
  new name();
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void>
  test_bumpAndCleanup_error_prepareNeeded_multiplePackages() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');
    newFile(otherFilePath, '''
class C {
  C();
  C.name();
}
''');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      uris: [projectFolderUri, toUri(otherPackagePath)],
      steps: [MigrationStep.Bump, MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0: Failed
    Package "test_project" requires pre-bump fixes before the SDK constraint can be bumped.

other_package:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      2 changes made in 1 file.

      other_package/lib/other.dart
        unnecessary_type_name_in_constructor • 2 changes''',
      expectedEdit: '''
>>>>>>>>>> ../other_package/lib/other.dart
class C {
  new();
  new name();
}
>>>>>>>>>> ../other_package/pubspec.yaml
name: other_package
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_cleanup() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.13.0'
''');
    newFile(mainFilePath, '''
class C {
  C();
  C.name();
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
test_project:
  3.13.0:
    Cleanup changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 2 changes''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class C {
  new();
  new name();
}
''',
    );
  }

  /// Cleanup does not advance the SDK version, so a package that is already at
  /// the latest known version is still eligible for it.
  Future<void> test_cleanup_atLatestKnownSdkVersion() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^${knownSdkVersions.last}'
''');
    newFile(mainFilePath, 'void m(int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Cleanup],
      apply: true,
      expectedSummary:
          '''
test_project:
  ${knownSdkVersions.last}:
    Cleanup changes:
      0 changes made in 0 files.''',
    );
  }

  Future<void> test_cleanup_dryRun() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.13.0'
''');
    newFile(mainFilePath, '''
class C {
  C();
  C.name();
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Cleanup],
      expectedSummary: '''
test_project:
  3.13.0:
    Cleanup changes:
      2 changes would be made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 2 changes''',
    );
  }

  Future<void> test_cleanup_error_missingSdkConstraint() async {
    await _setupProject(pubspecContent: 'name: test_project');
    await _assertMigrationResult(
      steps: [MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
test_project:
  Skipped (Unknown SDK version.)''',
    );
  }

  Future<void> test_cleanup_multiplePackages_oneSkipped() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.13.0'
''');
    newFile(mainFilePath, '''
class C {
  C();
  C.name();
}
''');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');
    newFile(otherFilePath, 'void f(int y) {}\n');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      uris: [projectFolderUri, toUri(otherPackagePath)],
      steps: [MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
test_project:
  3.13.0:
    Cleanup changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 2 changes

other_package:
  3.12.0:
    Cleanup changes:
      0 changes made in 0 files.''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class C {
  new();
  new name();
}
''',
    );
  }

  Future<void> test_cleanup_noCleanupFixesRegistered_skipped() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.10.0'
''');
    newFile(mainFilePath, 'void m(int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
test_project:
  3.10.0:
    Cleanup changes:
      0 changes made in 0 files.''',
    );
  }

  Future<void> test_dryRun() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
class C {
  C(var x);
  C.name(final String s);
}
''');

    await initialize();

    await _assertMigrationResult(
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes would be made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change
        var_with_no_type_annotation • 1 change

    SDK constraint:
      Would bump ^3.12.0 -> ^3.13.0

    Cleanup changes:
      2 changes would be made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 2 changes''',
    );
  }

  Future<void> test_empty() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
void m(final int x) {}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [],
      apply: true,
      expectedSummary: '''
test_project:
  No changes.''',
    );
  }

  Future<void> test_prepare() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
void m(final int x) {}

class C {
  C();
  C.name();
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x) {}

class C {
  C();
  C.name();
}
''',
    );
  }

  Future<void> test_prepare_dryRun() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
void m(final int x) {}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare],
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change would be made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change''',
    );
  }

  Future<void> test_prepare_zeroChanges() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
void m(int x) {}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      0 changes made in 0 files.''',
    );
  }

  Future<void> test_prepareAndBump() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
void m(final int x) {}

class C {
  C();
  C.name();
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x) {}

class C {
  C();
  C.name();
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndBump_multipleFiles() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    var otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    newFile(mainFilePath, 'void m(final int x) {}\n');
    newFile(otherFilePath, 'void f(var y) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes made in 2 files.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change

      my_project/lib/other.dart
        var_with_no_type_annotation • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x) {}
>>>>>>>>>> lib/other.dart
void f(y) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndBump_multipleModifiers() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x, var y) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change
        var_with_no_type_annotation • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x, y) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndBump_multiplePackages() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    writePubspecFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');
    newFile(otherFilePath, 'void f(var y) {}\n');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump],
      uris: [projectFolderUri, toUri(otherPackagePath)],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

other_package:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      other_package/lib/other.dart
        var_with_no_type_annotation • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> ../other_package/lib/other.dart
void f(y) {}
>>>>>>>>>> ../other_package/pubspec.yaml
name: other_package
environment:
  sdk: '^3.13.0'
>>>>>>>>>> lib/main.dart
void m(int x) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndBump_nestedAnalysisOptions() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    var analysisOptionsPath = join(projectFolderPath, 'analysis_options.yaml');
    newFile(analysisOptionsPath, '');

    var aPath = join(projectFolderPath, 'lib', 'a.dart');
    newFile(aPath, 'void m(final int x) {}\n');

    var nestedAnalysisOptionsPath = join(
      projectFolderPath,
      'lib',
      'src',
      'analysis_options.yaml',
    );
    newFile(nestedAnalysisOptionsPath, '');

    var bPath = join(projectFolderPath, 'lib', 'src', 'b.dart');
    newFile(bPath, 'void f(final int y) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes made in 2 files.

      my_project/lib/a.dart
        avoid_final_parameters • 1 change

      my_project/lib/src/b.dart
        avoid_final_parameters • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/a.dart
void m(int x) {}
>>>>>>>>>> lib/src/b.dart
void f(int y) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndBump_nestedPackage() async {
    // Parent package
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    // Nested package in 'example/'
    var examplePath = join(projectFolderPath, 'example');
    var examplePubspecPath = join(examplePath, 'pubspec.yaml');
    var exampleMainPath = join(examplePath, 'lib', 'main.dart');
    writePubspecFile(examplePubspecPath, '''
name: example
environment:
  sdk: '^3.12.0'
''');
    newFile(exampleMainPath, 'void f(var y) {}\n');

    await initialize();

    // Migrate ONLY the parent package.
    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      1 change made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 1 change

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndBump_noEdits() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(int x, y) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndCleanUp() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
void m(final int x) {}
''');

    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: [projectFolderUri],
        apply: true,
        steps: [MigrationStep.Prepare, MigrationStep.Cleanup],
      ),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "The 'prepare' and 'cleanup' steps cannot be run together without "
          "also running 'bump'.",
        ),
      ),
    );
  }

  Future<void> test_prepareBumpAndCleanup() async {
    writePubspecFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
class C {
  C(final int x);
  C.name(final String s);
}
''');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump, MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
test_project:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        avoid_final_parameters • 2 changes

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

    Cleanup changes:
      2 changes made in 1 file.

      my_project/lib/main.dart
        unnecessary_type_name_in_constructor • 2 changes''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
class C {
  new(int x);
  new name(String s);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }
}
