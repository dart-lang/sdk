// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';

/// Instances of the class [AnalysisOptionsMap] map [File]s under analysis to
/// their corresponding [AnalysisOptions].
class AnalysisOptionsMap {
  final List<OptionsMapEntry> entries = [];

  /// Create an empty [AnalysisOptionsMap] instance.
  AnalysisOptionsMap();

  /// Map this [folder] to the given [options].
  void add(Folder folder, AnalysisOptions options) {
    entries.add(OptionsMapEntry(folder, options));
    // Sort entries by (reverse) containment (for now).
    entries.sort((e1, e2) => e1.folder.contains(e2.folder.path) ? 1 : -1);
  }

  /// Get the [AnalysisOptions] instance for the given [file] (or `null` if none
  /// has been set).
  AnalysisOptions? getOptions(File file) {
    for (var entry in entries) {
      if (entry.folder.contains(file.path)) return entry.options;
    }

    return null;
  }

  /// Create an [AnalysisOptionsMap] that holds one set of [sharedOptions] for all
  /// associated files.
  // TODO(pq): replace w/ a factory constructor when SharedOptionsOptionsMap is made private
  static SharedOptionsOptionsMap forSharedOptions(
          AnalysisOptionsImpl sharedOptions) =>
      SharedOptionsOptionsMap(sharedOptions);
}

/// Instances of [OptionsMapEntry] associate [Folder]s with their
/// corresponding [AnalysisOptions].
class OptionsMapEntry {
  /// The folder containing an options file.
  final Folder folder;

  /// The corresponding options object.
  final AnalysisOptions options;

  /// Create a new entry for the give [folder] and corresponding [options];
  OptionsMapEntry(this.folder, this.options);
}

// TODO(pq): make private when no longer referenced.
class SharedOptionsOptionsMap extends AnalysisOptionsMap {
  /// The [entries] list is empty but that's OK. We'll always just return
  /// the shared options.
  final AnalysisOptionsImpl sharedOptions;
  SharedOptionsOptionsMap(this.sharedOptions);
  @override
  AnalysisOptions getOptions(File file) => sharedOptions;
}
