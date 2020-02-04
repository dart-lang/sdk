// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FantasyRepoSettingsTest);
    defineReflectiveTests(FantasyRepoE2ETest);
    defineReflectiveTests(FantasyRepoTest);
  });
}

@reflectiveTest
class FantasyRepoSettingsTest {
  test_fromNameDefaultCase() {
    FantasyRepoSettings settings = FantasyRepoSettings.fromName('defaultCase');

    expect(settings.name, equals('defaultCase'));
    expect(settings.clone, equals('git@github.com:dart-lang/defaultCase.git'));
    expect(settings.branch, equals('master'));
    expect(settings.revision, equals('master'));
  }

  test_fromNameDotDartCase() {
    FantasyRepoSettings settings =
        FantasyRepoSettings.fromName('somethingImportant.dart');

    expect(settings.name, equals('somethingImportant.dart'));
    expect(settings.clone,
        equals('git@github.com:google/somethingImportant.dart.git'));
    expect(settings.branch, equals('master'));
    expect(settings.revision, equals('master'));
  }

  test_fromNameTableCase() {
    FantasyRepoSettings settings = FantasyRepoSettings.fromName('git');

    expect(settings.name, equals('git'));
    expect(settings.clone, equals('git@github.com:kevmoo/git.git'));
    expect(settings.branch, equals('master'));
    expect(settings.revision, equals('master'));
  }

  test_equality() {
    var test1 = FantasyRepoSettings('one', 'two', 'three', 'four');
    var test2 = FantasyRepoSettings('one', 'two', 'three', 'four');
    var test3 = FantasyRepoSettings('one', 'two', 'three', 'five');
    var test4 = FantasyRepoSettings('one', 'two');

    expect(test1, equals(test2));
    expect(test1, isNot(equals(test3)));
    expect(test1, isNot(equals(test4)));
  }
}

@reflectiveTest
class FantasyRepoE2ETest {
  Directory tempDir;

  setUp() async {
    tempDir = await Directory.systemTemp.createTemp('FantasyRepoE2ETest');
  }

  test_fantasyRepoE2ETest() async {
    // Only one of these, as they are slow due to the real fork/execs of 'git'.
    // Check any important edge cases via unit tests and mocking.

    // TODO(jcollins-g): This test is not fully isolated from the global git
    // config.  Fix that.
    SubprocessLauncher launcher = SubprocessLauncher('FantasyRepoE2ETest');
    Directory origRepoDir = Directory(path.join(tempDir.path, 'origRepo'));

    // Create and add a commit to origRepoDir that includes a file we should
    // check out, and others we shouldn't.
    await launcher.runStreamed('git', ['init', origRepoDir.path]);
    File dotPackages = File(path.join(origRepoDir.path, '.packages'));
    File pubspecLock = File(path.join(origRepoDir.path, 'pubspec.lock'));
    File pubspecYaml = File(path.join(origRepoDir.path, 'pubspec.yaml'));
    File packageConfigJson =
        File(path.join(origRepoDir.path, '.dart_tool', 'package_config.json'));
    List<File> allFiles = [
      dotPackages,
      pubspecLock,
      pubspecYaml,
      packageConfigJson
    ];
    await Future.wait([
      for (var f in [dotPackages, pubspecLock, pubspecYaml, packageConfigJson])
        f.create(recursive: true)
    ]);
    await launcher.runStreamed(
        'git', ['add', '-f', ...allFiles.map((f) => path.canonicalize(f.path))],
        workingDirectory: origRepoDir.path);
    await launcher.runStreamed('git', ['commit', '-m', 'add some files'],
        workingDirectory: origRepoDir.path);

    // Use the repo builder to clone this and verify that the right files are
    // checked out.
    Directory repoRoot = Directory(path.join(tempDir.path, 'repoRoot'));
    await FantasyRepo.buildFrom(
        FantasyRepoSettings('repoE2Etest', origRepoDir.path), repoRoot,
        launcher: launcher);

    dotPackages = File(path.join(repoRoot.path, '.packages'));
    pubspecLock = File(path.join(repoRoot.path, 'pubspec.lock'));
    pubspecYaml = File(path.join(repoRoot.path, 'pubspec.yaml'));
    packageConfigJson =
        File(path.join(repoRoot.path, '.dart_tool', 'package_config.json'));

    expect(await dotPackages.exists(), isFalse);
    expect(await pubspecLock.exists(), isFalse);
    expect(await pubspecYaml.exists(), isTrue);
    expect(await packageConfigJson.exists(), isFalse);

    // Update the original repository.
    File aNewFile = File(path.join(origRepoDir.path, 'hello_new_file_here'));
    await aNewFile.create(recursive: true);
    await launcher.runStreamed(
        'git', ['add', '-f', path.canonicalize(aNewFile.path)],
        workingDirectory: origRepoDir.path);
    await launcher.runStreamed('git', ['commit', '-m', 'add more files'],
        workingDirectory: origRepoDir.path);

    // Finally, use the repoBuilder to update a repository from head and verify
    // we did it right.
    await FantasyRepo.buildFrom(
        FantasyRepoSettings('repoE2Etest', origRepoDir.path), repoRoot,
        launcher: launcher);

    aNewFile = File(path.join(repoRoot.path, 'hello_new_file_here'));

    expect(await dotPackages.exists(), isFalse);
    expect(await pubspecLock.exists(), isFalse);
    expect(await pubspecYaml.exists(), isTrue);
    expect(await packageConfigJson.exists(), isFalse);
    expect(await aNewFile.exists(), isTrue);
  }
}

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

class MockSubprocessLauncher extends Mock implements SubprocessLauncher {}

@reflectiveTest
class FantasyRepoTest {
  // TODO(jcollins-g): extend MemoryResourceProvider and analyzer File
  // implementations and port over, or add mock_filesystem to third_party.
  Map<String, MockFile> mockFiles;
  Map<String, MockDirectory> mockDirectories;
  MockDirectory Function(String) directoryBuilder;
  MockFile Function(String) fileBuilder;
  MockSubprocessLauncher mockLauncher;
  String parentPath;
  String repoPath;

  setUp() {
    mockFiles = {};
    mockDirectories = {};
    fileBuilder = (String s) {
      mockFiles[s] ??= MockFile();
      return mockFiles[s];
    };
    directoryBuilder = (String s) {
      mockDirectories[s] ??= MockDirectory();
      return mockDirectories[s];
    };
    mockLauncher = MockSubprocessLauncher();
    parentPath = 'parentdir';
    repoPath = path.join(parentPath, 'subdir');
    MockDirectory repoDir = directoryBuilder(repoPath);
    MockDirectory parentDir = directoryBuilder('parentdir');
    when(parentDir.exists()).thenAnswer((_) => Future.value(true));
    when(repoDir.parent).thenReturn(parentDir);
    when(repoDir.path).thenReturn(repoPath);
  }

  _setUpNewClone(String repoName) async {
    FantasyRepoSettings settings = FantasyRepoSettings.fromName(repoName);
    when(directoryBuilder(repoPath).exists())
        .thenAnswer((_) => Future.value(false));
    await FantasyRepo.buildFrom(settings, mockDirectories[repoPath],
        launcher: mockLauncher, fileBuilder: fileBuilder);
  }

  test_checkHttpStringSubstitution() async {
    await _setUpNewClone('defaultCase');
    verify(mockLauncher.runStreamed(
        'git',
        [
          'remote',
          'add',
          'origin',
          '-t',
          'master',
          'git@github.com:dart-lang/defaultCase.git'
        ],
        workingDirectory: repoPath));
    verify(mockLauncher.runStreamed(
        'git',
        [
          'remote',
          'add',
          'originHTTP',
          '-t',
          'master',
          'https://github.com/dart-lang/defaultCase.git'
        ],
        workingDirectory: repoPath));
  }

  test_verifyWorkingDirectoryForGitConfig() async {
    await _setUpNewClone('defaultCase');
    verify(mockLauncher.runStreamed(
        'git', ['config', 'core.sparsecheckout', 'true'],
        workingDirectory: repoPath));
  }
}
