// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A description of a set of changes to a single transform.
class TransformOverride {
  /// The title of the transform being overridden.
  final String title;

  /// The overridden value of the `bulkApply` property of the transform, or
  /// `null` if the property should not be overridden.
  final bool? bulkApply;

  /// Initialize a newly created transform override to override the transform
  /// with the given [title]. The remaining parameters correspond to properties
  /// of the transform. They should have non-null values when the property is to
  /// be overridden, and a value of `null` when the property should be
  /// unchanged.
  TransformOverride({required this.title, this.bulkApply});
}
