// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/entities.dart' show ImportEntity;

/// A "hunk" of the program that will be loaded whenever one of its [imports]
/// are loaded.
///
/// Elements that are only used in one deferred import, is in an OutputUnit with
/// the deferred import as single element in the [imports] set.
///
/// Whenever a deferred Element is shared between several deferred imports it is
/// in an output unit with those imports in the [imports] Set.
///
/// We never create two OutputUnits sharing the same set of [imports].
class OutputUnit implements Comparable<OutputUnit> {
  /// `true` if this output unit is for the main output file.
  final bool isMainOutput;

  /// A unique name representing this [OutputUnit].
  final String name;

  /// The deferred imports that use the elements in this output unit.
  final Set<ImportEntity> imports;

  OutputUnit(this.isMainOutput, this.name, this.imports);

  @override
  int compareTo(OutputUnit other) {
    if (identical(this, other)) return 0;
    if (isMainOutput && !other.isMainOutput) return -1;
    if (!isMainOutput && other.isMainOutput) return 1;
    var size = imports.length;
    var otherSize = other.imports.length;
    if (size != otherSize) return size.compareTo(otherSize);
    var thisImports = imports.toList();
    var otherImports = other.imports.toList();
    for (var i = 0; i < size; i++) {
      var cmp = compareImportEntities(thisImports[i], otherImports[i]);
      if (cmp != 0) return cmp;
    }
    // TODO(sigmund): make compare stable.  If we hit this point, all imported
    // libraries are the same, however [this] and [other] use different deferred
    // imports in the program. We can make this stable if we sort based on the
    // deferred imports themselves (e.g. their declaration location).
    return name.compareTo(other.name);
  }

  @override
  String toString() => "OutputUnit($name, $imports)";
}

int compareImportEntities(ImportEntity a, ImportEntity b) {
  if (a == b) {
    return 0;
  } else {
    return a.uri.path.compareTo(b.uri.path);
  }
}
