// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library package.map.provider;

import 'dart:convert';
import 'dart:io' as io;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * A PackageMapProvider is an entity capable of determining the mapping from
 * package name to source directory for a given folder.
 */
abstract class PackageMapProvider {
  /**
   * Compute a package map for the given folder, if possible.
   *
   * If a package map can't be computed, return null.
   */
  PackageMapInfo computePackageMap(Folder folder);
}

/**
 * Data structure output by PackageMapProvider.  This contains both the package
 * map and dependency information.
 */
class PackageMapInfo {
  /**
   * The package map itself.  This is a map from package name to a list of
   * the folders containing source code for the package.
   */
  Map<String, List<Folder>> packageMap;

  /**
   * Dependency information.  This is a set of the paths which were consulted
   * in order to generate the package map.  If any of these files is
   * modified, the package map will need to be regenerated.
   */
  Set<String> dependencies;

  PackageMapInfo(this.packageMap, this.dependencies);
}

/**
 * Implementation of PackageMapProvider that operates by executing pub.
 */
class PubPackageMapProvider implements PackageMapProvider {
  static const String PUB_LIST_COMMAND = 'list-package-dirs';

  /**
   * [ResourceProvider] that is used to create the [Folder]s that populate the
   * package map.
   */
  final ResourceProvider resourceProvider;

  PubPackageMapProvider(this.resourceProvider);

  @override
  PackageMapInfo computePackageMap(Folder folder) {
    // TODO(paulberry) make this asynchronous so that we can (a) do other
    // analysis while it's in progress, and (b) time out if it takes too long
    // to respond.
    String executable = SHARED_SDK.pubExecutable.getAbsolutePath();
    io.ProcessResult result;
    try {
      result = io.Process.runSync(
          executable, [PUB_LIST_COMMAND], workingDirectory: folder.path);
    } on io.ProcessException catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          "Error running pub $PUB_LIST_COMMAND\n${exception}\n${stackTrace}");
    }
    if (result.exitCode != 0) {
      AnalysisEngine.instance.logger.logInformation(
          "pub $PUB_LIST_COMMAND failed: exit code ${result.exitCode}");
      return null;
    }
    try {
      return parsePackageMap(result.stdout);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          "Malformed output from pub $PUB_LIST_COMMAND\n${exception}\n${stackTrace}");
    }

    return null;
  }

  /**
   * Decode the JSON output from pub into a package map.
   */
  PackageMapInfo parsePackageMap(String jsonText) {
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
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{};
    Map obj = JSON.decode(jsonText);
    Map packages = obj['packages'];
    processPaths(String packageName, List paths) {
      List<Folder> folders = <Folder>[];
      for (var path in paths) {
        if (path is String) {
          Resource resource = resourceProvider.getResource(path);
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
          dependencies.add(path);
        }
      }
    }
    return new PackageMapInfo(packageMap, dependencies);
  }
}