// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';

/// Inspects a delta [Component] and compares against the last known accepted
/// version.
class HotReloadDeltaInspector {
  /// A partial index for the last accepted generation [Component].
  ///
  /// In practice this is likely a partial index of the last known accepted
  /// generation that only contains the libraries present in the delta.
  late LibraryIndex _partialLastAcceptedLibraryIndex;

  /// Rejection errors discovered while comparing a delta with the previous
  /// generation.
  final _rejectionMessages = <String>[];

  /// Returns all hot reload rejection errors discovered while comparing [delta]
  /// against the [lastAccepted] version.
  // TODO(nshahan): Annotate delta component with information for DDC.
  List<String> compareGenerations(Component lastAccepted, Component delta) {
    _partialLastAcceptedLibraryIndex = LibraryIndex(lastAccepted,
        [for (var library in delta.libraries) '${library.fileUri}']);
    _rejectionMessages.clear();

    for (var library in delta.libraries) {
      for (var deltaClass in library.classes) {
        final acceptedClass = _partialLastAcceptedLibraryIndex.tryGetClass(
            '${library.importUri}', deltaClass.name);
        if (acceptedClass == null) {
          // No previous version of the class to compare with.
          continue;
        }
        _checkConstClassConsistency(acceptedClass, deltaClass);
      }
    }
    return _rejectionMessages;
  }

  /// Records a rejection error when [acceptedClass] is const but [deltaClass]
  /// is non-const.
  ///
  /// [acceptedClass] and [deltaClass] must represent the same class in the
  /// last known accepted and delta components respectively.
  void _checkConstClassConsistency(Class acceptedClass, Class deltaClass) {
    if (acceptedClass.hasConstConstructor && !deltaClass.hasConstConstructor) {
      _rejectionMessages.add('Const class cannot become non-const: '
          "Library:'${deltaClass.enclosingLibrary.importUri}' "
          'Class: ${deltaClass.name}');
    }
  }
}
