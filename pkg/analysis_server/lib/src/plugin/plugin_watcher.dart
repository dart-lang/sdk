// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/plugin/dsatur.dart';
import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/plugin_trust.dart';
import 'package:analysis_server/src/plugin2/generator.dart';
import 'package:analysis_server/src/utilities/file_paths.dart' as file_paths;
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/hash/blake3.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:convert/convert.dart';

/// An object that watches the results produced by analysis drivers to identify
/// references to previously unseen packages and, if those packages have plugins
/// associated with them, causes the plugin to be associated with the driver's
/// context root (which in turn might cause the plugin to be started).
class PluginWatcher implements DriverWatcher {
  static final ScalarBlake3 _hasher = ScalarBlake3();

  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The object managing the execution of plugins.
  final PluginManager manager;

  /// The object used to locate plugins within packages.
  final PluginLocator _locator;

  /// A table mapping analysis drivers to information related to the driver.
  final Map<AnalysisDriver, _DriverInfo> _driverInfo =
      <AnalysisDriver, _DriverInfo>{};

  final bool? _pluginsAreEnabled;

  final PluginTrust _pluginTrust;

  final void Function(String message)? _onUnseenUntrustedPluginDirectory;

  final Set<String> _notifiedUnseenDirectories = {};

  /// Initialize a newly created plugin watcher.
  new(
    this.resourceProvider,
    this.manager, {
    required this._pluginsAreEnabled,
    PluginTrust? pluginTrust,
    this._onUnseenUntrustedPluginDirectory,
  }) : _pluginTrust = pluginTrust ?? PluginTrust(resourceProvider),
       _locator = PluginLocator(resourceProvider);

  @override
  void addedDriver(AnalysisDriver driver) {
    if (_pluginsAreEnabled == false) {
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

    var hasPlugins = _optionsForDriver(driver)
        .any((options) => options.pluginConfigurations.isNotEmpty);
    // Now we add any specified (new) plugins to the context, as a single
    // "legacy plugin" shared entrypoint.
    // Add a shared entrypoint plugin to the context root, only if one or more
    // plugins are specified in analysis options.
    if (!hasPlugins || !_addPlugins(driver)) {
      manager.contextRootsWithNoPlugins.add(contextRoot.root.path);

      // Call the plugin manager "initialized."
      if (!manager.initializedCompleter.isCompleted) {
        manager.initializedCompleter.complete();
      }
      return;
    }
  }

  @override
  void removedDriver(AnalysisDriver driver) {
    if (_pluginsAreEnabled == false) {
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
    if (driver.enabledLegacyPluginNames.isEmpty) return;

    var contextRoot = driver.analysisContext!.contextRoot;
    var optionsDirPath =
        contextRoot.optionsFile?.parent.path ?? contextRoot.root.path;

    for (var hostPackageName in driver.enabledLegacyPluginNames) {
      var resolved = _resolveLegacyPlugin(driver, hostPackageName);
      if (resolved == null) {
        return;
      }
      var (:packageRoot, :pluginPath) = resolved;
      if (!_isPluginTrusted(
        dirPath: optionsDirPath,
        pluginName: hostPackageName,
        source: PathPluginSource(path: packageRoot),
        resolvePluginFolder: () => resourceProvider.getFolder(packageRoot),
      )) {
        continue;
      }
      //
      // Add the plugin to the context root.
      //
      // TODO(brianwilkerson): Do we need to wait for the plugin to be added?
      // If we don't, then tests don't have any way to know when to expect
      // that the list of plugins has been updated.
      manager.addPluginToContextRoot(
        contextRoot,
        pluginPath,
        isLegacyPlugin: true,
      );
    }
  }

  /// Groups the plugin configurations specified in the [driver]'s analysis
  /// options files (using the DSATUR algorithm ([groupVerticesMinimal]) to
  /// minimize the number of isolates), generates the synthetic packages, and
  /// adds them to the context root.
  ///
  /// Returns whether any plugins were added.
  bool _addPlugins(AnalysisDriver driver) {
    var contextRoot = driver.analysisContext!.contextRoot;
    var uniqueOptions = _optionsForDriver(driver);

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
        var configurations = options.pluginConfigurations;
        if (configurations.isNotEmpty) {
          Map<String, Folder>? resolvedFolders;
          Folder? resolveFolder(String pluginName) {
            resolvedFolders ??= _locatePluginFolders(
              driver,
              options.pluginConfigurations,
              options.pluginsOptions.dependencyOverrides,
            );
            return resolvedFolders![pluginName];
          }

          configurations = [
            for (var config in configurations)
              if (_isPluginTrusted(
                dirPath: file.parent.path,
                pluginName: config.name,
                source: config.source,
                resolvePluginFolder: () => resolveFolder(config.name),
              ))
                config,
          ];
        }
        var spec = PluginSpecVertex(
          file.path,
          configurations,
          options.pluginsOptions.dependencyOverrides,
        );
        allSpecs.add(spec);
        if (configurations.isNotEmpty) {
          specsForGrouping.add(spec);
        }
      }
    }

    if (specsForGrouping.isEmpty) return false;

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

      var newPubspecContent = packageGenerator.generatePubspec();
      var pubspecHash = hex.encode(
        _hasher.hash(utf8.encode(newPubspecContent)),
      );
      var folderName = '${contextRoot.root.path}_$pubspecHash';
      var sharedPluginFolder = manager.pluginStateFolder(folderName);

      manager.instrumentationService.logInfo(
        "Creating shared plugin folder at '${sharedPluginFolder.path}' for "
        "context root: '${contextRoot.root.path}' group $i",
      );
      manager.sessionLogger.logInfo(
        "Creating shared plugin folder at '${sharedPluginFolder.path}' for "
        "context root: '${contextRoot.root.path}' group $i",
      );
      sharedPluginFolder.create();
      var pubspecFile = sharedPluginFolder.getFile(file_paths.pubspecYaml);
      // Only write the pubspec if it is different, to support caching.
      if (!pubspecFile.exists ||
          newPubspecContent != pubspecFile.readAsStringSync()) {
        pubspecFile.writeAsStringSync(newPubspecContent);
      }

      var binFolder = sharedPluginFolder.getFolder('bin')..create();
      var entrypointFile = binFolder.getFile(file_paths.pluginEntrypointDart);
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
      manager.sessionLogger.logInfo(
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
    return true;
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

  bool _isPluginTrusted({
    required String dirPath,
    required String pluginName,
    required PluginSource source,
    required Folder? Function() resolvePluginFolder,
  }) {
    var pluginsAreEnabled = _pluginsAreEnabled;
    if (pluginsAreEnabled != null) {
      // This is the override; if `--plugins` or `--no-plugins` was given,
      // just use that setting.
      return pluginsAreEnabled;
    }

    var sourceTrust = _pluginTrust.getSourceTrust(pluginName, source);
    if (sourceTrust == .trusted) return true;
    if (sourceTrust == .untrusted) return false;

    if (_pluginTrust.hasTrustedHashes(pluginName)) {
      var pluginFolder = resolvePluginFolder();
      if (pluginFolder != null &&
          _pluginTrust.isContentTrusted(pluginName, pluginFolder)) {
        return true;
      }
    }

    if (_notifiedUnseenDirectories.add(dirPath)) {
      _onUnseenUntrustedPluginDirectory?.call(untrustedPluginsMessage(dirPath));
    }
    return false;
  }

  /// Resolves the root package folders for [configurations] on disk.
  Map<String, Folder> _locatePluginFolders(
    AnalysisDriver driver,
    List<PluginConfiguration> configurations,
    Map<String, PluginSource>? dependencyOverrides,
  ) {
    var result = <String, Folder>{};
    var unresolved = <PluginConfiguration>[];

    for (var config in configurations) {
      var effectiveSource = dependencyOverrides?[config.name] ?? config.source;
      if (effectiveSource is PathPluginSource) {
        var folder = resourceProvider.getFolder(effectiveSource.path);
        if (folder.exists) {
          result[config.name] = folder;
          continue;
        }
      }
      unresolved.add(config);
    }

    if (unresolved.isEmpty) {
      return result;
    }

    var contextRoot = driver.analysisContext!.contextRoot;
    var packageGenerator = PluginPackageGenerator(
      configurations: configurations,
      dependencyOverrides:
          dependencyOverrides == null || dependencyOverrides.isEmpty
          ? null
          : dependencyOverrides,
    );
    var newPubspecContent = packageGenerator.generatePubspec();
    var pubspecHash = hex.encode(_hasher.hash(utf8.encode(newPubspecContent)));
    var folderName = '${contextRoot.root.path}_$pubspecHash';
    var sharedPluginFolder = manager.pluginStateFolder(folderName)..create();
    var pubspecFile = sharedPluginFolder.getFile(file_paths.pubspecYaml);
    if (!pubspecFile.exists ||
        newPubspecContent != pubspecFile.readAsStringSync()) {
      pubspecFile.writeAsStringSync(newPubspecContent);
    }

    var packageConfigFile = manager.resolvePackageConfig(sharedPluginFolder);
    var packages = packageConfigFile != null
        ? parsePackageConfigJsonFile(resourceProvider, packageConfigFile)
        : Packages.empty;

    var pathContext = resourceProvider.pathContext;
    for (var config in unresolved) {
      if (packages[config.name]?.rootFolder case var folder?
          when folder.exists) {
        result[config.name] = folder;
        continue;
      }
      var source =
          driver.sourceFactory.forUri('package:${config.name}/main.dart') ??
          driver.sourceFactory.forUri(
            'package:${config.name}/${config.name}.dart',
          );
      if (source != null) {
        var packageRoot = pathContext.dirname(
          pathContext.dirname(source.fullName),
        );
        var folder = resourceProvider.getFolder(packageRoot);
        if (folder.exists) {
          result[config.name] = folder;
        }
      }
    }

    return result;
  }

  /// Returns the unique [AnalysisOptionsImpl]s in [driver] that apply to
  /// [driver]'s context root.
  Set<AnalysisOptionsImpl> _optionsForDriver(AnalysisDriver driver) {
    var contextRoot = driver.analysisContext!.contextRoot;
    return {
      for (var options in driver.analysisOptionsMap.options)
        if (options.file case var file?
            when file == contextRoot.optionsFile ||
                contextRoot.isAnalyzed(file.parent.path))
          options,
    };
  }

  ({String packageRoot, String pluginPath})? _resolveLegacyPlugin(
    AnalysisDriver driver,
    String hostPackageName,
  ) {
    var uri = 'package:$hostPackageName/$hostPackageName.dart';
    var source = driver.sourceFactory.forUri(uri);
    if (source == null) {
      return null;
    }
    var context = resourceProvider.pathContext;
    var packageRoot = context.dirname(context.dirname(source.fullName));
    var pluginPath = _locator.findPlugin(packageRoot);
    if (pluginPath == null) {
      return null;
    }
    return (packageRoot: packageRoot, pluginPath: pluginPath);
  }

  static String untrustedPluginsMessage(String dirPath) =>
      "Analyzer plugins are configured in '$dirPath', but were not run "
      'because they are not trusted.\n'
      'Run \'dart analyze --plugins "$dirPath"\' to run plugins once, '
      '\'dart analyze --trust-plugins "$dirPath"\' to trust plugins in '
      "'$dirPath' with their current contents, "
      '\'dart analyze --always-trust-plugins "$dirPath"\' to always trust '
      "plugins in '$dirPath', or "
      '\'dart analyze --never-trust-plugins "$dirPath"\' to never trust '
      "plugins in '$dirPath'.\n";
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
