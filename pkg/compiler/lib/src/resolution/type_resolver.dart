// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

class TypeResolver {
  final Compiler compiler;

  TypeResolver(this.compiler);

  /// Tries to resolve the type name as an element.
  Element resolveTypeName(Identifier prefixName,
                          Identifier typeName,
                          Scope scope,
                          {bool deferredIsMalformed: true}) {
    Element element;
    if (prefixName != null) {
      Element prefixElement =
          lookupInScope(compiler, prefixName, scope, prefixName.source);
      if (prefixElement != null && prefixElement.isPrefix) {
        // The receiver is a prefix. Lookup in the imported members.
        PrefixElement prefix = prefixElement;
        element = prefix.lookupLocalMember(typeName.source);
        // TODO(17260, sigurdm): The test for DartBackend is there because
        // dart2dart outputs malformed types with prefix.
        if (element != null &&
            prefix.isDeferred &&
            deferredIsMalformed &&
            compiler.backend is! DartBackend) {
          element = new ErroneousElementX(MessageKind.DEFERRED_TYPE_ANNOTATION,
                                          {'node': typeName},
                                          element.name,
                                          element);
        }
      } else {
        // The caller of this method will create the ErroneousElement for
        // the MalformedType.
        element = null;
      }
    } else {
      element = lookupInScope(compiler, typeName, scope, typeName.source);
    }
    return element;
  }

  DartType resolveTypeAnnotation(MappingVisitor visitor, TypeAnnotation node,
                                 {bool malformedIsError: false,
                                  bool deferredIsMalformed: true}) {
    ResolutionRegistry registry = visitor.registry;

    Identifier typeName;
    DartType type;

    DartType checkNoTypeArguments(DartType type) {
      List<DartType> arguments = new List<DartType>();
      bool hasTypeArgumentMismatch = resolveTypeArguments(
          visitor, node, const <DartType>[], arguments);
      if (hasTypeArgumentMismatch) {
        return new MalformedType(
            new ErroneousElementX(MessageKind.TYPE_ARGUMENT_COUNT_MISMATCH,
                {'type': node}, typeName.source, visitor.enclosingElement),
                type, arguments);
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
        type = const VoidType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      } else if (identical(typeName.source, 'dynamic')) {
        type = const DynamicType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      }
    }

    Element element = resolveTypeName(prefixName, typeName, visitor.scope,
                                      deferredIsMalformed: deferredIsMalformed);

    DartType reportFailureAndCreateType(MessageKind messageKind,
                                        Map messageArguments,
                                        {DartType userProvidedBadType,
                                         Element erroneousElement}) {
      if (malformedIsError) {
        visitor.error(node, messageKind, messageArguments);
      } else {
        registry.registerThrowRuntimeError();
        visitor.warning(node, messageKind, messageArguments);
      }
      if (erroneousElement == null) {
        registry.registerThrowRuntimeError();
        erroneousElement = new ErroneousElementX(
            messageKind, messageArguments, typeName.source,
            visitor.enclosingElement);
      }
      List<DartType> arguments = <DartType>[];
      resolveTypeArguments(visitor, node, const <DartType>[], arguments);
      return new MalformedType(erroneousElement,
              userProvidedBadType, arguments);
    }

    // Try to construct the type from the element.
    if (element == null) {
      type = reportFailureAndCreateType(
          MessageKind.CANNOT_RESOLVE_TYPE, {'typeName': node.typeName});
    } else if (element.isAmbiguous) {
      AmbiguousElement ambiguous = element;
      type = reportFailureAndCreateType(
          ambiguous.messageKind, ambiguous.messageArguments);
      ambiguous.diagnose(registry.mapping.analyzedElement, compiler);
    } else if (element.isErroneous) {
      if (element is ErroneousElement) {
        type = reportFailureAndCreateType(
            element.messageKind, element.messageArguments,
            erroneousElement: element);
      } else {
        type = const DynamicType();
      }
    } else if (!element.impliesType) {
      type = reportFailureAndCreateType(
          MessageKind.NOT_A_TYPE, {'node': node.typeName});
    } else {
      bool addTypeVariableBoundsCheck = false;
      if (element.isClass) {
        ClassElement cls = element;
        // TODO(johnniwinther): [_ensureClassWillBeResolved] should imply
        // [computeType].
        compiler.resolver._ensureClassWillBeResolved(cls);
        cls.computeType(compiler);
        List<DartType> arguments = <DartType>[];
        bool hasTypeArgumentMismatch = resolveTypeArguments(
            visitor, node, cls.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadInterfaceType(cls.declaration,
              new InterfaceType.forUserProvidedBadType(cls.declaration,
                                                       arguments));
        } else {
          if (arguments.isEmpty) {
            type = cls.rawType;
          } else {
            type = new InterfaceType(cls.declaration, arguments.toList(growable: false));
            addTypeVariableBoundsCheck = true;
          }
        }
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        // TODO(johnniwinther): [ensureResolved] should imply [computeType].
        typdef.ensureResolved(compiler);
        typdef.computeType(compiler);
        List<DartType> arguments = <DartType>[];
        bool hasTypeArgumentMismatch = resolveTypeArguments(
            visitor, node, typdef.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadTypedefType(typdef,
              new TypedefType.forUserProvidedBadType(typdef, arguments));
        } else {
          if (arguments.isEmpty) {
            type = typdef.rawType;
          } else {
            type = new TypedefType(typdef, arguments.toList(growable: false));
            addTypeVariableBoundsCheck = true;
          }
        }
      } else if (element.isTypeVariable) {
        TypeVariableElement typeVariable = element;
        Element outer =
            visitor.enclosingElement.outermostEnclosingMemberOrTopLevel;
        if (!outer.isClass &&
            !outer.isTypedef &&
            !Elements.hasAccessToTypeVariables(visitor.enclosingElement)) {
          registry.registerThrowRuntimeError();
          type = reportFailureAndCreateType(
              MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
              {'typeVariableName': node},
              userProvidedBadType: typeVariable.type);
        } else {
          type = typeVariable.type;
        }
        type = checkNoTypeArguments(type);
      } else {
        compiler.internalError(node,
            "Unexpected element kind ${element.kind}.");
      }
      if (addTypeVariableBoundsCheck) {
        registry.registerTypeVariableBoundCheck();
        visitor.addDeferredAction(
            visitor.enclosingElement,
            () => checkTypeVariableBounds(node, type));
      }
    }
    registry.useType(node, type);
    return type;
  }

  /// Checks the type arguments of [type] against the type variable bounds.
  void checkTypeVariableBounds(TypeAnnotation node, GenericType type) {
    void checkTypeVariableBound(_, DartType typeArgument,
                                   TypeVariableType typeVariable,
                                   DartType bound) {
      if (!compiler.types.isSubtype(typeArgument, bound)) {
        compiler.reportWarning(node,
            MessageKind.INVALID_TYPE_VARIABLE_BOUND,
            {'typeVariable': typeVariable,
             'bound': bound,
             'typeArgument': typeArgument,
             'thisType': type.element.thisType});
      }
    };

    compiler.types.checkTypeVariableBounds(type, checkTypeVariableBound);
  }

  /**
   * Resolves the type arguments of [node] and adds these to [arguments].
   *
   * Returns [: true :] if the number of type arguments did not match the
   * number of type variables.
   */
  bool resolveTypeArguments(MappingVisitor visitor,
                            TypeAnnotation node,
                            List<DartType> typeVariables,
                            List<DartType> arguments) {
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
        visitor.warning(
            typeArguments.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
        typeArgumentCountMismatch = true;
      }
      DartType argType = resolveTypeAnnotation(visitor, typeArguments.head);
      // TODO(karlklose): rewrite to not modify [arguments].
      arguments.add(argType);
    }
    if (index < expectedVariables) {
      visitor.warning(node.typeArguments,
                      MessageKind.MISSING_TYPE_ARGUMENT);
      typeArgumentCountMismatch = true;
    }
    return typeArgumentCountMismatch;
  }
}
