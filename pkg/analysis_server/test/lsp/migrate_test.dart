// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MigrateDependencyConflictTest);
    defineReflectiveTests(MigratePackageValidationTest);
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

  Future<void> _assertMigrationResult({
    List<Uri>? uris,
    List<MigrationStep> steps = const [MigrationStep.All],
    Object? expectedSummary,
    String? expectedEdit,
    bool apply = false,
  }) async {
    await workspaceAnalysisComplete();
    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: uris ?? [projectFolderUri],
        apply: apply,
        steps: steps,
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
    if (!apply) {
      expect(result.edit, isNull);
    } else if (expectedEdit != null) {
      verifyEdit(result.edit!, expectedEdit);
    }
  }

  Future<void> _setupProject({
    required String pubspecContent,
    String? customPubspecFilePath,
  }) async {
    var pubspecPath = customPubspecFilePath ?? pubspecFilePath;
    newFile(pubspecPath, pubspecContent);

    await initialize();
  }
}

@reflectiveTest
class MigrateDependencyConflictTest extends AbstractMigrateTest {
  Future<void> test_dart3BackwardsCompatibility() async {
    newFile(pubspecFilePath, '''
name: test
environment:
  sdk: '^3.12.0'
''');

    var depPath = convertPath('/dep_package');
    newFile(join(depPath, 'pubspec.yaml'), '''
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
    writeTestPackageConfig(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_dependencyConflict() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');

    var depPath = convertPath('/dep_package');
    newFile(join(depPath, 'pubspec.yaml'), '''
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
    writeTestPackageConfig(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
- test_project: Skipped
  Incompatible dependencies:
    - dep_package

No SDK constraints were bumped.''',
    );
  }

  Future<void> test_multiple() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');

    // dep_package1: Incompatible
    var dep1Path = convertPath('/dep_package1');
    newFile(join(dep1Path, 'pubspec.yaml'), '''
name: dep_package1
environment:
  sdk: '>=3.0.0 <3.13.0'
''');
    newFile(join(dep1Path, 'lib', 'dep1.dart'), '');

    // dep_package2: Incompatible
    var dep2Path = convertPath('/dep_package2');
    newFile(join(dep2Path, 'pubspec.yaml'), '''
name: dep_package2
environment:
  sdk: '>=3.0.0 <3.13.0'
''');
    newFile(join(dep2Path, 'lib', 'dep2.dart'), '');

    // dep_package3: Compatible
    var dep3Path = convertPath('/dep_package3');
    newFile(join(dep3Path, 'pubspec.yaml'), '''
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

    writeTestPackageConfig(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
- test_project: Skipped
  Incompatible dependencies:
    - dep_package1
    - dep_package2

No SDK constraints were bumped.''',
    );
  }

  Future<void> test_transitive() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');

    // direct_dep: Compatible
    var directDepPath = convertPath('/direct_dep');
    newFile(join(directDepPath, 'pubspec.yaml'), '''
name: direct_dep
environment:
  sdk: '>=3.0.0 <4.0.0'
''');
    newFile(join(directDepPath, 'lib', 'direct_dep.dart'), '');

    // transitive_dep: Incompatible
    var transitiveDepPath = convertPath('/transitive_dep');
    newFile(join(transitiveDepPath, 'pubspec.yaml'), '''
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
    writeTestPackageConfig(config: builder, languageVersion: '3.12');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
- test_project: Skipped
  Incompatible dependencies:
    - transitive_dep

No SDK constraints were bumped.''',
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

    newFile(pubspecFilePath, 'name: test_project');

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

    newFile(pubspecFilePath, 'invalid: [');

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

  Future<void> test_error_workspacePackage() async {
    await initialize();

    newFile(pubspecFilePath, '''
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
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
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
class MigrateStepsTest extends AbstractMigrateTest {
  Future<void> test_all() async {
    newFile(pubspecFilePath, '''
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
Preparatory changes for a version bump:
  2 changes made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 2 changes

Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Cleanup changes after a version bump:
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

    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
class C {
  C(var int x);
}
''');

    newFile(otherPubspecPath, '''
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
Preparatory changes for a version bump:
  2 changes made in 2 files.

  my_project/lib/main.dart
    extraneous_modifier • 1 change

  other_package/lib/other.dart
    extraneous_modifier • 1 change

Bumped SDK constraints in 2 package(s):
  - test_project: ^3.12.0 -> ^3.13.0
  - other_package: ^3.12.0 -> ^3.13.0

Cleanup changes after a version bump:
  2 changes made in 2 files.

  my_project/lib/main.dart
    unnecessary_type_name_in_constructor • 1 change

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
  new(int x);
}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_bump() async {
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
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_bump_emptyPubspec() async {
    await _setupProject(pubspecContent: '');
    await _assertMigrationResult(
      apply: true,
      steps: [MigrationStep.Bump],
      expectedSummary: 'No SDK constraints were bumped.',
    );
  }

  Future<void> test_bump_error_prepareNeeded() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      apply: true,
      expectedSummary: allOf(
        contains(
          '- test_project:\n'
          '    Failed version bump with error: Package "test_project" requires '
          'pre-bump fixes before the SDK constraint can be bumped.',
        ),
        contains('No SDK constraints were bumped.'),
      ),
    );
  }

  Future<void> test_bump_error_prepareNeeded_multiplePackages() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    newFile(otherPubspecPath, '''
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
      expectedSummary: allOf(
        contains(
          'Bumped SDK constraints in 1 package(s):\n'
          '  - other_package: ^3.12.0 -> ^3.13.0',
        ),
        contains(
          '- test_project:\n'
          '    Failed version bump with error: Package "test_project" requires '
          'pre-bump fixes before the SDK constraint can be bumped.',
        ),
      ),
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

    newFile(pathContext.join(project1Path, 'pubspec.yaml'), '''
name: project1
environment:
  sdk: '^3.0.0'
''');

    newFile(pathContext.join(project2Path, 'pubspec.yaml'), '''
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
Bumped SDK constraints in 2 package(s):
  - project1: ^3.0.0 -> ^3.1.0
  - project2: ^3.2.0 -> ^3.3.0''',
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
      expectedSummary: 'No SDK constraints were bumped.',
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
      expectedSummary: contains('>=3.0.0 <4.0.0 -> >=3.1.0'),
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
      pubspecContent: 'name: other_project',
      customPubspecFilePath: otherPubspecPath,
    );
    await _assertMigrationResult(
      steps: [MigrationStep.Bump],
      uris: [Uri.file(otherDirPath)],
      apply: true,
      expectedSummary: contains('- other_project: Skipped (not analyzed)'),
    );
  }

  Future<void> test_bumpAndCleanup() async {
    newFile(pubspecFilePath, '''
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
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Cleanup changes after a version bump:
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

    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    newFile(otherPubspecPath, '''
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
- test_project:
    Failed version bump with error: Package "test_project" requires pre-bump fixes before the SDK constraint can be bumped.

Bumped SDK constraints in 1 package(s):
  - other_package: ^3.12.0 -> ^3.13.0

Cleanup changes after a version bump:
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
    newFile(pubspecFilePath, '''
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
Cleanup changes after a version bump:
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

  Future<void> test_cleanup_error_missingSdkConstraint() async {
    await _setupProject(pubspecContent: 'name: test_project');
    await _assertMigrationResult(
      steps: [MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
- test_project:
    Failed cleanup with error: Unknown SDK version.

Cleanup changes after a version bump:
  0 changes made in 0 files.''',
    );
  }

  Future<void> test_cleanup_multiplePackages_oneSkipped() async {
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    newFile(pubspecFilePath, '''
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

    newFile(otherPubspecPath, '''
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
Cleanup changes after a version bump:
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

  Future<void> test_cleanup_noCleanupFixesRegistered_skipped() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^2.12.0'
''');
    newFile(mainFilePath, 'void m(int x) {}\n');

    await initialize();

    await _assertMigrationResult(
      steps: [MigrationStep.Cleanup],
      apply: true,
      expectedSummary: '''
Cleanup changes after a version bump:
  0 changes made in 0 files.''',
    );
  }

  Future<void> test_dryRun() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
class C {
  C(var int x);
  C.name(final String s);
}
''');

    await initialize();

    await _assertMigrationResult(
      expectedSummary: '''
Preparatory changes for a version bump:
  2 changes would be made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 2 changes

Would bump SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Cleanup changes after a version bump:
  2 changes would be made in 1 file.

  my_project/lib/main.dart
    unnecessary_type_name_in_constructor • 2 changes''',
    );
  }

  Future<void> test_empty() async {
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, '''
void m(final int x) {}
''');

    await initialize();

    await _assertMigrationResult(steps: [], apply: true, expectedSummary: '');
  }

  Future<void> test_prepare() async {
    newFile(pubspecFilePath, '''
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
Preparatory changes for a version bump:
  1 change made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 1 change''',
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

  Future<void> test_prepareAndBump() async {
    newFile(pubspecFilePath, '''
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
Preparatory changes for a version bump:
  1 change made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 1 change

Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
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
    newFile(pubspecFilePath, '''
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
Preparatory changes for a version bump:
  2 changes made in 2 files.

  my_project/lib/main.dart
    extraneous_modifier • 1 change

  my_project/lib/other.dart
    extraneous_modifier • 1 change

Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
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
    newFile(pubspecFilePath, '''
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
Preparatory changes for a version bump:
  2 changes made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 2 changes

Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
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

    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    newFile(otherPubspecPath, '''
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
Preparatory changes for a version bump:
  2 changes made in 2 files.

  my_project/lib/main.dart
    extraneous_modifier • 1 change

  other_package/lib/other.dart
    extraneous_modifier • 1 change

Bumped SDK constraints in 2 package(s):
  - test_project: ^3.12.0 -> ^3.13.0
  - other_package: ^3.12.0 -> ^3.13.0''',
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
    newFile(pubspecFilePath, '''
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
Preparatory changes for a version bump:
  2 changes made in 2 files.

  my_project/lib/a.dart
    extraneous_modifier • 1 change

  my_project/lib/src/b.dart
    extraneous_modifier • 1 change

Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
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
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');
    writeTestPackageConfig(languageVersion: '3.12');

    // Nested package in 'example/'
    var examplePath = join(projectFolderPath, 'example');
    var examplePubspecPath = join(examplePath, 'pubspec.yaml');
    var exampleMainPath = join(examplePath, 'lib', 'main.dart');
    newFile(examplePubspecPath, '''
name: example
environment:
  sdk: '^3.12.0'
''');
    newFile(exampleMainPath, 'void f(var y) {}\n');
    writePackageConfig(
      examplePath,
      packageName: 'example',
      languageVersion: '3.12',
    );

    await initialize();

    // Migrate ONLY the parent package.
    await _assertMigrationResult(
      steps: [MigrationStep.Prepare, MigrationStep.Bump],
      apply: true,
      expectedSummary: '''
Preparatory changes for a version bump:
  1 change made in 1 file.

  my_project/lib/main.dart
    avoid_final_parameters • 1 change

Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
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
    newFile(pubspecFilePath, '''
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
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_prepareAndCleanUp() async {
    newFile(pubspecFilePath, '''
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
    newFile(pubspecFilePath, '''
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
Preparatory changes for a version bump:
  2 changes made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 2 changes

Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Cleanup changes after a version bump:
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
