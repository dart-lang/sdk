// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.plugin.plugin_config_test;

import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';

main() {
  group('plugin config tests', () {
    group('parsing', () {
      test('plugin map', () {
        const optionsSrc = '''
analyzer:
  plugins:
    my_plugin1: ^0.1.0 #shorthand 
    my_plugin2:
      version: ^0.2.0
    my_plugin3:
      class_name: MyPlugin
      library_uri: myplugin/myplugin.dart
      path: '/u/disk/src/'
''';
        var config = parseConfig(optionsSrc);
        var plugins = pluginsSortedByName(config.plugins);
        expect(plugins, hasLength(3));
        expect(plugins[0].name, equals('my_plugin1'));
        expect(plugins[0].version, equals('^0.1.0'));
        expect(plugins[1].name, equals('my_plugin2'));
        expect(plugins[1].version, equals('^0.2.0'));
        expect(plugins[2].name, equals('my_plugin3'));
        expect(plugins[2].version, isNull);
        expect(plugins[2].path, equals('/u/disk/src/'));
        expect(plugins[2].libraryUri, equals('myplugin/myplugin.dart'));
        expect(plugins[2].className, equals('MyPlugin'));
      });

      test('plugin map (empty)', () {
        const optionsSrc = '''
analyzer:
  plugins:
    # my_plugin1: ^0.1.0 #shorthand 
''';
        var config = parseConfig(optionsSrc);
        // Commented out plugins shouldn't cause a parse failure.
        expect(config.plugins, hasLength(0));
      });

      test('plugin manifest', () {
        const manifestSrc = '''
class_name: AnalyzerPlugin
library_uri: myplugin/analyzer_plugin.dart
contributes_to: analyzer  
''';
        var manifest = parsePluginManifestString(manifestSrc);
        var plugin = manifest.plugin;
        expect(plugin.libraryUri, equals('myplugin/analyzer_plugin.dart'));
        expect(plugin.className, equals('AnalyzerPlugin'));
        expect(manifest.contributesTo, unorderedEquals(['analyzer']));
      });

      test('plugin manifest (contributes_to list)', () {
        const manifestSrc = '''
class_name: AnalyzerPlugin
library_uri: myplugin/analyzer_plugin.dart
contributes_to: 
  - analyzer
  - analysis_server  
''';
        var manifest = parsePluginManifestString(manifestSrc);
        var plugin = manifest.plugin;
        expect(plugin.libraryUri, equals('myplugin/analyzer_plugin.dart'));
        expect(plugin.className, equals('AnalyzerPlugin'));
        expect(manifest.contributesTo,
            unorderedEquals(['analyzer', 'analysis_server']));
      });

      group('errors', () {
        test('bad config format', () {
          const optionsSrc = '''
analyzer:
  plugins:
    - my_plugin1
    - my_plugin2
''';
          try {
            parseConfig(optionsSrc);
            fail('expected PluginConfigFormatException');
          } on PluginConfigFormatException catch (e) {
            expect(
                e.message,
                equals(
                    'Unrecognized plugin config format, expected `YamlMap`, got `YamlList`'));
            expect(e.yamlNode, new isInstanceOf<YamlList>());
          }
        });
        test('bad manifest format', () {
          const manifestSource = '''
library_uri:
 - should be a scalar uri
''';
          try {
            parsePluginManifestString(manifestSource);
            fail('expected PluginConfigFormatException');
          } on PluginConfigFormatException catch (e) {
            expect(
                e.message,
                equals(
                    'Unable to parse pugin manifest, expected `String`, got `YamlList`'));
            expect(e.yamlNode, new isInstanceOf<YamlList>());
          }
        });
      });
    });
  });
}

PluginConfig parseConfig(String optionsSrc) {
  var options = new AnalysisOptionsProvider().getOptionsFromString(optionsSrc);
  return new PluginConfig.fromOptions(options);
}

List<PluginInfo> pluginsSortedByName(Iterable<PluginInfo> plugins) =>
    plugins.toList()..sort((p1, p2) => p1.name.compareTo(p2.name));
