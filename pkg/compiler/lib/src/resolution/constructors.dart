// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.constructors;
import '../compiler.dart' show
    Compiler;
import '../constants/constructors.dart' show
    GenerativeConstantConstructor,
    RedirectingGenerativeConstantConstructor;
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../diagnostics/diagnostic_listener.dart' show
    DiagnosticReporter,
    DiagnosticMessage;
import '../diagnostics/invariant.dart' show
    invariant;
import '../diagnostics/messages.dart' show
    MessageKind;
import '../diagnostics/spannable.dart' show
    Spannable;
import '../elements/elements.dart';
import '../elements/modelx.dart' show
    ConstructorElementX,
    ErroneousConstructorElementX,
    ErroneousElementX,
    ErroneousFieldElementX,
    FieldElementX,
    InitializingFormalElementX,
    ParameterElementX;
import '../tree/tree.dart';
import '../util/util.dart' show
    Link;
import '../universe/call_structure.dart' show
    CallStructure;
import '../universe/selector.dart' show
    Selector;

import 'members.dart' show
    lookupInScope,
    ResolverVisitor;
import 'registry.dart' show
    ResolutionRegistry;
import 'resolution_common.dart' show
    CommonResolverVisitor;
import 'resolution_result.dart';

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

  reportDuplicateInitializerError(Element field, Node init, Node existing) {
    reporter.reportError(
        reporter.createMessage(
            init,
            MessageKind.DUPLICATE_INITIALIZER,
            {'fieldName': field.name}),
        <DiagnosticMessage>[
            reporter.createMessage(
                existing,
                MessageKind.ALREADY_INITIALIZED,
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
      field.parseNode(visitor.resolution.parsing);
      Expression initializer = field.initializer;
      if (initializer != null) {
        reportDuplicateInitializerError(field, init, initializer);
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
      target = constructor.enclosingClass.lookupLocalMember(name);
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
    registry.useElement(init, target);
    registry.registerStaticUse(target);
    checkForDuplicateInitializers(target, init);
    // Resolve initializing value.
    ResolutionResult result = visitor.visitInStaticContext(
        init.arguments.head,
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

  InterfaceType getSuperOrThisLookupTarget(Node diagnosticNode,
                                           {bool isSuperCall}) {
    if (isSuperCall) {
      // Calculate correct lookup target and constructor name.
      if (identical(constructor.enclosingClass, visitor.compiler.objectClass)) {
        reporter.reportErrorMessage(
            diagnosticNode, MessageKind.SUPER_INITIALIZER_IN_OBJECT);
        isValidAsConstant = false;
      } else {
        return constructor.enclosingClass.supertype;
      }
    }
    return constructor.enclosingClass.thisType;
  }

  ResolutionResult resolveSuperOrThisForSend(Send call) {
    // Resolve the selector and the arguments.
    ArgumentsResult argumentsResult = visitor.inStaticContext(() {
      visitor.resolveSelector(call, null);
      return visitor.resolveArguments(call.argumentsNode);
    }, inConstantInitializer: isConst);

    bool isSuperCall = Initializers.isSuperConstructorCall(call);
    InterfaceType targetType =
        getSuperOrThisLookupTarget(call, isSuperCall: isSuperCall);
    ClassElement lookupTarget = targetType.element;
    Selector constructorSelector =
        visitor.getRedirectingThisOrSuperConstructorSelector(call);
    ConstructorElement calledConstructor = findConstructor(
        constructor.library, lookupTarget, constructorSelector.name);

    final bool isImplicitSuperCall = false;
    final String className = lookupTarget.name;
    verifyThatConstructorMatchesCall(calledConstructor,
                                     argumentsResult.callStructure,
                                     isImplicitSuperCall,
                                     call,
                                     className,
                                     constructorSelector);

    registry.useElement(call, calledConstructor);
    registry.registerStaticUse(calledConstructor);
    if (isConst) {
      if (isValidAsConstant &&
          calledConstructor.isConst &&
          argumentsResult.isValidAsConstant) {
        CallStructure callStructure = argumentsResult.callStructure;
        List<ConstantExpression> arguments = argumentsResult.constantArguments;
        return new ConstantResult(
            call,
            new ConstructedConstantExpression(
                targetType,
                calledConstructor,
                callStructure,
                arguments),
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
    if (classElement != visitor.compiler.objectClass) {
      assert(superClass != null);
      assert(superClass.isResolved);

      InterfaceType targetType =
          getSuperOrThisLookupTarget(functionNode, isSuperCall: true);
      ClassElement lookupTarget = targetType.element;
      Selector constructorSelector = new Selector.callDefaultConstructor();
      ConstructorElement calledConstructor = findConstructor(
          constructor.library,
          lookupTarget,
          constructorSelector.name);

      final String className = lookupTarget.name;
      final bool isImplicitSuperCall = true;
      verifyThatConstructorMatchesCall(calledConstructor,
                                       CallStructure.NO_ARGS,
                                       isImplicitSuperCall,
                                       functionNode,
                                       className,
                                       constructorSelector);
      registry.registerImplicitSuperCall(calledConstructor);
      registry.registerStaticUse(calledConstructor);

      if (isConst && isValidAsConstant) {
        return new ConstructedConstantExpression(
            targetType,
            calledConstructor,
            CallStructure.NO_ARGS,
            const <ConstantExpression>[]);
      }
    }
    return null;
  }

  void verifyThatConstructorMatchesCall(
      ConstructorElementX lookedupConstructor,
      CallStructure call,
      bool isImplicitSuperCall,
      Node diagnosticNode,
      String className,
      Selector constructorSelector) {
    if (lookedupConstructor == null ||
        !lookedupConstructor.isGenerativeConstructor) {
      String fullConstructorName = Elements.constructorNameForDiagnostics(
              className,
              constructorSelector.name);
      MessageKind kind = isImplicitSuperCall
          ? MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT
          : MessageKind.CANNOT_RESOLVE_CONSTRUCTOR;
      reporter.reportErrorMessage(
          diagnosticNode, kind, {'constructorName': fullConstructorName});
      isValidAsConstant = false;
    } else {
      lookedupConstructor.computeType(visitor.resolution);
      if (!call.signatureApplies(lookedupConstructor.functionSignature)) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT
                           : MessageKind.NO_MATCHING_CONSTRUCTOR;
        reporter.reportErrorMessage(diagnosticNode, kind);
        isValidAsConstant = false;
      } else if (constructor.isConst
                 && !lookedupConstructor.isConst) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.CONST_CALLS_NON_CONST_FOR_IMPLICIT
                           : MessageKind.CONST_CALLS_NON_CONST;
        reporter.reportErrorMessage(diagnosticNode, kind);
        isValidAsConstant = false;
      }
    }
  }

  /**
   * Resolve all initializers of this constructor. In the case of a redirecting
   * constructor, the resolved constructor's function element is returned.
   */
  ConstructorElement resolveInitializers() {
    Map<dynamic/*String|int*/, ConstantExpression> defaultValues =
        <dynamic/*String|int*/, ConstantExpression>{};
    ConstructedConstantExpression constructorInvocation;
    // Keep track of all "this.param" parameters specified for constructor so
    // that we can ensure that fields are initialized only once.
    FunctionSignature functionParameters = constructor.functionSignature;
    functionParameters.forEachParameter((ParameterElementX element) {
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
        InitializingFormalElementX initializingFormal = element;
        FieldElement field = initializingFormal.fieldElement;
        checkForDuplicateInitializers(field, element.initializer);
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
          if (functionNode.hasBody() && !constructor.isConst) {
            reporter.reportErrorMessage(
                functionNode, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY);
          }
          // Check that there are no other initializers.
          if (!initializers.tail.isEmpty) {
            reporter.reportErrorMessage(
                call, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER);
          } else {
            constructor.isRedirectingGenerative = true;
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
                      defaultValues,
                      constructorInvocation);
            }
          }
          return result.element;
        } else {
          reporter.reportErrorMessage(
              call, MessageKind.CONSTRUCTOR_CALL_EXPECTED);
          return null;
        }
      } else {
        reporter.reportErrorMessage(
            link.head, MessageKind.INVALID_INITIALIZER);
      }
    }
    if (!resolvedSuper) {
      constructorInvocation = resolveImplicitSuperConstructorSend();
    }
    if (isConst && isValidAsConstant) {
      constructor.constantConstructor = new GenerativeConstantConstructor(
          constructor.enclosingClass.thisType,
          defaultValues,
          fieldInitializers,
          constructorInvocation);
    }
    return null;  // If there was no redirection always return null.
  }
}

class ConstructorResolver extends CommonResolverVisitor<ConstructorResult> {
  final ResolverVisitor resolver;
  final bool inConstContext;

  ConstructorResolver(Compiler compiler, this.resolver,
                      {bool this.inConstContext: false})
      : super(compiler);

  ResolutionRegistry get registry => resolver.registry;

  visitNode(Node node) {
    throw 'not supported';
  }

  ConstructorResult reportAndCreateErroneousConstructorElement(
      Spannable diagnosticNode,
      ConstructorResultKind resultKind,
      DartType type,
      Element enclosing,
      String name,
      MessageKind kind,
      Map arguments,
      {bool isError: false,
       bool missingConstructor: false}) {
    if (missingConstructor) {
      registry.registerThrowNoSuchMethod();
    } else {
      registry.registerThrowRuntimeError();
    }
    if (isError || inConstContext) {
      reporter.reportErrorMessage(
          diagnosticNode, kind, arguments);
    } else {
      reporter.reportWarningMessage(
          diagnosticNode, kind, arguments);
    }
    ErroneousElement error = new ErroneousConstructorElementX(
        kind, arguments, name, enclosing);
    if (type == null) {
      type = new MalformedType(error, null);
    }
    return new ConstructorResult(resultKind, error, type);
  }

  ConstructorResult resolveConstructor(
      InterfaceType type,
      Node diagnosticNode,
      String constructorName) {
    ClassElement cls = type.element;
    cls.ensureResolved(resolution);
    ConstructorElement constructor = findConstructor(
        resolver.enclosingElement.library, cls, constructorName);
    if (constructor == null) {
      String fullConstructorName =
          Elements.constructorNameForDiagnostics(cls.name, constructorName);
      return reportAndCreateErroneousConstructorElement(
          diagnosticNode,
          ConstructorResultKind.UNRESOLVED_CONSTRUCTOR, type,
          cls, constructorName,
          MessageKind.CANNOT_FIND_CONSTRUCTOR,
          {'constructorName': fullConstructorName},
          missingConstructor: true);
    } else if (inConstContext && !constructor.isConst) {
      reporter.reportErrorMessage(
          diagnosticNode, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
      return new ConstructorResult(
          ConstructorResultKind.NON_CONSTANT, constructor, type);
    } else {
      if (constructor.isGenerativeConstructor) {
        if (cls.isAbstract) {
          reporter.reportWarningMessage(
              diagnosticNode, MessageKind.ABSTRACT_CLASS_INSTANTIATION);
          registry.registerAbstractClassInstantiation();
          return new ConstructorResult(
              ConstructorResultKind.ABSTRACT, constructor, type);
        } else {
          return new ConstructorResult(
              ConstructorResultKind.GENERATIVE, constructor, type);
        }
      } else {
        assert(invariant(diagnosticNode, constructor.isFactoryConstructor,
            message: "Unexpected constructor $constructor."));
        return new ConstructorResult(
            ConstructorResultKind.FACTORY, constructor, type);
      }
    }
  }

  ConstructorResult visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    ConstructorResult result = visit(selector);
    assert(invariant(selector, result != null,
        message: 'No result returned for $selector.'));
    return finishConstructorReference(result, node.send.selector, node);
  }

  /// Finishes resolution of a constructor reference and records the
  /// type of the constructed instance on [expression].
  ConstructorResult finishConstructorReference(
      ConstructorResult result,
      Node diagnosticNode,
      Node expression) {
    assert(invariant(diagnosticNode, result != null,
        message: 'No result returned for $diagnosticNode.'));

    if (result.kind != null) {
      resolver.registry.setType(expression, result.type);
      return result;
    }

    // Find the unnamed constructor if the reference resolved to a
    // class.
    if (result.type != null) {
      // The unnamed constructor may not exist, so [e] may become unresolved.
      result = resolveConstructor(result.type, diagnosticNode, '');
    } else {
      Element element = result.element;
      if (element.isErroneous) {
        result = constructorResultForErroneous(diagnosticNode, element);
      } else {
        result = reportAndCreateErroneousConstructorElement(
            diagnosticNode,
            ConstructorResultKind.INVALID_TYPE, null,
            element, element.name,
            MessageKind.NOT_A_TYPE, {'node': diagnosticNode});
      }
    }
    resolver.registry.setType(expression, result.type);
    return result;
  }

  ConstructorResult visitTypeAnnotation(TypeAnnotation node) {
    // This is not really resolving a type-annotation, but the name of the
    // constructor. Therefore we allow deferred types.
    DartType type = resolver.resolveTypeAnnotation(
        node,
        malformedIsError: inConstContext,
        deferredIsMalformed: false);
    registry.registerRequiredType(type, resolver.enclosingElement);
    return constructorResultForType(node, type);
  }

  ConstructorResult visitSend(Send node) {
    ConstructorResult receiver = visit(node.receiver);
    assert(invariant(node.receiver, receiver != null,
        message: 'No result returned for $node.receiver.'));
    if (receiver.kind != null) {
      assert(invariant(node, receiver.element.isErroneous,
          message: "Unexpected prefix result: $receiver."));
      // We have already found an error.
      return receiver;
    }

    Identifier name = node.selector.asIdentifier();
    if (name == null) {
      reporter.internalError(node.selector, 'unexpected node');
    }

    if (receiver.type != null) {
      if (receiver.type.isInterfaceType) {
        return resolveConstructor(receiver.type, name, name.source);
      } else {
        // TODO(johnniwinther): Update the message for the different types.
        return reportAndCreateErroneousConstructorElement(
            name,
            ConstructorResultKind.INVALID_TYPE, null,
            resolver.enclosingElement, name.source,
            MessageKind.NOT_A_TYPE, {'node': name});
      }
    } else if (receiver.element.isPrefix) {
      PrefixElement prefix = receiver.element;
      Element member = prefix.lookupLocalMember(name.source);
      return constructorResultForElement(node, name.source, member);
    } else {
      return reporter.internalError(
          node.receiver, 'unexpected receiver $receiver');
    }
  }

  ConstructorResult visitIdentifier(Identifier node) {
    String name = node.source;
    Element element = resolver.reportLookupErrorIfAny(
        lookupInScope(reporter, node, resolver.scope, name), node, name);
    registry.useElement(node, element);
    // TODO(johnniwinther): Change errors to warnings, cf. 11.11.1.
    return constructorResultForElement(node, name, element);
  }

  /// Assumed to be called by [resolveRedirectingFactory].
  ConstructorResult visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    Node constructorReference = node.constructorReference;
    return finishConstructorReference(visit(constructorReference),
        constructorReference, node);
  }

  ConstructorResult constructorResultForElement(
      Node node, String name, Element element) {
    element = Elements.unwrap(element, reporter, node);
    if (element == null) {
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE, null,
          resolver.enclosingElement, name,
          MessageKind.CANNOT_RESOLVE,
          {'name': name});
    } else if (element.isErroneous) {
      return constructorResultForErroneous(node, element);
    } else if (element.isClass) {
      ClassElement cls = element;
      cls.computeType(resolution);
      return constructorResultForType(node, cls.rawType);
    } else if (element.isPrefix) {
      return new ConstructorResult.forElement(element);
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
          ConstructorResultKind.INVALID_TYPE, null,
          resolver.enclosingElement, name,
          MessageKind.NOT_A_TYPE, {'node': name});
    }
  }

  ConstructorResult constructorResultForErroneous(
      Node node, Element error) {
    if (error is! ErroneousElementX) {
      // Parser error. The error has already been reported.
      error = new ErroneousConstructorElementX(
          MessageKind.NOT_A_TYPE, {'node': node},
          error.name, error);
      registry.registerThrowRuntimeError();
    }
    return new ConstructorResult(
        ConstructorResultKind.INVALID_TYPE,
        error,
        new MalformedType(error, null));
  }

  ConstructorResult constructorResultForType(
      Node node,
      DartType type) {
    String name = type.name;
    if (type.isMalformed) {
      return new ConstructorResult(
          ConstructorResultKind.INVALID_TYPE, type.element, type);
    } else if (type.isInterfaceType) {
      return new ConstructorResult.forType(type);
    } else if (type.isTypedef) {
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE, type,
          resolver.enclosingElement, name,
          MessageKind.CANNOT_INSTANTIATE_TYPEDEF, {'typedefName': name});
    } else if (type.isTypeVariable) {
      return reportAndCreateErroneousConstructorElement(
          node,
          ConstructorResultKind.INVALID_TYPE, type,
          resolver.enclosingElement, name,
          MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE,
          {'typeVariableName': name});
    }
    return reporter.internalError(node, "Unexpected constructor type $type");
  }

}

enum ConstructorResultKind {
  GENERATIVE,
  FACTORY,
  ABSTRACT,
  INVALID_TYPE,
  UNRESOLVED_CONSTRUCTOR,
  NON_CONSTANT,
}

class ConstructorResult {
  final ConstructorResultKind kind;
  final Element element;
  final DartType type;

  ConstructorResult(this.kind, this.element, this.type);

  ConstructorResult.forElement(this.element)
      : kind = null,
        type = null;

  ConstructorResult.forType(this.type)
      : kind = null,
        element = null;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('ConstructorResult(');
    if (kind != null) {
      sb.write('kind=$kind,');
      sb.write('element=$element,');
      sb.write('type=$type');
    } else if (element != null) {
      sb.write('element=$element');
    } else {
      sb.write('type=$type');
    }
    sb.write(')');
    return sb.toString();
  }
}

/// Lookup the [constructorName] constructor in [cls] and normalize the result
/// with respect to privacy and patching.
ConstructorElement findConstructor(
    LibraryElement currentLibrary,
    ClassElement cls,
    String constructorName) {
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
