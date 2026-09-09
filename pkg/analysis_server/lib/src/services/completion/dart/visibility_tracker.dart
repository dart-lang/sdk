// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analyzer/dart/element/element.dart';

/// This class tracks the set of names already added in the completion list in
/// order to prevent suggesting elements that have been shadowed by more local
/// declarations.
class VisibilityTracker {
  /// The set of known previously declared names.
  final Set<String> _declaredNames = {};
  final _notImportedNames = HashMap<String, List<String>>();

  /// Whether the given [name] is visible at the completion location.
  ///
  /// This is the same as [isVisible], but for suggestions that aren't based on
  /// an element, such as the fields of a record type or the `call` method of a
  /// function type.
  bool isNameVisible({
    required String name,
    required ImportData? importData,
    String? shadowPrefix,
  }) {
    if (shadowPrefix != null) name = '$shadowPrefix.$name';

    var isNotImported = importData?.isNotImported ?? false;
    var prefix = importData?.prefix;
    var qualifiedName = prefix != null ? '$prefix.$name' : name;

    // Track names from non imported libraries so as to allow multiple
    // suggestions with same name from differnet libraries.
    if (isNotImported) {
      if (_declaredNames.contains(qualifiedName)) {
        return false;
      }
      var libraryUri = importData!.libraryUri.toString();
      var notImportedList = _notImportedNames.putIfAbsent(
        name,
        () => <String>[],
      );
      if (notImportedList.isEmpty || !notImportedList.contains(libraryUri)) {
        notImportedList.add(libraryUri);
        return true;
      }
      return false;
    }
    return _declaredNames.add(qualifiedName);
  }

  /// Whether the name of the [element] is visible at the completion location.
  ///
  /// A name is not visible if it is shadowed by an element on the scope chain
  /// that has the same name.
  ///
  /// If the [importData] indicated that the element is already imported (either
  /// by being `null` or by returning `false` from `isNotImported`), the name
  /// is visible.
  ///
  /// If it is already imported, it will be added to the list of
  /// [_declaredNames] so that it will shadow any elements of the same name
  /// further up the scope chain.
  ///
  /// If [shadowPrefix] is provided, the element is checked as if it were
  /// being suggested with that prefix (e.g. `this` or the name of the type
  /// that declares a static member), rather than with its bare name. This
  /// allows a member that is shadowed by its bare name to still be suggested
  /// in a qualified form.
  bool isVisible({
    required Element? element,
    required ImportData? importData,
    String? shadowPrefix,
  }) {
    var name = element?.displayName;
    if (name == null) {
      return false;
    }
    return isNameVisible(
      name: name,
      importData: importData,
      shadowPrefix: shadowPrefix,
    );
  }
}
