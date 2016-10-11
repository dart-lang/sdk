// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.source.pub_package_map_provider;

import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * The function used to run pub list.
 */
typedef io.ProcessResult RunPubList(Folder folder);

/**
 * Implementation of PackageMapProvider that operates by executing pub.
 */
class PubPackageMapProvider implements PackageMapProvider {
  static const String PUB_LIST_COMMAND = 'list-package-dirs';

  /**
   * The name of the 'pubspec.lock' file, which we assume is the dependency
   * in the event that [PUB_LIST_COMMAND] fails.
   */
  static const String PUBSPEC_LOCK_NAME = 'pubspec.lock';

  /**
   * [ResourceProvider] that is used to create the [Folder]s that populate the
   * package map.
   */
  final ResourceProvider resourceProvider;

  /**
   * Sdk that we use to find the pub executable.
   */
  final FolderBasedDartSdk sdk;

  /**
   * The function used to run pub list.
   */
  RunPubList _runPubList;

  /**
   * Construct a new instance.
   * A [RunPubList] implementation may be injected for testing
   */
  PubPackageMapProvider(this.resourceProvider, this.sdk, [this._runPubList]) {
    if (_runPubList == null) {
      _runPubList = _runPubListDefault;
    }
  }

  @override
  PackageMapInfo computePackageMap(Folder folder) {
    // If the pubspec.lock file does not exist, no need to run anything.
    {
      String lockPath = getPubspecLockPath(folder);
      if (!resourceProvider.getFile(lockPath).exists) {
        return computePackageMapError(folder);
      }
    }
    // TODO(paulberry) make this asynchronous so that we can (a) do other
    // analysis while it's in progress, and (b) time out if it takes too long
    // to respond.
    io.ProcessResult result;
    try {
      result = _runPubList(folder);
    } on io.ProcessException catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          "Error running pub $PUB_LIST_COMMAND\n$exception\n$stackTrace");
    }
    if (result == null || result.exitCode != 0) {
      String exitCode =
          result != null ? 'exit code ${result.exitCode}' : 'null';
      AnalysisEngine.instance.logger
          .logInformation("pub $PUB_LIST_COMMAND failed: $exitCode");
      return computePackageMapError(folder);
    }
    try {
      PackageMapInfo packageMap =
          parsePackageMap(JSON.decode(result.stdout), folder);
      return packageMap;
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          "Malformed output from pub $PUB_LIST_COMMAND\n$exception\n$stackTrace");
    }

    return computePackageMapError(folder);
  }

  /**
   * Create a PackageMapInfo object representing an error condition.
   */
  PackageMapInfo computePackageMapError(Folder folder) {
    // Even if an error occurs, we still need to know the dependencies, so that
    // we'll know when to try running "pub list-package-dirs" again.
    // Unfortunately, "pub list-package-dirs" doesn't tell us dependencies when
    // an error occurs, so just assume there is one dependency, "pubspec.lock".
    String lockPath = getPubspecLockPath(folder);
    List<String> dependencies = <String>[lockPath];
    return new PackageMapInfo(null, dependencies.toSet());
  }

  /**
   * Return the path to the `pubspec.lock` file in the given [folder].
   */
  String getPubspecLockPath(Folder folder) =>
      resourceProvider.pathContext.join(folder.path, PUBSPEC_LOCK_NAME);

  /**
   * Decode the JSON output from pub into a package map.  Paths in the
   * output are considered relative to [folder].
   */
  PackageMapInfo parsePackageMap(Map obj, Folder folder) {
    // The output of pub looks like this:
    // {
    //   "packages": {
    //     "foo": "path/to/foo",
    //     "bar": ["path/to/bar1", "path/to/bar2"],
    //     "myapp": "path/to/myapp",  // self link is included
    //   },
    //   "input_files": [
    //     "path/to/myapp/pubspec.lock"
    //   ]
    // }
    Map<String, List<Folder>> packageMap = new HashMap<String, List<Folder>>();
    Map packages = obj['packages'];
    processPaths(String packageName, List paths) {
      List<Folder> folders = <Folder>[];
      for (var path in paths) {
        if (path is String) {
          Resource resource = folder.getChildAssumingFolder(path);
          if (resource is Folder) {
            folders.add(resource);
          }
        }
      }
      if (folders.isNotEmpty) {
        packageMap[packageName] = folders;
      }
    }

    packages.forEach((key, value) {
      if (value is String) {
        processPaths(key, [value]);
      } else if (value is List) {
        processPaths(key, value);
      }
    });
    Set<String> dependencies = new Set<String>();
    List inputFiles = obj['input_files'];
    if (inputFiles != null) {
      for (var path in inputFiles) {
        if (path is String) {
          dependencies.add(folder.canonicalizePath(path));
        }
      }
    }
    return new PackageMapInfo(packageMap, dependencies);
  }

  /**
   * Run pub list to determine the packages and input files.
   */
  io.ProcessResult _runPubListDefault(Folder folder) {
    String executablePath = sdk.pubExecutable.path;
    List<String> arguments = [PUB_LIST_COMMAND];
    String workingDirectory = folder.path;
    int subprocessId = AnalysisEngine.instance.instrumentationService
        .logSubprocessStart(executablePath, arguments, workingDirectory);
    io.ProcessResult result = io.Process
        .runSync(executablePath, arguments, workingDirectory: workingDirectory);
    AnalysisEngine.instance.instrumentationService.logSubprocessResult(
        subprocessId, result.exitCode, result.stdout, result.stderr);
    return result;
  }
}
