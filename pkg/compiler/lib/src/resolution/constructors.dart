// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.constructors;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../constants/constructors.dart'
    show
        GenerativeConstantConstructor,
        RedirectingGenerativeConstantConstructor;
import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart'
    show
        ConstructorElementX,
        ErroneousConstructorElementX,
        ErroneousElementX,
        ErroneousFieldElementX,
        FieldElementX,
        InitializingFormalElementX,
        ParameterElementX;
import '../elements/names.dart';
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/feature.dart' show Feature;
import '../universe/use.dart' show StaticUse;
import '../util/util.dart' show Link;
import 'members.dart' show lookupInScope, ResolverVisitor;
import 'registry.dart' show ResolutionRegistry;
import 'resolution_common.dart' show CommonResolverVisitor;
import 'resolution_result.dart';
import 'scope.dart' show Scope, ExtensionScope;

class InitializerResolver {
  final ResolverVisitor visitor;
  final ConstructorElementX constructor;
  final FunctionExpression functionNode;
  final Map<FieldElement, Node> initialized = <FieldElement, Node>{};
  final Map<FieldElement, ConstantExpression> fieldInitializers =
      <FieldElement, ConstantExpression>{};
  Link<Node> initializers;
  bool hasSuper = false;
  bool isValidAsConstant = true;

  bool get isConst => constructor.isConst;

  InitializerResolver(this.visitor, this.constructor, this.functionNode);

  ResolutionRegistry get registry => visitor.registry;

  DiagnosticReporter get reporter => visitor.reporter;

  bool isFieldInitializer(SendSet node) {
    if (node.selector.asIdentifier() == null) return false;
    if (node.receiver == null) return true;
    if (node.receiver.asIdentifier() == null) return false;
    return node.receiver.asIdentifier().isThis();
  }

  reportDuplicateInitializerError(
      Element field, Node init, Spannable existing) {
    reporter.reportError(
        reporter.createMessage(
            init, MessageKind.DUPLICATE_INITIALIZER, {'fieldName': field.name}),
        <DiagnosticMessage>[
          reporter.createMessage(existing, MessageKind.ALREADY_INITIALIZED,
              {'fieldName': field.name}),
        ]);
    isValidAsConstant = false;
  }

  void checkForDuplicateInitializers(FieldElementX field, Node init) {
    // [field] can be null if it could not be resolved.
    if (field == null) return;
    if (initialized.containsKey(field)) {
      reportDuplicateInitializerError(field, init, initialized[field]);
    } else if (field.isFinal) {
      field.parseNode(visitor.resolution.parsingContext);
      Expression initializer = field.initializer;
      if (initializer != null) {
        reportDuplicateInitializerError(
            field,
            init,
            reporter.withCurrentElement(
                field, () => reporter.spanFromSpannable(initializer)));
      }
    }
    initialized[field] = init;
  }

  void resolveFieldInitializer(SendSet init) {
    // init is of the form [this.]field = value.
    final Node selector = init.selector;
    final String name = selector.asIdentifier().source;
    // Lookup target field.
    Element target;
    FieldElement field;
    if (isFieldInitializer(init)) {
      // Use [enclosingElement] instead of [enclosingClass] to ensure lookup in
      // patch class when necessary.
      ClassElement cls = constructor.enclosingElement;
      target = cls.lookupLocalMember(name);
      if (target == null) {
        reporter.reportErrorMessage(
            selector, MessageKind.CANNOT_RESOLVE, {'name': name});
        target = new ErroneousFieldElementX(
            selector.asIdentifier(), constructor.enclosingClass);
      } else if (target.kind != ElementKind.FIELD) {
        reporter.reportErrorMessage(
            selector, MessageKind.NOT_A_FIELD, {'fieldName': name});
        target = new ErroneousFieldElementX(
            selector.asIdentifier(), constructor.enclosingClass);
      } else if (!target.isInstanceMember) {
        reporter.reportErrorMessage(
            selector, MessageKind.INIT_STATIC_FIELD, {'fieldName': name});
      } else {
        field = target;
      }
    } else {
      reporter.reportErrorMessage(
          init, MessageKind.INVALID_RECEIVER_IN_INITIALIZER);
    }
    if (target != null) {
      registry.useElement(init, target);
      checkForDuplicateInitializers(target, init);
    }
    if (field != null) {
      registry.registerStaticUse(new StaticUse.fieldInit(field));
    }
    // Resolve initializing value.
    ResolutionResult result = visitor.visitInStaticContext(init.arguments.head,
        inConstantInitializer: isConst);
    if (isConst) {
      if (result.isConstant && field != null) {
        // TODO(johnniwinther): Report error if `result.constant` is `null`.
        fieldInitializers[field] = result.constant;
      } else {
        isValidAsConstant = false;
      }
    }
  }

  ResolutionInterfaceType getSuperOrThisLookupTarget(Node diagnosticNode,
      {bool isSuperCall}) {
    if (isSuperCall) {
      // Calculate correct lookup target and constructor name.
      if (constructor.enclosingClass.isObject) {
        reporter.reportErrorMessage(
            diagnosticNode, MessageKind.SUPER_INITIALIZER_IN_OBJECT);
        isValidAsConstant = false;
      } else {
        return constructor.enclosingClass.supertype;
      }
    }
    return constructor.enclosingClass.thisType;
  }

  ResolutionResult resolveSuperOrThisForSend(Send node) {
    // Resolve the selector and the arguments.
    ArgumentsResult argumentsResult = visitor.inStaticContext(() {
      // TODO(johnniwinther): Remove this when [SendStructure] is used directly.
      visitor.resolveSelector(node, null);
      return visitor.resolveArguments(node.argumentsNode);
    }, inConstantInitializer: isConst);

    bool isSuperCall = Initializers.isSuperConstructorCall(node);
    ResolutionInterfaceType targetType =
        getSuperOrThisLookupTarget(node, isSuperCall: isSuperCall);
    ClassElement lookupTarget = targetType.element;
    String constructorName =
        visitor.getRedirectingThisOrSuperConstructorName(node).text;
    ConstructorElement foundConstructor =
        findConstructor(constructor.library, lookupTarget, constructorName);

    final String className = lookupTarget.name;
    CallStructure callStructure = argumentsResult.callStructure;
    ConstructorElement calledConstructor = verifyThatConstructorMatchesCall(
        node, foundConstructor, callStructure, className,
        constructorName: constructorName,
        isThisCall: !isSuperCall,
        isImplicitSuperCall: false);
    // TODO(johnniwinther): Remove this when information is pulled from an
    // [InitializerStructure].
    registry.useElement(node, calledConstructor);
    if (!calledConstructor.isError) {
      registry.registerStaticUse(new StaticUse.superConstructorInvoke(
          calledConstructor, callStructure));
    }
    if (isConst) {
      if (isValidAsConstant &&
          calledConstructor.isConst &&
          argumentsResult.isValidAsConstant) {
        List<ConstantExpression> arguments = argumentsResult.constantArguments;
        return new ConstantResult(
            node,
            new ConstructedConstantExpression(
                targetType, calledConstructor, callStructure, arguments),
            element: calledConstructor);
      } else {
        isValidAsConstant = false;
      }
    }
    return new ResolutionResult.forElement(calledConstructor);
  }

  ConstructedConstantExpression resolveImplicitSuperConstructorSend() {
    // If the class has a super resolve the implicit super call.
    ClassElement classElement = constructor.enclosingClass;
    ClassElement superClass = classElement.superclass;
    if (!classElement.isObject) {
      assert(superClass != null);
      assert(superClass.isResolved);

      ResolutionInterfaceType targetType =
          getSuperOrThisLookupTarget(functionNode, isSuperCall: true);
      ClassElement lookupTarget = targetType.element;
      ConstructorElement calledConstructor =
          findConstructor(constructor.library, lookupTarget, '');

      final String className = lookupTarget.name;
      CallStructure callStructure = CallStructure.NO_ARGS;
      ConstructorElement result = verifyThatConstructorMatchesCall(
          functionNode, calledConstructor, callStructure, className,
          isImplicitSuperCall: true);
      if (!result.isError) {
        registry.registerStaticUse(new StaticUse.superConstructorInvoke(
            calledConstructor, callStructure));
      }

      if (isConst && isValidAsConstant) {
        return new ConstructedConstantExpression(targetType, result,
            CallStructure.NO_ARGS, const <ConstantExpression>[]);
      }
    }
    return null;
  }

  ConstructorElement reportAndCreateErroneousConstructor(
      Spannable diagnosticNode, String name, MessageKind kind, Map arguments) {
    isValidAsConstant = false;
    reporter.reportErrorMessage(diagnosticNode, kind, arguments);
    return new ErroneousConstructorElementX(
        kind, arguments, name, visitor.currentClass);
  }

  /// Checks that [lookedupConstructor] is valid as a target for the super/this
  /// constructor call using with the given [callStructure].
  ///
  /// If [lookedupConstructor] is valid it is returned, otherwise an error is
  /// reported and an [ErroneousConstructorElement] is returned.
  ConstructorElement verifyThatConstructorMatchesCall(
      Node node,
      ConstructorElement lookedupConstructor,
      CallStructure callStructure,
      String className,
      {String constructorName: '',
      bool isImplicitSuperCall: false,
      bool isThisCall: false}) {
    Element result = lookedupConstructor;
    if (lookedupConstructor == null) {
      String fullConstructorName =
          Elements.constructorNameForDiagnostics(className, constructorName);
      MessageKind kind = isImplicitSuperCall
          ? MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT
          : MessageKind.CANNOT_RESOLVE_CONSTRUCTOR;
      result = reportAndCreateErroneousConstructor(node, constructorName, kind,
          {'constructorName': fullConstructorName});
    } else if (!lookedupConstructor.isGenerativeConstructor) {
      MessageKind kind = isThisCall
          ? MessageKind.THIS_CALL_TO_FACTORY
          : MessageKind.SUPER_CALL_TO_FACTORY;
      result =
          reportAndCreateErroneousConstructor(node, constructorName, kind, {});
    } else {
      lookedupConstructor.computeType(visitor.resolution);
      if (!callStructure
          .signatureApplies(lookedupConstructor.parameterStructure)) {
        MessageKind kind = isImplicitSuperCall
            ? MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT
            : MessageKind.NO_MATCHING_CONSTRUCTOR;
        result = reportAndCreateErroneousConstructor(
            node, constructorName, kind, {});
      } else if (constructor.isConst && !lookedupConstructor.isConst) {
        MessageKind kind = isImplicitSuperCall
            ? MessageKind.CONST_CALLS_NON_CONST_FOR_IMPLICIT
            : MessageKind.CONST_CALLS_NON_CONST;
        result = reportAndCreateErroneousConstructor(
            node, constructorName, kind, {});
      }
    }
    return result;
  }

  /**
   * Resolve all initializers of this constructor. In the case of a redirecting
   * constructor, the resolved constructor's function element is returned.
   */
  ConstructorElement resolveInitializers() {
    Map<dynamic /*String|int*/, ConstantExpression> defaultValues =
        <dynamic /*String|int*/, ConstantExpression>{};
    ConstructedConstantExpression constructorInvocation;
    // Keep track of all "this.param" parameters specified for constructor so
    // that we can ensure that fields are initialized only once.
    FunctionSignature functionParameters = constructor.functionSignature;
    Scope oldScope = visitor.scope;
    // In order to get the correct detection of name clashes between all
    // parameters (regular ones and initializing formals) we must extend
    // the parameter scope rather than adding a new nested scope.
    visitor.scope = new ExtensionScope(visitor.scope);
    Link<Node> parameterNodes = (functionNode.parameters == null)
        ? const Link<Node>()
        : functionNode.parameters.nodes;
    functionParameters.forEachParameter((ParameterElementX element) {
      List<Element> optionals = functionParameters.optionalParameters;
      if (!optionals.isEmpty && element == optionals.first) {
        NodeList nodes = parameterNodes.head;
        parameterNodes = nodes.nodes;
      }
      if (isConst) {
        if (element.isOptional) {
          if (element.constantCache == null) {
            // TODO(johnniwinther): Remove this when all constant expressions
            // can be computed during resolution.
            isValidAsConstant = false;
          } else {
            ConstantExpression defaultValue = element.constant;
            if (defaultValue != null) {
              if (element.isNamed) {
                defaultValues[element.name] = defaultValue;
              } else {
                int index =
                    element.functionDeclaration.parameters.indexOf(element);
                defaultValues[index] = defaultValue;
              }
            } else {
              isValidAsConstant = false;
            }
          }
        }
      }
      if (element.isInitializingFormal) {
        VariableDefinitions variableDefinitions = parameterNodes.head;
        Node parameterNode = variableDefinitions.definitions.nodes.head;
        InitializingFormalElementX initializingFormal = element;
        FieldElement field = initializingFormal.fieldElement;
        if (!field.isMalformed) {
          registry.registerStaticUse(new StaticUse.fieldInit(field));
        }
        checkForDuplicateInitializers(field, parameterNode);
        visitor.defineLocalVariable(parameterNode, initializingFormal);
        visitor.addToScope(initializingFormal);
        if (isConst) {
          if (element.isNamed) {
            fieldInitializers[field] = new NamedArgumentReference(element.name);
          } else {
            int index = element.functionDeclaration.parameters.indexOf(element);
            fieldInitializers[field] = new PositionalArgumentReference(index);
          }
        } else {
          isValidAsConstant = false;
        }
      }
      parameterNodes = parameterNodes.tail;
    });

    if (functionNode.initializers == null) {
      initializers = const Link<Node>();
    } else {
      initializers = functionNode.initializers.nodes;
    }
    bool resolvedSuper = false;
    for (Link<Node> link = initializers; !link.isEmpty; link = link.tail) {
      if (link.head.asSendSet() != null) {
        final SendSet init = link.head.asSendSet();
        resolveFieldInitializer(init);
      } else if (link.head.asSend() != null) {
        final Send call = link.head.asSend();
        if (call.argumentsNode == null) {
          reporter.reportErrorMessage(
              link.head, MessageKind.INVALID_INITIALIZER);
          continue;
        }
        if (Initializers.isSuperConstructorCall(call)) {
          if (resolvedSuper) {
            reporter.reportErrorMessage(
                call, MessageKind.DUPLICATE_SUPER_INITIALIZER);
          }
          ResolutionResult result = resolveSuperOrThisForSend(call);
          if (isConst) {
            if (result.isConstant) {
              constructorInvocation = result.constant;
            } else {
              isValidAsConstant = false;
            }
          }
          resolvedSuper = true;
        } else if (Initializers.isConstructorRedirect(call)) {
          // Check that there is no body (Language specification 7.5.1).  If the
          // constructor is also const, we already reported an error in
          // [resolveMethodElement].
          if (functionNode.hasBody && !constructor.isConst) {
            reporter.reportErrorMessage(
                functionNode, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY);
          }
          // Check that there are no other initializers.
          if (!initializers.tail.isEmpty) {
            reporter.reportErrorMessage(
                call, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER);
          } else {
            constructor.isRedirectingGenerativeInternal = true;
          }
          // Check that there are no field initializing parameters.
          FunctionSignature signature = constructor.functionSignature;
          signature.forEachParameter((ParameterElement parameter) {
            if (parameter.isInitializingFormal) {
              Node node = parameter.node;
              reporter.reportErrorMessage(
                  node, MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED);
              isValidAsConstant = false;
            }
          });
          ResolutionResult result = resolveSuperOrThisForSend(call);
          if (isConst) {
            if (result.isConstant) {
              constructorInvocation = result.constant;
            } else {
              isValidAsConstant = false;
            }
            if (isConst && isValidAsConstant) {
              constructor.constantConstructor =
                  new RedirectingGenerativeConstantConstructor(
                      defaultValues, constructorInvocation);
            }
          }
          return result.element;
        } else {
          reporter.reportErrorMessage(
              call, MessageKind.CONSTRUCTOR_CALL_EXPECTED);
          return null;
        }
      } else {
        reporter.reportErrorMessage(link.head, MessageKind.INVALID_INITIALIZER);
      }
    }
    if (!resolvedSuper) {
      constructorInvocation = resolveImplicitSuperConstructorSend();
    }
    if (isConst && isValidAsConstant) {
      constructor.enclosingClass.forEachInstanceField((_, FieldElement field) {
        if (!fieldInitializers.containsKey(field)) {
          visitor.resolution.ensureResolved(field);
          // TODO(johnniwinther): Report error if `field.constant` is `null`.
          if (field.constant != null) {
            fieldInitializers[field] = field.constant;
          } else {
            isValidAsConstant = false;
          }
        }
      });
      if (isValidAsConstant) {
        constructor.constantConstructor = new GenerativeConstantConstructor(
            constructor.enclosingClass.thisType,
            defaultValues,
            fieldInitializers,
            constructorInvocation);
      }
    }
    visitor.scope = oldScope;
    return null; // If there was no redirection always return null.
  }
}

class ConstructorResolver extends CommonResolverVisitor<ConstructorResult> {
  final ResolverVisitor resolver;
  final bool inConstContext;

  ConstructorResolver(Resolution resolution, this.resolver,
      {bool this.inConstContext: false})
      : super(resolution);

  ResolutionRegistry get registry => resolver.registry;

  Element get context => resolver.enclosingElement;

  visitNode(Node node) {
    throw 'not supported';
  }

  ConstructorResult reportAndCreateErroneousConstructorElement(
      Spannable diagnosticNode,
      ConstructorResultKind resultKind,
      ResolutionDartType type,
      String name,
      MessageKind kind,
      Map arguments,
      {bool isError: false,
      bool missingConstructor: false,
      List<DiagnosticMessage> infos: const <DiagnosticMessage>[]}) {
    if (missingConstructor) {
      registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    } else {
      registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
    }
    DiagnosticMessage message =
        reporter.createMessage(diagnosticNode, kind, arguments);
    if (isError || inConstContext) {
      reporter.reportError(message, infos);
    } else {
      reporter.reportWarning(message, infos);
    }
    ErroneousElement error =
        new ErroneousConstructorElementX(kind, arguments, name, context);
    if (type == null) {
      type = new MalformedType(error, null);
    }
    return new ConstructorResult.forError(resultKind, error, type);
  }

  ConstructorResult resolveConstructor(
      PrefixElement prefix,
      ResolutionInterfaceType type,
      Node diagnosticNode,
      String constructorName) {
    ClassElement cls = type.element;
    cls.ensureResolved(resolution);
    ConstructorElement constructor =
        findConstructor(context.library, cls, constructorName);
    if (constructor == null) {
      MessageKind kind = constructorName.isEmpty
          ? MessageKind.CANNOT_FIND_UNNAMED_CONSTRUCTOR
          : MessageKind.CANNOT_FIND_CONSTRUCTOR;
      return reportAndCreateErroneousConstructorElement(
          diagnosticNode,
          ConstructorResultKind.UNRESOLVED_CONSTRUCTOR,
          type,
          constructorName,
          kind,
          {'className': cls.name, 'constructorName': constructorName},
          missingConstructor: true);
    } else if (inConstContext && !constructor.isConst) {
      reporter.reportErrorMessage(
          diagnosticNode, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
      return new ConstructorResult(
          ConstructorResultKind.NON_CONSTANT, prefix, constructor, type);
    } else {
      if (cls.isEnumClass && resolver.currentClass != cls) {
        return reportAndCreateErroneousConstructorElement(
            diagnosticNode,
            ConstructorResultKind.INVALID_TYPE,
            type,
            constructorName,
            MessageKind.CANNOT_INSTANTIATE_ENUM,
            {'enumName': cls.name},
            isError: true);
      }
      if (constructor.isGenerativeConstructor) {
        if (cls.isAbstract) {
          reporter.reportWarningMessage(
              diagnosticNode, MessageKind.ABSTRACT_CLASS_INSTANTIATION);
          registry.registerFeature(Feature.ABSTRACT_CLASS_INSTANTIATION);
          return new ConstructorResult(
              ConstructorResultKind.ABSTRACT, prefix, constructor, type);
        } else {
          return new ConstructorResult(
              ConstructorResultKind.GENERATIVE, prefix, constructor, type);
        }
      } else {
        assert(constructor.isFactoryConstructor,
            failedAt(diagnosticNode, "Unexpected constructor $constructor."));
        return new ConstructorResult(
            ConstructorResultKind.FACTORY, prefix, constructor, type);
      }
    }
  }

  ConstructorResult visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    ConstructorResult result = visit(selector);
    assert(result != null,
        failedAt(selector, 'No result returned for $selector.'));
    return finishConstructorReference(result, node.send.selector, node);
  }

  /// Finishes resolution of a constructor reference and records the
  /// type of the constructed instance on [expression].
  ConstructorResult finishConstructorReference(
      ConstructorResult result, Node diagnosticNode, Node expression) {
    assert(result != null,
        failedAt(diagnosticNode, 'No result returned for $diagnosticNode.'));

    if (result.kind != null) {
      resolver.registry.setType(expression, result.type);
      return result;
    }

    // Find the unnamed constructor if the reference resolved to a
    // class.
    if (result.type != null) {
      // The unnamed constructor may not exist, so [e] may become unresolved.
      result =
          resolveConstructor(result.prefix, result.type, diagnosticNode, '');
    } else {
      Element element = result.element;
      if (element.isMalformed) {
        result = constructorResultForErroneous(diagnosticNode, element);
      } else {
        result = reportAndCreateErroneousConstructorElement(
            diagnosticNode,
            ConstructorResultKind.INVALID_TYPE,
            null,
            element.name,
            MessageKind.NOT_A_TYPE,
            {'node': diagnosticNode});
      }
    }
    resolver.registry.setType(expression, result.type);
    return result;
  }

  ConstructorResult visitNominalTypeAnnotation(NominalTypeAnnotation node) {
    // This is not really resolving a type-annotation, but the name of the
    // constructor. Therefore we allow deferred types.
    ResolutionDartType type = resolver.resolveTypeAnnotation(node,
        malformedIsError: inConstContext,
        deferredIsMalformed: false,
        registerCheckedModeCheck: false);
    Send send = node.typeName.asSend();
    PrefixElement prefix;
    if (send != null) {
      // The type name is of the form [: prefix . identifier :].
      String name = send.receiver.asIdentifier().source;
      Element element = lookupInScope(reporter, send, resolver.scope, name);
      if (element != null && element.isPrefix) {
        prefix = element;
      }
    }
    return constructorResultForType(node, type, prefix: prefix);
  }

  ConstructorResult visitSend(Send node) {
    ConstructorResult receiver = visit(node.receiver);
    assert(receiver != null,
        failedAt(node.receiver, 'No result returned for $node.receiver.'));
    if (receiver.kind != null) {
      assert(receiver.element.isMalformed,
          failedAt(node, "Unexpected prefix result: $receiver."));
      // We have already found an error.
      return receiver;
    }

    Identifier name = node.selector.asIdentifier();
    if (name == null) {
      reporter.internalError(node.selector, 'unexpected node');
    }

    if (receiver.type != null) {
      if (receiver.type.isInterfaceType) {
        return resolveConstructor(
            receiver.prefix, receiver.type, name, name.source);
      } else {
        // TODO(johnniwinther): Update the message for the different types.
        return reportAndCreateErroneousConstructorElement(
            name,
            ConstructorResultKind.INVALID_TYPE,
            null,
            name.source,
            MessageKind.NOT_A_TYPE,
            {'node': name});
      }
    } else if (receiver.element.isPrefix) {
      PrefixElement prefix = receiver.element;
      Element member = prefix.lookupLocalMember(name.source);
      return constructorResultForElement(node, name.source, member,
          prefix: prefix);
    } else {
      return reporter.internalError(
          node.receiver, 'unexpected receiver $receiver');
    }
  }

  ConstructorResult visitIdentifier(Identifier node) {
    String name = node.source;
    Element element = lookupInScope(reporter, node, resolver.scope, name);
    registry.useElement(node, element);
    return constructorResultForElement(node, name, element);
  }

  /// Assumed to be called by [resolveRedirectingFactory].
  ConstructorResult visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    Node constructorReference = node.constructorReference;
    return finishConstructorReference(
        visit(constructorReference), constructorReference, node);
  }

  ConstructorResult constructorResultForElement(
      Node node, String name, Element element,
      {PrefixElement prefix}) {
    element = Elements.unwrap(element, reporter, node);
    if (element == null) {
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE,
          null,
          name,
          MessageKind.CANNOT_RESOLVE,
          {'name': name});
    } else if (element.isAmbiguous) {
      AmbiguousElement ambiguous = element;
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE,
          null,
          name,
          ambiguous.messageKind,
          ambiguous.messageArguments,
          infos: ambiguous.computeInfos(context, reporter));
    } else if (element.isMalformed) {
      return constructorResultForErroneous(node, element);
    } else if (element.isClass) {
      ClassElement cls = element;
      cls.computeType(resolution);
      return constructorResultForType(node, cls.rawType, prefix: prefix);
    } else if (element.isPrefix) {
      return new ConstructorResult.forPrefix(element);
    } else if (element.isTypedef) {
      TypedefElement typdef = element;
      typdef.ensureResolved(resolution);
      return constructorResultForType(node, typdef.rawType);
    } else if (element.isTypeVariable) {
      TypeVariableElement typeVariableElement = element;
      return constructorResultForType(node, typeVariableElement.type);
    } else {
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE,
          null,
          name,
          MessageKind.NOT_A_TYPE,
          {'node': name});
    }
  }

  ConstructorResult constructorResultForErroneous(Node node, Element error) {
    if (error is! ErroneousElementX) {
      // Parser error. The error has already been reported.
      error = new ErroneousConstructorElementX(
          MessageKind.NOT_A_TYPE, {'node': node}, error.name, error);
      registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
    }
    return new ConstructorResult.forError(ConstructorResultKind.INVALID_TYPE,
        error, new MalformedType(error, null));
  }

  ConstructorResult constructorResultForType(Node node, ResolutionDartType type,
      {PrefixElement prefix}) {
    String name = type.name;
    if (type.isTypeVariable) {
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE,
          type,
          name,
          MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE,
          {'typeVariableName': name});
    } else if (type.isMalformed) {
      // `type is MalformedType`: `MethodTypeVariableType` is handled above.
      return new ConstructorResult.forError(
          ConstructorResultKind.INVALID_TYPE, type.element, type);
    } else if (type.isInterfaceType) {
      return new ConstructorResult.forType(prefix, type);
    } else if (type.isTypedef) {
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE,
          type,
          name,
          MessageKind.CANNOT_INSTANTIATE_TYPEDEF,
          {'typedefName': name});
    }
    return reporter.internalError(node, "Unexpected constructor type $type");
  }
}

/// The kind of constructor found by the [ConstructorResolver].
enum ConstructorResultKind {
  /// A generative or redirecting generative constructor.
  GENERATIVE,

  /// A factory or redirecting factory constructor.
  FACTORY,

  /// A generative or redirecting generative constructor on an abstract class.
  ABSTRACT,

  /// No constructor was found because the type was invalid, for instance
  /// unresolved, an enum class, a type variable, a typedef or a non-type.
  INVALID_TYPE,

  /// No constructor of the sought name was found on the class.
  UNRESOLVED_CONSTRUCTOR,

  /// A non-constant constructor was found for a const constructor invocation.
  NON_CONSTANT,
}

/// The (partial) result of the resolution of a new expression used in
/// [ConstructorResolver].
class ConstructorResult {
  /// The prefix used to access the constructor. For instance `prefix` in `new
  /// prefix.Class.constructorName()`.
  final PrefixElement prefix;

  /// The kind of the found constructor.
  final ConstructorResultKind kind;

  /// The currently found element. Since [ConstructorResult] is used for partial
  /// results, this might be a [PrefixElement], a [ClassElement], a
  /// [ConstructorElement] or in the negative cases an [ErroneousElement].
  final Element element;

  /// The type of the new expression. For instance `Foo<String>` in
  /// `new prefix.Foo<String>.constructorName()`.
  final ResolutionDartType type;

  /// Creates a fully resolved constructor access where [element] is resolved
  /// to a constructor and [type] to an interface type.
  ConstructorResult(this.kind, this.prefix, ConstructorElement this.element,
      ResolutionInterfaceType this.type);

  /// Creates a fully resolved constructor access where [element] is an
  /// [ErroneousElement].
  // TODO(johnniwinther): Do we still need the prefix for cases like
  // `new deferred.Class.unresolvedConstructor()` ?
  ConstructorResult.forError(
      this.kind, ErroneousElement this.element, this.type)
      : prefix = null;

  /// Creates a constructor access that is partially resolved to a prefix. For
  /// instance `prefix` of `new prefix.Class()`.
  ConstructorResult.forPrefix(this.element)
      : prefix = null,
        kind = null,
        type = null;

  /// Creates a constructor access that is partially resolved to a type. For
  /// instance `Foo<String>` of `new Foo<String>.constructorName()`.
  ConstructorResult.forType(this.prefix, this.type)
      : kind = null,
        element = null;

  bool get isDeferred => prefix != null && prefix.isDeferred;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('ConstructorResult(');
    if (kind != null) {
      sb.write('kind=$kind,');
      if (prefix != null) {
        sb.write('prefix=$prefix,');
      }
      sb.write('element=$element,');
      sb.write('type=$type');
    } else if (element != null) {
      sb.write('element=$element');
    } else {
      if (prefix != null) {
        sb.write('prefix=$prefix,');
      }
      sb.write('type=$type');
    }
    sb.write(')');
    return sb.toString();
  }
}

/// Lookup the [constructorName] constructor in [cls] and normalize the result
/// with respect to privacy and patching.
ConstructorElement findConstructor(
    LibraryElement currentLibrary, ClassElement cls, String constructorName) {
  if (Name.isPrivateName(constructorName) &&
      currentLibrary.library != cls.library) {
    // TODO(johnniwinther): Report a special error on unaccessible private
    // constructors.
    return null;
  }
  // TODO(johnniwinther): Use [Name] for lookup.
  ConstructorElement constructor = cls.lookupConstructor(constructorName);
  if (constructor != null) {
    constructor = constructor.declaration;
  }
  return constructor;
}
