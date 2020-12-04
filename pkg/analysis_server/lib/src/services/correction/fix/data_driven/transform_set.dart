// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_matcher.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:meta/meta.dart';

/// A set of transforms used to aid in the construction of fixes for issues
/// related to some body of code. Typically there is one set of transforms for
/// each version of each package used by the code being analyzed.
class TransformSet {
  /// The transforms in this set.
  final List<Transform> _transforms = [];

  /// Add the given [transform] to this set.
  void addTransform(Transform transform) {
    _transforms.add(transform);
  }

  /// Return a list of the transforms that match the [matcher]. The flag
  /// [applyingBulkFixes] indicates whether the transforms are being applied in
  /// the context of a bulk fix.
  List<Transform> transformsFor(ElementMatcher matcher,
      {@required bool applyingBulkFixes}) {
    var result = <Transform>[];
    for (var transform in _transforms) {
      if (transform.appliesTo(matcher, applyingBulkFixes: applyingBulkFixes)) {
        result.add(transform);
      }
    }
    return result;
  }
}
