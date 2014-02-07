// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

/**
 * [SignatureResolver] resolves function signatures.
 */
class SignatureResolver extends CommonResolverVisitor<Element> {
  final Element enclosingElement;
  final MessageKind defaultValuesError;
  Link<Element> optionalParameters = const Link<Element>();
  int optionalParameterCount = 0;
  bool isOptionalParameter = false;
  bool optionalParametersAreNamed = false;
  VariableDefinitions currentDefinitions;

  SignatureResolver(Compiler compiler,
                    this.enclosingElement,
                    {this.defaultValuesError})
      : super(compiler);

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
      // TODO(johnniwinther): Unify handling of metadata on locals/formals.
      for (Link<Node> link = currentDefinitions.metadata.nodes;
           !link.isEmpty;
           link = link.tail) {
        ParameterMetadataAnnotation metadata =
            new ParameterMetadataAnnotation(link.head);
        element.addMetadata(metadata);
        metadata.ensureResolved(compiler);
      }
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

  Element visitIdentifier(Identifier node) {
    validateName(node);
    Element variables = new VariableListElementX.node(currentDefinitions,
        ElementKind.VARIABLE_LIST, enclosingElement);
    // Ensure a parameter is not typed 'void'.
    variables.computeType(compiler);
    return new VariableElementX(node.source, variables,
        ElementKind.PARAMETER, node);
  }

  String getParameterName(Send node) {
    var identifier = node.selector.asIdentifier();
    if (identifier != null) {
      // Normal parameter: [:Type name:].
      validateName(identifier);
      return identifier.source;
    } else {
      // Function type parameter: [:void name(DartType arg):].
      var functionExpression = node.selector.asFunctionExpression();
      if (functionExpression != null &&
          functionExpression.name.asIdentifier() != null) {
        validateName(functionExpression.name);
        return functionExpression.name.asIdentifier().source;
      } else {
        cancel(node,
            'internal error: unimplemented receiver on parameter send');
      }
    }
  }

  // The only valid [Send] can be in constructors and must be of the form
  // [:this.x:] (where [:x:] represents an instance field).
  FieldParameterElement visitSend(Send node) {
    FieldParameterElement element;
    if (node.receiver.asIdentifier() == null ||
        !node.receiver.asIdentifier().isThis()) {
      error(node, MessageKind.INVALID_PARAMETER);
    } else if (!identical(enclosingElement.kind,
                          ElementKind.GENERATIVE_CONSTRUCTOR)) {
      error(node, MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED);
    } else {
      String name = getParameterName(node);
      Element fieldElement = currentClass.lookupLocalMember(name);
      if (fieldElement == null ||
          !identical(fieldElement.kind, ElementKind.FIELD)) {
        error(node, MessageKind.NOT_A_FIELD, {'fieldName': name});
      } else if (!fieldElement.isInstanceMember()) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, {'fieldName': name});
      }
      Element variables = new VariableListElementX.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      element = new FieldParameterElementX(name, fieldElement, variables, node);
    }
    return element;
  }

  /// A [SendSet] node is an optional parameter with a default value.
  Element visitSendSet(SendSet node) {
    Element element;
    if (node.receiver != null) {
      element = visitSend(node);
    } else if (node.selector.asIdentifier() != null ||
               node.selector.asFunctionExpression() != null) {
      Element variables = new VariableListElementX.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      Identifier identifier = node.selector.asIdentifier() != null ?
          node.selector.asIdentifier() :
          node.selector.asFunctionExpression().name.asIdentifier();
      validateName(identifier);
      String source = identifier.source;
      element = new VariableElementX(source, variables,
          ElementKind.PARAMETER, node);
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

    Element variable = visit(node.name);
    SignatureResolver.analyze(compiler, node.parameters, node.returnType,
        variable,
        defaultValuesError: MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT);
    // TODO(ahe): Resolve and record the function type in the correct
    // [TreeElements].
    return variable;
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
   * Resolves formal parameters and return type to a [FunctionSignature].
   */
  static FunctionSignature analyze(Compiler compiler,
                                   NodeList formalParameters,
                                   Node returnNode,
                                   Element element,
                                   {MessageKind defaultValuesError}) {
    SignatureResolver visitor = new SignatureResolver(compiler, element,
        defaultValuesError: defaultValuesError);
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
      returnType = compiler.resolveReturnType(element, returnNode);
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
    node.accept(new ResolverVisitor(compiler, enclosingElement,
                                    new TreeElementMapping(enclosingElement)));
  }

  // TODO(ahe): This is temporary.
  ClassElement get currentClass {
    return enclosingElement.isMember()
      ? enclosingElement.getEnclosingClass() : null;
  }
}
