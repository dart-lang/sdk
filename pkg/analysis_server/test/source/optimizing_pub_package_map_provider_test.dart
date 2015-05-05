// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source.optimizing_pub_package_map_provider;

import 'dart:convert';
import 'dart:io' as io;

import 'package:analysis_server/src/source/optimizing_pub_package_map_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:path/path.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';
  defineReflectiveTests(OptimizingPubPackageMapProviderTest);
  defineReflectiveTests(OptimizingPubPackageMapInfoTest);
}

@reflectiveTest
class OptimizingPubPackageMapInfoTest {
  MemoryResourceProvider resourceProvider;

  int createFile(String path) {
    return resourceProvider.newFile(path, 'contents').modificationStamp;
  }

  void createFolder(String path) {
    resourceProvider.newFolder(path);
  }

  void modifyFile(String path) {
    resourceProvider.modifyFile(path, 'contents');
  }

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
  }

  test_isChangedDependency_fileNotPresent() {
    String path = '/dep';
    int timestamp = 1;
    OptimizingPubPackageMapInfo info =
        new OptimizingPubPackageMapInfo({}, [path].toSet(), {path: timestamp});
    expect(info.isChangedDependency(path, resourceProvider), isTrue);
  }

  test_isChangedDependency_matchingTimestamp() {
    String path = '/dep';
    int timestamp = createFile(path);
    OptimizingPubPackageMapInfo info =
        new OptimizingPubPackageMapInfo({}, [path].toSet(), {path: timestamp});
    expect(info.isChangedDependency(path, resourceProvider), isFalse);
  }

  test_isChangedDependency_mismatchedTimestamp() {
    String path = '/dep';
    int timestamp = createFile(path);
    OptimizingPubPackageMapInfo info =
        new OptimizingPubPackageMapInfo({}, [path].toSet(), {path: timestamp});
    modifyFile(path);
    expect(info.isChangedDependency(path, resourceProvider), isTrue);
  }

  test_isChangedDependency_nonDependency() {
    OptimizingPubPackageMapInfo info =
        new OptimizingPubPackageMapInfo({}, ['/dep1'].toSet(), {});
    expect(info.isChangedDependency('/dep2', resourceProvider), isFalse);
  }

  test_isChangedDependency_nonFile() {
    String path = '/dep';
    int timestamp = 1;
    createFolder(path);
    OptimizingPubPackageMapInfo info =
        new OptimizingPubPackageMapInfo({}, [path].toSet(), {path: timestamp});
    expect(info.isChangedDependency(path, resourceProvider), isTrue);
  }

  test_isChangedDependency_noTimestampInfo() {
    String path = '/dep';
    OptimizingPubPackageMapInfo info =
        new OptimizingPubPackageMapInfo({}, [path].toSet(), {});
    expect(info.isChangedDependency(path, resourceProvider), isTrue);
  }
}

@reflectiveTest
class OptimizingPubPackageMapProviderTest {
  MemoryResourceProvider resourceProvider;
  OptimizingPubPackageMapProvider provider;
  Folder projectFolder;
  io.ProcessResult pubListResult;

  void setPubListError() {
    pubListResult = new _MockProcessResult(0, 1, '', 'ERROR');
  }

  void setPubListResult({Map<String, String> packages: const {},
      List<String> input_files: const []}) {
    pubListResult = new _MockProcessResult(0, 0,
        JSON.encode({'packages': packages, 'input_files': input_files}), '');
  }

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    provider = new OptimizingPubPackageMapProvider(
        resourceProvider, null, _runPubList);
    projectFolder = resourceProvider.newFolder('/my/proj');
  }

  test_computePackageMap_noPreviousInfo() {
    String dep = posix.join(projectFolder.path, 'dep');
    String pkgName = 'foo';
    String pkgPath = '/pkg/foo';
    setPubListResult(packages: {pkgName: pkgPath}, input_files: [dep]);
    OptimizingPubPackageMapInfo info =
        provider.computePackageMap(projectFolder);
    expect(info.dependencies, hasLength(1));
    expect(info.dependencies, contains(dep));
    expect(info.packageMap, hasLength(1));
    expect(info.packageMap, contains(pkgName));
    expect(info.packageMap[pkgName], hasLength(1));
    expect(info.packageMap[pkgName][0].path, pkgPath);
    expect(info.modificationTimes, isEmpty);
  }

  test_computePackageMap_noPreviousInfo_pubListError() {
    String pubspecLock = posix.join(projectFolder.path, 'pubspec.lock');
    setPubListError();
    OptimizingPubPackageMapInfo info =
        provider.computePackageMap(projectFolder);
    expect(info.dependencies, hasLength(1));
    expect(info.dependencies, contains(pubspecLock));
    expect(info.packageMap, isNull);
    expect(info.modificationTimes, isEmpty);
  }

  test_computePackageMap_withPreviousInfo() {
    String dep = posix.join(projectFolder.path, 'dep');
    int timestamp = resourceProvider.newFile(dep, 'contents').modificationStamp;
    setPubListResult(input_files: [dep]);
    OptimizingPubPackageMapInfo info1 =
        provider.computePackageMap(projectFolder);
    OptimizingPubPackageMapInfo info2 =
        provider.computePackageMap(projectFolder, info1);
    expect(info2.dependencies, hasLength(1));
    expect(info2.dependencies, contains(dep));
    expect(info2.modificationTimes, hasLength(1));
    expect(info2.modificationTimes, contains(dep));
    expect(info2.modificationTimes[dep], timestamp);
  }

  test_computePackageMap_withPreviousInfo_newDependency() {
    String dep = posix.join(projectFolder.path, 'dep');
    resourceProvider.newFile(dep, 'contents').modificationStamp;
    setPubListResult(input_files: []);
    OptimizingPubPackageMapInfo info1 =
        provider.computePackageMap(projectFolder);
    setPubListResult(input_files: [dep]);
    OptimizingPubPackageMapInfo info2 =
        provider.computePackageMap(projectFolder, info1);
    expect(info2.modificationTimes, isEmpty);
  }

  test_computePackageMap_withPreviousInfo_oldDependencyNoLongerAFile() {
    String dep = posix.join(projectFolder.path, 'dep');
    resourceProvider.newFile(dep, 'contents').modificationStamp;
    setPubListResult(input_files: [dep]);
    OptimizingPubPackageMapInfo info1 =
        provider.computePackageMap(projectFolder);
    resourceProvider.deleteFile(dep);
    resourceProvider.newFolder(dep);
    OptimizingPubPackageMapInfo info2 =
        provider.computePackageMap(projectFolder, info1);
    expect(info2.modificationTimes, isEmpty);
  }

  test_computePackageMap_withPreviousInfo_oldDependencyNoLongerPresent() {
    String dep = posix.join(projectFolder.path, 'dep');
    resourceProvider.newFile(dep, 'contents').modificationStamp;
    setPubListResult(input_files: [dep]);
    OptimizingPubPackageMapInfo info1 =
        provider.computePackageMap(projectFolder);
    resourceProvider.deleteFile(dep);
    OptimizingPubPackageMapInfo info2 =
        provider.computePackageMap(projectFolder, info1);
    expect(info2.modificationTimes, isEmpty);
  }

  test_computePackageMap_withPreviousInfo_oldDependencyNoLongerRelevant() {
    String dep = posix.join(projectFolder.path, 'dep');
    resourceProvider.newFile(dep, 'contents').modificationStamp;
    setPubListResult(input_files: [dep]);
    OptimizingPubPackageMapInfo info1 =
        provider.computePackageMap(projectFolder);
    setPubListResult(input_files: []);
    OptimizingPubPackageMapInfo info2 =
        provider.computePackageMap(projectFolder, info1);
    expect(info2.modificationTimes, isEmpty);
  }

  test_computePackageMap_withPreviousInfo_pubListError() {
    String dep = posix.join(projectFolder.path, 'dep');
    String pubspecLock = posix.join(projectFolder.path, 'pubspec.lock');
    int timestamp = resourceProvider.newFile(dep, 'contents').modificationStamp;
    setPubListResult(input_files: [dep]);
    OptimizingPubPackageMapInfo info1 =
        provider.computePackageMap(projectFolder);
    setPubListError();
    OptimizingPubPackageMapInfo info2 =
        provider.computePackageMap(projectFolder, info1);
    expect(info2.dependencies, hasLength(2));
    expect(info2.dependencies, contains(dep));
    expect(info2.dependencies, contains(pubspecLock));
    expect(info2.modificationTimes, hasLength(1));
    expect(info2.modificationTimes, contains(dep));
    expect(info2.modificationTimes[dep], timestamp);
  }

  io.ProcessResult _runPubList(Folder folder) {
    expect(folder, projectFolder);
    return pubListResult;
  }
}

class _MockProcessResult implements io.ProcessResult {
  @override
  final int pid;

  @override
  final int exitCode;

  @override
  final stdout;

  @override
  final stderr;

  _MockProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}
