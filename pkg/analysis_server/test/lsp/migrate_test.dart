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
    defineReflectiveTests(MigrateTest);
  });
}

@reflectiveTest
class MigrateTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    registerBuiltInFixGenerators();
  }

  Future<void> test_bumpSdkConstraint() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
environment:
  sdk: '^3.0.0'
''',
    );
    await _assertMigrationResult(
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.0.0 -> ^3.1.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.1.0'
''',
    );
  }

  Future<void> test_bumpSdkConstraint_emptyPubspec() async {
    await _setupProject(pubspecContent: '');
    await _assertMigrationResult(
      apply: true,
      expectedSummary: 'No SDK constraints were bumped.',
    );
  }

  Future<void> test_bumpSdkConstraint_multiplePackages() async {
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

  Future<void> test_bumpSdkConstraint_noneBumped() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
''',
    );
    await _assertMigrationResult(
      apply: true,
      expectedSummary: 'No SDK constraints were bumped.',
    );
  }

  Future<void> test_bumpSdkConstraint_range() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
''',
    );
    await _assertMigrationResult(
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

  Future<void> test_bumpSdkConstraint_skipped() async {
    var otherDirPath = convertPath('/other_project');
    var otherPubspecPath = pathContext.join(otherDirPath, 'pubspec.yaml');

    await _setupProject(
      pubspecContent: 'name: other_project',
      customPubspecFilePath: otherPubspecPath,
    );
    await _assertMigrationResult(
      uris: [Uri.file(otherDirPath)],
      apply: true,
      expectedSummary: contains('- other_project: Skipped (not analyzed)'),
    );
  }

  Future<void> test_dependencyConflict() async {
    failTestOnErrorDiagnostic = false;

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
      apply: true,
      expectedSummary: '''
- test_project: Skipped
  Incompatible dependencies:
    - dep_package
No SDK constraints were bumped.''',
    );
  }

  Future<void> test_dependencyConflict_multiple() async {
    failTestOnErrorDiagnostic = false;

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
      apply: true,
      expectedSummary: '''
- test_project: Skipped
  Incompatible dependencies:
    - dep_package1
    - dep_package2
No SDK constraints were bumped.''',
    );
  }

  Future<void> test_dependencyConflict_transitive() async {
    failTestOnErrorDiagnostic = false;

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
      apply: true,
      expectedSummary: '''
- test_project: Skipped
  Incompatible dependencies:
    - transitive_dep
No SDK constraints were bumped.''',
    );
  }

  Future<void> test_dryRun() async {
    failTestOnErrorDiagnostic = false;
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
Would bump SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  2 fixes would be made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 2 fixes

Post-migration fixes:
  2 fixes would be made in 1 file.

  my_project/lib/main.dart
    unnecessary_type_name_in_constructor • 2 fixes''',
    );
  }

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

  Future<void> test_fullMigration_313() async {
    failTestOnErrorDiagnostic = false;
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
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  2 fixes made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 2 fixes

Post-migration fixes:
  2 fixes made in 1 file.

  my_project/lib/main.dart
    unnecessary_type_name_in_constructor • 2 fixes''',
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

  Future<void> test_fullMigration_313_multiplePackages() async {
    failTestOnErrorDiagnostic = false;
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
      uris: [projectFolderUri, toUri(otherPackagePath)],
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 2 package(s):
  - test_project: ^3.12.0 -> ^3.13.0
  - other_package: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  2 fixes made in 2 files.

  my_project/lib/main.dart
    extraneous_modifier • 1 fix

  other_package/lib/other.dart
    extraneous_modifier • 1 fix

Post-migration fixes:
  2 fixes made in 2 files.

  my_project/lib/main.dart
    unnecessary_type_name_in_constructor • 1 fix

  other_package/lib/other.dart
    unnecessary_type_name_in_constructor • 1 fix''',
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

  Future<void> test_postMigration_313() async {
    failTestOnErrorDiagnostic = false;
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
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Post-migration fixes:
  2 fixes made in 1 file.

  my_project/lib/main.dart
    unnecessary_type_name_in_constructor • 2 fixes''',
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

  Future<void> test_preMigration_313() async {
    failTestOnErrorDiagnostic = false;
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x, var y) {}\n');

    await initialize();

    await _assertMigrationResult(
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  2 fixes made in 1 file.

  my_project/lib/main.dart
    extraneous_modifier • 2 fixes''',
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

  Future<void> test_preMigration_313_multipleFiles() async {
    failTestOnErrorDiagnostic = false;
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
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  2 fixes made in 2 files.

  my_project/lib/main.dart
    extraneous_modifier • 1 fix

  my_project/lib/other.dart
    extraneous_modifier • 1 fix''',
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

  Future<void> test_preMigration_313_multiplePackages() async {
    failTestOnErrorDiagnostic = false;
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
      uris: [projectFolderUri, toUri(otherPackagePath)],
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 2 package(s):
  - test_project: ^3.12.0 -> ^3.13.0
  - other_package: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  2 fixes made in 2 files.

  my_project/lib/main.dart
    extraneous_modifier • 1 fix

  other_package/lib/other.dart
    extraneous_modifier • 1 fix''',
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

  Future<void> test_preMigration_313_nestedAnalysisOptions() async {
    failTestOnErrorDiagnostic = false;
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
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  2 fixes made in 2 files.

  my_project/lib/a.dart
    extraneous_modifier • 1 fix

  my_project/lib/src/b.dart
    extraneous_modifier • 1 fix''',
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

  Future<void> test_preMigration_313_noEdits() async {
    failTestOnErrorDiagnostic = false;
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(int x, y) {}\n');

    await initialize();

    await _assertMigrationResult(
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

  Future<void> test_preMigration_nestedPackage() async {
    failTestOnErrorDiagnostic = false;

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
      apply: true,
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
  - test_project: ^3.12.0 -> ^3.13.0

Pre-migration fixes:
  1 fix made in 1 file.

  my_project/lib/main.dart
    avoid_final_parameters • 1 fix''',
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

  Future<void> test_validDirectory() async {
    await _setupProject(pubspecContent: 'name: test_project');
    await _assertMigrationResult(apply: true);
  }

  Future<void> _assertMigrationResult({
    List<Uri>? uris,
    Object? expectedSummary,
    String? expectedEdit,
    bool apply = false,
  }) async {
    await initialAnalysis;
    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: uris ?? [projectFolderUri], apply: apply),
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
