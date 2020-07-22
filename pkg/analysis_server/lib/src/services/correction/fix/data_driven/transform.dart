// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:meta/meta.dart';

/// The behavior common to all of the data used to construct fixes.
class Transform {
  /// The human-readable title describing the transform.
  final String title;

  /// The element being transformed.
  final ElementDescriptor element;

  /// A list containing the changes to be applied to affect the transform.
  final List<Change> changes;

  /// Initialize a newly created transform to describe a transformation of the
  /// [element].
  Transform(
      {@required this.title, @required this.element, @required this.changes});

  /// Return `true` if this transform can be applied to fix an issue related to
  /// an element with the given [name] in a library that imports the
  /// [importedUris].
  bool appliesTo(String name, List<String> importedUris) {
    return element.matches(name, importedUris);
  }
}
