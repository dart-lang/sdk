// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Everything the front end needs to know to tell the server to perform a hint
/// action.
class HintAction {
  final HintActionKind kind;
  final int? nodeId;
  HintAction(this.kind, this.nodeId);

  HintAction.fromJson(Map<String, Object?> json)
      : nodeId = json['nodeId'] as int?,
        kind = HintActionKind.values
            .singleWhere((action) => action.index == json['kind']);

  Map<String, Object?> toJson() => {
        'nodeId': nodeId,
        'kind': kind.index,
      };
}

/// Enum describing the possible hints that can be performed on an edge or a
/// node.
///
/// Which actions are available can be built by other visitors, and the hint can
/// be applied by visitors such as EditPlanner when the user requests it from
/// the front end.
enum HintActionKind {
  /// Add a `/*?*/` hint to a type.
  addNullableHint,

  /// Add a `/*!*/` hint to a type.
  addNonNullableHint,

  /// Change a `/*!*/` hint to a `/*?*/` hint.
  changeToNullableHint,

  /// Change a `/*?*/` hint to a `/*!*/` hint.
  changeToNonNullableHint,

  /// Remove a `/*?*/` hint.
  removeNullableHint,

  /// Remove a `/*!*/` hint.
  removeNonNullableHint,
}

/// Extension methods to make [HintActionKind] act as a smart enum.
extension HintActionKindBehaviors on HintActionKind {
  /// Get the text description of a [HintActionKind], for display to users.
  String? get description {
    switch (this) {
      case HintActionKind.addNullableHint:
        return 'Add /*?*/ hint';
      case HintActionKind.addNonNullableHint:
        return 'Add /*!*/ hint';
      case HintActionKind.removeNullableHint:
        return 'Remove /*?*/ hint';
      case HintActionKind.removeNonNullableHint:
        return 'Remove /*!*/ hint';
      case HintActionKind.changeToNullableHint:
        return 'Change to /*?*/ hint';
      case HintActionKind.changeToNonNullableHint:
        return 'Change to /*!*/ hint';
    }
  }
}
