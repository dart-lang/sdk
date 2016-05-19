// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.plugin.plugin_manager;

import 'dart:io';

import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:path/path.dart' as path;

const _manifestFileName = 'plugins.yaml';

/// Given a local configuration (as defined in an analysis options file) and
/// information from a plugin manifest, return plugin info appropriate for
/// configuring this plugin.
PluginInfo combine(PluginInfo localConfig, PluginInfo manifestInfo) {
  return new PluginInfo(
      name: localConfig.name,
      version: manifestInfo.version,
      className: manifestInfo.className,
      libraryUri: manifestInfo.libraryUri);
}

/// Call-back to allow for the injection of manifest readers that do not need
/// to go to disk (for testing purposes).
typedef String ManifestReader(Uri uri);

/// Wraps a [plugin] info object elaborated with any configuration information
/// extracted from an associated manifest and [status].
class PluginDetails {
  /// Plugin status.
  final PluginStatus status;

  /// Plugin info.
  final PluginInfo plugin;

  /// Wrap a [plugin] with [status] info.
  PluginDetails(this.plugin) : status = PluginStatus.Applicable;
  PluginDetails.notApplicable(this.plugin)
      : status = PluginStatus.NotApplicable;
  PluginDetails.notFound(this.plugin) : status = PluginStatus.NotFound;
}

/// Manages plugin information derived from plugin manifests.
class PluginManager {
  /// Mapping from package name to package location.
  final Map<String, Uri> _packageMap;

  /// The package naming the app to host plugins.
  final String hostPackage;

  /// Function to perform the reading of manifest URIs. (For testing.)
  ManifestReader _manifestReader;

  /// Create a plugin manager with backing package map information.
  PluginManager(this._packageMap, this.hostPackage,
      [ManifestReader manifestReader]) {
    _manifestReader =
        manifestReader != null ? manifestReader : _findAndReadManifestAtUri;
  }

  /// Find a plugin manifest describing the given [pluginPackage].
  PluginManifest findManifest(String pluginPackage) {
    Uri uri = _packageMap[pluginPackage];
    String contents = _manifestReader(uri);
    if (contents == null) {
      return null;
    }
    return parsePluginManifestString(contents);
  }

  /// Return [PluginDetails] derived from associated plugin manifests
  /// corresponding to plugins specified in the given [config].
  Iterable<PluginDetails> getPluginDetails(PluginConfig config) =>
      config.plugins.map((PluginInfo localConfig) {
        PluginManifest manifest = findManifest(localConfig.name);
        return _getDetails(localConfig, manifest);
      });

  String _findAndReadManifestAtUri(Uri uri) {
    File manifestFile = _findManifest(uri);
    return manifestFile?.readAsStringSync();
  }

  File _findManifest(Uri uri) {
    if (uri == null) {
      return null;
    }

    Directory directory = new Directory.fromUri(uri);
    File file = new File(path.join(directory.path, _manifestFileName));

    return file.existsSync() ? file : null;
  }

  PluginDetails _getDetails(PluginInfo localConfig, PluginManifest manifest) {
    if (manifest == null) {
      return new PluginDetails.notFound(localConfig);
    }
    if (!manifest.contributesTo.contains(hostPackage)) {
      return new PluginDetails.notApplicable(localConfig);
    }

    return new PluginDetails(combine(localConfig, manifest.plugin));
  }
}

/// Describes plugin status.
enum PluginStatus { Applicable, NotApplicable, NotFound }
