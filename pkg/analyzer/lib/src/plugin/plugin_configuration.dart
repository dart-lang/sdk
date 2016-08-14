// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.plugin.plugin_configuration;

import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:yaml/yaml.dart';

const _analyzerOptionScope = 'analyzer';

const _pluginOptionScope = 'plugins';

/// Parse the given string into a plugin manifest.
PluginManifest parsePluginManifestString(String manifestSource) {
  var yaml = loadYaml(manifestSource);
  if (yaml == null) {
    return null;
  }
  _verifyMap(yaml, 'plugin manifest');
  Iterable<String> pluginHost = _parseHosts(yaml['contributes_to']);
  PluginInfo plugin = _parsePlugin(yaml);
  return new PluginManifest(contributesTo: pluginHost, plugin: plugin);
}

String _asString(dynamic yaml) {
  if (yaml != null && yaml is! String) {
    throw new PluginConfigFormatException(
        'Unable to parse pugin manifest, '
        'expected `String`, got `${yaml.runtimeType}`',
        yaml);
  }
  return yaml;
}

Iterable<String> _parseHosts(dynamic yaml) {
  List<String> hosts = <String>[];
  if (yaml is String) {
    hosts.add(yaml);
  } else if (yaml is YamlList) {
    yaml.forEach((h) => hosts.add(_asString(h)));
  }
  return hosts;
}

PluginInfo _parsePlugin(dynamic yaml) {
  if (yaml != null) {
    _verifyMap(yaml, 'plugin manifest');
    return new PluginInfo._fromYaml(details: yaml);
  }
  return null;
}

PluginInfo _processPluginMapping(dynamic name, dynamic details) {
  if (name is String) {
    if (details is String) {
      return new PluginInfo(name: name, version: details);
    }
    if (details is YamlMap) {
      return new PluginInfo._fromYaml(name: name, details: details);
    }
  }

  return null;
}

_verifyMap(dynamic yaml, String context) {
  if (yaml is! YamlMap) {
    throw new PluginConfigFormatException(
        'Unable to parse $context, '
        'expected `YamlMap`, got `${yaml.runtimeType}`',
        yaml);
  }
}

/// A callback for error handling.
typedef ErrorHandler(Exception e);

/// Describes plugin configuration information as extracted from an
/// analysis options map or plugin manifest.
class PluginConfig {
  final Iterable<PluginInfo> plugins;
  PluginConfig(this.plugins);

  /// Create a plugin configuration from an options map.
  factory PluginConfig.fromOptions(Map<String, Object> options) {
    List<PluginInfo> plugins = [];
    var analyzerOptions = options[_analyzerOptionScope];
    if (analyzerOptions != null) {
      //TODO(pq): handle "raw" maps (https://github.com/dart-lang/sdk/issues/25126)
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
          // Anything but an empty list of plugins is treated as a format error.
          if (pluginConfig != null) {
            throw new PluginConfigFormatException(
                'Unrecognized plugin config format, expected `YamlMap`, '
                'got `${pluginConfig.runtimeType}`',
                pluginConfig);
          }
        }
      }
    }

    return new PluginConfig(plugins);
  }
}

/// Thrown on bad plugin config format.
class PluginConfigFormatException implements Exception {
  /// Descriptive message.
  final message;

  /// The `plugin:` yaml node for generating detailed error feedback.
  final yamlNode;
  PluginConfigFormatException(this.message, this.yamlNode);
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
  void optionsProcessed(AnalysisContext context, Map<String, Object> options) {
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

  factory PluginInfo._fromYaml({String name, YamlMap details}) =>
      new PluginInfo(
          name: name,
          version: _asString(details['version']),
          className: _asString(details['class_name']),
          libraryUri: _asString(details['library_uri']),
          packageName: _asString(details['package_name']),
          path: _asString(details['path']));
}

/// Plugin manifests accompany plugin packages, providing
/// configuration information for published plugins.
///
/// Provisionally, plugin manifests live in a file `plugin.yaml`
/// at the root of the plugin package.
///
///     my_plugin/
///       bin/
///       lib/
///       plugin.yaml
///       pubspec.yaml
///
/// Provisional manifest file format:
///
///     class_name: MyAnalyzerPlugin
///     library_uri: 'my_plugin/my_analyzer_plugin.dart'
///     contributes_to: analyzer
class PluginManifest {
  PluginInfo plugin;
  Iterable<String> contributesTo;
  PluginManifest({this.plugin, this.contributesTo});
}
