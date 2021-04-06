// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override.dart';

/// A description of a set of transform overrides.
class TransformOverrideSet {
  /// A map from transform titles to the override for that transform.
  final Map<String, TransformOverride> overrideMap = {};

  /// Initialize a newly created transform override set to include all of the
  /// [overrides].
  TransformOverrideSet(List<TransformOverride> overrides) {
    for (var override in overrides) {
      overrideMap[override.title] = override;
    }
  }

  /// Return the overrides in this set.
  List<TransformOverride> get overrides => overrideMap.values.toList();

  /// Return the override for the transform with the given [title] or `null` if
  /// there is no such override in this set.
  TransformOverride? overrideForTransform(String title) => overrideMap[title];
}
