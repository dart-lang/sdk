// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.plugin.plugin_config_test;

import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:unittest/unittest.dart';

main() {
  group('PluginConfig', () {
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
        var plugins = pluginsSortedByName(config);
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
    });
  });
}

PluginConfig parseConfig(String optionsSrc) {
  var options = new AnalysisOptionsProvider().getOptionsFromString(optionsSrc);
  return new PluginConfig.fromOptions(options);
}

List<PluginInfo> pluginsSortedByName(PluginConfig config) =>
    config.plugins.toList()..sort((p1, p2) => p1.name.compareTo(p2.name));
