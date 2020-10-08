// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The path to an element.
class ElementDescriptor {
  /// The URIs of the library in which the element is defined.
  final List<Uri> libraryUris;

  /// The kind of element that was changed.
  final String _kind;

  /// The components that uniquely identify the element within its library.
  final List<String> components;

  /// Initialize a newly created element descriptor to describe an element
  /// accessible via any of the [libraryUris] where the path to the element
  /// within the library is given by the list of [components]. The [kind] of the
  /// element is represented by the key used in the data file.
  ElementDescriptor(
      {@required this.libraryUris,
      @required String kind,
      @required this.components})
      : _kind = kind;

  /// Return `true` if the described element is a constructor.
  bool get isConstructor => _kind == 'constructor';
}
