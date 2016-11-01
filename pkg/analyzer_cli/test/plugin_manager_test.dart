// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.plugin_manager_test;

import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:analyzer_cli/src/plugin/plugin_manager.dart';
import 'package:test/test.dart';

main() {
  group('plugin manager tests', () {
    test('combine plugin info', () {
      PluginInfo localInfo = new PluginInfo(name: 'my_plugin');
      PluginInfo manifestInfo = new PluginInfo(
          className: 'MyPlugin', libraryUri: 'my_plugin/my_plugin.dart');

      PluginInfo merged = combine(localInfo, manifestInfo);
      expect(merged.name, equals('my_plugin'));
      expect(merged.className, equals('MyPlugin'));
      expect(merged.libraryUri, equals('my_plugin/my_plugin.dart'));
    });

    test('find manifest', () {
      const manifestSrc = '''
library_uri: 'my_plugin/my_plugin.dart'
''';
      var packageMap = {'my_plugin': new Uri.file('my_plugin')};

      PluginManager pm =
          new PluginManager(packageMap, 'analyzer', (Uri uri) => manifestSrc);

      PluginManifest manifest = pm.findManifest('my_plugin');
      expect(manifest, isNotNull);
      expect(manifest.plugin.libraryUri, equals('my_plugin/my_plugin.dart'));
    });

    final plugin1Uri = new Uri.file('my_plugin1');
    final plugin2Uri = new Uri.file('my_plugin2');
    final plugin3Uri = new Uri.file('my_plugin3');

    const serverPluginManifest = '''
library_uri: 'my_plugin2/my_plugin2.dart'
contributes_to: analysis_server
''';
    const analyzerPluginManifest = '''
library_uri: 'my_plugin3/my_plugin3.dart'
contributes_to: analyzer
''';

    var packageMap = {
      'my_plugin': plugin1Uri,
      'my_plugin2': plugin2Uri,
      'my_plugin3': plugin3Uri
    };

    var manifestReader = (Uri uri) {
      if (uri == plugin2Uri) return serverPluginManifest;
      if (uri == plugin3Uri) return analyzerPluginManifest;
      return null;
    };

    test('get plugin details', () {
      PluginManager pm =
          new PluginManager(packageMap, 'analysis_server', manifestReader);

      PluginInfo notFound = new PluginInfo(name: 'my_plugin1');
      PluginInfo applicable = new PluginInfo(name: 'my_plugin2');
      PluginInfo notApplicable = new PluginInfo(name: 'my_plugin3');

      PluginConfig localConfig =
          new PluginConfig([notFound, applicable, notApplicable]);

      Iterable<PluginDetails> details = pm.getPluginDetails(localConfig);
      expect(details, hasLength(3));

      List<PluginDetails> plugins = sortByName(details);

      expect(plugins[0].plugin.name, equals('my_plugin1'));
      expect(plugins[0].status, equals(PluginStatus.NotFound));
      expect(plugins[1].plugin.name, equals('my_plugin2'));
      expect(
          plugins[1].plugin.libraryUri, equals('my_plugin2/my_plugin2.dart'));
      expect(plugins[1].status, equals(PluginStatus.Applicable));
      expect(plugins[2].plugin.name, equals('my_plugin3'));
      expect(plugins[2].status, equals(PluginStatus.NotApplicable));
    });
  });
}

List<PluginDetails> sortByName(Iterable<PluginDetails> details) =>
    details.toList()
      ..sort((p1, p2) => p1.plugin.name.compareTo(p2.plugin.name));
