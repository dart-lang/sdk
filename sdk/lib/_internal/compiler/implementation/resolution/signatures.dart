// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

/**
 * [SignatureResolver] resolves function signatures.
 */
class SignatureResolver extends MappingVisitor<Element> {
  final Element enclosingElement;
  final Scope scope;
  final MessageKind defaultValuesError;
  Link<Element> optionalParameters = const Link<Element>();
  int optionalParameterCount = 0;
  bool isOptionalParameter = false;
  bool optionalParametersAreNamed = false;
  VariableDefinitions currentDefinitions;

  SignatureResolver(Compiler compiler,
                    Element enclosingElement,
                    TreeElementMapping treeElements,
                    {this.defaultValuesError})
      : this.enclosingElement = enclosingElement,
        this.scope = enclosingElement.buildScope(),
        super(compiler, treeElements);

  bool get defaultValuesAllowed => defaultValuesError == null;

  Element visitNodeList(NodeList node) {
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
    return null;
  }

  Element visitVariableDefinitions(VariableDefinitions node) {
    Link<Node> definitions = node.definitions.nodes;
    if (definitions.isEmpty) {
      cancel(node, 'internal error: no parameter definition');
      return null;
    }
    if (!definitions.tail.isEmpty) {
      cancel(definitions.tail.head, 'internal error: extra definition');
      return null;
    }
    Node definition = definitions.head;
    if (definition is NodeList) {
      cancel(node, 'optional parameters are not implemented');
    }
    if (node.modifiers.isConst()) {
      error(node, MessageKind.FORMAL_DECLARED_CONST);
    }
    if (node.modifiers.isStatic()) {
      error(node, MessageKind.FORMAL_DECLARED_STATIC);
    }

    if (currentDefinitions != null) {
      cancel(node, 'function type parameters not supported');
    }
    currentDefinitions = node;
    Element element = definition.accept(this);
    if (currentDefinitions.metadata != null) {
      compiler.resolver.resolveMetadata(element, node);
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

  void computeParameterType(ParameterElementX element) {
    if (currentDefinitions.type != null) {
      element.type = compiler.resolver.resolveTypeAnnotation(element,
          currentDefinitions.type);
    } else {
      // Is node.definitions exactly one FunctionExpression?
      Link<Node> link = currentDefinitions.definitions.nodes;
      if (!link.isEmpty &&
          link.head.asFunctionExpression() != null &&
          link.tail.isEmpty) {
        FunctionExpression functionExpression = link.head;
        // We found exactly one FunctionExpression
        element.functionSignature = SignatureResolver.analyze(
            compiler, functionExpression.parameters,
            functionExpression.returnType, element, mapping,
            defaultValuesError: MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT);
        element.type =
            compiler.computeFunctionType(element, element.functionSignature);
      } else {
        element.type = compiler.types.dynamicType;
      }
    }
  }

  Element visitIdentifier(Identifier node) {
    return createParameter(node, node);
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
        cancel(node,
            'internal error: unimplemented receiver on parameter send');
        return null;
      }
    }
  }

  // The only valid [Send] can be in constructors and must be of the form
  // [:this.x:] (where [:x:] represents an instance field).
  FieldParameterElementX visitSend(Send node) {
    return createFieldParameter(node);
  }

  ParameterElementX createParameter(Node node, Identifier name) {
    validateName(name);
    ParameterElementX parameter = new ParameterElementX(
        name.source,
        enclosingElement, ElementKind.PARAMETER, currentDefinitions, node);
    computeParameterType(parameter);
    return parameter;
  }

  FieldParameterElementX createFieldParameter(Send node) {
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
      Element fieldElement = currentClass.lookupLocalMember(name.source);
      if (fieldElement == null ||
          !identical(fieldElement.kind, ElementKind.FIELD)) {
        error(node, MessageKind.NOT_A_FIELD, {'fieldName': name});
      } else if (!fieldElement.isInstanceMember()) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, {'fieldName': name});
      }
      element = new FieldParameterElementX(name.source,
          enclosingElement, currentDefinitions, node, fieldElement);
      computeParameterType(element);
    }
    return element;
  }

  /// A [SendSet] node is an optional parameter with a default value.
  Element visitSendSet(SendSet node) {
    ParameterElementX element;
    if (node.receiver != null) {
      element = createFieldParameter(node);
    } else if (node.selector.asIdentifier() != null ||
               node.selector.asFunctionExpression() != null) {
      element = createParameter(node, getParameterName(node));
    }
    Node defaultValue = node.arguments.head;
    if (!defaultValuesAllowed) {
      error(defaultValue, defaultValuesError);
    }
    // Visit the value. The compile time constant handler will
    // make sure it's a compile time constant.
    resolveExpression(defaultValue);
    return element;
  }

  Element visitFunctionExpression(FunctionExpression node) {
    // This is a function typed parameter.
    Modifiers modifiers = currentDefinitions.modifiers;
    if (modifiers.isFinal()) {
      compiler.reportError(modifiers,
          MessageKind.FINAL_FUNCTION_TYPE_PARAMETER);
    }
    if (modifiers.isVar()) {
      compiler.reportError(modifiers, MessageKind.VAR_FUNCTION_TYPE_PARAMETER);
    }

    return createParameter(node, node.name);
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
                                   Element element,
                                   TreeElementMapping mapping,
                                   {MessageKind defaultValuesError}) {
    SignatureResolver visitor = new SignatureResolver(compiler, element,
        mapping, defaultValuesError: defaultValuesError);
    Link<Element> parameters = const Link<Element>();
    int requiredParameterCount = 0;
    if (formalParameters == null) {
      if (!element.isGetter()) {
        compiler.reportError(element, MessageKind.MISSING_FORMALS);
      }
    } else {
      if (element.isGetter()) {
        if (!identical(formalParameters.getEndToken().next.stringValue,
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
    if (element.isFactoryConstructor()) {
      returnType = element.getEnclosingClass().computeType(compiler);
      // Because there is no type annotation for the return type of
      // this element, we explicitly add one.
      if (compiler.enableTypeAssertions) {
        compiler.enqueuer.resolution.registerIsCheck(
            returnType, new TreeElementMapping(element));
      }
    } else {
      returnType = compiler.resolver.resolveReturnType(element, returnNode);
    }

    if (element.isSetter() && (requiredParameterCount != 1 ||
                               visitor.optionalParameterCount != 0)) {
      // If there are no formal parameters, we already reported an error above.
      if (formalParameters != null) {
        compiler.reportError(formalParameters,
                                 MessageKind.ILLEGAL_SETTER_FORMALS);
      }
    }
    return new FunctionSignatureX(parameters,
                                  visitor.optionalParameters,
                                  requiredParameterCount,
                                  visitor.optionalParameterCount,
                                  visitor.optionalParametersAreNamed,
                                  returnType);
  }

  // TODO(ahe): This is temporary.
  void resolveExpression(Node node) {
    if (node == null) return;
    node.accept(new ResolverVisitor(compiler, enclosingElement, mapping));
  }

  // TODO(ahe): This is temporary.
  ClassElement get currentClass {
    return enclosingElement.isMember()
      ? enclosingElement.getEnclosingClass() : null;
  }
}
