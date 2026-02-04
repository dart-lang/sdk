// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/dart/analysis/analysis_options.dart';
library;

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';

/// Instances of the class [AnalysisOptionsMap] map [File]s under analysis to
/// their corresponding [AnalysisOptions].
class AnalysisOptionsMap {
  /// Default options, shared by files with no associated analysis options file
  /// folder entry.
  final AnalysisOptionsImpl _defaultOptions;

  final Map<Folder, AnalysisOptionsImpl> _map;

  /// Create an empty [AnalysisOptionsMap] instance.
  AnalysisOptionsMap()
    : _defaultOptions = AnalysisOptionsImpl(),
      // Sort entries by (reverse) containment (for now).
      _map = SplayTreeMap((a, b) => b.path.compareTo(a.path));

  /// Create an [AnalysisOptionsMap] that holds one set of [sharedOptions] for
  /// all associated files.
  AnalysisOptionsMap.forSharedOptions(AnalysisOptionsImpl sharedOptions)
    : _defaultOptions = sharedOptions,
      _map = SplayTreeMap.of({
        // If there's an associated file, create an entry so that we can display
        // it in the diagnostics page.
        ?sharedOptions.file?.parent: sharedOptions,
      }, (a, b) => b.path.compareTo(a.path));

  /// All [Folder]s in the options map.
  List<Folder> get folders => _map.keys.toList();

  /// All [AnalysisOptionsImpl]s in the options map, falling back to the
  /// [_defaultOptions] object if the options map is empty.
  List<AnalysisOptionsImpl> get options {
    var allOptions = _map.values.toList();
    return switch (allOptions) {
      ([]) => [_defaultOptions],
      _ => allOptions,
    };
  }

  /// Gets the [AnalysisOptions] instance for the given [file] (or a shared empty
  /// default options object if there is no entry for a containing folder).
  AnalysisOptionsImpl operator [](File file) {
    for (var MapEntry(key: folder, value: options) in _map.entries) {
      if (folder.contains(file.path)) return options;
    }

    return _defaultOptions;
  }

  /// Maps this [folder] to the given [options].
  void operator []=(Folder folder, AnalysisOptionsImpl options) {
    _map[folder] = options;
  }
}
