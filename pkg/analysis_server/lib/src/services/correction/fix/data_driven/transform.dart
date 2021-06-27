// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/changes_selector.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_matcher.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override.dart';

/// A description of a set of changes to a single element of the API.
class Transform {
  /// The human-readable title describing the transform.
  final String title;

  /// The date on which the API was changed.
  final DateTime date;

  /// A flag indicating whether this transform can be used when applying bulk
  /// fixes.
  final bool bulkApply;

  /// The element being transformed.
  final ElementDescriptor element;

  /// A list containing the changes to be applied to affect the transform.
  final ChangesSelector changesSelector;

  /// Initialize a newly created transform to describe a transformation of the
  /// [element].
  Transform(
      {required this.title,
      required this.date,
      required this.bulkApply,
      required this.element,
      required this.changesSelector});

  /// Return `true` if this transform can be applied to fix an issue related to
  /// an element that matches the given [matcher]. The flag [applyingBulkFixes]
  /// indicates whether the transforms are being applied in the context of a
  /// bulk fix.
  bool appliesTo(ElementMatcher matcher, {required bool applyingBulkFixes}) {
    if (applyingBulkFixes && !bulkApply) {
      return false;
    }
    return matcher.matches(element);
  }

  /// Return a new transform with the [override] applied, or this transform if
  /// there are no overrides.
  Transform applyOverride(TransformOverride override) {
    var overriddenBulkApply = override.bulkApply;
    if (overriddenBulkApply != null && overriddenBulkApply != bulkApply) {
      return Transform(
          title: title,
          date: date,
          bulkApply: overriddenBulkApply,
          element: element,
          changesSelector: changesSelector);
    }
    return this;
  }
}
