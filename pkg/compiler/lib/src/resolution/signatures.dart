// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.signatures;

import '../common.dart';
import '../common/resolution.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../elements/entities.dart' show AsyncMarker;
import '../elements/modelx.dart'
    show
        ErroneousFieldElementX,
        ErroneousInitializingFormalElementX,
        FormalElementX,
        FunctionSignatureX,
        InitializingFormalElementX,
        LocalParameterElementX,
        TypeVariableElementX;
import '../elements/names.dart';
import '../tree/tree.dart';
import '../util/util.dart' show Link, LinkBuilder;
import 'members.dart' show ResolverVisitor;
import 'registry.dart' show ResolutionRegistry;
import 'resolution_common.dart' show MappingVisitor;
import 'scope.dart' show Scope, TypeVariablesScope;

/**
 * [SignatureResolver] resolves function signatures.
 */
class SignatureResolver extends MappingVisitor<FormalElementX> {
  final ResolverVisitor resolver;
  final FunctionTypedElement enclosingElement;
  final Scope scope;
  final MessageKind defaultValuesError;
  final bool createRealParameters;
  List<Element> optionalParameters = const <Element>[];
  int optionalParameterCount = 0;
  bool isOptionalParameter = false;
  bool optionalParametersAreNamed = false;
  VariableDefinitions currentDefinitions;

  SignatureResolver(
      Resolution resolution,
      FunctionTypedElement enclosingElement,
      Scope scope,
      ResolutionRegistry registry,
      {this.defaultValuesError,
      this.createRealParameters})
      : this.scope = scope,
        this.enclosingElement = enclosingElement,
        this.resolver = new ResolverVisitor(
            resolution, enclosingElement, registry,
            scope: scope),
        super(resolution, registry);

  bool get defaultValuesAllowed => defaultValuesError == null;

  visitNodeList(NodeList node) {
    // This must be a list of optional arguments.
    String value = node.beginToken.stringValue;
    if ((!identical(value, '[')) && (!identical(value, '{'))) {
      reporter.internalError(node, "expected optional parameters");
    }
    optionalParametersAreNamed = (identical(value, '{'));
    isOptionalParameter = true;
    LinkBuilder<Element> elements = analyzeNodes(node.nodes);
    optionalParameterCount = elements.length;
    optionalParameters = elements.toList();
  }

  FormalElementX visitVariableDefinitions(VariableDefinitions node) {
    Link<Node> definitions = node.definitions.nodes;
    if (definitions.isEmpty) {
      reporter.internalError(node, 'no parameter definition');
      return null;
    }
    if (!definitions.tail.isEmpty) {
      reporter.internalError(definitions.tail.head, 'extra definition');
      return null;
    }
    Node definition = definitions.head;
    if (definition is NodeList) {
      reporter.internalError(node, 'optional parameters are not implemented');
    }
    if (node.modifiers.isConst) {
      reporter.reportErrorMessage(node, MessageKind.FORMAL_DECLARED_CONST);
    }
    if (node.modifiers.isStatic) {
      reporter.reportErrorMessage(node, MessageKind.FORMAL_DECLARED_STATIC);
    }

    if (currentDefinitions != null) {
      reporter.internalError(node, 'function type parameters not supported');
    }
    currentDefinitions = node;
    FormalElementX element = definition == null
        ? createUnnamedParameter() // This happens in function types.
        : definition.accept(this);
    if (currentDefinitions.metadata != null) {
      element.metadataInternal =
          resolution.resolver.resolveMetadata(element, node);
    }
    currentDefinitions = null;
    return element;
  }

  void validateName(Identifier node) {
    if (isOptionalParameter &&
        optionalParametersAreNamed &&
        Name.isPrivateName(node.source)) {
      reporter.reportErrorMessage(node, MessageKind.PRIVATE_NAMED_PARAMETER);
    }
  }

  void computeParameterType(FormalElementX element,
      [VariableElement fieldElement]) {
    // Function-type as in `foo(int bar(String x))`
    void computeInlineFunctionType(FunctionExpression functionExpression) {
      FunctionSignature functionSignature = SignatureResolver.analyze(
          resolution,
          scope,
          functionExpression.typeVariables,
          functionExpression.parameters,
          functionExpression.returnType,
          element,
          registry,
          defaultValuesError: MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT);
      element.functionSignature = functionSignature;
    }

    if (currentDefinitions.type != null) {
      element.typeCache = resolveTypeAnnotation(currentDefinitions.type);
    } else {
      // Is node.definitions exactly one FunctionExpression?
      Link<Node> link = currentDefinitions.definitions.nodes;
      assert(!link.isEmpty, failedAt(currentDefinitions));
      assert(link.tail.isEmpty, failedAt(currentDefinitions));
      if (link.head.asFunctionExpression() != null) {
        // Inline function typed parameter, like `void m(int f(String s))`.
        computeInlineFunctionType(link.head);
      } else if (link.head.asSend() != null &&
          link.head.asSend().selector.asFunctionExpression() != null) {
        // Inline function typed initializing formal or
        // parameter with default value, like `C(int this.f(String s))` or
        // `void m([int f(String s) = null])`.
        computeInlineFunctionType(
            link.head.asSend().selector.asFunctionExpression());
      } else {
        assert(link.head.asIdentifier() != null || link.head.asSend() != null,
            failedAt(currentDefinitions));
        if (fieldElement != null) {
          element.typeCache = fieldElement.computeType(resolution);
        } else {
          element.typeCache = const ResolutionDynamicType();
        }
      }
    }
  }

  FormalElementX visitIdentifier(Identifier node) {
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
        reporter.internalError(
            node, 'internal error: unimplemented receiver on parameter send');
        return null;
      }
    }
  }

  // The only valid [Send] can be in constructors and must be of the form
  // [:this.x:] (where [:x:] represents an instance field).
  InitializingFormalElementX visitSend(Send node) {
    return createFieldParameter(node, null);
  }

  FormalElementX createParameter(Identifier name, Expression initializer) {
    validateName(name);
    FormalElementX parameter;
    if (createRealParameters) {
      parameter = new LocalParameterElementX(
          enclosingElement, currentDefinitions, name, initializer,
          isOptional: isOptionalParameter, isNamed: optionalParametersAreNamed);
    } else {
      parameter = new FormalElementX(
          ElementKind.PARAMETER, enclosingElement, currentDefinitions, name);
    }
    computeParameterType(parameter);
    return parameter;
  }

  FormalElementX createUnnamedParameter() {
    FormalElementX parameter;
    assert(!createRealParameters);
    parameter = new FormalElementX.unnamed(
        ElementKind.PARAMETER, enclosingElement, currentDefinitions);
    computeParameterType(parameter);
    return parameter;
  }

  InitializingFormalElementX createFieldParameter(
      Send node, Expression initializer) {
    InitializingFormalElementX element;
    Identifier receiver = node.receiver.asIdentifier();
    if (receiver == null || !receiver.isThis()) {
      reporter.reportErrorMessage(node, MessageKind.INVALID_PARAMETER);
      return new ErroneousInitializingFormalElementX(
          getParameterName(node), enclosingElement);
    } else {
      if (!enclosingElement.isGenerativeConstructor) {
        reporter.reportErrorMessage(
            node, MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED);
        return new ErroneousInitializingFormalElementX(
            getParameterName(node), enclosingElement);
      }
      Identifier name = getParameterName(node);
      validateName(name);
      Element fieldElement =
          enclosingElement.enclosingClass.lookupLocalMember(name.source);
      if (fieldElement == null ||
          !identical(fieldElement.kind, ElementKind.FIELD)) {
        reporter.reportErrorMessage(
            node, MessageKind.NOT_A_FIELD, {'fieldName': name});
        fieldElement =
            new ErroneousFieldElementX(name, enclosingElement.enclosingClass);
      } else if (!fieldElement.isInstanceMember) {
        reporter.reportErrorMessage(
            node, MessageKind.NOT_INSTANCE_FIELD, {'fieldName': name});
        fieldElement =
            new ErroneousFieldElementX(name, enclosingElement.enclosingClass);
      }
      element = new InitializingFormalElementX(
          enclosingElement, currentDefinitions, name, initializer, fieldElement,
          isOptional: isOptionalParameter, isNamed: optionalParametersAreNamed);
      computeParameterType(element, fieldElement);
    }
    return element;
  }

  /// A [SendSet] node is an optional parameter with a default value.
  Element visitSendSet(SendSet node) {
    FormalElementX element;
    if (node.receiver != null) {
      element = createFieldParameter(node, node.arguments.first);
    } else if (node.selector.asIdentifier() != null ||
        node.selector.asFunctionExpression() != null) {
      element = createParameter(getParameterName(node), node.arguments.first);
    }
    Node defaultValue = node.arguments.head;
    if (!defaultValuesAllowed) {
      reporter.reportErrorMessage(defaultValue, defaultValuesError);
    }
    return element;
  }

  Element visitFunctionExpression(FunctionExpression node) {
    // This is a function typed parameter.
    Modifiers modifiers = currentDefinitions.modifiers;
    if (modifiers.isFinal) {
      reporter.reportErrorMessage(
          modifiers, MessageKind.FINAL_FUNCTION_TYPE_PARAMETER);
    }
    if (modifiers.isVar) {
      reporter.reportErrorMessage(
          modifiers, MessageKind.VAR_FUNCTION_TYPE_PARAMETER);
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
        if (!link.tail.isEmpty || (link.head is! NodeList)) {
          reporter.internalError(link.head, "expected optional parameters");
        }
      }
    }
    return elements;
  }

  /**
   * Resolves formal parameters and return type of a [FunctionExpression]
   * to a [FunctionSignature].
   *
   * If [createRealParameters] is `true`, the parameters will be
   * real parameters implementing the [ParameterElement] interface. Otherwise,
   * the parameters will only implement [FormalElement].
   */
  static FunctionSignature analyze(
      Resolution resolution,
      Scope scope,
      NodeList typeVariables,
      NodeList formalParameters,
      Node returnNode,
      FunctionTypedElement element,
      ResolutionRegistry registry,
      {MessageKind defaultValuesError,
      bool createRealParameters: false,
      bool isFunctionExpression: false}) {
    DiagnosticReporter reporter = resolution.reporter;

    List<ResolutionDartType> createTypeVariables(NodeList typeVariableNodes) {
      if (element.isPatch) {
        FunctionTypedElement origin = element.origin;
        origin.computeType(resolution);
        return origin.typeVariables;
      }
      if (typeVariableNodes == null) return const <ResolutionDartType>[];

      // Create the types and elements corresponding to [typeVariableNodes].
      Link<Node> nodes = typeVariableNodes.nodes;
      List<ResolutionDartType> arguments =
          new List.generate(nodes.slowLength(), (int index) {
        TypeVariable node = nodes.head;
        String variableName = node.name.source;
        nodes = nodes.tail;
        TypeVariableElementX variableElement =
            new TypeVariableElementX(variableName, element, index, node);
        // GENERIC_METHODS: When method type variables are implemented fully we
        // must resolve the actual bounds; currently we just claim that
        // every method type variable has upper bound [dynamic].
        variableElement.boundCache = const ResolutionDynamicType();
        ResolutionTypeVariableType variableType =
            new MethodTypeVariableType(variableElement);
        variableElement.typeCache = variableType;
        return variableType;
      }, growable: false);
      return arguments;
    }

    List<ResolutionDartType> typeVariableTypes =
        createTypeVariables(typeVariables);
    scope = new FunctionSignatureBuildingScope(scope, typeVariableTypes);
    SignatureResolver visitor = new SignatureResolver(
        resolution, element, scope, registry,
        defaultValuesError: defaultValuesError,
        createRealParameters: createRealParameters);
    List<Element> parameters = const <Element>[];
    int requiredParameterCount = 0;
    if (formalParameters == null) {
      if (!element.isGetter) {
        if (element.isMalformed) {
          // If the element is erroneous, an error should already have been
          // reported. In the case of parse errors, it is possible that there
          // are formal parameters, but something else in the method failed to
          // parse. So we suppress the message about missing formals.
          assert(reporter.hasReportedError, failedAt(element));
        } else {
          reporter.reportErrorMessage(element, MessageKind.MISSING_FORMALS);
        }
      }
    } else {
      if (element.isGetter) {
        if (!identical(
            formalParameters.endToken.next.stringValue,
            // TODO(ahe): Remove the check for native keyword.
            'native')) {
          reporter.reportErrorMessage(
              formalParameters, MessageKind.EXTRA_FORMALS);
        }
      }
      LinkBuilder<Element> parametersBuilder =
          visitor.analyzeNodes(formalParameters.nodes);
      requiredParameterCount = parametersBuilder.length;
      parameters = parametersBuilder.toList();
    }
    ResolutionDartType returnType;
    if (element.isFactoryConstructor) {
      returnType = element.enclosingClass.thisType;
      // Because there is no type annotation for the return type of
      // this element, we explicitly add one.
      registry.registerCheckedModeCheck(returnType);
    } else {
      AsyncMarker asyncMarker = AsyncMarker.SYNC;
      if (isFunctionExpression) {
        // Use async marker to determine the return type of function
        // expressions.
        FunctionElement function = element;
        asyncMarker = function.asyncMarker;
      }
      switch (asyncMarker) {
        case AsyncMarker.SYNC:
          returnType = visitor.resolveReturnType(returnNode);
          break;
        case AsyncMarker.SYNC_STAR:
          ResolutionInterfaceType iterableType =
              resolution.commonElements.iterableType();
          returnType = iterableType;
          break;
        case AsyncMarker.ASYNC:
          ResolutionInterfaceType futureType =
              resolution.commonElements.futureType();
          returnType = futureType;
          break;
        case AsyncMarker.ASYNC_STAR:
          ResolutionInterfaceType streamType =
              resolution.commonElements.streamType();
          returnType = streamType;
          break;
      }
    }

    if (element.isSetter &&
        (requiredParameterCount != 1 || visitor.optionalParameterCount != 0)) {
      // If there are no formal parameters, we already reported an error above.
      if (formalParameters != null) {
        reporter.reportErrorMessage(
            formalParameters, MessageKind.ILLEGAL_SETTER_FORMALS);
      }
    }
    LinkBuilder<ResolutionDartType> parameterTypes =
        new LinkBuilder<ResolutionDartType>();
    for (FormalElement parameter in parameters) {
      parameterTypes.addLast(parameter.type);
    }
    List<ResolutionDartType> optionalParameterTypes =
        const <ResolutionDartType>[];
    List<String> namedParameters = const <String>[];
    List<ResolutionDartType> namedParameterTypes = const <ResolutionDartType>[];
    List<Element> orderedOptionalParameters =
        visitor.optionalParameters.toList();
    if (visitor.optionalParametersAreNamed) {
      // TODO(karlklose); replace when [visitor.optionalParameters] is a [List].
      orderedOptionalParameters.sort((Element a, Element b) {
        return a.name.compareTo(b.name);
      });
      LinkBuilder<String> namedParametersBuilder = new LinkBuilder<String>();
      LinkBuilder<ResolutionDartType> namedParameterTypesBuilder =
          new LinkBuilder<ResolutionDartType>();
      for (FormalElement parameter in orderedOptionalParameters) {
        namedParametersBuilder.addLast(parameter.name);
        namedParameterTypesBuilder.addLast(parameter.type);
      }
      namedParameters = namedParametersBuilder.toLink().toList(growable: false);
      namedParameterTypes =
          namedParameterTypesBuilder.toLink().toList(growable: false);
    } else {
      // TODO(karlklose); replace when [visitor.optionalParameters] is a [List].
      LinkBuilder<ResolutionDartType> optionalParameterTypesBuilder =
          new LinkBuilder<ResolutionDartType>();
      for (FormalElement parameter in visitor.optionalParameters) {
        optionalParameterTypesBuilder.addLast(parameter.type);
      }
      optionalParameterTypes =
          optionalParameterTypesBuilder.toLink().toList(growable: false);
    }
    ResolutionFunctionType type = new ResolutionFunctionType(
        element.declaration,
        returnType,
        parameterTypes.toLink().toList(growable: false),
        optionalParameterTypes,
        namedParameters,
        namedParameterTypes);
    return new FunctionSignatureX(
        typeVariables: typeVariableTypes,
        requiredParameters: parameters,
        optionalParameters: visitor.optionalParameters,
        requiredParameterCount: requiredParameterCount,
        optionalParameterCount: visitor.optionalParameterCount,
        optionalParametersAreNamed: visitor.optionalParametersAreNamed,
        orderedOptionalParameters: orderedOptionalParameters,
        type: type);
  }

  ResolutionDartType resolveTypeAnnotation(TypeAnnotation annotation) {
    ResolutionDartType type = resolveReturnType(annotation);
    if (type.isVoid) {
      reporter.reportErrorMessage(annotation, MessageKind.VOID_NOT_ALLOWED);
    }
    return type;
  }

  ResolutionDartType resolveReturnType(TypeAnnotation annotation) {
    if (annotation == null) return const ResolutionDynamicType();
    ResolutionDartType result = resolver.resolveTypeAnnotation(annotation);
    if (result == null) {
      return const ResolutionDynamicType();
    }
    return result;
  }
}

/// Used during `SignatureResolver.analyze` to provide access to the type
/// variables of the function signature itself when its signature is analyzed.
class FunctionSignatureBuildingScope extends TypeVariablesScope {
  @override
  final List<ResolutionDartType> typeVariables;

  FunctionSignatureBuildingScope(Scope parent, this.typeVariables)
      : super(parent);

  String toString() => 'FunctionSignatureBuildingScope($typeVariables)';
}
