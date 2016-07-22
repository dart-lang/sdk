// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.analyzer.repository;

import '../repository.dart';
import 'loader.dart';

@deprecated
class AnalyzerRepository extends Repository {
  AnalyzerLoader _analyzerLoader;

  /// Whether strong mode should be enabled for this repository.
  ///
  /// This is a flag on the repository itself because strong mode and non-strong
  /// mode code should not be mixed.
  final bool strongMode;

  AnalyzerRepository(
      {String sdk,
      String packageRoot,
      String workingDirectory,
      AnalyzerLoader analyzerLoader,
      this.strongMode: false})
      : _analyzerLoader = analyzerLoader,
        super(sdk: sdk, packageRoot: packageRoot,
            workingDirectory: workingDirectory);

  /// Gets the repository state that keeps track of how the analyzer's element
  /// model relates to the kernel IR.
  AnalyzerLoader getAnalyzerLoader() {
    return _analyzerLoader ??= new AnalyzerLoader(this, strongMode: strongMode);
  }
}
