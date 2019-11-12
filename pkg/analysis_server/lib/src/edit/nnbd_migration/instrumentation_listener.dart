// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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
    data.nodeInformation[node] = NodeInformation(
        _filePathForSource(source), typeAnnotation, null, 'the explicit type ');
    _sourceInfo(source).explicitTypeNullability[typeAnnotation] = node;
  }

  @override
  void externalDecoratedType(Element element, DecoratedTypeInfo decoratedType) {
    _storeNodeInformation(decoratedType, element.source, null, element, '');
  }

  @override
  void externalDecoratedTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedTypeInfo decoratedType) {
    _storeNodeInformation(
        decoratedType, typeParameter.source, null, typeParameter, 'bound of ');
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
    _storeNodeInformation(
        decoratedReturnType, source, node, null, 'return type of ');
  }

  @override
  void implicitType(
      Source source, AstNode node, DecoratedTypeInfo decoratedType) {
    _storeNodeInformation(decoratedType, source, node, null, 'type of ');
  }

  @override
  void implicitTypeArguments(
      Source source, AstNode node, Iterable<DecoratedTypeInfo> types) {
    int i = 0;
    for (var type in types) {
      _storeNodeInformation(
          type, source, node, null, 'implicit type argument $i of ');
      i++;
    }
  }

  @override
  void propagationStep(PropagationInfo info) {
    data.propagationSteps.add(info);
  }

  String _filePathForSource(Source source) {
    return source.toString();
  }

  /// Return the source information associated with the given [source], creating
  /// it if there has been no previous information for that source.
  SourceInformation _sourceInfo(Source source) =>
      data.sourceInformation.putIfAbsent(source, () => SourceInformation());

  void _storeNodeInformation(DecoratedTypeInfo decoratedType, Source source,
      AstNode astNode, Element element, String description) {
    // Make sure source info exists for the given source.
    _sourceInfo(source);
    data.nodeInformation[decoratedType.node] = NodeInformation(
        _filePathForSource(source), astNode, element, description);
    var dartType = decoratedType.type;
    if (dartType is InterfaceType) {
      for (int i = 0; i < dartType.typeArguments.length; i++) {
        _storeNodeInformation(decoratedType.typeArgument(i), source, astNode,
            element, 'type argument $i of $description');
      }
    } else if (dartType is FunctionType) {
      _storeNodeInformation(decoratedType.returnType, source, astNode, element,
          'return type of $description');
      int i = 0;
      for (var parameter in dartType.parameters) {
        if (parameter.isNamed) {
          var name = parameter.name;
          _storeNodeInformation(decoratedType.namedParameter(name), source,
              astNode, element, 'named parameter $name of $description');
        } else {
          _storeNodeInformation(decoratedType.positionalParameter(i), source,
              astNode, element, 'positional parameter $i of $description');
          i++;
        }
      }
    }
  }
}
