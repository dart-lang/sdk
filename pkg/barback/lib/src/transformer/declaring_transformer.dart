// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.declaring_transformer;

import 'dart:async';

import 'declaring_transform.dart';

/// An interface for [Transformer]s that can cheaply figure out which assets
/// they'll emit without doing the work of actually creating those assets.
///
/// If a transformer implements this interface, that allows barback to perform
/// optimizations to make the asset graph work more smoothly.
abstract class DeclaringTransformer {
  /// Declare which assets would be emitted for the primary input id specified
  /// by [transform].
  ///
  /// This works a little like [Transformer.apply], with two main differences.
  /// First, instead of having access to the primary input's contents, it only
  /// has access to its id. Second, instead of emitting [Asset]s, it just emits
  /// [AssetId]s through [transform.addOutputId].
  ///
  /// If this does asynchronous work, it should return a [Future] that completes
  /// once it's finished.
  declareOutputs(DeclaringTransform transform);
}
