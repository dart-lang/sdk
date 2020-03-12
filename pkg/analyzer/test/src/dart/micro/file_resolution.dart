// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:crypto/crypto.dart';

import '../resolution/resolution.dart';

/// [FileResolver] based implementation of [ResolutionTest].
class FileResolutionTest with ResourceProviderMixin, ResolutionTest {
  final ByteStore byteStore = MemoryByteStore();

  final StringBuffer logBuffer = StringBuffer();
  PerformanceLog logger;

  DartSdk sdk;
  Map<String, List<Folder>> packageMap;
  FileResolver fileResolver;

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  /// Override this to change the analysis options for a given set of tests.
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl();

  @override
  Future<ResolvedUnitResult> resolveFile(String path) async {
    return fileResolver.resolve(path);
  }

  String _getDigest(String path) {
    var content;
    try {
      content = resourceProvider.getFile(path).readAsStringSync();
    } catch (_) {
      return '';
    }
    var contentBytes = utf8.encode(content);
    return md5.convert(contentBytes).toString();
  }

  void setUp() {
    sdk = MockSdk(
      resourceProvider: resourceProvider,
      additionalLibraries: additionalMockSdkLibraries,
    );
    logger = PerformanceLog(logBuffer);

    // TODO(brianwilkerson) Create an empty package map by default and only add
    //  packages in the tests that need them.
    packageMap = <String, List<Folder>>{
      'test': [getFolder('/test/lib')],
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
      'meta': [getFolder('/.pub-cache/meta/lib')],
    };

    fileResolver = FileResolver(
        logger,
        resourceProvider,
        byteStore,
        SourceFactory([
          DartUriResolver(sdk),
          PackageMapUriResolver(resourceProvider, packageMap),
          ResourceUriResolver(resourceProvider)
        ]),
        (String path) => _getDigest(path),
        null);
  }
}
