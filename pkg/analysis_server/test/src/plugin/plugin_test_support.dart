// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;

import '../../mocks.dart';
import '../../support/sdk_paths.dart';

/// A superclass for test classes that define tests that require plugins to be
/// created on disk.
abstract class PluginTestSupport {
  /// The default content of the plugin. This is a minimal plugin that will only
  /// respond correctly to version checks and to shutdown requests.
  static const _defaultPluginContent = r'''
import 'dart:async';
import 'dart:isolate';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:pub_semver/pub_semver.dart';

void main(List<String> args, SendPort sendPort) {
  MinimalPlugin plugin = new MinimalPlugin(PhysicalResourceProvider.INSTANCE);
  new ServerPluginStarter(plugin).start(sendPort);
}

class MinimalPlugin extends ServerPlugin {
  MinimalPlugin(ResourceProvider provider) : super(provider);

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'minimal';

  @override
  String get version => '0.0.1';

  @override
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) => null;

  @override
  Future<AnalysisHandleWatchEventsResult> handleAnalysisHandleWatchEvents(
      AnalysisHandleWatchEventsParams parameters) async =>
    new AnalysisHandleWatchEventsResult();

  @override
  bool isCompatibleWith(Version serverVersion) => true;
}
''';

  late PhysicalResourceProvider resourceProvider;

  late TestNotificationManager notificationManager;

  void setUp() {
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    notificationManager = TestNotificationManager();
  }

  /// Creates a directory structure representing a plugin on disk, runs the
  /// given [test] function, and then removes the directory.
  ///
  /// The directory will have the following structure:
  /// ```
  /// <pluginDirectory>
  ///   .dart_tool/
  ///     package_config.dart
  ///   bin/
  ///     plugin.dart
  /// ```
  /// The name of the plugin directory will be the [pluginName], if one is
  /// provided (in order to allow more than one plugin to be created by a single
  /// test). The 'plugin.dart' file will contain the given [content], or default
  /// content that implements a minimal plugin if the contents are not given.
  /// The [test] function will be passed the path of the directory that was
  /// created.
  Future<void> withPlugin({
    String pluginName = 'test_plugin',
    String content = _defaultPluginContent,
    required Future<void> Function(String) test,
  }) async {
    var tempDirectory = io.Directory.systemTemp.createTempSync(pluginName);
    try {
      var pluginPath = tempDirectory.resolveSymbolicLinksSync();
      // Create a package config file.
      var pluginDartToolPath = path.join(pluginPath, '.dart_tool');
      io.Directory(pluginDartToolPath).createSync();
      var packageConfigFile = io.File(
        path.join(pluginDartToolPath, 'package_config.json'),
      );
      packageConfigFile.writeAsStringSync(
        io.File(sdkPackageConfigPath).readAsStringSync(),
      );
      //
      // Create the 'bin' directory.
      //
      var binPath = path.join(pluginPath, 'bin');
      io.Directory(binPath).createSync();
      //
      // Create the 'plugin.dart' file.
      //
      var pluginFile = io.File(path.join(binPath, 'plugin.dart'));
      pluginFile.writeAsStringSync(content);
      //
      // Run the actual test code.
      //
      await test(pluginPath);
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}
