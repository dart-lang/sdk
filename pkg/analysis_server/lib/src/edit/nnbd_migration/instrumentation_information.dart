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

  /// A map from elements outside of the code being migrated, to the nullability
  /// nodes associated with the type of the element.
  final Map<Element, DecoratedTypeInfo> externalDecoratedType = {};

  /// A map from the graph edges between nullability nodes, to information about
  /// the edge that was created and why it was created.
  final Map<EdgeInfo, EdgeOriginInfo> edgeOrigin = {};

  /// The node used for type sources that are never `null`.
  NullabilityNodeInfo never;

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
    for (MapEntry<Source, SourceInformation> sourceEntry
        in sourceInformation.entries) {
      SourceInformation sourceInfo = sourceEntry.value;
      for (MapEntry<AstNode, DecoratedTypeInfo> entry
          in sourceInfo.implicitReturnType.entries) {
        if (entry.value.node == node) {
          return NodeInformation(
              sourceEntry.key.fullName, entry.key, entry.value);
        }
      }
      for (MapEntry<AstNode, DecoratedTypeInfo> entry
          in sourceInfo.implicitType.entries) {
        if (entry.value.node == node) {
          return NodeInformation(
              sourceEntry.key.fullName, entry.key, entry.value);
        }
      }
      for (MapEntry<AstNode, List<DecoratedTypeInfo>> entry
          in sourceInfo.implicitTypeArguments.entries) {
        for (var type in entry.value) {
          if (type.node == node) {
            return NodeInformation(sourceEntry.key.fullName, entry.key, type);
          }
        }
      }
    }
    // The loop below doesn't help because we still don't have access to an AST
    // node.
//    for (MapEntry<Element, DecoratedTypeInfo> entry in externalDecoratedType.entries) {
//      if (entry.value.node == node) {
//        return NodeInformation(null, null, entry.value);
//      }
//    }
    return null;
  }
}

/// The instrumentation information about a [NullabilityNodeInfo].
class NodeInformation {
  final String filePath;

  final AstNode astNode;

  final DecoratedTypeInfo decoratedType;

  NodeInformation(this.filePath, this.astNode, this.decoratedType);
}

/// The instrumentation information gathered from the migration engine that is
/// specific to a single source.
class SourceInformation {
  /// A map from the type annotations found in the source code, to the
  /// nullability nodes that are associated with that type.
  final Map<TypeAnnotation, NullabilityNodeInfo> explicitTypeNullability = {};

  /// A map from the fixes that were decided on to the reasons for the fix.
  final Map<SingleNullabilityFix, List<FixReasonInfo>> fixes = {};

  /// A map from AST nodes that have an implicit return type to the nullability
  /// node associated with the implicit return type of the AST node. The node
  /// can be an
  /// - executable declaration,
  /// - function-typed formal parameter declaration,
  /// - function type alias declaration,
  /// - generic function type, or
  /// - function expression.
  final Map<AstNode, DecoratedTypeInfo> implicitReturnType = {};

  /// A map from AST nodes that have an implicit type to the nullability node
  /// associated with the implicit type of the AST node. The node can be a
  /// - formal parameter,
  /// - declared identifier, or
  /// - variable in a variable declaration list.
  final Map<AstNode, DecoratedTypeInfo> implicitType = {};

  /// Called whenever the migration engine encounters an AST node with implicit
  /// type arguments, to report the nullability nodes associated with the
  /// implicit type arguments of the AST node.
  ///
  /// A map from AST nodes that have implicit type arguments to the nullability
  /// nodes associated with the implicit type arguments of the AST node. The
  /// node can be a
  /// - constructor redirection,
  /// - function expression invocation,
  /// - method invocation,
  /// - instance creation expression,
  /// - list/map/set literal, or
  /// - type annotation.
  final Map<AstNode, List<DecoratedTypeInfo>> implicitTypeArguments = {};

  /// Initialize a newly created holder of instrumentation information that is
  /// specific to a single source.
  SourceInformation();
}
