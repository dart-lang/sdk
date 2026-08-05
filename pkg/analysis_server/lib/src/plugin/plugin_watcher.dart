// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/plugin/dsatur.dart';
import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin2/generator.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;

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

  final bool _pluginsAreEnabled;

  /// Initialize a newly created plugin watcher.
  new(this.resourceProvider, this.manager, {required this._pluginsAreEnabled})
    : _locator = PluginLocator(resourceProvider);

  @override
  void addedDriver(AnalysisDriver driver) {
    if (!_pluginsAreEnabled) {
      // Call the plugin manager "initialized."
      if (!manager.initializedCompleter.isCompleted) {
        manager.initializedCompleter.complete();
      }
      return;
    }
    var contextRoot = driver.analysisContext!.contextRoot;
    _driverInfo[driver] = _DriverInfo(contextRoot, <String>[
      contextRoot.root.path,
      _getSdkPath(driver),
    ]);

    // We temporarily support both "legacy plugins" and (new) "plugins." We
    // restrict the number of legacy plugins to 1, for performance reasons.
    // At some point, we will stop adding legacy plugins to the context root.
    _addLegacyPlugins(driver);

    var hasPlugins = driver.analysisOptionsMap.options.any(
      (options) => options.pluginConfigurations.isNotEmpty,
    );
    if (!hasPlugins) {
      manager.contextRootsWithNoPlugins.add(contextRoot.root.path);

      // Call the plugin manager "initialized."
      if (!manager.initializedCompleter.isCompleted) {
        manager.initializedCompleter.complete();
      }
      return;
    }

    // Now we add any specified (new) plugins to the context, as a single
    // "legacy plugin" shared entrypoint.
    // Add a shared entrypoint plugin to the context root, only if one or more
    // plugins are specified in analysis options.
    _addPlugins(driver);
  }

  @override
  void removedDriver(AnalysisDriver driver) {
    if (!_pluginsAreEnabled) {
      return;
    }
    var info = _driverInfo[driver];
    if (info == null) {
      throw StateError('Cannot remove a driver that was not added');
    }
    manager.removedContextRoot(driver.analysisContext!.contextRoot);
    _driverInfo.remove(driver);
  }

  void _addLegacyPlugins(AnalysisDriver driver) {
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
  }

  /// Groups the plugin configurations specified in the [driver]'s analysis
  /// options files (using the DSATUR algorithm ([groupVerticesMinimal]) to
  /// minimize the number of isolates), generates the synthetic packages, and
  /// adds them to the context root.
  void _addPlugins(AnalysisDriver driver) {
    var contextRoot = driver.analysisContext!.contextRoot;
    var uniqueOptions = driver.analysisOptionsMap.options.toSet();

    // All plugin specifications across the context root, including those with
    // empty configurations. This is used to build the configuration maps sent
    // to isolates, ensuring empty subdirectories override parent settings.
    var allSpecs = <PluginSpecVertex>[];

    // Only non-empty plugin specifications. This is used to compute isolate
    // groupings via DSATUR, as we only need to spawn isolates for directories
    // that actually run plugins.
    var specsForGrouping = <PluginSpecVertex>[];
    for (var options in uniqueOptions) {
      var file = options.file;
      if (file != null) {
        var spec = PluginSpecVertex(
          file.path,
          options.pluginConfigurations,
          options.pluginsOptions.dependencyOverrides,
        );
        allSpecs.add(spec);
        if (options.pluginConfigurations.isNotEmpty) {
          specsForGrouping.add(spec);
        }
      }
    }

    if (specsForGrouping.isEmpty) return;

    // Group the plugin configurations using DSATUR.
    var groups = groupVerticesMinimal(specsForGrouping);

    // For each plugin group, generate the synthetic package and spawn/update
    // the isolate.
    for (var i = 0; i < groups.length; i++) {
      var group = groups[i];
      var groupConfigurationsMap = {
        for (var spec in group)
          for (var config in spec.configurations) config.name: config,
      };
      var groupConfigurations = groupConfigurationsMap.values.toList();
      var groupDependencyOverrides = {
        for (var spec in group) ...?spec.dependencyOverrides,
      };
      var packageGenerator = PluginPackageGenerator(
        configurations: groupConfigurations,
        dependencyOverrides: groupDependencyOverrides.isEmpty
            ? null
            : groupDependencyOverrides,
      );

      // TODO(srawlins): Better to name the folder based on a hash of the...
      // maybe the plugin names. Maybe the configutations.
      var folderName = groups.length == 1
          ? contextRoot.root.path
          : '${contextRoot.root.path}_group_$i';
      var sharedPluginFolder = manager.pluginStateFolder(folderName);

      manager.instrumentationService.logInfo(
        "Creating shared plugin folder at '${sharedPluginFolder.path}' for "
        "context root: '${contextRoot.root.path}' group $i",
      );
      sharedPluginFolder.create();
      var pubspecFile = sharedPluginFolder.getFile(file_paths.pubspecYaml);
      var newPubspecContent = packageGenerator.generatePubspec();
      // Only write the pubspec if it is different, to support caching.
      if (!pubspecFile.exists ||
          newPubspecContent != pubspecFile.readAsStringSync()) {
        pubspecFile.writeAsStringSync(newPubspecContent);
      }

      var binFolder = sharedPluginFolder.getFolder('bin')..create();
      var entrypointFile = binFolder.getFile('plugin.dart');
      var newEntrypointContent = packageGenerator.generateEntrypoint();
      // Only write the entrypoint if it is different, to support caching.
      if (!entrypointFile.exists ||
          newEntrypointContent != entrypointFile.readAsStringSync()) {
        entrypointFile.writeAsStringSync(newEntrypointContent);
      }

      manager.instrumentationService.logInfo(
        'Adding ${groupConfigurations.length} analyzer plugins for '
        "context root: '${contextRoot.root.path}' group $i",
      );

      var groupProtocolConfigurations =
          <String, Map<String, protocol.PluginConfiguration>>{};
      for (var spec in allSpecs) {
        var dirPath = resourceProvider
            .getFile(spec.optionsFilePath)
            .parent
            .path;
        var pluginMap = <String, protocol.PluginConfiguration>{};
        var isSpecInGroup = group.any(
          (v) => v.optionsFilePath == spec.optionsFilePath,
        );
        if (isSpecInGroup) {
          for (var config in spec.configurations) {
            var severities = {
              for (var MapEntry(key: code, value: ruleConfig)
                  in config.diagnosticConfigs.entries)
                code: ruleConfig.severity.name,
            };
            pluginMap[config.name] = protocol.PluginConfiguration(
              config.isEnabled,
              severities,
            );
          }
        }
        groupProtocolConfigurations[dirPath] = pluginMap;
      }

      unawaited(() async {
        await manager.addPluginToContextRoot(
          contextRoot,
          sharedPluginFolder.path,
          isLegacyPlugin: false,
        );
        var pluginIsolate = manager.pluginIsolates
            .where((e) => e.pluginId == sharedPluginFolder.path)
            .firstOrNull;
        pluginIsolate?.sendRequest(
          protocol.AnalysisSetConfigurationsParams(groupProtocolConfigurations),
        );
      }());
    }
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
  new(this.contextRoot, this.packageRoots);
}
