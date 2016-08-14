// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/model.dart';
import 'package:package_config/packages.dart';
import 'package:yaml/src/yaml_node.dart';
import 'package:yaml/yaml.dart';

/// The descriptor used to associate analysis configuration with analysis
/// contexts in configuration data.
final ResultDescriptor<AnalysisConfiguration> ANALYSIS_CONFIGURATION =
    new ResultDescriptorImpl('analysis.config', null);

/// Return configuration associated with this [context], or `null` if there is
/// none.
AnalysisConfiguration getConfiguration(AnalysisContext context) =>
    context.getConfigurationData(ANALYSIS_CONFIGURATION);

/// Associate this [config] with the given [context].
void setConfiguration(AnalysisContext context, AnalysisConfiguration config) {
  context.setConfigurationData(ANALYSIS_CONFIGURATION, config);
}

/// Analysis configuration.
abstract class AnalysisConfiguration {
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();
  final Packages packages;
  final ResourceProvider resourceProvider;
  AnalysisConfiguration(this.resourceProvider, this.packages);

  factory AnalysisConfiguration.fromPubspec(
          File pubspec, ResourceProvider resourceProvider, Packages packages) =>
      new PubspecConfiguration(pubspec, resourceProvider, packages);

  /// Get a map of options defined by this configuration (or `null` if none
  /// are specified).
  Map get options;
}

/// Describes an analysis configuration.
class AnalysisConfigurationDescriptor {
  /// The name of the package hosting the configuration.
  String package;

  /// The name of the configuration "pragma".
  String pragma;

  AnalysisConfigurationDescriptor.fromAnalyzerOptions(Map analyzerOptions) {
    Object config = analyzerOptions['configuration'];
    if (config is String) {
      List<String> items = config.split('/');
      if (items.length == 2) {
        package = items[0].trim();
        pragma = items[1].trim();
      }
    }
  }

  /// Return true if this descriptor is valid.
  bool get isValid => package != null && pragma != null;
}

/// Pubspec-specified analysis configuration.
class PubspecConfiguration extends AnalysisConfiguration {
  final File pubspec;
  PubspecConfiguration(
      this.pubspec, ResourceProvider resourceProvider, Packages packages)
      : super(resourceProvider, packages);

  @override
  Map get options {
    //Safest not to cache (requested infrequently).
    if (pubspec.exists) {
      try {
        String contents = pubspec.readAsStringSync();
        YamlNode map = loadYamlNode(contents);
        if (map is YamlMap) {
          YamlNode config = map['analyzer'];
          if (config is YamlMap) {
            AnalysisConfigurationDescriptor descriptor =
                new AnalysisConfigurationDescriptor.fromAnalyzerOptions(config);

            if (descriptor.isValid) {
              //Create a path, given descriptor and packagemap
              Uri uri = packages.asMap()[descriptor.package];
              Uri pragma = new Uri.file('config/${descriptor.pragma}.yaml',
                  windows: false);
              Uri optionsUri = uri.resolveUri(pragma);
              String path = resourceProvider.pathContext.fromUri(optionsUri);
              File file = resourceProvider.getFile(path);
              if (file.exists) {
                return optionsProvider.getOptionsFromFile(file);
              }
            }
          }
        }
      } catch (_) {
        // Skip exceptional configurations.
      }
    }
    return null;
  }
}
