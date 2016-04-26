// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.call_structure;

import '../common.dart';
import '../common/names.dart' show Names;
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../util/util.dart';
import 'selector.dart' show Selector;

/// The structure of the arguments at a call-site.
// TODO(johnniwinther): Should these be cached?
// TODO(johnniwinther): Should isGetter/isSetter be part of the call structure
// instead of the selector?
class CallStructure {
  static const CallStructure NO_ARGS = const CallStructure.unnamed(0);
  static const CallStructure ONE_ARG = const CallStructure.unnamed(1);
  static const CallStructure TWO_ARGS = const CallStructure.unnamed(2);

  /// The numbers of arguments of the call. Includes named arguments.
  final int argumentCount;

  /// The number of named arguments of the call.
  int get namedArgumentCount => 0;

  /// The number of positional argument of the call.
  int get positionalArgumentCount => argumentCount;

  const CallStructure.unnamed(this.argumentCount);

  factory CallStructure(int argumentCount, [List<String> namedArguments]) {
    if (namedArguments == null || namedArguments.isEmpty) {
      return new CallStructure.unnamed(argumentCount);
    }
    return new NamedCallStructure(argumentCount, namedArguments);
  }

  /// `true` if this call has named arguments.
  bool get isNamed => false;

  /// `true` if this call has no named arguments.
  bool get isUnnamed => true;

  /// The names of the named arguments in call-site order.
  List<String> get namedArguments => const <String>[];

  /// The names of the named arguments in canonicalized order.
  List<String> getOrderedNamedArguments() => const <String>[];

  /// A description of the argument structure.
  String structureToString() => 'arity=$argumentCount';

  String toString() => 'CallStructure(${structureToString()})';

  Selector get callSelector => new Selector.call(Names.call, this);

  bool match(CallStructure other) {
    if (identical(this, other)) return true;
    return this.argumentCount == other.argumentCount &&
        this.namedArgumentCount == other.namedArgumentCount &&
        sameNames(this.namedArguments, other.namedArguments);
  }

  // TODO(johnniwinther): Cache hash code?
  int get hashCode {
    return Hashing.listHash(namedArguments,
        Hashing.objectHash(argumentCount, namedArguments.length));
  }

  bool operator ==(other) {
    if (other is! CallStructure) return false;
    return match(other);
  }

  bool signatureApplies(FunctionSignature parameters) {
    if (argumentCount > parameters.parameterCount) return false;
    int requiredParameterCount = parameters.requiredParameterCount;
    int optionalParameterCount = parameters.optionalParameterCount;
    if (positionalArgumentCount < requiredParameterCount) return false;

    if (!parameters.optionalParametersAreNamed) {
      // We have already checked that the number of arguments are
      // not greater than the number of parameters. Therefore the
      // number of positional arguments are not greater than the
      // number of parameters.
      assert(positionalArgumentCount <= parameters.parameterCount);
      return namedArguments.isEmpty;
    } else {
      if (positionalArgumentCount > requiredParameterCount) return false;
      assert(positionalArgumentCount == requiredParameterCount);
      if (namedArgumentCount > optionalParameterCount) return false;
      Set<String> nameSet = new Set<String>();
      parameters.optionalParameters.forEach((Element element) {
        nameSet.add(element.name);
      });
      for (String name in namedArguments) {
        if (!nameSet.contains(name)) return false;
        // TODO(5213): By removing from the set we are checking
        // that we are not passing the name twice. We should have this
        // check in the resolver also.
        nameSet.remove(name);
      }
      return true;
    }
  }

  /**
   * Returns a `List` with the evaluated arguments in the normalized order.
   *
   * [compileDefaultValue] is a function that returns a compiled constant
   * of an optional argument that is not in [compiledArguments].
   *
   * Precondition: `this.applies(element, world)`.
   *
   * Invariant: [element] must be the implementation element.
   */
  /*<T>*/ List/*<T>*/ makeArgumentsList(
      Link<Node> arguments,
      FunctionElement element,
      /*T*/ compileArgument(Node argument),
      /*T*/ compileDefaultValue(ParameterElement element)) {
    assert(invariant(element, element.isImplementation));
    List/*<T>*/ result = new List();

    FunctionSignature parameters = element.functionSignature;
    parameters.forEachRequiredParameter((ParameterElement element) {
      result.add(compileArgument(arguments.head));
      arguments = arguments.tail;
    });

    if (!parameters.optionalParametersAreNamed) {
      parameters.forEachOptionalParameter((ParameterElement element) {
        if (!arguments.isEmpty) {
          result.add(compileArgument(arguments.head));
          arguments = arguments.tail;
        } else {
          result.add(compileDefaultValue(element));
        }
      });
    } else {
      // Visit named arguments and add them into a temporary list.
      List compiledNamedArguments = [];
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        NamedArgument namedArgument = arguments.head;
        compiledNamedArguments.add(compileArgument(namedArgument.expression));
      }
      // Iterate over the optional parameters of the signature, and try to
      // find them in [compiledNamedArguments]. If found, we use the
      // value in the temporary list, otherwise the default value.
      parameters.orderedOptionalParameters.forEach((ParameterElement element) {
        int foundIndex = namedArguments.indexOf(element.name);
        if (foundIndex != -1) {
          result.add(compiledNamedArguments[foundIndex]);
        } else {
          result.add(compileDefaultValue(element));
        }
      });
    }
    return result;
  }

  /**
   * Fills [list] with the arguments in the order expected by
   * [callee], and where [caller] is a synthesized element
   *
   * [compileArgument] is a function that returns a compiled version
   * of a parameter of [callee].
   *
   * [compileConstant] is a function that returns a compiled constant
   * of an optional argument that is not in the parameters of [callee].
   *
   * Returns [:true:] if the signature of the [caller] matches the
   * signature of the [callee], [:false:] otherwise.
   */
  static/*<T>*/ bool addForwardingElementArgumentsToList(
      ConstructorElement caller,
      List/*<T>*/ list,
      ConstructorElement callee,
      /*T*/ compileArgument(ParameterElement element),
      /*T*/ compileConstant(ParameterElement element)) {
    assert(invariant(caller, !callee.isMalformed,
        message: "Cannot compute arguments to malformed constructor: "
            "$caller calling $callee."));

    FunctionSignature signature = caller.functionSignature;
    Map<Node, ParameterElement> mapping = <Node, ParameterElement>{};

    // TODO(ngeoffray): This is a hack that fakes up AST nodes, so
    // that we can call [addArgumentsToList].
    Link<Node> computeCallNodesFromParameters() {
      LinkBuilder<Node> builder = new LinkBuilder<Node>();
      signature.forEachRequiredParameter((ParameterElement element) {
        Node node = element.node;
        mapping[node] = element;
        builder.addLast(node);
      });
      if (signature.optionalParametersAreNamed) {
        signature.forEachOptionalParameter((ParameterElement element) {
          mapping[element.initializer] = element;
          builder.addLast(new NamedArgument(null, null, element.initializer));
        });
      } else {
        signature.forEachOptionalParameter((ParameterElement element) {
          Node node = element.node;
          mapping[node] = element;
          builder.addLast(node);
        });
      }
      return builder.toLink();
    }

    /*T*/ internalCompileArgument(Node node) {
      return compileArgument(mapping[node]);
    }

    Link<Node> nodes = computeCallNodesFromParameters();

    // Synthesize a structure for the call.
    // TODO(ngeoffray): Should the resolver do it instead?
    List<String> namedParameters;
    if (signature.optionalParametersAreNamed) {
      namedParameters =
          signature.optionalParameters.map((e) => e.name).toList();
    }
    CallStructure callStructure =
        new CallStructure(signature.parameterCount, namedParameters);
    if (!callStructure.signatureApplies(signature)) {
      return false;
    }
    list.addAll(callStructure.makeArgumentsList(
        nodes, callee, internalCompileArgument, compileConstant));

    return true;
  }

  static bool sameNames(List<String> first, List<String> second) {
    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}

///
class NamedCallStructure extends CallStructure {
  final List<String> namedArguments;
  final List<String> _orderedNamedArguments = <String>[];

  NamedCallStructure(int argumentCount, this.namedArguments)
      : super.unnamed(argumentCount) {
    assert(namedArguments.isNotEmpty);
  }

  @override
  bool get isNamed => true;

  @override
  bool get isUnnamed => false;

  @override
  int get namedArgumentCount => namedArguments.length;

  @override
  int get positionalArgumentCount => argumentCount - namedArgumentCount;

  @override
  List<String> getOrderedNamedArguments() {
    if (!_orderedNamedArguments.isEmpty) return _orderedNamedArguments;

    _orderedNamedArguments.addAll(namedArguments);
    _orderedNamedArguments.sort((String first, String second) {
      return first.compareTo(second);
    });
    return _orderedNamedArguments;
  }

  @override
  String structureToString() {
    return 'arity=$argumentCount, named=[${namedArguments.join(', ')}]';
  }
}
