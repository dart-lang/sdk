// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/front_end/instrumentation_information.dart';
import 'package:nnbd_migration/src/front_end/migration_summary.dart';

/// A listener used to gather instrumentation information from the migration
/// engine.
class InstrumentationListener implements NullabilityMigrationInstrumentation {
  final MigrationSummary? migrationSummary;

  /// The instrumentation information being gathered.
  InstrumentationInformation data = InstrumentationInformation();

  /// Initialize a newly created listener.
  InstrumentationListener({this.migrationSummary});

  @override
  void changes(Source source, Map<int?, List<AtomicEdit>> changes) {
    assert(_sourceInfo(source).changes == null);
    _sourceInfo(source).changes = changes;
    migrationSummary?.recordChanges(source, changes);
  }

  @override
  void explicitTypeNullability(Source? source, TypeAnnotation typeAnnotation,
      NullabilityNodeInfo? node) {
    _sourceInfo(source).explicitTypeNullability[typeAnnotation] = node;
  }

  @override
  void externalDecoratedType(
      Element element, DecoratedTypeInfo decoratedType) {}

  @override
  void externalDecoratedTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedTypeInfo decoratedType) {}

  @override
  void finished() {
    migrationSummary?.write();
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
      Source? source, AstNode node, DecoratedTypeInfo? decoratedReturnType) {}

  @override
  void implicitType(
      Source? source, AstNode? node, DecoratedTypeInfo decoratedType) {}

  @override
  void implicitTypeArguments(
      Source? source, AstNode node, Iterable<DecoratedTypeInfo> types) {}

  @override
  void prepareForUpdate() {
    for (var source in data.sourceInformation.keys) {
      _sourceInfo(source).changes = null;
    }
  }

  /// Return the source information associated with the given [source], creating
  /// it if there has been no previous information for that source.
  SourceInformation _sourceInfo(Source? source) =>
      data.sourceInformation.putIfAbsent(source, () => SourceInformation());
}
