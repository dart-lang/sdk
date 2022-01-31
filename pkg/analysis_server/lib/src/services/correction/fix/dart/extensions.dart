// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';

class Extensions {
  final ResolvedUnitResult resolvedUnit;

  Extensions(this.resolvedUnit);

  DriverBasedAnalysisContext get _analysisContext {
    var analysisContext = resolvedUnit.session.analysisContext;
    return analysisContext as DriverBasedAnalysisContext;
  }

  /// Return libraries that may be imported into the [resolvedUnit] file,
  /// and might have extensions that define a non-static public member with
  /// the [memberName].
  Stream<LibraryElement> libraries(String memberName) async* {
    var analysisDriver = _analysisContext.driver;
    await analysisDriver.discoverAvailableFiles();

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(resolvedUnit.path),
    );

    for (var file in fsState.knownFiles.toList()) {
      if (!filter.shouldInclude(file)) {
        continue;
      }

      var libraryElement = analysisDriver.getLibraryByFile(file);
      if (libraryElement == null) {
        continue;
      }

      yield libraryElement;
    }
  }
}
