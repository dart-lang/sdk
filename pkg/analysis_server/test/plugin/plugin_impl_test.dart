// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.operation;

import 'package:analysis_server/plugin/plugin.dart';
import 'package:analysis_server/src/plugin/plugin_impl.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';

  group('ExtensionManager', () {
    test('processPlugins', () {
      TestPlugin plugin1 = new TestPlugin('plugin1');
      TestPlugin plugin2 = new TestPlugin('plugin1');
      ExtensionManager manager = new ExtensionManager();
      manager.processPlugins([plugin1, plugin2]);
      expect(plugin1.extensionPointsRegistered, true);
      expect(plugin1.extensionsRegistered, true);
      expect(plugin2.extensionPointsRegistered, true);
      expect(plugin2.extensionsRegistered, true);
    });

    test('registerExtension - valid', () {
      Plugin plugin = new TestPlugin('plugin');
      ExtensionManager manager = new ExtensionManager();
      ExtensionPoint point =
          manager.registerExtensionPoint(plugin, 'point', null);
      expect(point, isNotNull);
      Object extension = 'extension';
      manager.registerExtension('plugin.point', extension);
      List<Object> extensions = point.extensions;
      expect(extensions, isNotNull);
      expect(extensions, hasLength(1));
      expect(extensions[0], extension);
    });

    test('registerExtension - non existent', () {
      ExtensionManager manager = new ExtensionManager();
      expect(
          () => manager.registerExtension('does not exist', 'extension'),
          throwsA(new isInstanceOf<ExtensionError>()));
      ;
    });

    test('registerExtensionPoint - non-conflicting', () {
      Plugin plugin1 = new TestPlugin('plugin1');
      Plugin plugin2 = new TestPlugin('plugin2');
      ExtensionManager manager = new ExtensionManager();
      expect(
          manager.registerExtensionPoint(plugin1, 'point1', null),
          isNotNull);
      expect(
          manager.registerExtensionPoint(plugin1, 'point2', null),
          isNotNull);
      expect(
          manager.registerExtensionPoint(plugin2, 'point1', null),
          isNotNull);
      expect(
          manager.registerExtensionPoint(plugin2, 'point2', null),
          isNotNull);
    });

    test('registerExtensionPoint - conflicting - same plugin', () {
      Plugin plugin1 = new TestPlugin('plugin1');
      ExtensionManager manager = new ExtensionManager();
      expect(
          manager.registerExtensionPoint(plugin1, 'point1', null),
          isNotNull);
      expect(
          () => manager.registerExtensionPoint(plugin1, 'point1', null),
          throwsA(new isInstanceOf<ExtensionError>()));
    });

    test('registerExtensionPoint - conflicting - different plugins', () {
      Plugin plugin1 = new TestPlugin('plugin1');
      Plugin plugin2 = new TestPlugin('plugin1');
      ExtensionManager manager = new ExtensionManager();
      expect(
          manager.registerExtensionPoint(plugin1, 'point1', null),
          isNotNull);
      expect(
          () => manager.registerExtensionPoint(plugin2, 'point1', null),
          throwsA(new isInstanceOf<ExtensionError>()));
    });
  });

  group('ExtensionPointImpl', () {
    test('extensions - empty', () {
      Plugin plugin = new TestPlugin('plugin');
      ExtensionPointImpl point = new ExtensionPointImpl(plugin, 'point', null);
      List<Object> extensions = point.extensions;
      expect(extensions, isNotNull);
      expect(extensions, isEmpty);
    });

    test('uniqueIdentifier', () {
      Plugin plugin = new TestPlugin('plugin');
      ExtensionPointImpl point = new ExtensionPointImpl(plugin, 'point', null);
      expect(point.uniqueIdentifier, 'plugin.point');
    });

    test('add - single', () {
      Plugin plugin = new TestPlugin('plugin');
      ExtensionPointImpl point = new ExtensionPointImpl(plugin, 'point', null);
      Object extension = 'extension';
      point.add(extension);
      List<Object> extensions = point.extensions;
      expect(extensions, isNotNull);
      expect(extensions, hasLength(1));
      expect(extensions[0], extension);
    });

    test('add - multiple', () {
      Plugin plugin = new TestPlugin('plugin');
      ExtensionPointImpl point = new ExtensionPointImpl(plugin, 'point', null);
      point.add('extension 1');
      point.add('extension 2');
      point.add('extension 3');
      List<Object> extensions = point.extensions;
      expect(extensions, isNotNull);
      expect(extensions, hasLength(3));
    });

    test('add - with validator - valid', () {
      Plugin plugin = new TestPlugin('plugin');
      ExtensionPointImpl point =
          new ExtensionPointImpl(plugin, 'point', (Object extension) {
        if (extension is! String) {
          throw new ExtensionError('');
        }
      });
      point.add('extension');
    });

    test('add - with validator - invalid', () {
      Plugin plugin = new TestPlugin('plugin');
      ExtensionPointImpl point =
          new ExtensionPointImpl(plugin, 'point', (Object extension) {
        if (extension is! String) {
          throw new ExtensionError('');
        }
      });
      expect(() => point.add(1), throwsA(new isInstanceOf<ExtensionError>()));
    });
  });
}

/**
 * A simple plugin that can be used by tests.
 */
class TestPlugin extends Plugin {
  /**
   * A flag indicating whether the method [registerExtensionPoints] has been
   * invoked.
   */
  bool extensionPointsRegistered = false;

  /**
   * A flag indicating whether the method [registerExtensions] has been invoked.
   */
  bool extensionsRegistered = false;

  @override
  String uniqueIdentifier;

  /**
   * Initialize a newly created plugin to have the given identifier.
   */
  TestPlugin(this.uniqueIdentifier);

  @override
  void registerExtensionPoints(RegisterExtensionPoint register) {
    extensionPointsRegistered = true;
  }

  @override
  void registerExtensions(RegisterExtension register) {
    extensionsRegistered = true;
  }
}
