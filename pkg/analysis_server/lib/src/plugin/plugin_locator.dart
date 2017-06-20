// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

/**
 * An object used to locate a plugin within a package.
 */
class PluginLocator {
  /**
   * The key used in the `pubspec.yaml` file to specify the location of the
   * analysis plugin.
   */
  static const String analyzerPluginKey = 'analyzer_plugin';

  /**
   * The name of the default plugin directory, located within the `tools`
   * directory.
   */
  static const String defaultPluginFolderName = 'analyzer_plugin';

  /**
   * The name of the `pubspec.yaml` file.
   */
  static const String pubspecFileName = 'pubspec.yaml';

  /**
   * The name of the `tools` directory, in which the default plugin directory is
   * located.
   */
  static const String toolsFolderName = 'tools';

  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  final Map<String, String> pluginMap = <String, String>{};

  /**
   * Initialize a newly created plugin locator to use the given
   * [resourceProvider] to access the file system.
   */
  PluginLocator(this.resourceProvider);

  /**
   * Given the root directory of a package (the [packageRoot]), return the path
   * to the plugin associated with the package, or `null` if there is no plugin
   * associated with the package.
   *
   * This will look first in the `pubspec.yaml` file in the package root for a
   * top-level key (`analysis_plugin`) indicating where the plugin is located.
   * The value associated with the key is expected to be the path of the plugin
   * relative to the package root. If the directory exists, the it is returned.
   *
   * If the key is not defined in the `pubspec.yaml` file, or if the directory
   * given does not exist, then this method will look for the directory
   * `tools/analysis_plugin` relative to the package root. If the directory
   * exists, then it is returned.
   *
   * This method does not validate the content of the plugin directory before
   * returning it.
   */
  String findPlugin(String packageRoot) {
    return pluginMap.putIfAbsent(packageRoot, () => _findPlugin(packageRoot));
  }

  /**
   * The implementation of [findPlugin].
   */
  String _findPlugin(String packageRoot) {
    Folder packageFolder = resourceProvider.getFolder(packageRoot);
    File pubspecFile = packageFolder.getChildAssumingFile(pubspecFileName);
    if (pubspecFile.exists) {
      try {
        YamlDocument document = loadYamlDocument(pubspecFile.readAsStringSync(),
            sourceUrl: pubspecFile.toUri());
        YamlNode contents = document.contents;
        if (contents is YamlMap) {
          String pluginPath = contents[analyzerPluginKey];
          if (pluginPath != null) {
            Folder pluginFolder =
                packageFolder.getChildAssumingFolder(pluginPath);
            if (pluginFolder.exists) {
              return pluginFolder.path;
            }
          }
        }
      } catch (exception) {
        // If we can't read the file, or if it isn't valid YAML, then ignore it.
      }
    }
    Folder pluginFolder = packageFolder
        .getChildAssumingFolder(toolsFolderName)
        .getChildAssumingFolder(defaultPluginFolderName);
    if (pluginFolder.exists) {
      return pluginFolder.path;
    }
    return null;
  }
}
