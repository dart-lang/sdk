// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source.caching_pub_package_map_provider;

import 'dart:convert';
import 'dart:core';
import 'dart:io' as io;

import 'package:analysis_server/src/source/caching_pub_package_map_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';

main() {
  group('CachingPubPackageMapProvider', () {
    MemoryResourceProvider resProvider;
    _MockPubListRunner mockRunner;
    bool writeFileException;

    Map result1 = {
      'packages': {'foo': '/tmp/proj1/packages/foo'},
      'input_files': ['/tmp/proj1/pubspec.yaml']
    };

    Map result1error = {
      'input_files': ['/tmp/proj1/pubspec.lock']
    };

    Map result2 = {
      'packages': {'bar': '/tmp/proj2/packages/bar'},
      'input_files': ['/tmp/proj2/pubspec.yaml']
    };

    Folder newProj(Map result) {
      Map packages = result['packages'];
      packages.forEach((String name, String path) {
        resProvider.newFolder(path);
      });
      List<String> inputFiles = result['input_files'] as List<String>;
      for (String path in inputFiles) {
        resProvider.newFile(path, '');
      }
      Folder projectFolder = resProvider.getResource(inputFiles[0]).parent;
      resProvider.newFile(projectFolder.path + '/pubspec.lock', '');
      return projectFolder;
    }

    int mockWriteFile(File cacheFile, String content) {
      if (writeFileException) {
        throw 'simulated write failure: $cacheFile';
      }
      if (!cacheFile.exists) {
        resProvider.newFolder(cacheFile.parent.path);
        resProvider.newFile(cacheFile.path, content);
      } else {
        resProvider.modifyFile(cacheFile.path, content);
      }
      Resource res = resProvider.getResource(cacheFile.path);
      if (res is File) {
        return res.createSource().modificationStamp;
      }
      throw 'expected file, but found $res';
    }

    CachingPubPackageMapProvider newPkgProvider() {
      Folder sdkFolder = resProvider
          .newFolder(resProvider.convertPath('/Users/user/dart-sdk'));
      return new CachingPubPackageMapProvider(
          resProvider,
          new FolderBasedDartSdk(resProvider, sdkFolder),
          mockRunner.runPubList,
          mockWriteFile);
    }

    setUp(() {
      resProvider = new MemoryResourceProvider();
      resProvider.newFolder('/tmp/proj/packages/foo');
      mockRunner = new _MockPubListRunner();
      writeFileException = false;
    });

    group('computePackageMap', () {
      // Assert pub list called once and results are cached in memory
      test('cache memory', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);
      });

      // Assert pub list called once and results are cached on disk
      test('cache disk', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider1 = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider1.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        CachingPubPackageMapProvider pkgProvider2 = newPkgProvider();
        info = pkgProvider2.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);
      });

      // Assert pub list called even if cache file is corrupted
      test('corrupt cache file', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider1 = newPkgProvider();
        resProvider.newFile(pkgProvider1.cacheFile.path, 'corrupt content');
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider1.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        CachingPubPackageMapProvider pkgProvider2 = newPkgProvider();
        info = pkgProvider2.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);
      });

      // Assert gracefully continue even if write to file fails
      test('failed write to cache file', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        writeFileException = true;
        PackageMapInfo info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);
      });

      // Assert modification in one shows up in the other
      test('shared disk cache', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider1 = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider1.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        Folder folder2 = newProj(result2);
        CachingPubPackageMapProvider pkgProvider2 = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result2);
        info = pkgProvider2.computePackageMap(folder2);
        expect(mockRunner.runCount, 2);
        _assertInfo(info, result2);

        info = pkgProvider1.computePackageMap(folder2);
        expect(mockRunner.runCount, 2);
        _assertInfo(info, result2);
      });

      // Assert pub list called again if input file modified
      test('input file changed', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        resProvider.modifyFile(info.dependencies.first, 'new content');
        mockRunner.nextResult = JSON.encode(result1);
        info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 2);
        _assertInfo(info, result1);
      });

      // Assert pub list called again if input file modified
      // after reloading package provider cache from disk
      test('input file changed 2', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider1 = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider1.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        resProvider.modifyFile(info.dependencies.first, 'new content');
        mockRunner.nextResult = JSON.encode(result1);
        CachingPubPackageMapProvider pkgProvider2 = newPkgProvider();
        info = pkgProvider2.computePackageMap(folder1);
        expect(mockRunner.runCount, 2);
        _assertInfo(info, result1);
      });

      // Assert pub list called again if input file deleted
      test('input file deleted', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        resProvider.deleteFile(info.dependencies.first);
        mockRunner.nextResult = JSON.encode(result1);
        info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 2);
        _assertInfo(info, result1);
      });

      // Assert pub list not called if folder does not exist
      // and returns same cached result if folder restored as before
      test('project removed then restored', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        CachingPubPackageMapProvider pkgProvider = newPkgProvider();
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);

        _RestorePoint restorePoint = new _RestorePoint(resProvider, folder1);
        resProvider.deleteFolder(folder1.path);
        info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertError(info, result1error);

        restorePoint.restore();
        info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 1);
        _assertInfo(info, result1);
      });

      // Assert pub list *is* run again
      // if dependency has changed during execution
      test('dependency changed during execution', () {
        expect(mockRunner.runCount, 0);

        Folder folder1 = newProj(result1);
        Resource pubspecFile = folder1.getChild('pubspec.yaml');
        expect(pubspecFile.exists, isTrue);
        CachingPubPackageMapProvider pkgProvider = newPkgProvider();
        mockRunner.nextResultFunction = () {
          resProvider.modifyFile(pubspecFile.path, 'new content');
          return JSON.encode(result1);
        };
        mockRunner.nextResult = JSON.encode(result1);
        PackageMapInfo info = pkgProvider.computePackageMap(folder1);
        expect(mockRunner.runCount, 2);
        _assertInfo(info, result1);
      });
    });
  });
}

_assertError(PackageMapInfo info, Map expected) {
  expect(info.packageMap, isNull);
  List<String> expectedFiles = expected['input_files'] as List<String>;
  expect(info.dependencies, hasLength(expectedFiles.length));
  for (String path in expectedFiles) {
    expect(info.dependencies, contains(path));
  }
}

_assertInfo(PackageMapInfo info, Map expected) {
  Map<String, String> expectedPackages =
      expected['packages'] as Map<String, String>;
  expect(info.packageMap, hasLength(expectedPackages.length));
  for (String key in expectedPackages.keys) {
    List<Folder> packageList = info.packageMap[key];
    expect(packageList, hasLength(1));
    expect(packageList[0].path, expectedPackages[key]);
  }
  List<String> expectedFiles = expected['input_files'] as List<String>;
  expect(info.dependencies, hasLength(expectedFiles.length));
  for (String path in expectedFiles) {
    expect(info.dependencies, contains(path));
  }
}

typedef String MockResultFunction();

/**
 * Mock for simulating and tracking execution of pub list
 */
class _MockPubListRunner {
  int runCount = 0;
  List nextResults = [];

  void set nextResult(String result) {
    nextResults.add(result);
  }

  void set nextResultFunction(MockResultFunction resultFunction) {
    nextResults.add(resultFunction);
  }

  io.ProcessResult runPubList(Folder folder) {
    if (nextResults.isEmpty) {
      throw 'missing nextResult';
    }
    var result = nextResults.removeAt(0);
    if (result is MockResultFunction) {
      result = result();
    }
    ++runCount;
    return new _MockResult(result);
  }
}

class _MockResult implements io.ProcessResult {
  String result;

  _MockResult(this.result);

  @override
  int get exitCode => 0;

  // TODO: implement stdout
  @override
  get stdout => result;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * An object containing information to restore the state of a deleted
 * folder and its content.
 */
class _RestorePoint {
  final MemoryResourceProvider provider;
  final List<String> _folderPaths = <String>[];
  final List<String> _filePaths = <String>[];
  final List<TimestampedData> _fileContents = <TimestampedData>[];

  /**
   * Construct a new instance that captures the current state of the folder
   * and all of its contained files and folders.
   */
  _RestorePoint(this.provider, Folder folder) {
    record(folder);
  }

  /**
   * Capture the current state of the folder
   * and all of its contained files and folders.
   */
  void record(Folder folder) {
    _folderPaths.add(folder.path);
    for (Resource child in folder.getChildren()) {
      if (child is Folder) {
        record(child);
      } else if (child is File) {
        _filePaths.add(child.path);
        _fileContents.add(child.createSource().contents);
      } else {
        throw 'unknown resource: $child';
      }
    }
  }

  /**
   * Restore the original files and folders.
   */
  void restore() {
    for (String path in _folderPaths) {
      provider.newFolder(path);
    }
    int fileCount = _filePaths.length;
    for (int fileIndex = 0; fileIndex < fileCount; ++fileIndex) {
      String path = _filePaths[fileIndex];
      TimestampedData content = _fileContents[fileIndex];
      provider.newFile(path, content.data, content.modificationTime);
    }
  }
}
