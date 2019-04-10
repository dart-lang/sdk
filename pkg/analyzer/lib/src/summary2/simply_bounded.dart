// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart' show LinkedNode;
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// Compute simple-boundedness for all classes and generic types aliases in
/// the source [libraryBuilders].  There might be dependencies between them,
/// so they all should be processed simultaneously.
void computeSimplyBounded(
  LinkedBundleContext bundleContext,
  Iterable<SourceLibraryBuilder> libraryBuilders,
) {
  var walker = SimplyBoundedDependencyWalker(bundleContext);
  var nodes = <SimplyBoundedNode>[];
  for (var libraryBuilder in libraryBuilders) {
    var unitsRef = libraryBuilder.reference.getChild('@unit');
    for (var unitRef in unitsRef.children) {
      for (var classRef in unitRef.getChild('@class').children) {
        var node = walker.getNode(classRef);
        nodes.add(node);
      }
      for (var ref in unitRef.getChild('@typeAlias').children) {
        var node = walker.getNode(ref);
        nodes.add(node);
      }
    }
  }

  for (var node in nodes) {
    if (!node.isEvaluated) {
      walker.walk(node);
    }
    LinkedNodeBuilder builder = node._reference.node;
    builder.simplyBoundable_isSimplyBounded = node.isSimplyBounded;
  }
}

/// The graph walker for evaluating whether types are simply bounded.
class SimplyBoundedDependencyWalker
    extends graph.DependencyWalker<SimplyBoundedNode> {
  final LinkedBundleContext bundleContext;
  final Map<Reference, SimplyBoundedNode> nodeMap = {};

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

  SimplyBoundedNode getNode(Reference reference) {
    var node = nodeMap[reference];
    if (node == null) {
      if (reference.isClass) {
        var parameters = LinkedUnitContext.getTypeParameters(reference.node);
        node = SimplyBoundedNode(
          this,
          reference,
          parameters ?? const <LinkedNode>[],
          const <LinkedNode>[],
        );
      } else if (reference.isTypeAlias) {
        var parameters = LinkedUnitContext.getTypeParameters(reference.node);
        node = SimplyBoundedNode(
          this,
          reference,
          parameters ?? const <LinkedNode>[],
          _collectTypedefRhsTypes(reference.node),
        );
      } else {
        throw UnimplementedError('$reference');
      }
      nodeMap[reference] = node;
    }
    return node;
  }

  /// Collects all the type references appearing on the "right hand side" of a
  /// typedef.
  ///
  /// The "right hand side" of a typedef is the type appearing after the "="
  /// in a new style typedef declaration, or for an old style typedef
  /// declaration, the type that *would* appear after the "=" if it were
  /// converted to a new style typedef declaration.  This means that type
  /// parameter declarations and their bounds are not included.
  static List<LinkedNode> _collectTypedefRhsTypes(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.functionTypeAlias) {
      var types = <LinkedNode>[];
      _TypeCollector.addType(
        types,
        node.functionTypeAlias_returnType,
      );
      _TypeCollector.visitParameters(
        types,
        node.functionTypeAlias_formalParameters,
      );
      return types;
    } else if (kind == LinkedNodeKind.genericTypeAlias) {
      var types = <LinkedNode>[];
      var function = node.genericTypeAlias_functionType;
      _TypeCollector.addType(
        types,
        function.genericFunctionType_returnType,
      );
      _TypeCollector.visitParameters(
        types,
        function.genericFunctionType_formalParameters,
      );
      return types;
    } else {
      throw StateError('$kind');
    }
  }
}

/// The graph node used to construct the dependency graph for evaluating
/// whether types are simply bounded.
class SimplyBoundedNode extends graph.Node<SimplyBoundedNode> {
  final SimplyBoundedDependencyWalker _walker;
  final Reference _reference;

  /// The type parameters of the type whose simple-boundedness we check.
  final List<LinkedNode> _typeParameters;

  /// If the type whose simple-boundedness we check is a typedef, the types
  /// appearing in its "right hand side".
  final List<LinkedNode> _rhsTypes;

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
    this._reference,
    this._typeParameters,
    this._rhsTypes,
  );

  @override
  List<SimplyBoundedNode> computeDependencies() {
    var dependencies = <SimplyBoundedNode>[];
    for (var typeParameter in _typeParameters) {
      var bound = typeParameter.typeParameter_bound;
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
  bool _visitType(List<SimplyBoundedNode> dependencies, LinkedNode type,
      bool allowTypeParameters) {
    if (type == null) return true;

    if (type.kind == LinkedNodeKind.typeName) {
      var element = TypeBuilder.typeNameElementIndex(type.typeName_name);
      var reference = _walker.bundleContext.referenceOfIndex(element);

      if (reference.isTypeParameter) {
        return allowTypeParameters;
      }

      var arguments = type.typeName_typeArguments;
      if (arguments == null) {
        var graphNode = _walker.nodeMap[reference];

        // If not a node being linked, then the flag is already set.
        if (graphNode == null) {
          if (reference.isClass || reference.isTypeAlias) {
            var elementFactory = _walker.bundleContext.elementFactory;
            var node = elementFactory.nodeOfReference(reference);
            return node.simplyBoundable_isSimplyBounded;
          }
          return true;
        }

        dependencies.add(graphNode);
      } else {
        for (var argument in arguments.typeArgumentList_arguments) {
          if (!_visitType(dependencies, argument, allowTypeParameters)) {
            return false;
          }
        }
      }
      return true;
    }

    if (type.kind == LinkedNodeKind.genericFunctionType) {
      var types = <LinkedNode>[];
      _TypeCollector.addType(types, type.genericFunctionType_returnType);
      _TypeCollector.visitParameters(
        types,
        type.genericFunctionType_formalParameters,
      );
      for (var type in types) {
        if (!_visitType(dependencies, type, allowTypeParameters)) {
          return false;
        }
      }
      return true;
    }

    throw UnimplementedError('${type.kind}');
  }
}

/// Helper for collecting type annotations in formal parameters.
class _TypeCollector {
  static void addType(List<LinkedNode> types, LinkedNode type) {
    if (type != null) {
      types.add(type);
    }
  }

  static void visitParameter(List<LinkedNode> types, LinkedNode parameter) {
    var kind = parameter.kind;
    if (kind == LinkedNodeKind.defaultFormalParameter) {
      visitParameter(types, parameter.defaultFormalParameter_parameter);
    } else if (kind == LinkedNodeKind.functionTypedFormalParameter) {
      addType(types, parameter.functionTypedFormalParameter_returnType);
      visitParameters(
        types,
        parameter.functionTypedFormalParameter_formalParameters,
      );
    } else if (kind == LinkedNodeKind.simpleFormalParameter) {
      addType(types, parameter.simpleFormalParameter_type);
    } else {
      throw UnimplementedError('$kind');
    }
  }

  static void visitParameters(List<LinkedNode> types, LinkedNode parameters) {
    assert(parameters.kind == LinkedNodeKind.formalParameterList);
    for (var parameter in parameters.formalParameterList_parameters) {
      visitParameter(types, parameter);
    }
  }
}
