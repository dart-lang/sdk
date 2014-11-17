// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source.pub_package_map_provider;

import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:path/path.dart';

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
  final DirectoryBasedDartSdk sdk;

  PubPackageMapProvider(this.resourceProvider, this.sdk);

  @override
  PackageMapInfo computePackageMap(Folder folder) {
    // TODO(paulberry) make this asynchronous so that we can (a) do other
    // analysis while it's in progress, and (b) time out if it takes too long
    // to respond.
    String executable = sdk.pubExecutable.getAbsolutePath();
    io.ProcessResult result;
    try {
      result = io.Process.runSync(
          executable,
          [PUB_LIST_COMMAND],
          workingDirectory: folder.path);
    } on io.ProcessException catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          "Error running pub $PUB_LIST_COMMAND\n$exception\n$stackTrace");
    }
    if (result.exitCode != 0) {
      AnalysisEngine.instance.logger.logInformation(
          "pub $PUB_LIST_COMMAND failed: exit code ${result.exitCode}");
      return _error(folder);
    }
    try {
      return parsePackageMap(result.stdout, folder);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          "Malformed output from pub $PUB_LIST_COMMAND\n$exception\n$stackTrace");
    }

    return _error(folder);
  }

  /**
   * Decode the JSON output from pub into a package map.  Paths in the
   * output are considered relative to [folder].
   */
  PackageMapInfo parsePackageMap(String jsonText, Folder folder) {
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
    Map obj = JSON.decode(jsonText);
    Map packages = obj['packages'];
    processPaths(String packageName, List paths) {
      List<Folder> folders = <Folder>[];
      for (var path in paths) {
        if (path is String) {
          Resource resource = folder.getChild(path);
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
   * Create a PackageMapInfo object representing an error condition.
   */
  PackageMapInfo _error(Folder folder) {
    // Even if an error occurs, we still need to know the dependencies, so that
    // we'll know when to try running "pub list-package-dirs" again.
    // Unfortunately, "pub list-package-dirs" doesn't tell us dependencies when
    // an error occurs, so just assume there is one dependency, "pubspec.lock".
    List<String> dependencies = <String>[join(folder.path, PUBSPEC_LOCK_NAME)];
    return new PackageMapInfo(null, dependencies.toSet());
  }
}
