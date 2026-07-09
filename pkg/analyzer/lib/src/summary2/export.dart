// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class Export {
  final LibraryBuilder exporter;
  final ExportLocation location;
  final List<Combinator> combinators;

  Export({
    required this.exporter,
    required this.location,
    required this.combinators,
  });

  bool addToExportScope(ExportEntry entry) {
    if (combinators.allows(entry.name)) {
      return exporter.exportScope.export(location, entry);
    }
    return false;
  }
}

final class ExportEntry {
  final String name;
  final ExportableReference reference;
  final List<ExportLocation> locations;

  ExportEntry({
    required this.name,
    required this.reference,
    required this.locations,
  });

  bool get isDeclared => locations.isEmpty;

  bool get isReExported => locations.isNotEmpty;

  void addLocation(ExportLocation location) {
    // This list is very small, contains on it is probably ok.
    if (!locations.contains(location)) {
      locations.add(location);
    }
  }

  /// We are done updating this object, returns the immutable version.
  ExportEntry toFinalized() {
    if (isDeclared) {
      return this;
    }
    return ExportEntry(
      name: name,
      reference: reference,
      locations: locations.toFixedList(),
    );
  }

  @override
  String toString() {
    return '$reference';
  }
}

class ExportLocation {
  /// The index of the fragment with the `export` directive, `0` means the
  /// library file, a positive value means an included fragment.
  final int fragmentIndex;

  /// The index in [LibraryFragmentImpl.libraryExports].
  final int exportIndex;

  ExportLocation({required this.fragmentIndex, required this.exportIndex});

  @override
  bool operator ==(Object other) {
    return other is ExportLocation &&
        other.fragmentIndex == fragmentIndex &&
        other.exportIndex == exportIndex;
  }

  @override
  String toString() {
    return '($fragmentIndex, $exportIndex)';
  }
}

class ExportScope {
  final Map<String, ExportEntry> entriesByName = {};

  void declare(String name, ExportableReference reference) {
    entriesByName[name] = ExportEntry(
      name: name,
      reference: reference,
      locations: const [],
    );
  }

  bool export(ExportLocation location, ExportEntry entry) {
    var name = entry.name;
    var existing = entriesByName[name];
    if (existing?.reference == entry.reference) {
      if (existing != null && existing.isReExported) {
        existing.addLocation(location);
      }
      return false;
    }

    // Ambiguous declaration detected.
    if (existing != null) return false;

    entriesByName[name] = ExportEntry(
      name: name,
      reference: entry.reference,
      locations: [location],
    );
    return true;
  }

  void forEach(void Function(ExportEntry entry) f) {
    entriesByName.forEach((_, entry) {
      f(entry);
    });
  }

  List<ExportEntry> toExportEntries() {
    return entriesByName.values.map((entry) {
      return entry.toFinalized();
    }).toFixedList();
  }
}
