// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:crypto/crypto.dart';
import 'package:linter/src/rules.dart';

class CiderServiceTest with ResourceProviderMixin {
  final FileResolverTestData testData = FileResolverTestData();

  final StringBuffer logBuffer = StringBuffer();
  late PerformanceLog logger;

  late FileResolver fileResolver;

  String testPath = '/workspace/dart/test/lib/test.dart';

  /// Create a new [FileResolver] into [fileResolver].
  void createFileResolver() {
    var sdkRoot = newFolder('/sdk');
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);
    var sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);

    var workspace =
        BlazeWorkspace.find(resourceProvider, convertPath(testPath))!;

    fileResolver = FileResolver(
      logger: logger,
      resourceProvider: resourceProvider,
      sourceFactory: workspace.createSourceFactory(sdk, null),
      getFileDigest: (String path) => _getDigest(path),
      prefetchFiles: null,
      workspace: workspace,
      byteStore: MemoryByteStore(),
      isGenerated: (_) => false,
      testData: testData,
    );
  }

  void setUp() {
    registerLintRules();
    registerBuiltInProducers();

    logger = PerformanceLog(logBuffer);

    newFile('/workspace/${file_paths.blazeWorkspaceMarker}', '');
    newFile('/workspace/dart/test/BUILD', '');
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
