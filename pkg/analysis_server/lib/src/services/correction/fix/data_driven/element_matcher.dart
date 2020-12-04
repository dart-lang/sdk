// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:meta/meta.dart';

/// An object that can be used to determine whether an element is appropriate
/// for a given reference.
class ElementMatcher {
  /// The URIs of the libraries that are imported in the library containing the
  /// reference.
  final List<Uri> importedUris;

  /// The name of the element being referenced.
  final String name;

  /// A list of the kinds of elements that are appropriate for some given
  /// location in the code An empty list represents all kinds rather than no
  /// kinds.
  List<ElementKind> validKinds;

  /// Initialize a newly created matcher representing a reference to an element
  /// with the given [name] in a library that imports the [importedUris].
  ElementMatcher(
      {@required this.importedUris,
      @required this.name,
      List<ElementKind> kinds})
      : validKinds = kinds ?? const [];

  /// Return `true` if this matcher matches the given [element].
  bool matches(ElementDescriptor element) {
    var components = element.components;
    var lastComponent = components.last;
    if (lastComponent.isEmpty) {
      if (components[components.length - 2] != name) {
        return false;
      }
    } else if (lastComponent != name) {
      return false;
    }

    if (validKinds.isNotEmpty && !validKinds.contains(element.kind)) {
      return false;
    }

    var libraryUris = element.libraryUris;
    for (var importedUri in importedUris) {
      if (libraryUris.contains(importedUri)) {
        return true;
      }
    }
    return false;
  }
}
