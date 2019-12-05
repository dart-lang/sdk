// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:linter/src/analyzer.dart';

/// Builds the [DartLinter] with appropriate mock SDK, resource providers, and
/// package config path.
DartLinter buildDriver(LintRule rule, File file, {String analysisOptions}) {
  final memoryResourceProvider = MemoryResourceProvider(
      context: PhysicalResourceProvider.INSTANCE.pathContext);
  final resourceProvider = TestResourceProvider(memoryResourceProvider);

  final pathContext = memoryResourceProvider.pathContext;
  var packageConfigPath = memoryResourceProvider.convertPath(pathContext.join(
      pathContext.dirname(file.absolute.path), '.mock_packages'));
  if (!resourceProvider.getFile(packageConfigPath).exists) {
    packageConfigPath = null;
  }

  final options = LinterOptions([rule], analysisOptions)
    ..mockSdk = MockSdk(resourceProvider: memoryResourceProvider)
    ..resourceProvider = resourceProvider
    ..packageConfigPath = packageConfigPath;

  return DartLinter(options);
}

/// A resource provider that accesses entities in a MemoryResourceProvider,
/// falling back to the PhysicalResourceProvider when they don't exist.
class TestResourceProvider extends PhysicalResourceProvider {
  MemoryResourceProvider memoryResourceProvider;

  TestResourceProvider(this.memoryResourceProvider) : super(null);

  @override
  file_system.File getFile(String path) {
    final file = memoryResourceProvider.getFile(path);
    return file.exists ? file : super.getFile(path);
  }

  @override
  file_system.Folder getFolder(String path) {
    final folder = memoryResourceProvider.getFolder(path);
    return folder.exists ? folder : super.getFolder(path);
  }

  @override
  file_system.Resource getResource(String path) {
    final resource = memoryResourceProvider.getResource(path);
    return resource.exists ? resource : super.getResource(path);
  }
}
