// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/sdk_configuration.dart';
import 'package:path/path.dart' as p;

/// Test Dart SDK layout.
///
/// Contains definition of the default SDK layout required for tests.
/// We keep all the path constants in one place for ease of update.
class TestSdkLayout {
  static final defaultSdkDirectory = SdkLayout.defaultSdkDirectory;

  static TestSdkLayout defaultSdkLayout = TestSdkLayout.createDefault(
    defaultSdkDirectory,
  );

  static SdkConfiguration defaultSdkConfiguration = createConfiguration(
    defaultSdkLayout,
  );

  factory TestSdkLayout.createDefault(String sdkDirectory) =>
      TestSdkLayout.createDefaultFromSdkLayout(
        SdkLayout.createDefault(sdkDirectory),
      );

  factory TestSdkLayout.createDefaultFromSdkLayout(SdkLayout sdkLayout) =>
      TestSdkLayout(
        sdkDirectory: sdkLayout.sdkDirectory,
        summaryPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          '_internal',
          'ddc_outline.dill',
        ),
        fullDillPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          '_internal',
          'ddc_platform.dill',
        ),
        amdJsPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          'dev_compiler',
          'kernel',
          'amd',
          'dart_sdk.js',
        ),
        amdJsMapPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          'dev_compiler',
          'kernel',
          'amd',
          'dart_sdk.js.map',
        ),
        ddcJsPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          'dev_compiler',
          'kernel',
          'ddc',
          'dart_sdk.js',
        ),
        ddcJsMapPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          'dev_compiler',
          'kernel',
          'ddc',
          'dart_sdk.js.map',
        ),
        ddcModuleLoaderJsPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          'dev_compiler',
          'ddc',
          'ddc_module_loader.js',
        ),
        requireJsPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          'dev_compiler',
          'amd',
          'require.js',
        ),
        stackTraceMapperPath: p.join(
          sdkLayout.sdkDirectory,
          'lib',
          'dev_compiler',
          'web',
          'dart_stack_trace_mapper.js',
        ),
        dartPath: p.join(
          sdkLayout.sdkDirectory,
          'bin',
          Platform.isWindows ? 'dart.exe' : 'dart',
        ),
        dartAotRuntimePath: p.join(
          sdkLayout.sdkDirectory,
          'bin',
          Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime',
        ),
        frontendServerSnapshotPath: p.join(
          sdkLayout.sdkDirectory,
          'bin',
          'snapshots',
          'frontend_server_aot.dart.snapshot',
        ),
        dartdevcSnapshotPath: sdkLayout.dartdevcSnapshotPath,
        kernelWorkerSnapshotPath: p.join(
          sdkLayout.sdkDirectory,
          'bin',
          'snapshots',
          'kernel_worker_aot.dart.snapshot',
        ),
        devToolsDirectory: p.join(
          sdkLayout.sdkDirectory,
          'bin',
          'resources',
          'devtools',
        ),
      );

  final String sdkDirectory;

  String get amdJsFileName => p.basename(amdJsPath);
  String get amdJsMapFileName => p.basename(amdJsMapPath);
  String get ddcJsFileName => p.basename(ddcJsPath);
  String get ddcJsMapFileName => p.basename(ddcJsMapPath);
  String get summaryFileName => p.basename(summaryPath);
  String get fullDillFileName => p.basename(fullDillPath);

  final String amdJsPath;
  final String amdJsMapPath;
  final String ddcJsPath;
  final String ddcJsMapPath;
  final String summaryPath;
  final String fullDillPath;

  final String ddcModuleLoaderJsPath;
  final String requireJsPath;
  final String stackTraceMapperPath;

  final String dartPath;
  final String dartAotRuntimePath;
  final String frontendServerSnapshotPath;
  final String dartdevcSnapshotPath;
  final String kernelWorkerSnapshotPath;
  final String devToolsDirectory;

  const TestSdkLayout({
    required this.sdkDirectory,
    required this.amdJsPath,
    required this.amdJsMapPath,
    required this.ddcJsPath,
    required this.ddcJsMapPath,
    required this.summaryPath,
    required this.fullDillPath,
    required this.ddcModuleLoaderJsPath,
    required this.requireJsPath,
    required this.stackTraceMapperPath,
    required this.dartPath,
    required this.dartAotRuntimePath,
    required this.frontendServerSnapshotPath,
    required this.dartdevcSnapshotPath,
    required this.kernelWorkerSnapshotPath,
    required this.devToolsDirectory,
  });

  /// Creates configuration from sdk layout.
  static SdkConfiguration createConfiguration(TestSdkLayout sdkLayout) =>
      SdkConfiguration(
        sdkDirectory: sdkLayout.sdkDirectory,
        sdkSummaryPath: sdkLayout.summaryPath,
        compilerWorkerPath: sdkLayout.dartdevcSnapshotPath,
      );
}

// Update modified files.
Future<void> copyDirectory(String from, String to) async {
  if (!Directory(from).existsSync()) return;
  await Directory(to).create(recursive: true);

  await for (final file in Directory(from).list(followLinks: false)) {
    final copyTo = p.join(to, p.relative(file.path, from: from));
    if (file is Directory) {
      await copyDirectory(file.path, copyTo);
    } else if (file is File) {
      await File(file.path).copy(copyTo);
    } else if (file is Link) {
      await Link(copyTo).create(await file.target(), recursive: true);
    }
  }
}
