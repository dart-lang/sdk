// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.plugin.plugin_configuration;

import 'package:analyzer/plugin/options.dart';
import 'package:yaml/yaml.dart';

const _analyzerOptionScope = 'analyzer';

const _pluginOptionScope = 'plugins';

PluginInfo _processPluginMapping(dynamic name, dynamic details) {
  if (name is String) {
    if (details is String) {
      return new PluginInfo(name: name, version: details);
    }
    if (details is YamlMap) {
      return new PluginInfo(
          name: name,
          version: details['version'],
          className: details['class_name'],
          libraryUri: details['library_uri'],
          packageName: details['package_name'],
          path: details['path']);
    }
  }

  return null;
}

PluginInfo _processPluginNode(dynamic node) {
  if (node is String) {
    return new PluginInfo(name: node);
  }
  if (node is YamlMap) {
    if (node.length == 1) {
      return new PluginInfo(name: node.keys.first, version: node.values.first);
    }
  }
  return null;
}

typedef ErrorHandler(Exception);

/// Describes plugin configuration information as extracted from an
/// analysis options map.
class PluginConfig {
  final Iterable<PluginInfo> plugins;
  PluginConfig(this.plugins);

  /// Create a plugin configuration from an options map.
  factory PluginConfig.fromOptions(Map<String, YamlNode> options) {
    List<PluginInfo> plugins = [];
    var analyzerOptions = options[_analyzerOptionScope];
    if (analyzerOptions != null) {
      if (analyzerOptions is YamlMap) {
        var pluginConfig = analyzerOptions[_pluginOptionScope];
        if (pluginConfig is YamlMap) {
          pluginConfig.forEach((name, details) {
            var plugin = _processPluginMapping(name, details);
            if (plugin != null) {
              plugins.add(plugin);
            }
          });
        } else {
          var plugin = _processPluginNode(pluginConfig);
          if (plugin != null) {
            plugins.add(plugin);
          }
        }
      }
    }

    return new PluginConfig(plugins);
  }
}

/// Extracts plugin config details from analysis options.
class PluginConfigOptionsProcessor extends OptionsProcessor {
  final ErrorHandler _errorHandler;

  PluginConfig _config;

  PluginConfigOptionsProcessor([this._errorHandler]);

  /// The processed plugin config.
  PluginConfig get config => _config;

  @override
  void onError(Exception exception) {
    if (_errorHandler != null) {
      _errorHandler(exception);
    }
  }

  @override
  void optionsProcessed(Map<String, YamlNode> options) {
    _config = new PluginConfig.fromOptions(options);
  }
}

/// Describes plugin information.
class PluginInfo {
  final String name;
  final String className;
  final String version;
  final String libraryUri;
  final String packageName;
  final String path;
  PluginInfo(
      {this.name,
      this.version,
      this.className,
      this.libraryUri,
      this.packageName,
      this.path});
}
