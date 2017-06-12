// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution;

import 'dart:collection' show Queue;

import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common/resolution.dart'
    show ParsingContext, Resolution, ResolutionImpact, Target;
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../compile_time_constants.dart' show ConstantCompiler;
import '../constants/expressions.dart'
    show
        ConstantExpression,
        ConstantExpressionKind,
        ConstructedConstantExpression,
        ErroneousConstantExpression;
import '../constants/values.dart' show ConstantValue;
import '../common_elements.dart' show CommonElements;
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart'
    show
        BaseClassElementX,
        BaseFunctionElementX,
        ConstructorElementX,
        FieldElementX,
        FunctionElementX,
        GetterElementX,
        MetadataAnnotationX,
        MixinApplicationElementX,
        ParameterMetadataAnnotation,
        SetterElementX,
        TypedefElementX;
import '../enqueue.dart';
import '../options.dart';
import 'package:front_end/src/fasta/scanner.dart'
    show
        isBinaryOperator,
        isMinusOperator,
        isTernaryOperator,
        isUnaryOperator,
        isUserDefinableOperator;
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/feature.dart' show Feature;
import '../universe/use.dart' show StaticUse;
import '../universe/world_impact.dart' show WorldImpact;
import '../util/util.dart' show Link, Setlet;
import '../world.dart';
import 'class_hierarchy.dart';
import 'class_members.dart' show MembersCreator;
import 'constructors.dart';
import 'members.dart';
import 'registry.dart';
import 'resolution_result.dart';
import 'signatures.dart';
import 'tree_elements.dart';
import 'typedefs.dart';

class ResolverTask extends CompilerTask {
  final ConstantCompiler constantCompiler;
  final Resolution resolution;

  ResolverTask(this.resolution, this.constantCompiler, Measurer measurer)
      : super(measurer);

  String get name => 'Resolver';

  DiagnosticReporter get reporter => resolution.reporter;
  Target get target => resolution.target;
  CommonElements get commonElements => resolution.commonElements;
  ParsingContext get parsingContext => resolution.parsingContext;
  CompilerOptions get options => resolution.options;
  ResolutionEnqueuer get enqueuer => resolution.enqueuer;
  OpenWorld get world => enqueuer.worldBuilder;

  ResolutionImpact resolve(Element element) {
    return measure(() {
      if (Elements.isMalformed(element)) {
        // TODO(johnniwinther): Add a predicate for this.
        assert(
            element is! ErroneousElement,
            failedAt(
                element, "Element $element expected to have parse errors."));
        _ensureTreeElements(element);
        return const ResolutionImpact();
      }

      WorldImpact processMetadata([WorldImpact result]) {
        for (MetadataAnnotation metadata in element.implementation.metadata) {
          metadata.ensureResolved(resolution);
        }
        return result;
      }

      if (element.isConstructor ||
          element.isFunction ||
          element.isGetter ||
          element.isSetter) {
        return processMetadata(resolveMethodElement(element));
      }

      if (element.isField) {
        return processMetadata(resolveField(element));
      }
      if (element.isClass) {
        ClassElement cls = element;
        cls.ensureResolved(resolution);
        return processMetadata(const ResolutionImpact());
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        return processMetadata(resolveTypedef(typdef));
      }

      reporter.internalError(element, "resolve($element) not implemented.");
    });
  }

  void resolveRedirectingConstructor(InitializerResolver resolver, Node node,
      FunctionElement constructor, FunctionElement redirection) {
    assert(
        constructor.isImplementation,
        failedAt(
            node,
            'Redirecting constructors must be resolved on implementation '
            'elements.'));
    Setlet<FunctionElement> seen = new Setlet<FunctionElement>();
    seen.add(constructor);
    while (redirection != null) {
      // Ensure that we follow redirections through implementation elements.
      redirection = redirection.implementation;
      if (redirection.isError) {
        break;
      }
      if (seen.contains(redirection)) {
        reporter.reportErrorMessage(
            node, MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE);
        return;
      }
      seen.add(redirection);
      redirection = resolver.visitor.resolveConstructorRedirection(redirection);
    }
  }

  static void processAsyncMarker(Resolution resolution,
      BaseFunctionElementX element, ResolutionRegistry registry) {
    DiagnosticReporter reporter = resolution.reporter;
    CommonElements commonElements = resolution.commonElements;
    FunctionExpression functionExpression = element.node;
    AsyncModifier asyncModifier = functionExpression.asyncModifier;
    if (asyncModifier != null) {
      if (!resolution.target.supportsAsyncAwait) {
        reporter.reportErrorMessage(functionExpression.asyncModifier,
            MessageKind.ASYNC_AWAIT_NOT_SUPPORTED);
      } else {
        if (asyncModifier.isAsynchronous) {
          element.asyncMarker = asyncModifier.isYielding
              ? AsyncMarker.ASYNC_STAR
              : AsyncMarker.ASYNC;
        } else {
          element.asyncMarker = AsyncMarker.SYNC_STAR;
        }
        if (element.isAbstract) {
          reporter.reportErrorMessage(
              asyncModifier,
              MessageKind.ASYNC_MODIFIER_ON_ABSTRACT_METHOD,
              {'modifier': element.asyncMarker});
        } else if (element.isConstructor) {
          reporter.reportErrorMessage(
              asyncModifier,
              MessageKind.ASYNC_MODIFIER_ON_CONSTRUCTOR,
              {'modifier': element.asyncMarker});
        } else {
          if (element.isSetter) {
            reporter.reportErrorMessage(
                asyncModifier,
                MessageKind.ASYNC_MODIFIER_ON_SETTER,
                {'modifier': element.asyncMarker});
          }
          if (functionExpression.body.asReturn() != null &&
              element.asyncMarker.isYielding) {
            reporter.reportErrorMessage(
                asyncModifier,
                MessageKind.YIELDING_MODIFIER_ON_ARROW_BODY,
                {'modifier': element.asyncMarker});
          }
        }
        ClassElement cls;
        switch (element.asyncMarker) {
          case AsyncMarker.ASYNC:
            registry.registerFeature(Feature.ASYNC);
            cls = commonElements.futureClass;
            break;
          case AsyncMarker.ASYNC_STAR:
            registry.registerFeature(Feature.ASYNC_STAR);
            cls = commonElements.streamClass;
            break;
          case AsyncMarker.SYNC_STAR:
            registry.registerFeature(Feature.SYNC_STAR);
            cls = commonElements.iterableClass;
            break;
        }
        cls?.ensureResolved(resolution);
      }
    }
  }

  bool _isNativeClassOrExtendsNativeClass(ClassElement classElement) {
    assert(classElement != null);
    while (classElement != null) {
      if (target.isNativeClass(classElement)) return true;
      classElement = classElement.superclass;
    }
    return false;
  }

  WorldImpact resolveMethodElementImplementation(
      FunctionElementX element, FunctionExpression tree) {
    return reporter.withCurrentElement(element, () {
      if (element.isExternal && tree.hasBody) {
        reporter.reportErrorMessage(element, MessageKind.EXTERNAL_WITH_BODY,
            {'functionName': element.name});
      }
      if (element.isConstructor) {
        if (tree.returnType != null) {
          reporter.reportErrorMessage(
              tree, MessageKind.CONSTRUCTOR_WITH_RETURN_TYPE);
        }
        if (tree.hasBody && element.isConst) {
          if (element.isGenerativeConstructor) {
            reporter.reportErrorMessage(
                tree, MessageKind.CONST_CONSTRUCTOR_WITH_BODY);
          } else if (!tree.isRedirectingFactory) {
            reporter.reportErrorMessage(tree, MessageKind.CONST_FACTORY);
          }
        }
      }

      ResolverVisitor visitor = visitorFor(element);
      ResolutionRegistry registry = visitor.registry;
      registry.defineFunction(tree, element);
      visitor.setupFunction(tree, element); // Modifies the scope.
      processAsyncMarker(resolution, element, registry);

      if (element.isGenerativeConstructor) {
        // Even if there is no initializer list we still have to do the
        // resolution in case there is an implicit super constructor call.
        InitializerResolver resolver =
            new InitializerResolver(visitor, element, tree);
        FunctionElement redirection = resolver.resolveInitializers();
        if (redirection != null) {
          resolveRedirectingConstructor(resolver, tree, element, redirection);
        }
      } else if (tree.initializers != null) {
        reporter.reportErrorMessage(
            tree, MessageKind.FUNCTION_WITH_INITIALIZER);
      }

      if (!options.analyzeSignaturesOnly || tree.isRedirectingFactory) {
        // We need to analyze the redirecting factory bodies to ensure that
        // we can analyze compile-time constants.
        visitor.visit(tree.body);
      }

      // Get the resolution tree and check that the resolved
      // function doesn't use 'super' if it is mixed into another
      // class. This is the part of the 'super' mixin check that
      // happens when a function is resolved after the mixin
      // application has been performed.
      TreeElements resolutionTree = registry.mapping;
      ClassElement enclosingClass = element.enclosingClass;
      if (enclosingClass != null) {
        // TODO(johnniwinther): Find another way to obtain mixin uses.
        ClassElement mixin = enclosingClass;
        for (MixinApplicationElement mixinApplication
            in world.allMixinUsesOf(enclosingClass)) {
          checkMixinSuperUses(resolutionTree, mixinApplication, mixin);
        }
      }

      // TODO(9631): support noSuchMethod on native classes.
      if (element.isFunction &&
          element.isInstanceMember &&
          element.name == Identifiers.noSuchMethod_ &&
          _isNativeClassOrExtendsNativeClass(enclosingClass)) {
        reporter.reportErrorMessage(tree, MessageKind.NO_SUCH_METHOD_IN_NATIVE);
      }

      resolution.target.resolveNativeMember(element, registry.impactBuilder);

      return registry.impactBuilder;
    });
  }

  /// Returns `true` if [element] has been processed by the resolution enqueuer.
  bool _hasBeenProcessed(MemberElement element) {
    assert(element == element.analyzableElement.declaration,
        failedAt(element, "Unexpected element $element"));
    return enqueuer.processedEntities.contains(element);
  }

  WorldImpact resolveMethodElement(FunctionElementX element) {
    assert(element.isDeclaration, failedAt(element));
    return reporter.withCurrentElement(element, () {
      if (_hasBeenProcessed(element)) {
        // TODO(karlklose): Remove the check for [isConstructor]. [elememts]
        // should never be non-null, not even for constructors.
        assert(
            element.isConstructor,
            failedAt(element,
                'Non-constructor element $element has already been analyzed.'));
        return const ResolutionImpact();
      }
      if (element.isSynthesized) {
        if (element.isGenerativeConstructor) {
          ResolutionRegistry registry =
              new ResolutionRegistry(this.target, _ensureTreeElements(element));
          ConstructorElement constructor = element.asFunctionElement();
          ConstructorElement target = constructor.definingConstructor;
          // Ensure the signature of the synthesized element is
          // resolved. This is the only place where the resolver is
          // seeing this element.
          ResolutionFunctionType type = element.computeType(resolution);
          if (!target.isMalformed) {
            registry.registerStaticUse(new StaticUse.superConstructorInvoke(
                // TODO(johnniwinther): Provide the right call structure for
                // forwarding constructors.
                target,
                CallStructure.NO_ARGS));
          }
          // TODO(johnniwinther): Remove this substitution when synthesized
          // constructors handle type variables correctly.
          type = type.substByContext(
              constructor.enclosingClass.asInstanceOf(target.enclosingClass));
          type.parameterTypes.forEach(registry.registerCheckedModeCheck);
          type.optionalParameterTypes
              .forEach(registry.registerCheckedModeCheck);
          type.namedParameterTypes.forEach(registry.registerCheckedModeCheck);
          return registry.impactBuilder;
        } else {
          assert(element.isDeferredLoaderGetter || element.isMalformed);
          _ensureTreeElements(element);
          return const ResolutionImpact();
        }
      } else {
        element.parseNode(resolution.parsingContext);
        element.computeType(resolution);
        FunctionElementX implementation = element;
        if (element.isExternal) {
          implementation = target.resolveExternalFunction(element);
        }
        return resolveMethodElementImplementation(
            implementation, implementation.node);
      }
    });
  }

  /// Creates a [ResolverVisitor] for resolving an AST in context of [element].
  /// If [useEnclosingScope] is `true` then the initial scope of the visitor
  /// does not include inner scope of [element].
  ///
  /// This method should only be used by this library (or tests of
  /// this library).
  ResolverVisitor visitorFor(Element element, {bool useEnclosingScope: false}) {
    return new ResolverVisitor(resolution, element,
        new ResolutionRegistry(target, _ensureTreeElements(element)),
        useEnclosingScope: useEnclosingScope);
  }

  WorldImpact resolveField(FieldElementX element) {
    return reporter.withCurrentElement(element, () {
      VariableDefinitions tree = element.parseNode(parsingContext);
      if (element.modifiers.isStatic && element.isTopLevel) {
        reporter.reportErrorMessage(element.modifiers.getStatic(),
            MessageKind.TOP_LEVEL_VARIABLE_DECLARED_STATIC);
      }
      ResolverVisitor visitor = visitorFor(element);
      ResolutionRegistry registry = visitor.registry;
      // TODO(johnniwinther): Maybe remove this when placeholderCollector
      // migrates to the backend ast.
      registry.defineElement(element.definition, element);
      // TODO(johnniwinther): Share the resolved type between all variables
      // declared in the same declaration.
      if (tree.type != null) {
        ResolutionDartType type = visitor.resolveTypeAnnotation(tree.type);
        assert(
            element.variables.type == null ||
                // Crude check but we have no equivalence relation that
                // equates malformed types, like matching creations of type
                // `Foo<Unresolved>`.
                element.variables.type.toString() == type.toString(),
            failedAt(
                element,
                "Unexpected type computed for $element. "
                "Was ${element.variables.type}, computed $type."));
        element.variables.type = type;
      } else if (element.variables.type == null) {
        // Only assign the dynamic type if the element has no known type. This
        // happens for enum fields where the type is known but is not in the
        // synthesized AST.
        element.variables.type = const ResolutionDynamicType();
      } else {
        registry.registerCheckedModeCheck(element.variables.type);
      }

      Expression initializer = element.initializer;
      Modifiers modifiers = element.modifiers;
      if (initializer != null) {
        // TODO(johnniwinther): Avoid analyzing initializers if
        // [Compiler.analyzeSignaturesOnly] is set.
        ResolutionResult result = visitor.visit(initializer);
        if (result.isConstant) {
          element.constant = result.constant;
        }
      } else if (modifiers.isConst) {
        reporter.reportErrorMessage(
            element, MessageKind.CONST_WITHOUT_INITIALIZER);
      } else if (modifiers.isFinal && !element.isInstanceMember) {
        reporter.reportErrorMessage(
            element, MessageKind.FINAL_WITHOUT_INITIALIZER);
      } else {
        registry.registerFeature(Feature.FIELD_WITHOUT_INITIALIZER);
      }

      if (Elements.isStaticOrTopLevelField(element)) {
        visitor.addDeferredAction(element, () {
          if (element.modifiers.isConst) {
            element.constant = constantCompiler.compileConstant(element);
          } else {
            element.constant = constantCompiler.compileVariable(element);
          }
        });
        if (initializer != null) {
          if (!element.modifiers.isConst &&
              initializer.asLiteralNull() == null) {
            // TODO(johnniwinther): Determine the const-ness eagerly to avoid
            // unnecessary registrations.
            registry.registerFeature(Feature.LAZY_FIELD);
          }
        }
      }

      // Perform various checks as side effect of "computing" the type.
      element.computeType(resolution);

      resolution.target.resolveNativeMember(element, registry.impactBuilder);

      return registry.impactBuilder;
    });
  }

  ResolutionDartType resolveTypeAnnotation(
      Element element, TypeAnnotation annotation) {
    ResolutionDartType type = _resolveReturnType(element, annotation);
    if (type.isVoid) {
      reporter.reportErrorMessage(annotation, MessageKind.VOID_NOT_ALLOWED);
    }
    return type;
  }

  ResolutionDartType _resolveReturnType(
      Element element, TypeAnnotation annotation) {
    if (annotation == null) return const ResolutionDynamicType();
    ResolutionDartType result =
        visitorFor(element).resolveTypeAnnotation(annotation);
    assert(result != null,
        failedAt(annotation, "No type computed for $annotation."));
    if (result == null) {
      // TODO(karklose): warning.
      return const ResolutionDynamicType();
    }
    return result;
  }

  void resolveRedirectionChain(ConstructorElement constructor, Spannable node) {
    ConstructorElement target = constructor;
    ResolutionDartType targetType;
    List<ConstructorElement> seen = new List<ConstructorElement>();
    bool isMalformed = false;
    // Follow the chain of redirections and check for cycles.
    while (target.isRedirectingFactory) {
      if (target.hasEffectiveTarget) {
        // We found a constructor that already has been processed.
        // TODO(johnniwinther): Should `effectiveTargetType` be part of the
        // interface?
        targetType =
            target.computeEffectiveTargetType(target.enclosingClass.thisType);
        assert(
            targetType != null,
            failedAt(target,
                'Redirection target type has not been computed for $target'));
        target = target.effectiveTarget;
        break;
      }

      Element nextTarget = target.immediateRedirectionTarget;

      if (seen.contains(nextTarget)) {
        reporter.reportErrorMessage(
            node, MessageKind.CYCLIC_REDIRECTING_FACTORY);
        targetType = target.enclosingClass.thisType;
        isMalformed = true;
        break;
      }
      seen.add(target);
      target = nextTarget;
    }

    if (target.isGenerativeConstructor && target.enclosingClass.isAbstract) {
      isMalformed = true;
    }
    if (target.isMalformed) {
      isMalformed = true;
    }

    if (targetType == null) {
      assert(!target.isRedirectingFactory);
      targetType = target.enclosingClass.thisType;
    }

    // [target] is now the actual target of the redirections.  Run through
    // the constructors again and set their [redirectionTarget], so that we
    // do not have to run the loop for these constructors again. Furthermore,
    // compute [redirectionTargetType] for each factory by computing the
    // substitution of the target type with respect to the factory type.
    while (!seen.isEmpty) {
      ConstructorElementX factory = seen.removeLast();
      ResolvedAst resolvedAst = factory.resolvedAst;
      assert(
          resolvedAst != null, failedAt(node, 'No ResolvedAst for $factory.'));
      RedirectingFactoryBody redirectionNode = resolvedAst.body;
      ResolutionDartType factoryType =
          resolvedAst.elements.getType(redirectionNode);
      if (!factoryType.isDynamic) {
        targetType = targetType.substByContext(factoryType);
      }
      factory.setEffectiveTarget(target, targetType, isMalformed: isMalformed);
    }
  }

  /**
   * Load and resolve the supertypes of [cls].
   *
   * Warning: do not call this method directly. It should only be
   * called by [resolveClass] and [ClassSupertypeResolver].
   */
  void loadSupertypes(BaseClassElementX cls, Spannable from) {
    measure(() {
      if (cls.supertypeLoadState == STATE_DONE) return;
      if (cls.supertypeLoadState == STATE_STARTED) {
        reporter.reportErrorMessage(
            from, MessageKind.CYCLIC_CLASS_HIERARCHY, {'className': cls.name});
        cls.supertypeLoadState = STATE_DONE;
        cls.hasIncompleteHierarchy = true;
        ClassElement objectClass = commonElements.objectClass;
        cls.allSupertypesAndSelf = objectClass.allSupertypesAndSelf
            .extendClass(cls.computeType(resolution));
        cls.supertype = cls.allSupertypes.head;
        assert(cls.supertype != null,
            failedAt(from, 'Missing supertype on cyclic class $cls.'));
        cls.interfaces = const Link<ResolutionDartType>();
        return;
      }
      cls.supertypeLoadState = STATE_STARTED;
      reporter.withCurrentElement(cls, () {
        // TODO(ahe): Cache the node in cls.
        cls
            .parseNode(parsingContext)
            .accept(new ClassSupertypeResolver(resolution, cls));
        if (cls.supertypeLoadState != STATE_DONE) {
          cls.supertypeLoadState = STATE_DONE;
        }
      });
    });
  }

  // TODO(johnniwinther): Remove this queue when resolution has been split into
  // syntax and semantic resolution.
  TypeDeclarationElement currentlyResolvedTypeDeclaration;
  Queue<ClassElement> pendingClassesToBeResolved = new Queue<ClassElement>();
  Queue<ClassElement> pendingClassesToBePostProcessed =
      new Queue<ClassElement>();

  /// Resolve [element] using [resolveTypeDeclaration].
  ///
  /// This methods ensure that class declarations encountered through type
  /// annotations during the resolution of [element] are resolved after
  /// [element] has been resolved.
  // TODO(johnniwinther): Encapsulate this functionality in a
  // 'TypeDeclarationResolver'.
  _resolveTypeDeclaration(
      TypeDeclarationElement element, resolveTypeDeclaration()) {
    return reporter.withCurrentElement(element, () {
      return measure(() {
        TypeDeclarationElement previousResolvedTypeDeclaration =
            currentlyResolvedTypeDeclaration;
        currentlyResolvedTypeDeclaration = element;
        var result = resolveTypeDeclaration();
        if (previousResolvedTypeDeclaration == null) {
          do {
            while (!pendingClassesToBeResolved.isEmpty) {
              pendingClassesToBeResolved
                  .removeFirst()
                  .ensureResolved(resolution);
            }
            while (!pendingClassesToBePostProcessed.isEmpty) {
              _postProcessClassElement(
                  pendingClassesToBePostProcessed.removeFirst());
            }
          } while (!pendingClassesToBeResolved.isEmpty);
          assert(pendingClassesToBeResolved.isEmpty);
          assert(pendingClassesToBePostProcessed.isEmpty);
        }
        currentlyResolvedTypeDeclaration = previousResolvedTypeDeclaration;
        return result;
      });
    });
  }

  /**
   * Resolve the class [element].
   *
   * Before calling this method, [element] was constructed by the
   * scanner and most fields are null or empty. This method fills in
   * these fields and also ensure that the supertypes of [element] are
   * resolved.
   *
   * Warning: Do not call this method directly. Instead use
   * [:element.ensureResolved(resolution):].
   */
  TreeElements resolveClass(BaseClassElementX element) {
    return _resolveTypeDeclaration(element, () {
      // TODO(johnniwinther): Store the mapping in the resolution enqueuer.
      ResolutionRegistry registry = new ResolutionRegistry(
          resolution.target, _ensureTreeElements(element));
      resolveClassInternal(element, registry);
      return element.treeElements;
    });
  }

  void ensureClassWillBeResolvedInternal(ClassElement element) {
    if (currentlyResolvedTypeDeclaration == null) {
      element.ensureResolved(resolution);
    } else {
      pendingClassesToBeResolved.add(element);
    }
  }

  void resolveClassInternal(
      BaseClassElementX element, ResolutionRegistry registry) {
    if (!element.isPatch) {
      reporter.withCurrentElement(
          element,
          () => measure(() {
                assert(element.resolutionState == STATE_NOT_STARTED);
                element.resolutionState = STATE_STARTED;
                Node tree = element.parseNode(parsingContext);
                loadSupertypes(element, tree);

                ClassResolverVisitor visitor =
                    new ClassResolverVisitor(resolution, element, registry);
                visitor.visit(tree);
                element.resolutionState = STATE_DONE;
                pendingClassesToBePostProcessed.add(element);
              }));
      if (element.isPatched) {
        // Ensure handling patch after origin.
        element.patch.ensureResolved(resolution);
      }
    } else {
      // Handle patch classes:
      element.resolutionState = STATE_STARTED;
      // Ensure handling origin before patch.
      element.origin.ensureResolved(resolution);
      // Ensure that the type is computed.
      element.computeType(resolution);
      // Copy class hierarchy from origin.
      element.supertype = element.origin.supertype;
      element.interfaces = element.origin.interfaces;
      element.allSupertypesAndSelf = element.origin.allSupertypesAndSelf;
      // Stepwise assignment to ensure invariant.
      element.supertypeLoadState = STATE_STARTED;
      element.supertypeLoadState = STATE_DONE;
      element.resolutionState = STATE_DONE;
      // TODO(johnniwinther): Check matching type variables and
      // empty extends/implements clauses.
    }
  }

  void _postProcessClassElement(BaseClassElementX element) {
    for (MetadataAnnotation metadata in element.implementation.metadata) {
      metadata.ensureResolved(resolution);
      ConstantValue value =
          resolution.constants.getConstantValue(metadata.constant);
      if (!element.isProxy && resolution.isProxyConstant(value)) {
        element.isProxy = true;
      }
    }

    // Force resolution of metadata on non-instance members since they may be
    // inspected by the backend while emitting. Metadata on instance members is
    // handled as a result of processing instantiated class members in the
    // enqueuer.
    // TODO(ahe): Avoid this eager resolution.
    element.forEachMember((_, Element member) {
      if (!member.isInstanceMember) {
        reporter.withCurrentElement(member, () {
          for (MetadataAnnotation metadata in member.implementation.metadata) {
            metadata.ensureResolved(resolution);
          }
        });
      }
    });

    computeClassMember(element, Identifiers.call);
  }

  void computeClassMembers(ClassElement element) {
    MembersCreator.computeAllClassMembers(resolution, element);
  }

  void computeClassMember(ClassElement element, String name) {
    MembersCreator.computeClassMembersByName(resolution, element, name);
  }

  void checkClass(ClassElement element) {
    computeClassMembers(element);
    if (element.isMixinApplication) {
      checkMixinApplication(element);
    } else {
      checkClassMembers(element);
    }
  }

  void checkMixinApplication(MixinApplicationElementX mixinApplication) {
    Modifiers modifiers = mixinApplication.modifiers;
    int illegalFlags = modifiers.flags & ~Modifiers.FLAG_ABSTRACT;
    if (illegalFlags != 0) {
      Modifiers illegalModifiers = new Modifiers.withFlags(null, illegalFlags);
      reporter.reportErrorMessage(
          modifiers,
          MessageKind.ILLEGAL_MIXIN_APPLICATION_MODIFIERS,
          {'modifiers': illegalModifiers});
    }

    // In case of cyclic mixin applications, the mixin chain will have
    // been cut. If so, we have already reported the error to the
    // user so we just return from here.
    ClassElement mixin = mixinApplication.mixin;
    if (mixin == null) return;

    // Check that we're not trying to use Object as a mixin.
    if (mixin.superclass == null) {
      reporter.reportErrorMessage(
          mixinApplication, MessageKind.ILLEGAL_MIXIN_OBJECT);
      // Avoid reporting additional errors for the Object class.
      return;
    }

    if (mixin.isEnumClass) {
      // Mixing in an enum has already caused a compile-time error.
      return;
    }

    // Check that the mixed in class has Object as its superclass.
    if (!mixin.superclass.isObject) {
      reporter.reportErrorMessage(mixin, MessageKind.ILLEGAL_MIXIN_SUPERCLASS);
    }

    // Check that the mixed in class doesn't have any constructors and
    // make sure we aren't mixing in methods that use 'super'.
    mixin.forEachLocalMember((AstElement member) {
      if (member.isGenerativeConstructor && !member.isSynthesized) {
        reporter.reportErrorMessage(
            member, MessageKind.ILLEGAL_MIXIN_CONSTRUCTOR);
      } else {
        // Get the resolution tree and check that the resolved member
        // doesn't use 'super'. This is the part of the 'super' mixin
        // check that happens when a function is resolved before the
        // mixin application has been performed.
        // TODO(johnniwinther): Obtain the [TreeElements] for [member]
        // differently.
        if (_hasBeenProcessed(member)) {
          if (member.resolvedAst.kind == ResolvedAstKind.PARSED) {
            checkMixinSuperUses(
                member.resolvedAst.elements, mixinApplication, mixin);
          }
        }
      }
    });
  }

  void checkMixinSuperUses(TreeElements elements,
      MixinApplicationElement mixinApplication, ClassElement mixin) {
    // TODO(johnniwinther): Avoid the use of [TreeElements] here.
    Iterable<SourceSpan> superUses = elements.superUses;
    if (superUses.isEmpty) return;
    DiagnosticMessage error = reporter.createMessage(mixinApplication,
        MessageKind.ILLEGAL_MIXIN_WITH_SUPER, {'className': mixin.name});
    // Show the user the problematic uses of 'super' in the mixin.
    List<DiagnosticMessage> infos = <DiagnosticMessage>[];
    for (SourceSpan use in superUses) {
      infos.add(
          reporter.createMessage(use, MessageKind.ILLEGAL_MIXIN_SUPER_USE));
    }
    reporter.reportError(error, infos);
  }

  void checkClassMembers(ClassElement cls) {
    assert(cls.isDeclaration, failedAt(cls));
    if (cls.isObject) return;
    // TODO(johnniwinther): Should this be done on the implementation element as
    // well?
    List<Element> constConstructors = <Element>[];
    List<Element> nonFinalInstanceFields = <Element>[];
    cls.forEachMember((holder, dynamic member) {
      reporter.withCurrentElement(member, () {
        // Perform various checks as side effect of "computing" the type.
        member.computeType(resolution);

        // Check modifiers.
        // ignore: UNDEFINED_GETTER
        if (member.isFunction && member.modifiers.isFinal) {
          reporter.reportErrorMessage(
              member, MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER);
        }
        if (member.isConstructor) {
          // ignore: UNDEFINED_GETTER
          final mismatchedFlagsBits = member.modifiers.flags &
              (Modifiers.FLAG_STATIC | Modifiers.FLAG_ABSTRACT);
          if (mismatchedFlagsBits != 0) {
            final mismatchedFlags =
                new Modifiers.withFlags(null, mismatchedFlagsBits);
            reporter.reportErrorMessage(
                member,
                MessageKind.ILLEGAL_CONSTRUCTOR_MODIFIERS,
                {'modifiers': mismatchedFlags});
          }
          // ignore: UNDEFINED_GETTER
          if (member.modifiers.isConst) {
            constConstructors.add(member);
          }
        }
        if (member.isField) {
          // ignore: UNDEFINED_GETTER
          if (member.modifiers.isConst && !member.modifiers.isStatic) {
            reporter.reportErrorMessage(
                member, MessageKind.ILLEGAL_CONST_FIELD_MODIFIER);
          }
          // ignore: UNDEFINED_GETTER
          if (!member.modifiers.isStatic && !member.modifiers.isFinal) {
            nonFinalInstanceFields.add(member);
          }
        }
        checkAbstractField(member);
        checkUserDefinableOperator(member);
      });
    });
    if (!constConstructors.isEmpty && !nonFinalInstanceFields.isEmpty) {
      Spannable span =
          constConstructors.length > 1 ? cls : constConstructors[0];
      DiagnosticMessage error = reporter.createMessage(
          span,
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS,
          {'className': cls.name});
      List<DiagnosticMessage> infos = <DiagnosticMessage>[];
      if (constConstructors.length > 1) {
        for (Element constructor in constConstructors) {
          infos.add(reporter.createMessage(constructor,
              MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR));
        }
      }
      for (Element field in nonFinalInstanceFields) {
        infos.add(reporter.createMessage(
            field, MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD));
      }
      reporter.reportError(error, infos);
    }
  }

  void checkAbstractField(Element member) {
    // Only check for getters. The test can only fail if there is both a setter
    // and a getter with the same name, and we only need to check each abstract
    // field once, so we just ignore setters.
    if (!member.isGetter) return;

    // Find the associated abstract field.
    ClassElement classElement = member.enclosingClass;
    Element lookupElement = classElement.lookupLocalMember(member.name);
    if (lookupElement == null) {
      reporter.internalError(member, "No abstract field for accessor");
    } else if (!lookupElement.isAbstractField) {
      if (lookupElement.isMalformed || lookupElement.isAmbiguous) return;
      reporter.internalError(
          member, "Inaccessible abstract field for accessor");
    }
    AbstractFieldElement field = lookupElement;

    GetterElementX getter = field.getter;
    if (getter == null) return;
    SetterElementX setter = field.setter;
    if (setter == null) return;
    int getterFlags = getter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    int setterFlags = setter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    if (getterFlags != setterFlags) {
      final mismatchedFlags =
          new Modifiers.withFlags(null, getterFlags ^ setterFlags);
      reporter.reportWarningMessage(field.getter, MessageKind.GETTER_MISMATCH,
          {'modifiers': mismatchedFlags});
      reporter.reportWarningMessage(field.setter, MessageKind.SETTER_MISMATCH,
          {'modifiers': mismatchedFlags});
    }
  }

  void checkUserDefinableOperator(Element member) {
    FunctionElement function = member.asFunctionElement();
    if (function == null) return;
    String value = member.name;
    if (value == null) return;
    if (!(isUserDefinableOperator(value) || identical(value, 'unary-'))) return;

    bool isMinus = false;
    int requiredParameterCount;
    MessageKind messageKind;
    if (identical(value, 'unary-')) {
      isMinus = true;
      messageKind = MessageKind.MINUS_OPERATOR_BAD_ARITY;
      requiredParameterCount = 0;
    } else if (isMinusOperator(value)) {
      isMinus = true;
      messageKind = MessageKind.MINUS_OPERATOR_BAD_ARITY;
      requiredParameterCount = 1;
    } else if (isUnaryOperator(value)) {
      messageKind = MessageKind.UNARY_OPERATOR_BAD_ARITY;
      requiredParameterCount = 0;
    } else if (isBinaryOperator(value)) {
      messageKind = MessageKind.BINARY_OPERATOR_BAD_ARITY;
      requiredParameterCount = 1;
      if (identical(value, '==')) checkOverrideHashCode(member);
    } else if (isTernaryOperator(value)) {
      messageKind = MessageKind.TERNARY_OPERATOR_BAD_ARITY;
      requiredParameterCount = 2;
    } else {
      reporter.internalError(
          function, 'Unexpected user defined operator $value');
    }
    checkArity(function, requiredParameterCount, messageKind, isMinus);
  }

  void checkOverrideHashCode(FunctionElement operatorEquals) {
    if (operatorEquals.isAbstract) return;
    ClassElement cls = operatorEquals.enclosingClass;
    Element hashCodeImplementation = cls.lookupLocalMember('hashCode');
    if (hashCodeImplementation != null) return;
    reporter.reportHintMessage(operatorEquals,
        MessageKind.OVERRIDE_EQUALS_NOT_HASH_CODE, {'class': cls.name});
  }

  void checkArity(FunctionElement function, int requiredParameterCount,
      MessageKind messageKind, bool isMinus) {
    FunctionExpression node = function.node;
    FunctionSignature signature = function.functionSignature;
    if (signature.requiredParameterCount != requiredParameterCount) {
      Node errorNode = node;
      if (node.parameters != null) {
        if (isMinus ||
            signature.requiredParameterCount < requiredParameterCount) {
          // If there are too few parameters, point to the whole parameter list.
          // For instance
          //
          //     int operator +() {}
          //                   ^^
          //
          //     int operator []=(value) {}
          //                     ^^^^^^^
          //
          // For operator -, always point the whole parameter list, like
          //
          //     int operator -(a, b) {}
          //                   ^^^^^^
          //
          // instead of
          //
          //     int operator -(a, b) {}
          //                       ^
          //
          // since the correction might not be to remove 'b' but instead to
          // remove 'a, b'.
          errorNode = node.parameters;
        } else {
          errorNode = node.parameters.nodes.skip(requiredParameterCount).head;
        }
      }
      reporter.reportErrorMessage(
          errorNode, messageKind, {'operatorName': function.name});
    }
    if (signature.optionalParameterCount != 0) {
      Node errorNode =
          node.parameters.nodes.skip(signature.requiredParameterCount).head;
      if (signature.optionalParametersAreNamed) {
        reporter.reportErrorMessage(
            errorNode,
            MessageKind.OPERATOR_NAMED_PARAMETERS,
            {'operatorName': function.name});
      } else {
        reporter.reportErrorMessage(
            errorNode,
            MessageKind.OPERATOR_OPTIONAL_PARAMETERS,
            {'operatorName': function.name});
      }
    }
  }

  reportErrorWithContext(Element errorneousElement, MessageKind errorMessage,
      Element contextElement, MessageKind contextMessage) {
    reporter.reportError(
        reporter.createMessage(errorneousElement, errorMessage, {
          'memberName': contextElement.name,
          'className': contextElement.enclosingClass.name
        }),
        <DiagnosticMessage>[
          reporter.createMessage(contextElement, contextMessage),
        ]);
  }

  FunctionSignature resolveSignature(FunctionElementX element) {
    MessageKind defaultValuesError = null;
    if (element.isFactoryConstructor) {
      FunctionExpression body = element.parseNode(parsingContext);
      if (body.isRedirectingFactory) {
        defaultValuesError = MessageKind.REDIRECTING_FACTORY_WITH_DEFAULT;
      }
    }
    return reporter.withCurrentElement(element, () {
      FunctionExpression node = element.parseNode(parsingContext);
      return measure(() => SignatureResolver.analyze(
          resolution,
          element.enclosingElement.buildScope(),
          node.typeVariables,
          node.parameters,
          node.returnType,
          element,
          new ResolutionRegistry(
              resolution.target, _ensureTreeElements(element)),
          defaultValuesError: defaultValuesError,
          createRealParameters: true));
    });
  }

  WorldImpact resolveTypedef(TypedefElementX element) {
    if (element.isResolved) return const ResolutionImpact();
    world.registerTypedef(element);
    return _resolveTypeDeclaration(element, () {
      ResolutionRegistry registry = new ResolutionRegistry(
          resolution.target, _ensureTreeElements(element));
      return reporter.withCurrentElement(element, () {
        return measure(() {
          assert(element.resolutionState == STATE_NOT_STARTED);
          element.resolutionState = STATE_STARTED;
          Typedef node = element.parseNode(parsingContext);
          TypedefResolverVisitor visitor =
              new TypedefResolverVisitor(resolution, element, registry);
          visitor.visit(node);
          element.resolutionState = STATE_DONE;
          return registry.impactBuilder;
        });
      });
    });
  }

  void resolveMetadataAnnotation(MetadataAnnotationX annotation) {
    reporter.withCurrentElement(
        annotation.annotatedElement,
        () => measure(() {
              assert(annotation.resolutionState == STATE_NOT_STARTED);
              annotation.resolutionState = STATE_STARTED;

              Node node = annotation.parseNode(parsingContext);
              Element annotatedElement = annotation.annotatedElement;
              AnalyzableElement context = annotatedElement.analyzableElement;
              ClassElement classElement = annotatedElement.enclosingClass;
              if (classElement != null) {
                // The annotation is resolved in the scope of [classElement].
                classElement.ensureResolved(resolution);
              }
              assert(
                  context != null,
                  failedAt(
                      node,
                      "No context found for metadata annotation "
                      "on $annotatedElement."));
              ResolverVisitor visitor =
                  visitorFor(context, useEnclosingScope: true);
              ResolutionRegistry registry = visitor.registry;
              node.accept(visitor);
              // TODO(johnniwinther): Avoid passing the [TreeElements] to
              // [compileMetadata].
              ConstantExpression constant = constantCompiler.compileMetadata(
                  annotation, node, registry.mapping);
              switch (constant.kind) {
                case ConstantExpressionKind.CONSTRUCTED:
                  ConstructedConstantExpression constructedConstant = constant;
                  ResolutionInterfaceType type = constructedConstant.type;
                  if (type.isGeneric && !type.isRaw) {
                    // Const constructor calls cannot have type arguments.
                    // TODO(24312): Remove this.
                    reporter.reportErrorMessage(
                        node, MessageKind.INVALID_METADATA_GENERIC);
                    constant = new ErroneousConstantExpression();
                  }
                  break;
                case ConstantExpressionKind.FIELD:
                case ConstantExpressionKind.ERRONEOUS:
                  break;
                default:
                  reporter.reportErrorMessage(
                      node, MessageKind.INVALID_METADATA);
                  constant = new ErroneousConstantExpression();
                  break;
              }
              annotation.constant = constant;

              constantCompiler.evaluate(annotation.constant);
              // TODO(johnniwinther): Register the relation between the
              // annotation and the annotated element instead. This will allow
              // the backend to retrieve the backend constant and only register
              // metadata on the elements for which it is needed. (Issue 17732).
              annotation.resolutionState = STATE_DONE;
            }));
  }

  List<MetadataAnnotation> resolveMetadata(
      Element element, VariableDefinitions node) {
    List<MetadataAnnotation> metadata = <MetadataAnnotation>[];
    for (Metadata annotation in node.metadata.nodes) {
      ParameterMetadataAnnotation metadataAnnotation =
          new ParameterMetadataAnnotation(annotation);
      metadataAnnotation.annotatedElement = element;
      metadata.add(metadataAnnotation.ensureResolved(resolution));
    }
    return metadata;
  }
}

TreeElements _ensureTreeElements(AnalyzableElementX element) {
  if (element._treeElements == null) {
    element._treeElements = new TreeElementMapping(element);
  }
  return element._treeElements;
}

abstract class AnalyzableElementX implements AnalyzableElement {
  TreeElements _treeElements;

  bool get hasTreeElements => _treeElements != null;

  TreeElements get treeElements {
    assert(_treeElements != null,
        failedAt(this, "TreeElements have not been computed for $this."));
    return _treeElements;
  }

  void reuseElement() {
    _treeElements = null;
  }
}
