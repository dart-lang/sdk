// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';

/// Instances of the class [AnalysisOptionsMap] map [File]s under analysis to
/// their corresponding [AnalysisOptions].
class AnalysisOptionsMap {
  /// Default options, shared by files with no associated analysis options file
  /// folder entry.
  static final AnalysisOptionsImpl _defaultOptions = AnalysisOptionsImpl();

  final List<OptionsMapEntry> entries = [];

  /// Create an empty [AnalysisOptionsMap] instance.
  AnalysisOptionsMap();

  /// Map this [folder] to the given [options].
  void add(Folder folder, AnalysisOptionsImpl options) {
    entries.add(OptionsMapEntry(folder, options));
    // Sort entries by (reverse) containment (for now).
    entries.sort((e1, e2) => e1.folder.contains(e2.folder.path) ? 1 : -1);
  }

  /// Get the [AnalysisOptions] instance for the given [file] (or a shared empty
  /// default options object if there is no entry in [entries] for a containing folder).
  AnalysisOptionsImpl getOptions(File file) {
    for (var entry in entries) {
      if (entry.folder.contains(file.path)) return entry.options;
    }

    return _defaultOptions;
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
  final AnalysisOptionsImpl options;

  /// Create a new entry for the give [folder] and corresponding [options];
  OptionsMapEntry(this.folder, this.options);
}

// TODO(pq): make private when no longer referenced.
class SharedOptionsOptionsMap extends AnalysisOptionsMap {
  final AnalysisOptionsImpl sharedOptions;
  SharedOptionsOptionsMap(this.sharedOptions) {
    var optionsFile = sharedOptions.file;
    // If there's an associated file, create an entry so that we can display it
    // in the diagnostics page.
    if (optionsFile != null) {
      add(optionsFile.parent, sharedOptions);
    }
  }
  @override
  AnalysisOptionsImpl getOptions(File file) =>
      // No need to lookup. There's only one shared set of options.
      sharedOptions;
}
