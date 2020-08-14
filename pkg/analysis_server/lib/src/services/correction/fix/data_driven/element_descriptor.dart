// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The path to an element.
class ElementDescriptor {
  /// The URIs of the library in which the element is defined.
  final List<String> libraryUris;

  /// The components that uniquely identify the element within its library.
  final List<String> components;

  /// Initialize a newly created element descriptor to describe an element
  /// accessible via any of the [libraryUris] where the path to the element
  /// within the library is given by the list of [components].
  ElementDescriptor({@required this.libraryUris, @required this.components});

  /// Return `true` if this descriptor matches an element with the given [name]
  /// in a library that imports the [importedUris].
  bool matches(String name, List<String> importedUris) {
    if (components.last != name) {
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
