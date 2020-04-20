// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';

/// Compute simple-boundedness for all classes and generic types aliases in
/// the source [libraryBuilders].  There might be dependencies between them,
/// so they all should be processed simultaneously.
void computeSimplyBounded(
  LinkedBundleContext bundleContext,
  Iterable<LibraryBuilder> libraryBuilders,
) {
  var walker = SimplyBoundedDependencyWalker(bundleContext);
  var nodes = <SimplyBoundedNode>[];
  for (var libraryBuilder in libraryBuilders) {
    for (var unit in libraryBuilder.element.units) {
      for (var element in unit.functionTypeAliases) {
        var node = walker.getNode(element);
        nodes.add(node);
      }
      for (var element in unit.mixins) {
        var node = walker.getNode(element);
        nodes.add(node);
      }
      for (var element in unit.types) {
        var node = walker.getNode(element);
        nodes.add(node);
      }
    }
  }

  for (var node in nodes) {
    if (!node.isEvaluated) {
      walker.walk(node);
    }
    LazyAst.setSimplyBounded(node._node, node.isSimplyBounded);
  }
}

/// The graph walker for evaluating whether types are simply bounded.
class SimplyBoundedDependencyWalker
    extends graph.DependencyWalker<SimplyBoundedNode> {
  final LinkedBundleContext bundleContext;
  final Map<Element, SimplyBoundedNode> nodeMap = Map.identity();

  SimplyBoundedDependencyWalker(this.bundleContext);

  @override
  void evaluate(SimplyBoundedNode v) {
    v._evaluate();
  }

  @override
  void evaluateScc(List<SimplyBoundedNode> scc) {
    for (var node in scc) {
      node._markCircular();
    }
  }

  SimplyBoundedNode getNode(Element element) {
    var graphNode = nodeMap[element];
    if (graphNode == null) {
      var node = (element as ElementImpl).linkedNode;
      if (node is ClassDeclaration) {
        var parameters = node.typeParameters?.typeParameters;
        graphNode = SimplyBoundedNode(
          this,
          node,
          parameters ?? const <TypeParameter>[],
          const <TypeAnnotation>[],
        );
      } else if (node is ClassTypeAlias) {
        var parameters = node.typeParameters?.typeParameters;
        graphNode = SimplyBoundedNode(
          this,
          node,
          parameters ?? const <TypeParameter>[],
          const <TypeAnnotation>[],
        );
      } else if (node is FunctionTypeAlias) {
        var parameters = node.typeParameters?.typeParameters;
        graphNode = SimplyBoundedNode(
          this,
          node,
          parameters ?? const <TypeParameter>[],
          _collectTypedefRhsTypes(node),
        );
      } else if (node is GenericTypeAlias) {
        var parameters = node.typeParameters?.typeParameters;
        graphNode = SimplyBoundedNode(
          this,
          node,
          parameters ?? const <TypeParameter>[],
          _collectTypedefRhsTypes(node),
        );
      } else if (node is MixinDeclaration) {
        var parameters = node.typeParameters?.typeParameters;
        graphNode = SimplyBoundedNode(
          this,
          node,
          parameters ?? const <TypeParameter>[],
          const <TypeAnnotation>[],
        );
      } else {
        throw UnimplementedError('(${node.runtimeType}) $node');
      }
      nodeMap[element] = graphNode;
    }
    return graphNode;
  }

  /// Collects all the type references appearing on the "right hand side" of a
  /// typedef.
  ///
  /// The "right hand side" of a typedef is the type appearing after the "="
  /// in a new style typedef declaration, or for an old style typedef
  /// declaration, the type that *would* appear after the "=" if it were
  /// converted to a new style typedef declaration.  This means that type
  /// parameter declarations and their bounds are not included.
  static List<TypeAnnotation> _collectTypedefRhsTypes(AstNode node) {
    if (node is FunctionTypeAlias) {
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/41023
      if (node.parameters == null) {
        var buffer = StringBuffer();
        buffer.writeln('Unexpected FunctionTypeAlias state.');
        try {
          buffer.writeln('unit: ');
          buffer.writeln(node.parent.toSource());
        } catch (_) {
          try {
            buffer.writeln('node: ');
            buffer.writeln(node.toSource());
          } catch (_) {
            try {
              buffer.writeln('node parts:');
              buffer.writeln('  name: ${node.name}');
              buffer.writeln('  typeParameters: ${node.typeParameters}');
              buffer.writeln('  returnType: ${node.returnType}');
              buffer.writeln('  parameters: ${node.parameters}');
            } catch (_) {
              buffer.writeln('nothing worked');
            }
          }
        }
        throw StateError(buffer.toString());
      }

      var collector = _TypeCollector();
      collector.addType(node.returnType);
      collector.visitParameters(node.parameters);
      return collector.types;
    } else if (node is GenericTypeAlias) {
      var functionType = node.functionType;
      if (functionType != null) {
        var collector = _TypeCollector();
        collector.addType(functionType.returnType);
        collector.visitParameters(functionType.parameters);
        return collector.types;
      } else {
        return const <TypeAnnotation>[];
      }
    } else {
      throw StateError('(${node.runtimeType}) $node');
    }
  }
}

/// The graph node used to construct the dependency graph for evaluating
/// whether types are simply bounded.
class SimplyBoundedNode extends graph.Node<SimplyBoundedNode> {
  final SimplyBoundedDependencyWalker _walker;
  final AstNode _node;

  /// The type parameters of the type whose simple-boundedness we check.
  final List<TypeParameter> _typeParameters;

  /// If the type whose simple-boundedness we check is a typedef, the types
  /// appearing in its "right hand side".
  final List<TypeAnnotation> _rhsTypes;

  @override
  bool isEvaluated = false;

  /// After execution of [_evaluate], indicates whether the type is
  /// simply bounded.
  ///
  /// Prior to execution of [computeDependencies], `true`.
  ///
  /// Between execution of [computeDependencies] and [_evaluate], `true`
  /// indicates that the type is simply bounded only if all of its dependencies
  /// are simply bounded; `false` indicates that the type is not simply bounded.
  bool isSimplyBounded = true;

  SimplyBoundedNode(
    this._walker,
    this._node,
    this._typeParameters,
    this._rhsTypes,
  );

  @override
  List<SimplyBoundedNode> computeDependencies() {
    var dependencies = <SimplyBoundedNode>[];
    for (var typeParameter in _typeParameters) {
      var bound = typeParameter.bound;
      if (bound != null) {
        if (!_visitType(dependencies, bound, false)) {
          // Note: we might consider setting isEvaluated=true here to prevent an
          // unnecessary call to SimplyBoundedDependencyWalker.evaluate.
          // However, we'd have to be careful to make sure this doesn't violate
          // an invariant of the DependencyWalker algorithm, since normally it
          // only expects isEvaluated to change during a call to .evaluate or
          // .evaluateScc.
          isSimplyBounded = false;
          return const [];
        }
      }
    }
    for (var type in _rhsTypes) {
      if (!_visitType(dependencies, type, true)) {
        // Note: we might consider setting isEvaluated=true here to prevent an
        // unnecessary call to SimplyBoundedDependencyWalker.evaluate.
        // However, we'd have to be careful to make sure this doesn't violate
        // an invariant of the DependencyWalker algorithm, since normally it
        // only expects isEvaluated to change during a call to .evaluate or
        // .evaluateScc.
        isSimplyBounded = false;
        return const [];
      }
    }
    return dependencies;
  }

  void _evaluate() {
    for (var dependency in graph.Node.getDependencies(this)) {
      if (!dependency.isSimplyBounded) {
        isSimplyBounded = false;
        break;
      }
    }
    isEvaluated = true;
  }

  void _markCircular() {
    isSimplyBounded = false;
    isEvaluated = true;
  }

  /// Visits the type specified by [type], storing the [SimplyBoundedNode] for
  /// any types it references in [dependencies].
  ///
  /// Return `false` if a type that is known to be not simply bound is found.
  ///
  /// Return `false` if a reference to a type parameter is found, and
  /// [allowTypeParameters] is `false`.
  ///
  /// If `false` is returned, further visiting is short-circuited.
  ///
  /// Otherwise `true` is returned.
  bool _visitType(List<SimplyBoundedNode> dependencies, TypeAnnotation type,
      bool allowTypeParameters) {
    if (type == null) return true;

    if (type is TypeName) {
      var element = type.name.staticElement;

      if (element is TypeParameterElement) {
        return allowTypeParameters;
      }

      var arguments = type.typeArguments;
      if (arguments == null) {
        var graphNode = _walker.nodeMap[element];

        // If not a node being linked, then the flag is already set.
        if (graphNode == null) {
          if (element is TypeParameterizedElement) {
            return element.isSimplyBounded;
          }
          return true;
        }

        dependencies.add(graphNode);
      } else {
        for (var argument in arguments.arguments) {
          if (!_visitType(dependencies, argument, allowTypeParameters)) {
            return false;
          }
        }
      }
      return true;
    }

    if (type is GenericFunctionType) {
      var collector = _TypeCollector();
      collector.addType(type.returnType);
      collector.visitParameters(type.parameters);
      for (var type in collector.types) {
        if (!_visitType(dependencies, type, allowTypeParameters)) {
          return false;
        }
      }
      return true;
    }

    throw UnimplementedError('(${type.runtimeType}) $type');
  }
}

/// Helper for collecting type annotations.
class _TypeCollector {
  final List<TypeAnnotation> types = [];

  void addType(TypeAnnotation type) {
    if (type != null) {
      types.add(type);
    }
  }

  void visitParameter(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      visitParameter(node.parameter);
    } else if (node is FieldFormalParameter) {
      // The spec does not allow them here, ignore.
    } else if (node is FunctionTypedFormalParameter) {
      addType(node.returnType);
      visitParameters(node.parameters);
    } else if (node is SimpleFormalParameter) {
      addType(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  void visitParameters(FormalParameterList parameterList) {
    for (var parameter in parameterList.parameters) {
      visitParameter(parameter);
    }
  }
}
