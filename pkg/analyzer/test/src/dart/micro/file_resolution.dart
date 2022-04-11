// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:crypto/crypto.dart';
import 'package:linter/src/rules.dart';

import '../resolution/resolution.dart';

/// [FileResolver] based implementation of [ResolutionTest].
class FileResolutionTest with ResourceProviderMixin, ResolutionTest {
  static final String _testFile = '/workspace/dart/test/lib/test.dart';

  final CiderCachedByteStore byteStore =
      CiderCachedByteStore(20 * 1024 * 1024 /* 20 MB */);

  final StringBuffer logBuffer = StringBuffer();
  late PerformanceLog logger;

  late FileResolver fileResolver;

  Folder get sdkRoot => newFolder('/sdk');

  @override
  void addTestFile(String content) {
    newFile2(_testFile, content);
  }

  /// Create a new [FileResolver] into [fileResolver].
  ///
  /// We do this the first time, and to test reusing results from [byteStore].
  void createFileResolver() {
    var workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath(_testFile),
    )!;

    byteStore.testView = CiderByteStoreTestView();
    fileResolver = FileResolver.from(
      logger: logger,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      sourceFactory: workspace.createSourceFactory(
        FolderBasedDartSdk(resourceProvider, sdkRoot),
        null,
      ),
      getFileDigest: (String path) => _getDigest(path),
      workspace: workspace,
      prefetchFiles: null,
      isGenerated: null,
    );
    fileResolver.testView = FileResolverTestView();
  }

  Future<ErrorsResult> getTestErrors() async {
    var path = convertPath(_testFile);
    return fileResolver.getErrors2(path: path);
  }

  @override
  Future<ResolvedUnitResult> resolveFile(
    String path, {
    OperationPerformanceImpl? performance,
  }) async {
    result = await fileResolver.resolve2(
      path: path,
      performance: performance,
    );
    return result;
  }

  @override
  Future<void> resolveTestFile() async {
    var path = convertPath(_testFile);
    result = await resolveFile(path);
    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
  }

  void setUp() {
    registerLintRules();

    logger = PerformanceLog(logBuffer);
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    newFile2('/workspace/WORKSPACE', '');
    newFile2('/workspace/dart/test/BUILD', r'''
dart_package(
  null_safety = True,
)
''');
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
