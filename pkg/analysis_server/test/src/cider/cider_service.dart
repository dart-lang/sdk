// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:crypto/crypto.dart';
import 'package:linter/src/rules.dart';

class CiderServiceTest with ResourceProviderMixin {
  final StringBuffer logBuffer = StringBuffer();
  late PerformanceLog logger;

  late FileResolver fileResolver;

  String testPath = '/workspace/dart/test/lib/test.dart';

  /// Create a new [FileResolver] into [fileResolver].
  void createFileResolver() {
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    var sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);

    var workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath(testPath),
    )!;

    fileResolver = FileResolver(
      logger,
      resourceProvider,
      workspace.createSourceFactory(sdk, null),
      (String path) => _getDigest(path),
      null,
      workspace: workspace,
    );
    fileResolver.testView = FileResolverTestView();
  }

  void setUp() {
    registerLintRules();

    logger = PerformanceLog(logBuffer);

    newFile('/workspace/WORKSPACE');
    newFile('/workspace/dart/test/BUILD');
    createFileResolver();
  }

  String _getDigest(String path) {
    try {
      var content = resourceProvider.getFile(path).readAsStringSync();
      var contentBytes = utf8.encode(content);
      return md5.convert(contentBytes).toString();
    } catch (_) {
      return '';
    }
  }
}
