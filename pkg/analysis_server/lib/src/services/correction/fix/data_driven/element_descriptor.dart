// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The path to an element.
class ElementDescriptor {
  /// The URIs of the library in which the element is defined.
  final List<String> libraryUris;

  /// The kind of element that was changed.
  final String kind;

  /// The components that uniquely identify the element within its library.
  final List<String> components;

  /// Initialize a newly created element descriptor to describe an element
  /// accessible via any of the [libraryUris] where the path to the element
  /// within the library is given by the list of [components]. The [kind] of the
  /// element is represented by the key used in the data file.
  ElementDescriptor(
      {@required this.libraryUris,
      @required this.kind,
      @required this.components});

  /// Return `true` if this descriptor matches an element with the given [name]
  /// in a library that imports the [importedUris].
  bool matches(String name, List<String> importedUris) {
    var lastComponent = components.last;
    if (lastComponent.isEmpty) {
      if (components[components.length - 2] != name) {
        return false;
      }
    } else if (lastComponent != name) {
      return false;
    }
    for (var importedUri in importedUris) {
      if (libraryUris.contains(importedUri)) {
        return true;
      }
    }
    return false;
  }
}
