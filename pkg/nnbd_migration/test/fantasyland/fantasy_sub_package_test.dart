// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'src/filesystem_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FantasySubPackageSettingsTest);
    defineReflectiveTests(FantasySubPackageTest);
  });
}

@reflectiveTest
class FantasySubPackageSettingsTest {
  test_settingsFromTable() {
    var subPackageSettings = FantasySubPackageSettings.fromName('vm_service');
    expect(subPackageSettings.name, equals('vm_service'));
    expect(subPackageSettings.repoSettings.name, equals('sdk'));
    expect(subPackageSettings.subDir, equals(path.join('pkg', 'vm_service')));
  }

  test_settingsFromTableDefault() {
    var subPackageSettings =
        FantasySubPackageSettings.fromName('completely_unknown_package');
    expect(subPackageSettings.name, equals('completely_unknown_package'));
    expect(subPackageSettings.repoSettings.name,
        equals('completely_unknown_package'));
    expect(subPackageSettings.subDir, equals('.'));
  }

  test_settingsEqual() {
    var repo1 = FantasyRepoSettings.fromName('some_repo_somewhere');
    var repo2 = FantasyRepoSettings.fromName('another_repo_somewhere_else');
    var test1 = FantasySubPackageSettings('foo', repo1, subDir: '.');
    var test2 = FantasySubPackageSettings('foo', repo2, subDir: '.');
    var test3 = FantasySubPackageSettings('foo', repo1,
        subDir: path.join('pkg', 'something'));
    var test4 = FantasySubPackageSettings('foobie', repo1);
    var test5 = FantasySubPackageSettings('foo', repo1);

    expect(test1, equals(test1));
    expect(test1, isNot(equals(test2)));
    expect(test1, isNot(equals(test3)));
    expect(test1, isNot(equals(test4)));
    expect(test1, equals(test5));
  }
}

class FantasyRepoFake extends FantasyRepo {
  final String name;
  final FantasyRepoSettings repoSettings;
  final Directory repoRoot;

  FantasyRepoFake(this.repoSettings, this.repoRoot) : name = repoSettings.name;
}

@reflectiveTest
class FantasySubPackageTest extends FilesystemTestBase {
  FantasyRepoFake fantasyRepo;
  FantasySubPackage fantasySubPackage;
  MockDirectory repoRoot;
  MockFile pubspecYaml;

  setUp() {
    super.setUp();
    repoRoot = directoryBuilder(path.join('workspace', 'repo_root'));
    fantasyRepo = FantasyRepoFake(
        FantasyRepoSettings('unreal_repo', '', '', ''),
        directoryBuilder(path.join('workspace', 'repo_root')));
    // subPackage 'unreal_package' at 'workspace_root/repo_root/unreal_package_dir'.
    fantasySubPackage = FantasySubPackage(
        FantasySubPackageSettings('unreal_package', fantasyRepo.repoSettings,
            subDir: 'unreal_package_dir'),
        fantasyRepo,
        fileBuilder: fileBuilder);
    // the pubspecYaml.
    pubspecYaml = fileBuilder(path.join(
        'workspace', 'repo_root', 'unreal_package_dir', 'pubspec.yaml'));
  }

  test_recognizeAllDependencies() async {
    when(pubspecYaml.exists()).thenAnswer((_) => Future.value(true));
    when(pubspecYaml.readAsString()).thenAnswer((_) => Future.value('''
      name: unreal_package
      version: 1.2.3
      dependencies:
        package2:
          path: correctly/enclosed
        package3:
          version: '0.0.0 >= 1.0.0'
        package4:
          version: any
      dev_dependencies:
        package5:
          version: any
    '''));
    List<FantasySubPackageSettings> dependencies =
        await fantasySubPackage.getPackageAllDependencies();
    expect(dependencies.length, equals(4));
  }

  test_recognizePathSubdir() async {
    when(pubspecYaml.exists()).thenAnswer((_) => Future.value(true));
    when(pubspecYaml.readAsString()).thenAnswer((_) => Future.value('''
      name: unreal_package
      version: 1.2.3
      dependencies:
        package2:
          path: correctly/enclosed
    '''));
    List<FantasySubPackageSettings> dependencies =
        await fantasySubPackage.getPackageAllDependencies();
    expect(dependencies.first.name, equals('package2'));
    expect(dependencies.first.repoSettings.name, equals('unreal_repo'));
    expect(dependencies.first.subDir,
        equals(path.join('unreal_package_dir', 'correctly', 'enclosed')));
  }

  test_recognizeVersion() async {
    when(pubspecYaml.exists()).thenAnswer((_) => Future.value(true));
    when(pubspecYaml.readAsString()).thenAnswer((_) => Future.value('''
      name: unreal_package
      version: 1.2.3
      dependencies:
        package3:
          version: '0.0.0 >= 1.0.0'
    '''));
    List<FantasySubPackageSettings> dependencies =
        await fantasySubPackage.getPackageAllDependencies();
    expect(dependencies.first.name, equals('package3'));
    expect(dependencies.first.repoSettings.name, equals('package3'));
    expect(dependencies.first.subDir, equals('.'));
  }

  @assertFailingTest
  test_assertOnPathOutsidePackage() async {
    when(pubspecYaml.exists()).thenAnswer((_) => Future.value(true));
    when(pubspecYaml.readAsString()).thenAnswer((_) => Future.value('''
      name: unreal_package
      version: 1.2.3
      dependencies:
        package2:
          path: ../incorrectly/enclosed
    '''));
    await fantasySubPackage.getPackageAllDependencies();
  }
}
