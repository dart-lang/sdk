// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analyzer/dart/element/element2.dart';

/// This class tracks the set of names already added in the completion list in
/// order to prevent suggesting elements that have been shadowed by more local
/// declarations.
class VisibilityTracker {
  /// The set of known previously declared names.
  final Set<String> _declaredNames = {};

  /// Whether the name of the [element] is visible at the completion location.
  ///
  /// A name is not visible if it is shadowed by an element on the scope chain
  /// that has the same name.
  ///
  /// If the [importData] indicated that the element is already imported (either
  /// by being `null` or by returning `false` from `isNotImported`) and the name
  /// is visible, it will be added to the list of [_declaredNames] so that it
  /// will shadow any elements of the same name further up the scope chain.
  bool isVisible({
    required Element2? element,
    required ImportData? importData,
  }) {
    var name = element?.displayName;
    if (name == null) {
      return false;
    }

    var isNotImported = importData?.isNotImported ?? false;
    var prefix = importData?.prefix;
    var qualifiedName = prefix != null ? '$prefix.$name' : name;

    if (isNotImported) {
      return !_declaredNames.contains(qualifiedName);
    }
    return _declaredNames.add(qualifiedName);
  }
}
