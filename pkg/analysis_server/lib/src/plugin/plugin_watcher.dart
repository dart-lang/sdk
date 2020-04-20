// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';

/// An object that watches the results produced by analysis drivers to identify
/// references to previously unseen packages and, if those packages have plugins
/// associated with them, causes the plugin to be associated with the driver's
/// context root (which in turn might cause the plugin to be started).
class PluginWatcher implements DriverWatcher {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The object managing the execution of plugins.
  final PluginManager manager;

  /// The object used to locate plugins within packages.
  final PluginLocator _locator;

  /// A table mapping analysis drivers to information related to the driver.
  final Map<AnalysisDriver, _DriverInfo> _driverInfo =
      <AnalysisDriver, _DriverInfo>{};

  /// Initialize a newly created plugin watcher.
  PluginWatcher(this.resourceProvider, this.manager)
      : _locator = PluginLocator(resourceProvider);

  /// The context manager has just added the given analysis [driver]. This
  /// method must be called before the driver has been allowed to perform any
  /// analysis.
  @override
  void addedDriver(AnalysisDriver driver, ContextRoot contextRoot) {
    _driverInfo[driver] = _DriverInfo(
        contextRoot, <String>[contextRoot.root, _getSdkPath(driver)]);
    var enabledPlugins = driver.analysisOptions.enabledPluginNames;
    for (var hostPackageName in enabledPlugins) {
      //
      // Determine whether the package exists and defines a plugin.
      //
      var uri = 'package:$hostPackageName/$hostPackageName.dart';
      var source = driver.sourceFactory.forUri(uri);
      if (source == null) {
        manager.recordPluginFailure(hostPackageName,
            'Could not resolve "$uri" in ${contextRoot.root}.');
      } else {
        var context = resourceProvider.pathContext;
        var packageRoot = context.dirname(context.dirname(source.fullName));
        var pluginPath = _locator.findPlugin(packageRoot);
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

  /// The context manager has just removed the given analysis [driver].
  @override
  void removedDriver(AnalysisDriver driver) {
    var info = _driverInfo[driver];
    if (info == null) {
      throw StateError('Cannot remove a driver that was not added');
    }
    manager.removedContextRoot(info.contextRoot);
    _driverInfo.remove(driver);
  }

  /// Return the path to the root of the SDK being used by the given analysis
  /// [driver].
  String _getSdkPath(AnalysisDriver driver) {
    var coreSource = driver.sourceFactory.forUri('dart:core');

    // TODO(scheglov) Debug for https://github.com/dart-lang/sdk/issues/35226
    if (coreSource == null) {
      var sdk = driver.sourceFactory.dartSdk;
      if (sdk is AbstractDartSdk) {
        var sdkJson = JsonEncoder.withIndent('  ').convert(sdk.debugInfo());
        throw StateError('No dart:core, sdk: $sdkJson');
      }
    }

    var sdkRoot = coreSource.fullName;
    while (resourceProvider.pathContext.basename(sdkRoot) != 'lib') {
      var parent = resourceProvider.pathContext.dirname(sdkRoot);
      if (parent == sdkRoot) {
        break;
      }
      sdkRoot = parent;
    }
    return sdkRoot;
  }
}

/// Information related to an analysis driver.
class _DriverInfo {
  /// The context root representing the context being analyzed by the driver.
  final ContextRoot contextRoot;

  /// A list of the absolute paths of directories inside of which we have
  /// already searched for a plugin.
  final List<String> packageRoots;

  /// Initialize a newly created information holder.
  _DriverInfo(this.contextRoot, this.packageRoots);
}
