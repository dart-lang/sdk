// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_node;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'phase.dart';
import 'transform.dart';
import 'transformer.dart';

/// Describes a transform on a set of assets and its relationship to the build
/// dependency graph.
///
/// Keeps track of whether it's dirty and needs to be run and which assets it
/// depends on.
class TransformNode {
  /// The [Phase] that this transform runs in.
  final Phase phase;

  /// The [Transformer] to apply to this node's inputs.
  final Transformer _transformer;

  /// The node for the primary asset this transform depends on.
  final AssetNode primary;

  /// True if an input has been modified since the last time this transform
  /// was run.
  bool get isDirty => _isDirty;
  var _isDirty = true;

  /// The inputs read by this transform the last time it was run.
  ///
  /// Used to tell if an input was removed in a later run.
  var _inputs = new Set<AssetNode>();

  /// The outputs created by this transform the last time it was run.
  ///
  /// Used to tell if an output was removed in a later run.
  var _outputs = new Set<AssetId>();

  TransformNode(this.phase, this._transformer, this.primary);

  /// Marks this transform as needing to be run.
  void dirty() {
    _isDirty = true;
  }

  /// Applies this transform.
  ///
  /// Returns a [TransformOutputs] describing the resulting outputs compared to
  /// previous runs.
  Future<TransformOutputs> apply() {
    var newInputs = new Set<AssetNode>();
    var newOutputs = new AssetSet();
    var transform = createTransform(this, newInputs, newOutputs);
    return _transformer.apply(transform).catchError((error) {
      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(error);

      // Don't allow partial results from a failed transform.
      newOutputs.clear();
    }).then((_) {
      _isDirty = false;

      // Stop watching any inputs that were removed.
      for (var oldInput in _inputs) {
        oldInput.consumers.remove(this);
      }

      // Watch any new inputs so this transform will be re-processed when an
      // input is modified.
      for (var newInput in newInputs) {
        newInput.consumers.add(this);
      }

      _inputs = newInputs;

      // See which outputs are missing from the last run.
      var outputIds = newOutputs.map((asset) => asset.id).toSet();
      var invalidIds = outputIds
          .where((id) => id.package != phase.cascade.package).toSet();
      outputIds.removeAll(invalidIds);

      for (var id in invalidIds) {
        // TODO(nweiz): report this as a warning rather than a failing error.
        phase.cascade.reportError(
            new InvalidOutputException(phase.cascade.package, id));
      }

      var removed = _outputs.difference(outputIds);
      _outputs = outputIds;

      return new TransformOutputs(newOutputs, removed);
    });
  }
}

/// The result of running a [Transform], compared to the previous time it was
/// applied.
class TransformOutputs {
  /// The outputs that are new or were modified since the last run.
  final AssetSet updated;

  /// The outputs that were created by the previous run but were not generated
  /// by the most recent run.
  final Set<AssetId> removed;

  TransformOutputs(this.updated, this.removed);
}
