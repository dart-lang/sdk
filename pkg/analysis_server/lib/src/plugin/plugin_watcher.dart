// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/util/absolute_path.dart';
import 'package:front_end/src/base/source.dart';
import 'package:path/src/context.dart';

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
    List<String> enabledPlugins = driver.analysisOptions.enabledPluginNames;
    for (String hostPackageName in enabledPlugins) {
      //
      // Determine whether the package exists and defines a plugin.
      //
      String uri = 'package:$hostPackageName/$hostPackageName.dart';
      Source source = driver.sourceFactory.forUri(uri);
      if (source == null) {
        manager.recordPluginFailure(hostPackageName,
            'Could not resolve "$uri" in ${contextRoot.root}.');
      } else {
        Context context = resourceProvider.pathContext;
        String packageRoot = context.dirname(context.dirname(source.fullName));
        String pluginPath = _locator.findPlugin(packageRoot);
        if (pluginPath == null) {
          manager.recordPluginFailure(
              hostPackageName, 'Could not find plugin in "$packageRoot".');
        } else {
          //
          // Add the plugin to the context root.
          //
          // TODO(brianwilkerson) Do we need to wait for the plugin to be added?
          // If we don't, then tests don't have any way to know when to expect
          // that the list of plugins has been updated.
          manager.addPluginToContextRoot(contextRoot, pluginPath);
        }
      }
    }
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
