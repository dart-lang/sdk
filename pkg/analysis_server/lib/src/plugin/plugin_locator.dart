// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

/// An object used to locate a plugin within a package.
class PluginLocator {
  /// The key used in the `pubspec.yaml` file to specify the location of the
  /// analysis plugin.
  static const String analyzerPluginKey = 'analyzer_plugin';

  /// The name of the default plugin directory, located within the `tools`
  /// directory.
  static const String defaultPluginFolderName = 'analyzer_plugin';

  /// The name of the `tools` directory, in which the default plugin directory
  /// is located.
  static const String toolsFolderName = 'tools';

  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  final Map<String, String?> pluginMap = {};

  /// Initialize a newly created plugin locator to use the given
  /// [resourceProvider] to access the file system.
  PluginLocator(this.resourceProvider);

  /// Given the root directory of a package (the [packageRoot]), returns the
  /// path to the plugin associated with the package, or `null` if there is no
  /// plugin associated with the package.
  ///
  /// Looks for the directory `tools/analysis_plugin` relative to
  /// the package root.
  ///
  /// The content of the plugin directory is not validated.
  String? findPlugin(String packageRoot) {
    return pluginMap.putIfAbsent(packageRoot, () => _findPlugin(packageRoot));
  }

  /// The implementation of [findPlugin].
  String? _findPlugin(String packageRoot) {
    var packageFolder = resourceProvider.getFolder(packageRoot);
    var pluginFolder = packageFolder
        .getChildAssumingFolder(toolsFolderName)
        .getChildAssumingFolder(defaultPluginFolderName);
    if (pluginFolder.exists) {
      return pluginFolder.path;
    }
    return null;
  }
}
