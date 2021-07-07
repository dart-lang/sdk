// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';

class MockAnalysisContext implements AnalysisContext {
  @override
  ContextRoot contextRoot;

  MockAnalysisContext(ResourceProvider resourceProvider)
      : contextRoot = MockContextRoot(resourceProvider);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAnalysisSession implements AnalysisSession {
  @override
  ResourceProvider resourceProvider;

  @override
  AnalysisContext analysisContext;

  MockAnalysisSession(this.resourceProvider)
      : analysisContext = MockAnalysisContext(resourceProvider);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockContextRoot implements ContextRoot {
  @override
  ResourceProvider resourceProvider;

  MockContextRoot(this.resourceProvider);

  @override
  bool isAnalyzed(String filePath) => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockEditBuilderImpl implements EditBuilderImpl {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
