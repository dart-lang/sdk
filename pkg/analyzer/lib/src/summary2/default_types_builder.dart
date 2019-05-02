// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/type_builder.dart';
import 'package:kernel/util/graph.dart' show Graph, computeStrongComponents;

class DefaultTypesBuilder {
  final Dart2TypeSystem typeSystem;

  DefaultTypesBuilder(this.typeSystem);

  void build(List<AstNode> nodes) {
    for (var node in nodes) {
      if (node is ClassDeclaration) {
        _breakRawTypeCycles(node.declaredElement, node.typeParameters);
        _computeBounds(node.typeParameters);
      } else if (node is ClassTypeAlias) {
        _breakRawTypeCycles(node.declaredElement, node.typeParameters);
        _computeBounds(node.typeParameters);
      } else if (node is FunctionTypeAlias) {
        _breakRawTypeCycles(node.declaredElement, node.typeParameters);
        _computeBounds(node.typeParameters);
      } else if (node is GenericTypeAlias) {
        _breakRawTypeCycles(node.declaredElement, node.typeParameters);
        _computeBounds(node.typeParameters);
      } else if (node is MixinDeclaration) {
        _breakRawTypeCycles(node.declaredElement, node.typeParameters);
        _computeBounds(node.typeParameters);
      }
    }
    for (var node in nodes) {
      if (node is ClassDeclaration) {
        _build(node.typeParameters);
      } else if (node is ClassTypeAlias) {
        _build(node.typeParameters);
      } else if (node is FunctionTypeAlias) {
        _build(node.typeParameters);
      } else if (node is GenericTypeAlias) {
        _build(node.typeParameters);
      } else if (node is MixinDeclaration) {
        _build(node.typeParameters);
      }
    }
  }

  void _breakRawTypeCycles(
    Element declarationElement,
    TypeParameterList parameterList,
  ) {
    if (parameterList == null) return;

    var allCycles = <List<_CycleElement>>[];
    for (var parameter in parameterList.typeParameters) {
      var boundNode = parameter.bound;
      if (boundNode == null) continue;

      var cycles = _findRawTypePathsToDeclaration(
        parameter,
        boundNode.type,
        declarationElement,
        Set<Element>.identity(),
      );
      allCycles.addAll(cycles);
    }

    for (var cycle in allCycles) {
      for (var element in cycle) {
        var boundNode = element.parameter.bound;
        if (boundNode is TypeName) {
          boundNode.type = DynamicTypeImpl.instance;
        } else {
          throw UnimplementedError('(${boundNode.runtimeType}) $boundNode');
        }
      }
    }
  }

  /// Build actual default type [DartType]s from computed [TypeBuilder]s.
  void _build(TypeParameterList parameterList) {
    if (parameterList == null) return;

    for (var parameter in parameterList.typeParameters) {
      var defaultType = LazyAst.getDefaultType(parameter);
      if (defaultType is TypeBuilder) {
        var builtType = defaultType.build();
        LazyAst.setDefaultType(parameter, builtType);
      }
    }
  }

  /// Compute bounds to be provided as type arguments in place of missing type
  /// arguments on raw types with the given type parameters.
  void _computeBounds(TypeParameterList parameterList) {
    if (parameterList == null) return;

    var dynamicType = typeSystem.typeProvider.dynamicType;
    var nullType = typeSystem.typeProvider.nullType;

    var nodes = parameterList.typeParameters;
    var length = nodes.length;
    var elements = List<TypeParameterElement>(length);
    var bounds = List<DartType>(length);
    for (int i = 0; i < length; i++) {
      var node = nodes[i];
      elements[i] = node.declaredElement;
      bounds[i] = node.bound?.type ?? dynamicType;
    }

    var graph = _TypeParametersGraph(elements, bounds);
    var stronglyConnected = computeStrongComponents(graph);
    for (var component in stronglyConnected) {
      var dynamicSubstitution = <TypeParameterElement, DartType>{};
      var nullSubstitution = <TypeParameterElement, DartType>{};
      for (var i in component) {
        var element = elements[i];
        dynamicSubstitution[element] = dynamicType;
        nullSubstitution[element] = nullType;
      }

      var substitution = Substitution.fromUpperAndLowerBounds(
        dynamicSubstitution,
        nullSubstitution,
      );
      for (var i in component) {
        bounds[i] = substitution.substituteType(bounds[i]);
      }
    }

    for (var i = 0; i < length; i++) {
      var thisSubstitution = <TypeParameterElement, DartType>{};
      var nullSubstitution = <TypeParameterElement, DartType>{};
      var element = elements[i];
      thisSubstitution[element] = bounds[i];
      nullSubstitution[element] = nullType;

      var substitution = Substitution.fromUpperAndLowerBounds(
        thisSubstitution,
        nullSubstitution,
      );
      for (var j = 0; j < length; j++) {
        bounds[j] = substitution.substituteType(bounds[j]);
      }
    }

    // Set computed TypeBuilder(s) as default types.
    for (var i = 0; i < length; i++) {
      LazyAst.setDefaultType(nodes[i], bounds[i]);
    }
  }

  /// Finds raw type paths starting with the [startParameter] and a
  /// [startType] that is used in its bound, and ending with [end].
  List<List<_CycleElement>> _findRawTypePathsToDeclaration(
    TypeParameter startParameter,
    DartType startType,
    Element end,
    Set<Element> visited,
  ) {
    var paths = <List<_CycleElement>>[];
    if (startType is NamedTypeBuilder) {
      var declaration = startType.element;
      if (startType.arguments.isEmpty) {
        if (startType.element == end) {
          paths.add([
            _CycleElement(startParameter, startType),
          ]);
        } else if (visited.add(startType.element)) {
          void recurseParameters(List<TypeParameterElement> parameters) {
            for (TypeParameterElementImpl parameter in parameters) {
              TypeParameter parameterNode = parameter.linkedNode;
              var bound = parameterNode.bound;
              if (bound != null) {
                var tails = _findRawTypePathsToDeclaration(
                  parameterNode,
                  bound.type,
                  end,
                  visited,
                );
                for (var tail in tails) {
                  paths.add(<_CycleElement>[
                    _CycleElement(startParameter, startType),
                  ]..addAll(tail));
                }
              }
            }
          }

          if (declaration is ClassElement) {
            recurseParameters(declaration.typeParameters);
          } else if (declaration is GenericTypeAliasElement) {
            recurseParameters(declaration.typeParameters);
          }
          visited.remove(startType.element);
        }
      } else {
        for (var argument in startType.arguments) {
          paths.addAll(
            _findRawTypePathsToDeclaration(
              startParameter,
              argument,
              end,
              visited,
            ),
          );
        }
      }
    } else if (startType is FunctionTypeBuilder) {
      paths.addAll(
        _findRawTypePathsToDeclaration(
          startParameter,
          startType.returnType,
          end,
          visited,
        ),
      );
      for (var formalParameter in startType.parameters) {
        paths.addAll(
          _findRawTypePathsToDeclaration(
            startParameter,
            formalParameter.type,
            end,
            visited,
          ),
        );
      }
    }
    return paths;
  }
}

class _CycleElement {
  final TypeParameter parameter;
  final DartType type;

  _CycleElement(this.parameter, this.type);
}

/// Graph of mutual dependencies of type parameters from the same declaration.
/// Type parameters are represented by their indices in the corresponding
/// declaration.
class _TypeParametersGraph implements Graph<int> {
  @override
  List<int> vertices;

  // Each `edges[i]` is the list of indices of type parameters that reference
  // the type parameter with the index `i` in their bounds.
  List<List<int>> _edges;

  Map<TypeParameterElement, int> _parameterToIndex = Map.identity();

  _TypeParametersGraph(
    List<TypeParameterElement> parameters,
    List<DartType> bounds,
  ) {
    assert(parameters.length == bounds.length);

    vertices = List<int>(parameters.length);
    _edges = List<List<int>>(parameters.length);
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = i;
      _edges[i] = <int>[];
      _parameterToIndex[parameters[i]] = i;
    }

    for (int i = 0; i < vertices.length; i++) {
      _collectReferencesFrom(i, bounds[i]);
    }
  }

  /// Return type parameters that depend on the [index]th type parameter.
  @override
  Iterable<int> neighborsOf(int index) {
    return _edges[index];
  }

  /// Collect references to the [index]th type parameter from the [type].
  void _collectReferencesFrom(int index, DartType type) {
    if (type is FunctionTypeBuilder) {
      for (var parameter in type.typeFormals) {
        _collectReferencesFrom(index, parameter.bound);
      }
      for (var parameter in type.parameters) {
        _collectReferencesFrom(index, parameter.type);
      }
      _collectReferencesFrom(index, type.returnType);
    } else if (type is NamedTypeBuilder) {
      for (var argument in type.arguments) {
        _collectReferencesFrom(index, argument);
      }
    } else if (type is TypeParameterType) {
      var typeIndex = _parameterToIndex[type.element];
      if (typeIndex != null) {
        _edges[typeIndex].add(index);
      }
    }
  }
}
