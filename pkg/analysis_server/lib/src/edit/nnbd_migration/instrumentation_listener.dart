// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';

/// A listener used to gather instrumentation information from the migration
/// engine.
class InstrumentationListener implements NullabilityMigrationInstrumentation {
  /// The instrumentation information being gathered.
  InstrumentationInformation data = InstrumentationInformation();

  /// Initialize a newly created listener.
  InstrumentationListener();

  @override
  void explicitTypeNullability(
      Source source, TypeAnnotation typeAnnotation, NullabilityNodeInfo node) {
    _sourceInfo(source).explicitTypeNullability[typeAnnotation] = node;
  }

  @override
  void externalDecoratedType(Element element, DecoratedTypeInfo decoratedType) {
    data.externalDecoratedType[element] = decoratedType;
  }

  @override
  void externalDecoratedTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedTypeInfo decoratedType) {
    // TODO(paulberry): make use of this information.
  }

  @override
  void fix(SingleNullabilityFix fix, Iterable<FixReasonInfo> reasons) {
    _sourceInfo(fix.source).fixes[fix] =
        reasons.where((reason) => reason != null).toList();
  }

  @override
  void graphEdge(EdgeInfo edge, EdgeOriginInfo originInfo) {
    data.edgeOrigin[edge] = originInfo;
  }

  @override
  void immutableNodes(NullabilityNodeInfo never, NullabilityNodeInfo always) {
    data.never = never;
    data.always = always;
  }

  @override
  void implicitReturnType(
      Source source, AstNode node, DecoratedTypeInfo decoratedReturnType) {
    _sourceInfo(source).implicitReturnType[node] = decoratedReturnType;
  }

  @override
  void implicitType(
      Source source, AstNode node, DecoratedTypeInfo decoratedType) {
    _sourceInfo(source).implicitType[node] = decoratedType;
  }

  @override
  void implicitTypeArguments(
      Source source, AstNode node, Iterable<DecoratedTypeInfo> types) {
    _sourceInfo(source).implicitTypeArguments[node] = types.toList();
  }

  @override
  void propagationStep(PropagationInfo info) {
    data.propagationSteps.add(info);
  }

  /// Return the source information associated with the given [source], creating
  /// it if there has been no previous information for that source.
  SourceInformation _sourceInfo(Source source) =>
      data.sourceInformation.putIfAbsent(source, () => SourceInformation());
}
