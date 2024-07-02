// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

/// Instances of the class [AnalysisOptionsMap] map [File]s under analysis to
/// their corresponding [AnalysisOptions].
class AnalysisOptionsMap {
  /// Default options, shared by files with no associated analysis options file
  /// folder entry.
  final AnalysisOptionsImpl _defaultOptions = AnalysisOptionsImpl();

  final List<OptionsMapEntry> entries = [];

  /// Create an empty [AnalysisOptionsMap] instance.
  AnalysisOptionsMap();

  /// Create an [AnalysisOptionsMap] that holds one set of [sharedOptions] for
  /// all associated files.
  factory AnalysisOptionsMap.forSharedOptions(
          AnalysisOptionsImpl sharedOptions) =>
      _SharedOptionsOptionsMap(sharedOptions);

  /// Get the first options entry or the default options object if there is none.
  AnalysisOptionsImpl get firstOrDefault =>
      entries.firstOrNull?.options ?? _defaultOptions;

  /// Get all the mapped options, falling back to the [_defaultOptions] object
  /// if the [entries] list is empty.
  Iterable<AnalysisOptionsImpl> get _allOptions {
    var allOptions = entries.map((e) => e.options).toList();
    if (allOptions.isEmpty) {
      allOptions.add(_defaultOptions);
    }
    return allOptions;
  }

  /// Map this [folder] to the given [options].
  void add(Folder folder, AnalysisOptionsImpl options) {
    entries.add(OptionsMapEntry(folder, options));
    // Sort entries by (reverse) containment (for now).
    entries.sort((e1, e2) => e2.folder.path.compareTo(e1.folder.path));
  }

  /// Perform the given [action] on all the mapped options.
  /// If the options [entries] map is empty, perform the action on this map's
  /// default options object.
  void forEachOptionsObject(void Function(AnalysisOptionsImpl element) action) {
    _allOptions.forEach(action);
  }

  /// Get the [AnalysisOptions] instance for the given [file] (or a shared empty
  /// default options object if there is no entry in [entries] for a containing
  /// folder).
  AnalysisOptionsImpl getOptions(File file) {
    for (var entry in entries) {
      if (entry.folder.contains(file.path)) return entry.options;
    }

    return _defaultOptions;
  }
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

/// An option map that contains only one shared set of options.
class _SharedOptionsOptionsMap extends AnalysisOptionsMap {
  final AnalysisOptionsImpl sharedOptions;
  _SharedOptionsOptionsMap(this.sharedOptions) {
    var optionsFile = sharedOptions.file;
    // If there's an associated file, create an entry so that we can display it
    // in the diagnostics page.
    if (optionsFile != null) {
      add(optionsFile.parent, sharedOptions);
    }
  }

  @override
  Iterable<AnalysisOptionsImpl> get _allOptions => [sharedOptions];

  @override
  AnalysisOptionsImpl getOptions(File file) =>
      // No need to lookup. There's only one shared set of options.
      sharedOptions;
}
