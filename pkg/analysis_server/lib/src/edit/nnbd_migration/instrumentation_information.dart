// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';

/// The instrumentation information gathered from the migration engine.
class InstrumentationInformation {
  /// The node used for type sources that are always `null`.
  NullabilityNodeInfo always;

  /// A map from the graph edges between nullability nodes, to information about
  /// the edge that was created and why it was created.
  final Map<EdgeInfo, EdgeOriginInfo> edgeOrigin = {};

  /// The node used for type sources that are never `null`.
  NullabilityNodeInfo never;

  /// A map associating [NodeInformation] with [NullabilityNodeInfo] objects.
  Map<NullabilityNodeInfo, NodeInformation> nodeInformation = {};

  /// A list of the steps in the propagation of nullability information through
  /// the nullability graph, to report details of the step that was performed
  /// and why it was performed.
  final List<PropagationInfo> propagationSteps = [];

  /// The instrumentation information that is specific to a single source.
  final Map<Source, SourceInformation> sourceInformation = {};

  /// Initialize a newly created holder of instrumentation information.
  InstrumentationInformation();

  /// Return information about the given [node].
  NodeInformation nodeInfoFor(NullabilityNodeInfo node) {
    return nodeInformation[node];
  }

  /// Return the type annotation associated with the [node] or `null` if the
  /// node represents an implicit type.
  TypeAnnotation typeAnnotationForNode(NullabilityNodeInfo node) {
    for (MapEntry<Source, SourceInformation> sourceEntry
        in sourceInformation.entries) {
      for (MapEntry<TypeAnnotation, NullabilityNodeInfo> typeEntry
          in sourceEntry.value.explicitTypeNullability.entries) {
        if (typeEntry.value == node) {
          return typeEntry.key;
        }
      }
    }
    return null;
  }
}

/// The instrumentation information about a [NullabilityNodeInfo].
class NodeInformation {
  final String filePath;

  final AstNode astNode;

  final Element element;

  final String descriptionPrefix;

  NodeInformation(
      this.filePath, this.astNode, this.element, this.descriptionPrefix);

  /// Return detail text for a fix built from an edge with this node as a
  /// destination.
  String get descriptionForDestination {
    // TODO(paulberry): describe AST nodes
    var description = (element ?? '???').toString();
    return "A nullable value can't be used as $descriptionPrefix$description";
  }
}

/// The instrumentation information gathered from the migration engine that is
/// specific to a single source.
class SourceInformation {
  /// A map from the type annotations found in the source code, to the
  /// nullability nodes that are associated with that type.
  ///
  /// TODO(paulberry): we should probably get rid of this data structure.
  final Map<TypeAnnotation, NullabilityNodeInfo> explicitTypeNullability = {};

  /// A map from the fixes that were decided on to the reasons for the fix.
  final Map<SingleNullabilityFix, List<FixReasonInfo>> fixes = {};

  /// Initialize a newly created holder of instrumentation information that is
  /// specific to a single source.
  SourceInformation();
}
