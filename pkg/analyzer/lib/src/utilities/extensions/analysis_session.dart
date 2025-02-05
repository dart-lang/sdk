// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';

extension AnalysisSessionExtension on AnalysisSession {
  /// Return the resolved library for the library containing the file with the
  /// given [path].
  Future<ResolvedLibraryResult?> getResolvedContainingLibrary(
    String path,
  ) async {
    var unitElement = await getUnitElement(path);
    if (unitElement is! UnitElementResult) {
      return null;
    }
    var libraryPath =
        unitElement.fragment.element.firstFragment.source.fullName;
    var result = await getResolvedLibrary(libraryPath);
    return result is ResolvedLibraryResult ? result : null;
  }
}
