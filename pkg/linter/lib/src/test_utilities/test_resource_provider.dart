// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';

/// Builds the [DartLinter] with appropriate mock SDK, resource providers, and
/// package config path.
DartLinter buildDriver(LintRule rule, File file, {String? analysisOptions}) {
  var memoryResourceProvider = MemoryResourceProvider(
      context: PhysicalResourceProvider.INSTANCE.pathContext);
  var resourceProvider = TestResourceProvider(memoryResourceProvider);

  var sdkRoot = memoryResourceProvider.getFolder(
    memoryResourceProvider.convertPath('/sdk'),
  );
  createMockSdk(
    resourceProvider: memoryResourceProvider,
    root: sdkRoot,
  );

  var options = LinterOptions([rule], analysisOptions)
    ..dartSdkPath = sdkRoot.path
    ..resourceProvider = resourceProvider;

  return DartLinter(options);
}

/// A resource provider that accesses entities in a MemoryResourceProvider,
/// falling back to the PhysicalResourceProvider when they don't exist.
class TestResourceProvider extends file_system.ResourceProvider {
  static final PhysicalResourceProvider physicalResourceProvider =
      PhysicalResourceProvider.INSTANCE;

  final MemoryResourceProvider memoryResourceProvider;

  TestResourceProvider(this.memoryResourceProvider);

  @override
  path.Context get pathContext => physicalResourceProvider.pathContext;

  @override
  file_system.File getFile(String path) {
    var file = memoryResourceProvider.getFile(path);
    return file.exists ? file : physicalResourceProvider.getFile(path);
  }

  @override
  file_system.Folder getFolder(String path) {
    var folder = memoryResourceProvider.getFolder(path);
    return folder.exists ? folder : physicalResourceProvider.getFolder(path);
  }

  @override
  file_system.Resource getResource(String path) {
    var resource = memoryResourceProvider.getResource(path);
    return resource.exists
        ? resource
        : physicalResourceProvider.getResource(path);
  }

  @override
  file_system.Folder? getStateLocation(String pluginId) =>
      physicalResourceProvider.getStateLocation(pluginId);
}
