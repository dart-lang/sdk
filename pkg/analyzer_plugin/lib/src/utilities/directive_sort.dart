// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares to URI strings for a directive to produce the desired sort order.
///
/// Should keep these in sync! Copied from
/// https://github.com/dart-lang/linter/blob/658f497eef/lib/src/rules/directives_ordering.dart#L380-L387
/// Consider finding a way to share this code!
int compareDirectiveUri(String a, String b) {
  if (!a.startsWith('package:') || !b.startsWith('package:')) {
    if (!a.startsWith('/') && !b.startsWith('/')) {
      return a.compareTo(b);
    }
  }
  var indexA = a.indexOf('/');
  var indexB = b.indexOf('/');
  if (indexA == -1 || indexB == -1) return a.compareTo(b);
  var result = a.substring(0, indexA).compareTo(b.substring(0, indexB));
  if (result != 0) return result;
  return a.substring(indexA + 1).compareTo(b.substring(indexB + 1));
}

/// The kind of directive for sorting purposes.
enum DirectiveSortKind { import, export, part }

/// The priority used for grouping directives when sorting.
class DirectiveSortPriority {
  static const IMPORT_SDK = DirectiveSortPriority._('IMPORT_SDK', 0);
  static const IMPORT_PKG = DirectiveSortPriority._('IMPORT_PKG', 1);
  static const IMPORT_OTHER = DirectiveSortPriority._('IMPORT_OTHER', 2);
  static const IMPORT_REL = DirectiveSortPriority._('IMPORT_REL', 3);
  static const EXPORT_SDK = DirectiveSortPriority._('EXPORT_SDK', 4);
  static const EXPORT_PKG = DirectiveSortPriority._('EXPORT_PKG', 5);
  static const EXPORT_OTHER = DirectiveSortPriority._('EXPORT_OTHER', 6);
  static const EXPORT_REL = DirectiveSortPriority._('EXPORT_REL', 7);
  static const PART = DirectiveSortPriority._('PART', 8);

  final String name;
  final int ordinal;

  factory DirectiveSortPriority(String uri, DirectiveSortKind kind) {
    switch (kind) {
      case DirectiveSortKind.import:
        if (uri.startsWith('dart:')) {
          return DirectiveSortPriority.IMPORT_SDK;
        } else if (uri.startsWith('package:')) {
          return DirectiveSortPriority.IMPORT_PKG;
        } else if (uri.contains('://')) {
          return DirectiveSortPriority.IMPORT_OTHER;
        } else {
          return DirectiveSortPriority.IMPORT_REL;
        }
      case DirectiveSortKind.export:
        if (uri.startsWith('dart:')) {
          return DirectiveSortPriority.EXPORT_SDK;
        } else if (uri.startsWith('package:')) {
          return DirectiveSortPriority.EXPORT_PKG;
        } else if (uri.contains('://')) {
          return DirectiveSortPriority.EXPORT_OTHER;
        } else {
          return DirectiveSortPriority.EXPORT_REL;
        }
      case DirectiveSortKind.part:
        return DirectiveSortPriority.PART;
    }
  }

  const DirectiveSortPriority._(this.name, this.ordinal);

  @override
  String toString() => name;
}
