// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin2/generator.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

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

  @override
  void addedDriver(AnalysisDriver driver) {
    var contextRoot = driver.analysisContext!.contextRoot;
    _driverInfo[driver] = _DriverInfo(contextRoot, <String>[
      contextRoot.root.path,
      _getSdkPath(driver),
    ]);

    // We temporarily support both "legacy plugins" and (new) "plugins." We
    // restrict the number of legacy plugins to 1, for performance reasons.
    // At some point, we will stop adding legacy plugins to the context root.

    for (var hostPackageName in driver.enabledLegacyPluginNames) {
      //
      // Determine whether the package exists and defines a plugin.
      //
      var uri = 'package:$hostPackageName/$hostPackageName.dart';
      var source = driver.sourceFactory.forUri(uri);
      if (source == null) {
        return;
      }
      var context = resourceProvider.pathContext;
      var packageRoot = context.dirname(context.dirname(source.fullName));
      var pluginPath = _locator.findPlugin(packageRoot);
      if (pluginPath == null) {
        return;
      }
      //
      // Add the plugin to the context root.
      //
      // TODO(brianwilkerson): Do we need to wait for the plugin to be added?
      // If we don't, then tests don't have any way to know when to expect
      // that the list of plugins has been updated.
      manager.addPluginToContextRoot(
        driver.analysisContext!.contextRoot,
        pluginPath,
        isLegacyPlugin: true,
      );
    }

    // Now we add any specified (new) plugins to the context, as a single
    // "legacy plugin" shared entrypoint.
    var pluginConfigurations = driver.pluginConfigurations;
    // Add a shared entrypoint plugin to the context root, only if one or more
    // plugins are specified in analysis options.
    if (pluginConfigurations.isNotEmpty) {
      var contextRoot = driver.analysisContext!.contextRoot;
      var packageGenerator = PluginPackageGenerator(pluginConfigurations);
      // The path here just needs to be unique per context root.
      var sharedPluginFolder = manager.pluginStateFolder(contextRoot.root.path)
        ..create();
      sharedPluginFolder
          .getChildAssumingFile(file_paths.pubspecYaml)
          .writeAsStringSync(packageGenerator.generatePubspec());
      var libFolder = sharedPluginFolder.getChildAssumingFolder('bin')
        ..create();
      libFolder
          .getChildAssumingFile('plugin.dart')
          .writeAsStringSync(packageGenerator.generateEntrypoint());

      manager.addPluginToContextRoot(
        contextRoot,
        sharedPluginFolder.path,
        isLegacyPlugin: false,
      );
    }
  }

  /// The context manager has just removed the given analysis [driver].
  @override
  void removedDriver(AnalysisDriver driver) {
    var info = _driverInfo[driver];
    if (info == null) {
      throw StateError('Cannot remove a driver that was not added');
    }
    manager.removedContextRoot(driver.analysisContext!.contextRoot);
    _driverInfo.remove(driver);
  }

  /// Return the path to the root of the SDK being used by the given analysis
  /// [driver].
  String _getSdkPath(AnalysisDriver driver) {
    var coreSource = driver.sourceFactory.forUri('dart:core');

    // TODO(scheglov): Debug for https://github.com/dart-lang/sdk/issues/35226
    if (coreSource == null) {
      var sdk = driver.sourceFactory.dartSdk;
      if (sdk is AbstractDartSdk) {
        var sdkJson = JsonEncoder.withIndent('  ').convert(sdk.debugInfo());
        throw StateError('No dart:core, sdk: $sdkJson');
      }
    }

    var sdkRoot = coreSource!.fullName;
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
