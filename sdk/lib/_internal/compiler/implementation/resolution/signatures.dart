// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

/**
 * [SignatureResolver] resolves function signatures.
 */
class SignatureResolver extends MappingVisitor<ParameterElementX> {
  final ResolverVisitor resolver;
  final FunctionTypedElement enclosingElement;
  final Scope scope;
  final MessageKind defaultValuesError;
  Link<Element> optionalParameters = const Link<Element>();
  int optionalParameterCount = 0;
  bool isOptionalParameter = false;
  bool optionalParametersAreNamed = false;
  VariableDefinitions currentDefinitions;

  SignatureResolver(Compiler compiler,
                    FunctionTypedElement enclosingElement,
                    ResolutionRegistry registry,
                    {this.defaultValuesError})
      : this.enclosingElement = enclosingElement,
        this.scope = enclosingElement.buildScope(),
        this.resolver =
            new ResolverVisitor(compiler, enclosingElement, registry),
        super(compiler, registry);

  bool get defaultValuesAllowed => defaultValuesError == null;

  visitNodeList(NodeList node) {
    // This must be a list of optional arguments.
    String value = node.beginToken.stringValue;
    if ((!identical(value, '[')) && (!identical(value, '{'))) {
      internalError(node, "expected optional parameters");
    }
    optionalParametersAreNamed = (identical(value, '{'));
    isOptionalParameter = true;
    LinkBuilder<Element> elements = analyzeNodes(node.nodes);
    optionalParameterCount = elements.length;
    optionalParameters = elements.toLink();
  }

  ParameterElementX visitVariableDefinitions(VariableDefinitions node) {
    Link<Node> definitions = node.definitions.nodes;
    if (definitions.isEmpty) {
      internalError(node, 'no parameter definition');
      return null;
    }
    if (!definitions.tail.isEmpty) {
      internalError(definitions.tail.head, 'extra definition');
      return null;
    }
    Node definition = definitions.head;
    if (definition is NodeList) {
      internalError(node, 'optional parameters are not implemented');
    }
    if (node.modifiers.isConst) {
      compiler.reportError(node, MessageKind.FORMAL_DECLARED_CONST);
    }
    if (node.modifiers.isStatic) {
      compiler.reportError(node, MessageKind.FORMAL_DECLARED_STATIC);
    }

    if (currentDefinitions != null) {
      internalError(node, 'function type parameters not supported');
    }
    currentDefinitions = node;
    ParameterElementX element = definition.accept(this);
    if (currentDefinitions.metadata != null) {
      element.metadata = compiler.resolver.resolveMetadata(element, node);
    }
    currentDefinitions = null;
    return element;
  }

  void validateName(Identifier node) {
    String name = node.source;
    if (isOptionalParameter &&
        optionalParametersAreNamed &&
        isPrivateName(node.source)) {
      compiler.reportError(node, MessageKind.PRIVATE_NAMED_PARAMETER);
    }
  }

  void computeParameterType(ParameterElementX element,
                            [VariableElement fieldElement]) {
    void computeFunctionType(FunctionExpression functionExpression) {
      FunctionSignature functionSignature = SignatureResolver.analyze(
          compiler, functionExpression.parameters,
          functionExpression.returnType, element, registry,
          defaultValuesError: MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT);
      element.functionSignatureCache = functionSignature;
      element.typeCache = functionSignature.type;
    }

    if (currentDefinitions.type != null) {
      element.typeCache = resolveTypeAnnotation(currentDefinitions.type);
    } else {
      // Is node.definitions exactly one FunctionExpression?
      Link<Node> link = currentDefinitions.definitions.nodes;
      assert(invariant(currentDefinitions, !link.isEmpty));
      assert(invariant(currentDefinitions, link.tail.isEmpty));
      if (link.head.asFunctionExpression() != null) {
        // Inline function typed parameter, like `void m(int f(String s))`.
        computeFunctionType(link.head);
      } else if (link.head.asSend() != null &&
                 link.head.asSend().selector.asFunctionExpression() != null) {
        // Inline function typed initializing formal or
        // parameter with default value, like `C(int this.f(String s))` or
        // `void m([int f(String s) = null])`.
        computeFunctionType(link.head.asSend().selector.asFunctionExpression());
      } else {
        assert(invariant(currentDefinitions,
            link.head.asIdentifier() != null || link.head.asSend() != null));
        if (fieldElement != null) {
          element.typeCache = fieldElement.computeType(compiler);
        } else {
          element.typeCache = const DynamicType();
        }
      }
    }
  }

  Element visitIdentifier(Identifier node) {
    return createParameter(node, null);
  }

  Identifier getParameterName(Send node) {
    var identifier = node.selector.asIdentifier();
    if (identifier != null) {
      // Normal parameter: [:Type name:].
      return identifier;
    } else {
      // Function type parameter: [:void name(DartType arg):].
      var functionExpression = node.selector.asFunctionExpression();
      if (functionExpression != null &&
          functionExpression.name.asIdentifier() != null) {
        return functionExpression.name.asIdentifier();
      } else {
        internalError(node,
            'internal error: unimplemented receiver on parameter send');
        return null;
      }
    }
  }

  // The only valid [Send] can be in constructors and must be of the form
  // [:this.x:] (where [:x:] represents an instance field).
  FieldParameterElementX visitSend(Send node) {
    return createFieldParameter(node, null);
  }

  ParameterElementX createParameter(Identifier name, Expression initializer) {
    validateName(name);
    ParameterElementX parameter = new ParameterElementX(
        ElementKind.PARAMETER, enclosingElement,
        currentDefinitions, name, initializer);
    computeParameterType(parameter);
    return parameter;
  }

  FieldParameterElementX createFieldParameter(Send node,
                                              Expression initializer) {
    FieldParameterElementX element;
    if (node.receiver.asIdentifier() == null ||
        !node.receiver.asIdentifier().isThis()) {
      error(node, MessageKind.INVALID_PARAMETER);
    } else if (!identical(enclosingElement.kind,
                          ElementKind.GENERATIVE_CONSTRUCTOR)) {
      error(node, MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED);
    } else {
      Identifier name = getParameterName(node);
      validateName(name);
      Element fieldElement =
          enclosingElement.enclosingClass.lookupLocalMember(name.source);
      if (fieldElement == null ||
          !identical(fieldElement.kind, ElementKind.FIELD)) {
        error(node, MessageKind.NOT_A_FIELD, {'fieldName': name});
      } else if (!fieldElement.isInstanceMember) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, {'fieldName': name});
      }
      element = new FieldParameterElementX(enclosingElement,
          currentDefinitions, name, initializer, fieldElement);
      computeParameterType(element, fieldElement);
    }
    return element;
  }

  /// A [SendSet] node is an optional parameter with a default value.
  Element visitSendSet(SendSet node) {
    ParameterElementX element;
    if (node.receiver != null) {
      element = createFieldParameter(node, node.arguments.first);
    } else if (node.selector.asIdentifier() != null ||
               node.selector.asFunctionExpression() != null) {
      element = createParameter(getParameterName(node), node.arguments.first);
    }
    Node defaultValue = node.arguments.head;
    if (!defaultValuesAllowed) {
      compiler.reportError(defaultValue, defaultValuesError);
    }
    return element;
  }

  Element visitFunctionExpression(FunctionExpression node) {
    // This is a function typed parameter.
    Modifiers modifiers = currentDefinitions.modifiers;
    if (modifiers.isFinal) {
      compiler.reportError(modifiers,
          MessageKind.FINAL_FUNCTION_TYPE_PARAMETER);
    }
    if (modifiers.isVar) {
      compiler.reportError(modifiers, MessageKind.VAR_FUNCTION_TYPE_PARAMETER);
    }

    return createParameter(node.name, null);
  }

  LinkBuilder<Element> analyzeNodes(Link<Node> link) {
    LinkBuilder<Element> elements = new LinkBuilder<Element>();
    for (; !link.isEmpty; link = link.tail) {
      Element element = link.head.accept(this);
      if (element != null) {
        elements.addLast(element);
      } else {
        // If parameter is null, the current node should be the last,
        // and a list of optional named parameters.
        if (!link.tail.isEmpty || (link.head is !NodeList)) {
          internalError(link.head, "expected optional parameters");
        }
      }
    }
    return elements;
  }

  /**
   * Resolves formal parameters and return type of a [FunctionExpression]
   * to a [FunctionSignature].
   */
  static FunctionSignature analyze(Compiler compiler,
                                   NodeList formalParameters,
                                   Node returnNode,
                                   FunctionTypedElement element,
                                   ResolutionRegistry registry,
                                   {MessageKind defaultValuesError}) {
    SignatureResolver visitor = new SignatureResolver(compiler, element,
        registry, defaultValuesError: defaultValuesError);
    Link<Element> parameters = const Link<Element>();
    int requiredParameterCount = 0;
    if (formalParameters == null) {
      if (!element.isGetter) {
        if (element.isErroneous) {
          // If the element is erroneous, an error should already have been
          // reported. In the case of parse errors, it is possible that there
          // are formal parameters, but something else in the method failed to
          // parse. So we suppress the message about missing formals.
          assert(invariant(element, compiler.compilationFailed));
        } else {
          compiler.reportError(element, MessageKind.MISSING_FORMALS);
        }
      }
    } else {
      if (element.isGetter) {
        if (!identical(formalParameters.endToken.next.stringValue,
                       // TODO(ahe): Remove the check for native keyword.
                       'native')) {
          compiler.reportError(formalParameters,
                               MessageKind.EXTRA_FORMALS);
        }
      }
      LinkBuilder<Element> parametersBuilder =
        visitor.analyzeNodes(formalParameters.nodes);
      requiredParameterCount  = parametersBuilder.length;
      parameters = parametersBuilder.toLink();
    }
    DartType returnType;
    if (element.isFactoryConstructor) {
      returnType = element.enclosingClass.thisType;
      // Because there is no type annotation for the return type of
      // this element, we explicitly add one.
      if (compiler.enableTypeAssertions) {
        registry.registerIsCheck(returnType);
      }
    } else {
      returnType = visitor.resolveReturnType(returnNode);
    }

    if (element.isSetter && (requiredParameterCount != 1 ||
                               visitor.optionalParameterCount != 0)) {
      // If there are no formal parameters, we already reported an error above.
      if (formalParameters != null) {
        compiler.reportError(formalParameters,
                                 MessageKind.ILLEGAL_SETTER_FORMALS);
      }
    }
    LinkBuilder<DartType> parameterTypes = new LinkBuilder<DartType>();
    for (ParameterElement parameter in parameters) {
       parameterTypes.addLast(parameter.type);
    }
    List<DartType> optionalParameterTypes = const <DartType>[];
    List<String> namedParameters = const <String>[];
    List<DartType> namedParameterTypes = const <DartType>[];
    List<Element> orderedOptionalParameters =
        visitor.optionalParameters.toList();
    if (visitor.optionalParametersAreNamed) {
      // TODO(karlklose); replace when [visitor.optinalParameters] is a [List].
      orderedOptionalParameters.sort((Element a, Element b) {
          return a.name.compareTo(b.name);
      });
      LinkBuilder<String> namedParametersBuilder = new LinkBuilder<String>();
      LinkBuilder<DartType> namedParameterTypesBuilder =
          new LinkBuilder<DartType>();
      for (ParameterElement parameter in orderedOptionalParameters) {
        namedParametersBuilder.addLast(parameter.name);
        namedParameterTypesBuilder.addLast(parameter.type);
      }
      namedParameters = namedParametersBuilder.toLink().toList(growable: false);
      namedParameterTypes = namedParameterTypesBuilder.toLink()
          .toList(growable: false);
    } else {
      // TODO(karlklose); replace when [visitor.optinalParameters] is a [List].
      LinkBuilder<DartType> optionalParameterTypesBuilder =
          new LinkBuilder<DartType>();
      for (ParameterElement parameter in visitor.optionalParameters) {
        optionalParameterTypesBuilder.addLast(parameter.type);
      }
      optionalParameterTypes = optionalParameterTypesBuilder.toLink()
          .toList(growable: false);
    }
    FunctionType type = new FunctionType(
        element.declaration,
        returnType,
        parameterTypes.toLink().toList(growable: false),
        optionalParameterTypes,
        namedParameters,
        namedParameterTypes);
    return new FunctionSignatureX(parameters,
                                  visitor.optionalParameters,
                                  requiredParameterCount,
                                  visitor.optionalParameterCount,
                                  visitor.optionalParametersAreNamed,
                                  orderedOptionalParameters,
                                  type);
  }

  DartType resolveTypeAnnotation(TypeAnnotation annotation) {
    DartType type = resolveReturnType(annotation);
    if (type.isVoid) {
      compiler.reportError(annotation, MessageKind.VOID_NOT_ALLOWED);
    }
    return type;
  }

  DartType resolveReturnType(TypeAnnotation annotation) {
    if (annotation == null) return const DynamicType();
    DartType result = resolver.resolveTypeAnnotation(annotation);
    if (result == null) {
      return const DynamicType();
    }
    return result;
  }
}
