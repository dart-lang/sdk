// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/util/absolute_path.dart';

/**
 * An object that watches the results produced by analysis drivers to identify
 * references to previously unseen packages and, if those packages have plugins
 * associated with them, causes the plugin to be associated with the driver's
 * context root (which in turn might cause the plugin to be started).
 */
class PluginWatcher implements DriverWatcher {
  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * The object managing the execution of plugins.
   */
  final PluginManager manager;

  /**
   * The object used to locate plugins within packages.
   */
  final PluginLocator _locator;

  /**
   * A table mapping analysis drivers to information related to the driver.
   */
  Map<AnalysisDriver, _DriverInfo> _driverInfo =
      <AnalysisDriver, _DriverInfo>{};

  /**
   * Initialize a newly created plugin watcher.
   */
  PluginWatcher(this.resourceProvider, this.manager)
      : _locator = new PluginLocator(resourceProvider);

  /**
   * The context manager has just added the given analysis [driver]. This method
   * must be called before the driver has been allowed to perform any analysis.
   */
  void addedDriver(AnalysisDriver driver, ContextRoot contextRoot) {
    _driverInfo[driver] = new _DriverInfo(
        contextRoot, <String>[contextRoot.root, _getSdkPath(driver)]);
    driver.fsState.knownFilesSetChanges.listen((KnownFilesSetChange change) {
      List<String> addedPluginPaths = _checkPluginsFor(driver, change);
      for (String pluginPath in addedPluginPaths) {
        manager.addPluginToContextRoot(contextRoot, pluginPath);
      }
    });
  }

  /**
   * The context manager has just removed the given analysis [driver].
   */
  void removedDriver(AnalysisDriver driver) {
    _DriverInfo info = _driverInfo[driver];
    if (info == null) {
      throw new StateError('Cannot remove a driver that was not added');
    }
    manager.removedContextRoot(info.contextRoot);
    _driverInfo.remove(driver);
  }

  /**
   * Check all of the files that have been analyzed so far by the given [driver]
   * to see whether any of them are in a package that had not previously been
   * seen that defines a plugin. Return a list of the roots of all such plugins
   * that are found.
   */
  List<String> _checkPluginsFor(
      AnalysisDriver driver, KnownFilesSetChange change) {
    _DriverInfo info = _driverInfo[driver];
    if (info == null) {
      // The driver must have been removed prior to getting the notification of
      // newly analyzed files.
      return const <String>[];
    }
    List<String> packageRoots = info.packageRoots;
    FileSystemState fileSystemState = driver.fsState;
    AbsolutePathContext context = resourceProvider.absolutePathContext;

    bool isInRoot(String path) {
      for (String root in packageRoots) {
        if (context.isWithin(root, path)) {
          return true;
        }
      }
      return false;
    }

    String getPackageRoot(String path, Uri uri) {
      List<String> segments = uri.pathSegments.toList();
      segments[0] = 'lib';
      String suffix = resourceProvider.pathContext.joinAll(segments);
      return path.substring(0, path.length - suffix.length - 1);
    }

    List<String> addedPluginPaths = <String>[];
    for (String path in change.added) {
      FileState state = fileSystemState.getFileForPath(path);
      if (!isInRoot(path)) {
        // Found a file not in a previously known package.
        Uri uri = state.uri;
        if (PackageMapUriResolver.isPackageUri(uri)) {
          String packageRoot = getPackageRoot(path, uri);
          packageRoots.add(packageRoot);
          String pluginPath = _locator.findPlugin(packageRoot);
          if (pluginPath != null) {
            addedPluginPaths.add(pluginPath);
          }
        }
      }
    }
    return addedPluginPaths;
  }

  /**
   * Return the path to the root of the SDK being used by the given analysis
   * [driver].
   */
  String _getSdkPath(AnalysisDriver driver) {
    AbsolutePathContext context = resourceProvider.absolutePathContext;
    String sdkRoot = driver.sourceFactory.forUri('dart:core').fullName;
    while (context.basename(sdkRoot) != 'lib') {
      String parent = context.dirname(sdkRoot);
      if (parent == sdkRoot) {
        break;
      }
      sdkRoot = parent;
    }
    return sdkRoot;
  }
}

/**
 * Information related to an analysis driver.
 */
class _DriverInfo {
  /**
   * The context root representing the context being analyzed by the driver.
   */
  final ContextRoot contextRoot;

  /**
   * A list of the absolute paths of directories inside of which we have already
   * searched for a plugin.
   */
  final List<String> packageRoots;

  /**
   * Initialize a newly created information holder.
   */
  _DriverInfo(this.contextRoot, this.packageRoots);
}
