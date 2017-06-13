// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.types;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../elements/resolution_types.dart';
import '../elements/elements.dart'
    show
        AmbiguousElement,
        ClassElement,
        Element,
        Elements,
        ErroneousElement,
        PrefixElement,
        TypedefElement,
        TypeVariableElement;
import '../elements/modelx.dart' show ErroneousElementX;
import '../resolution/resolution.dart';
import '../tree/tree.dart';
import '../universe/feature.dart' show Feature;
import '../util/util.dart' show Link;
import 'members.dart' show lookupInScope;
import 'registry.dart' show ResolutionRegistry;
import 'resolution_common.dart' show MappingVisitor;
import 'scope.dart' show Scope;

class _FormalsTypeResolutionResult {
  final List<ResolutionDartType> requiredTypes;
  final List<ResolutionDartType> orderedTypes;
  final List<String> names;
  final List<ResolutionDartType> nameTypes;

  _FormalsTypeResolutionResult(
      this.requiredTypes, this.orderedTypes, this.names, this.nameTypes);
}

class TypeResolver {
  final Resolution resolution;

  TypeResolver(this.resolution);

  ResolverTask get resolver => resolution.resolver;
  DiagnosticReporter get reporter => resolution.reporter;
  Types get types => resolution.types;

  /// Tries to resolve the type name as an element.
  Element resolveTypeName(
      Identifier prefixName, Identifier typeName, Scope scope,
      {bool deferredIsMalformed: true}) {
    Element element;
    if (prefixName != null) {
      Element prefixElement =
          lookupInScope(reporter, prefixName, scope, prefixName.source);
      if (prefixElement != null && prefixElement.isPrefix) {
        // The receiver is a prefix. Lookup in the imported members.
        PrefixElement prefix = prefixElement;
        element = prefix.lookupLocalMember(typeName.source);
        if (element != null && prefix.isDeferred && deferredIsMalformed) {
          element = new ErroneousElementX(MessageKind.DEFERRED_TYPE_ANNOTATION,
              {'node': typeName}, element.name, element);
        }
      } else {
        // The caller of this method will create the ErroneousElement for
        // the MalformedType.
        element = null;
      }
    } else {
      element = lookupInScope(reporter, typeName, scope, typeName.source);
    }
    return element;
  }

  ResolutionDartType resolveTypeAnnotation(
      MappingVisitor visitor, TypeAnnotation node,
      {bool malformedIsError: false, bool deferredIsMalformed: true}) {
    return _resolveTypeAnnotation(visitor, node, const [],
        malformedIsError: malformedIsError,
        deferredIsMalformed: deferredIsMalformed);
  }

  // TODO(floitsch): the [visibleTypeParameterNames] is a hack to put
  // type parameters in scope for the nested types.
  //
  // For example, in the following example, the generic type "A" would be stored
  // in `visibleTypeParameterNames`.
  // `typedef F = Function(List<A> Function<A>(A x))`.
  //
  // They are resolved to `dynamic` until dart2js supports generic methods.
  ResolutionDartType _resolveTypeAnnotation(MappingVisitor visitor,
      TypeAnnotation node, List<List<String>> visibleTypeParameterNames,
      {bool malformedIsError: false, bool deferredIsMalformed: true}) {
    if (node.asNominalTypeAnnotation() != null) {
      return resolveNominalTypeAnnotation(
          visitor, node, visibleTypeParameterNames,
          malformedIsError: malformedIsError,
          deferredIsMalformed: deferredIsMalformed);
    }
    assert(node.asFunctionTypeAnnotation() != null);
    return _resolveFunctionTypeAnnotation(
        visitor, node, visibleTypeParameterNames,
        malformedIsError: malformedIsError,
        deferredIsMalformed: deferredIsMalformed);
  }

  /// Resolves the types of a parameter list.
  ///
  /// This function does not accept "inline" function types. For example
  /// `foo(int bar(String x))` is not accepted.
  ///
  /// However, it does work with nested generalized function types:
  ///   `foo(int Function(String) x)`.
  _FormalsTypeResolutionResult _resolveFormalTypes(MappingVisitor visitor,
      NodeList formals, List<List<String>> visibleTypeParameterNames) {
    ResolutionDartType resolvePositionalType(VariableDefinitions node) {
      return _resolveTypeAnnotation(
          visitor, node.type, visibleTypeParameterNames);
    }

    void fillNamedTypes(NodeList namedFormals, List<String> names,
        List<ResolutionDartType> types) {
      List<Node> nodes = namedFormals.nodes.toList(growable: false);

      // Sort the named arguments first.
      nodes.sort((node1, node2) {
        VariableDefinitions a = node1;
        VariableDefinitions b = node2;
        assert(a.definitions.nodes.tail.isEmpty);
        assert(b.definitions.nodes.tail.isEmpty);
        return a.definitions.nodes.head
            .asIdentifier()
            .source
            .compareTo(b.definitions.nodes.head.asIdentifier().source);
      });

      for (VariableDefinitions node in nodes) {
        String name = node.definitions.nodes.head.asIdentifier().source;
        ResolutionDartType type = node.type == null
            ? const ResolutionDynamicType()
            : _resolveTypeAnnotation(
                visitor, node.type, visibleTypeParameterNames);
        names.add(name);
        types.add(type);
      }
    }

    List<ResolutionDartType> requiredTypes = <ResolutionDartType>[];
    NodeList optionalFormals = null;
    for (Link<Node> link = formals.nodes; !link.isEmpty; link = link.tail) {
      if (link.tail.isEmpty && link.head is NodeList) {
        optionalFormals = link.head;
        break;
      }
      requiredTypes.add(resolvePositionalType(link.head));
    }

    List<ResolutionDartType> orderedTypes = const <ResolutionDartType>[];
    List<String> names = const <String>[];
    List<ResolutionDartType> namedTypes = const <ResolutionDartType>[];

    if (optionalFormals != null) {
      // This must be a list of optional arguments.
      String value = optionalFormals.beginToken.stringValue;
      if ((!identical(value, '[')) && (!identical(value, '{'))) {
        reporter.internalError(optionalFormals, "expected optional parameters");
      }
      bool optionalParametersAreNamed = (identical(value, '{'));

      if (optionalParametersAreNamed) {
        names = <String>[];
        namedTypes = <ResolutionDartType>[];
        fillNamedTypes(optionalFormals, names, namedTypes);
      } else {
        orderedTypes = <ResolutionDartType>[];
        for (Link<Node> link = optionalFormals.nodes;
            !link.isEmpty;
            link = link.tail) {
          orderedTypes.add(resolvePositionalType(link.head));
        }
      }
    }
    return new _FormalsTypeResolutionResult(
        requiredTypes, orderedTypes, names, namedTypes);
  }

  ResolutionFunctionType _resolveFunctionTypeAnnotation(MappingVisitor visitor,
      FunctionTypeAnnotation node, List<List<String>> visibleTypeParameterNames,
      {bool malformedIsError: false, bool deferredIsMalformed: true}) {
    assert(visibleTypeParameterNames != null);

    if (node.typeParameters != null) {
      List<String> newTypeNames = node.typeParameters.map((TypeVariable node) {
        return node.name.asIdentifier().source;
      }).toList();
      visibleTypeParameterNames = visibleTypeParameterNames.toList()
        ..add(newTypeNames);
    }

    ResolutionDartType returnType = node.returnType == null
        ? const ResolutionDynamicType()
        : _resolveTypeAnnotation(
            visitor, node.returnType, visibleTypeParameterNames);
    var formalTypes =
        _resolveFormalTypes(visitor, node.formals, visibleTypeParameterNames);
    var result = new ResolutionFunctionType.generalized(
        returnType,
        formalTypes.requiredTypes,
        formalTypes.orderedTypes,
        formalTypes.names,
        formalTypes.nameTypes);
    visitor.registry.useType(node, result);
    return result;
  }

  ResolutionDartType resolveNominalTypeAnnotation(MappingVisitor visitor,
      NominalTypeAnnotation node, List<List<String>> visibleTypeParameterNames,
      {bool malformedIsError: false, bool deferredIsMalformed: true}) {
    ResolutionRegistry registry = visitor.registry;

    Identifier typeName;
    ResolutionDartType type;

    ResolutionDartType checkNoTypeArguments(ResolutionDartType type) {
      List<ResolutionDartType> arguments = new List<ResolutionDartType>();
      bool hasTypeArgumentMismatch = resolveTypeArguments(visitor, node,
          const <ResolutionDartType>[], arguments, visibleTypeParameterNames);
      if (hasTypeArgumentMismatch) {
        return new MalformedType(
            new ErroneousElementX(MessageKind.TYPE_ARGUMENT_COUNT_MISMATCH,
                {'type': node}, typeName.source, visitor.enclosingElement),
            type,
            arguments);
      }
      return type;
    }

    Identifier prefixName;
    Send send = node.typeName.asSend();
    if (send != null) {
      // The type name is of the form [: prefix . identifier :].
      prefixName = send.receiver.asIdentifier();
      typeName = send.selector.asIdentifier();
    } else {
      typeName = node.typeName.asIdentifier();
      if (identical(typeName.source, 'void')) {
        type = const ResolutionVoidType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      } else if (identical(typeName.source, 'dynamic')) {
        type = const ResolutionDynamicType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      }
    }

    ResolutionDartType reportFailureAndCreateType(
        MessageKind messageKind, Map messageArguments,
        {ResolutionDartType userProvidedBadType,
        Element erroneousElement,
        List<DiagnosticMessage> infos: const <DiagnosticMessage>[]}) {
      if (malformedIsError) {
        reporter.reportError(
            reporter.createMessage(node, messageKind, messageArguments), infos);
      } else {
        registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
        reporter.reportWarning(
            reporter.createMessage(node, messageKind, messageArguments), infos);
      }
      if (erroneousElement == null) {
        registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
        erroneousElement = new ErroneousElementX(messageKind, messageArguments,
            typeName.source, visitor.enclosingElement);
      }
      List<ResolutionDartType> arguments = <ResolutionDartType>[];
      resolveTypeArguments(visitor, node, const <ResolutionDartType>[],
          arguments, visibleTypeParameterNames);
      return new MalformedType(
          erroneousElement, userProvidedBadType, arguments);
    }

    Element element;
    // Resolve references to type names as dynamic.
    // TODO(floitsch): this hackishly resolves generic function type arguments
    // to dynamic.
    if (prefixName == null &&
        visibleTypeParameterNames.any((n) => n.contains(typeName.source))) {
      type = const ResolutionDynamicType();
    } else {
      element = resolveTypeName(prefixName, typeName, visitor.scope,
          deferredIsMalformed: deferredIsMalformed);
    }

    // Try to construct the type from the element.
    if (type != null) {
      // Already assigned to through the visibleTypeParameterNames.
      // Just make sure that it doesn't have type arguments.
      if (node.typeArguments != null) {
        reporter.reportWarningMessage(node.typeArguments.nodes.head,
            MessageKind.ADDITIONAL_TYPE_ARGUMENT);
      }
    } else if (element == null) {
      type = reportFailureAndCreateType(
          MessageKind.CANNOT_RESOLVE_TYPE, {'typeName': node.typeName});
    } else if (element.isAmbiguous) {
      AmbiguousElement ambiguous = element;
      type = reportFailureAndCreateType(
          ambiguous.messageKind, ambiguous.messageArguments,
          infos: ambiguous.computeInfos(
              registry.mapping.analyzedElement, reporter));
      ;
    } else if (element.isMalformed) {
      if (element is ErroneousElement) {
        type = reportFailureAndCreateType(
            element.messageKind, element.messageArguments,
            erroneousElement: element);
      } else {
        type = const ResolutionDynamicType();
      }
    } else if (!element.impliesType) {
      type = reportFailureAndCreateType(
          MessageKind.NOT_A_TYPE, {'node': node.typeName});
    } else if (element.library.isPlatformLibrary &&
        element.name == 'FutureOr') {
      type = const ResolutionDynamicType();
      registry.useType(node, type);
      return type;
    } else {
      bool addTypeVariableBoundsCheck = false;
      if (element.isClass) {
        ClassElement cls = element;
        // TODO(johnniwinther): [ensureClassWillBeResolvedInternal] should imply
        // [computeType].
        resolver.ensureClassWillBeResolvedInternal(cls);
        cls.computeType(resolution);
        List<ResolutionDartType> arguments = <ResolutionDartType>[];
        bool hasTypeArgumentMismatch = resolveTypeArguments(visitor, node,
            cls.typeVariables, arguments, visibleTypeParameterNames);
        if (hasTypeArgumentMismatch) {
          type = new BadInterfaceType(
              cls.declaration,
              new ResolutionInterfaceType.forUserProvidedBadType(
                  cls.declaration, arguments));
        } else {
          if (arguments.isEmpty) {
            type = cls.rawType;
          } else {
            type = new ResolutionInterfaceType(
                cls.declaration, arguments.toList(growable: false));
            addTypeVariableBoundsCheck =
                arguments.any((ResolutionDartType type) => !type.isDynamic);
          }
        }
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        // TODO(johnniwinther): [ensureResolved] should imply [computeType].
        typdef.ensureResolved(resolution);
        typdef.computeType(resolution);
        List<ResolutionDartType> arguments = <ResolutionDartType>[];
        bool hasTypeArgumentMismatch = resolveTypeArguments(visitor, node,
            typdef.typeVariables, arguments, visibleTypeParameterNames);
        if (hasTypeArgumentMismatch) {
          type = new BadTypedefType(
              typdef,
              new ResolutionTypedefType.forUserProvidedBadType(
                  typdef, arguments));
        } else {
          if (arguments.isEmpty) {
            type = typdef.rawType;
          } else {
            type = new ResolutionTypedefType(
                typdef, arguments.toList(growable: false));
            addTypeVariableBoundsCheck =
                arguments.any((ResolutionDartType type) => !type.isDynamic);
          }
        }
      } else if (element.isTypeVariable) {
        TypeVariableElement typeVariable = element;
        Element outer =
            visitor.enclosingElement.outermostEnclosingMemberOrTopLevel;
        if (!outer.isClass &&
            !outer.isTypedef &&
            !Elements.hasAccessToTypeVariable(
                visitor.enclosingElement, typeVariable)) {
          registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
          type = reportFailureAndCreateType(
              MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
              {'typeVariableName': node},
              userProvidedBadType: typeVariable.type);
        } else {
          type = typeVariable.type;
        }
        type = checkNoTypeArguments(type);
      } else {
        reporter.internalError(
            node, "Unexpected element kind ${element.kind}.");
      }
      if (addTypeVariableBoundsCheck) {
        visitor.addDeferredAction(visitor.enclosingElement,
            () => checkTypeVariableBounds(node, type));
      }
    }
    registry.useType(node, type);
    return type;
  }

  /// Checks the type arguments of [type] against the type variable bounds.
  void checkTypeVariableBounds(NominalTypeAnnotation node, GenericType type) {
    void checkTypeVariableBound(_, ResolutionDartType typeArgument,
        ResolutionTypeVariableType typeVariable, ResolutionDartType bound) {
      if (!types.isSubtype(typeArgument, bound)) {
        reporter.reportWarningMessage(
            node, MessageKind.INVALID_TYPE_VARIABLE_BOUND, {
          'typeVariable': typeVariable,
          'bound': bound,
          'typeArgument': typeArgument,
          'thisType': type.element.thisType
        });
      }
    }

    types.genericCheckTypeVariableBounds(type, checkTypeVariableBound);
  }

  /**
   * Resolves the type arguments of [node] and adds these to [arguments].
   *
   * Returns [: true :] if the number of type arguments did not match the
   * number of type variables.
   */
  bool resolveTypeArguments(
      MappingVisitor visitor,
      NominalTypeAnnotation node,
      List<ResolutionDartType> typeVariables,
      List<ResolutionDartType> arguments,
      List<List<String>> visibleTypeParameterNames) {
    if (node.typeArguments == null) {
      return false;
    }
    int expectedVariables = typeVariables.length;
    int index = 0;
    bool typeArgumentCountMismatch = false;
    for (Link<Node> typeArguments = node.typeArguments.nodes;
        !typeArguments.isEmpty;
        typeArguments = typeArguments.tail, index++) {
      if (index > expectedVariables - 1) {
        reporter.reportWarningMessage(
            typeArguments.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
        typeArgumentCountMismatch = true;
      }
      ResolutionDartType argType = _resolveTypeAnnotation(
          visitor, typeArguments.head, visibleTypeParameterNames);
      // TODO(karlklose): rewrite to not modify [arguments].
      arguments.add(argType);
    }
    if (index < expectedVariables) {
      reporter.reportWarningMessage(
          node.typeArguments, MessageKind.MISSING_TYPE_ARGUMENT);
      typeArgumentCountMismatch = true;
    }
    return typeArgumentCountMismatch;
  }
}
