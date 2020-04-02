// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/edit_plan.dart';

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
    for (var sourceEntry in sourceInformation.entries) {
      for (var typeEntry in sourceEntry.value.explicitTypeNullability.entries) {
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

  NodeInformation(this.filePath, this.astNode, this.element);

  /// Return detail text for a fix built from an edge with this node as a
  /// destination.
  String get descriptionForDestination {
    // TODO(paulberry): describe AST nodes.
    return "A nullable value can't be used here";
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

  /// A map from offsets within the source file to a list of changes to be
  /// applied at that offset.
  Map<int, List<AtomicEdit>> changes;

  /// Initialize a newly created holder of instrumentation information that is
  /// specific to a single source.
  SourceInformation();
}
