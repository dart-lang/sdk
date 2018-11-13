// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptions;

/**
 * An analysis context whose implementation is based on an analysis driver.
 */
class DriverBasedAnalysisContext implements AnalysisContext {
  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  @override
  final ContextRoot contextRoot;

  /**
   * The driver on which this context is based.
   */
  final AnalysisDriver driver;

  /**
   * Initialize a newly created context that uses the given [resourceProvider]
   * to access the file system and that is based on the given analysis [driver].
   */
  DriverBasedAnalysisContext(
      this.resourceProvider, this.contextRoot, this.driver);

  @override
  AnalysisOptions get analysisOptions => driver.analysisOptions;

  @override
  AnalysisSession get currentSession => driver.currentSession;

  @deprecated
  @override
  List<String> get excludedPaths => contextRoot.excludedPaths.toList();

  @deprecated
  @override
  List<String> get includedPaths => contextRoot.includedPaths.toList();

  @deprecated
  @override
  Iterable<String> analyzedFiles() {
    return contextRoot.analyzedFiles();
  }

  @deprecated
  @override
  bool isAnalyzed(String path) {
    return contextRoot.isAnalyzed(path);
  }
}
