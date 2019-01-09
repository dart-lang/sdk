// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

import '../../../generated/analysis_context_factory.dart';
import 'resolution.dart';

/// Task model based implementation of [ResolutionTest].
class TaskResolutionTest with ResourceProviderMixin, ResolutionTest {
  DartSdk sdk;

  SourceFactory sourceFactory;
  InternalAnalysisContext analysisContext;

  @override
  Future<TestAnalysisResult> resolveFile(String path) async {
    var file = resourceProvider.getFile(path);
    var content = file.readAsStringSync();
    var source = file.createSource(Uri.parse('package:test/test.dart'));

    analysisContext.computeKindOf(source);
    List<Source> libraries = analysisContext.getLibrariesContaining(source);
    Source library = libraries.first;

    var unit = analysisContext.resolveCompilationUnit2(source, library);
    var errors = analysisContext.computeErrors(source);

    return new TestAnalysisResult(path, content, unit, errors);
  }

  void setUp() {
    sdk = new MockSdk(resourceProvider: resourceProvider);

    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'test': [getFolder('/test/lib')],
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
    };

    analysisContext = AnalysisContextFactory.contextWithCore(
      contributedResolver:
          new PackageMapUriResolver(resourceProvider, packageMap),
      resourceProvider: resourceProvider,
    );
  }
}
