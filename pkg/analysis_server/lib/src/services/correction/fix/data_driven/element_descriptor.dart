// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:meta/meta.dart';

/// The path to an element.
class ElementDescriptor {
  /// The URIs of the library in which the element is defined.
  final List<Uri> libraryUris;

  /// The kind of element that was changed.
  final ElementKind kind;

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

  /// Return `true` if the described element is a constructor.
  bool get isConstructor => kind == ElementKind.constructorKind;
}
