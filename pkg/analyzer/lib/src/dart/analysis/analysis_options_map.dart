// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Instances of the class [AnalysisOptionsMap] map [File]s under analysis to their
/// corresponding [AnalysisOptions].
class AnalysisOptionsMap {
  // todo(pq): final backing representation TBD.
  final List<({Folder folder, AnalysisOptions options})> _entries = [];

  /// Map this [folder] to the given [options].
  void add(Folder folder, AnalysisOptions options) {
    _entries.add((folder: folder, options: options));
    // Sort entries by (reverse) containment (for now).
    _entries.sort((e1, e2) => e1.folder.contains(e2.folder.path) ? 1 : -1);
  }

  /// Get the [AnalysisOptions] instance for the given [file] (or `null` if none
  /// has been set).
  AnalysisOptions? getOptions(File file) {
    for (var entry in _entries) {
      if (entry.folder.contains(file.path)) return entry.options;
    }

    return null;
  }
}
