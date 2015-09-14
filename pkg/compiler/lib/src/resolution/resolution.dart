// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution;

import 'dart:collection' show Queue;

import '../common/names.dart' show
    Identifiers;
import '../common/tasks.dart' show
    CompilerTask,
    DeferredAction;
import '../compiler.dart' show
    Compiler;
import '../compile_time_constants.dart' show
    ConstantCompiler;
import '../constants/values.dart' show
    ConstantValue;
import '../dart_types.dart';
import '../diagnostics/invariant.dart' show
    invariant;
import '../diagnostics/messages.dart' show
    MessageKind;
import '../diagnostics/spannable.dart' show
    Spannable;
import '../elements/elements.dart';
import '../elements/modelx.dart' show
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
import '../enqueue.dart' show
    WorldImpact;
import '../tokens/token.dart' show
    isBinaryOperator,
    isMinusOperator,
    isTernaryOperator,
    isUnaryOperator,
    isUserDefinableOperator;
import '../tree/tree.dart';
import '../util/util.dart' show
    Link,
    LinkBuilder,
    Setlet;

import 'class_hierarchy.dart';
import 'class_members.dart' show MembersCreator;
import 'constructors.dart';
import 'members.dart';
import 'registry.dart';
import 'signatures.dart';
import 'tree_elements.dart';
import 'typedefs.dart';

class ResolverTask extends CompilerTask {
  final ConstantCompiler constantCompiler;

  ResolverTask(Compiler compiler, this.constantCompiler) : super(compiler);

  String get name => 'Resolver';

  WorldImpact resolve(Element element) {
    return measure(() {
      if (Elements.isErroneous(element)) {
        // TODO(johnniwinther): Add a predicate for this.
        assert(invariant(element, element is! ErroneousElement,
            message: "Element $element expected to have parse errors."));
        _ensureTreeElements(element);
        return const WorldImpact();
      }

      WorldImpact processMetadata([WorldImpact result]) {
        for (MetadataAnnotation metadata in element.implementation.metadata) {
          metadata.ensureResolved(compiler);
        }
        return result;
      }

      ElementKind kind = element.kind;
      if (identical(kind, ElementKind.GENERATIVE_CONSTRUCTOR) ||
          identical(kind, ElementKind.FUNCTION) ||
          identical(kind, ElementKind.GETTER) ||
          identical(kind, ElementKind.SETTER)) {
        return processMetadata(resolveMethodElement(element));
      }

      if (identical(kind, ElementKind.FIELD)) {
        return processMetadata(resolveField(element));
      }
      if (element.isClass) {
        ClassElement cls = element;
        cls.ensureResolved(compiler);
        return processMetadata(const WorldImpact());
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        return processMetadata(resolveTypedef(typdef));
      }

      compiler.unimplemented(element, "resolve($element)");
    });
  }

  void resolveRedirectingConstructor(InitializerResolver resolver,
                                     Node node,
                                     FunctionElement constructor,
                                     FunctionElement redirection) {
    assert(invariant(node, constructor.isImplementation,
        message: 'Redirecting constructors must be resolved on implementation '
                 'elements.'));
    Setlet<FunctionElement> seen = new Setlet<FunctionElement>();
    seen.add(constructor);
    while (redirection != null) {
      // Ensure that we follow redirections through implementation elements.
      redirection = redirection.implementation;
      if (seen.contains(redirection)) {
        resolver.visitor.error(node, MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE);
        return;
      }
      seen.add(redirection);
      redirection = resolver.visitor.resolveConstructorRedirection(redirection);
    }
  }

  static void processAsyncMarker(Compiler compiler,
                                 BaseFunctionElementX element,
                                 ResolutionRegistry registry) {
    FunctionExpression functionExpression = element.node;
    AsyncModifier asyncModifier = functionExpression.asyncModifier;
    if (asyncModifier != null) {

      if (asyncModifier.isAsynchronous) {
        element.asyncMarker = asyncModifier.isYielding
            ? AsyncMarker.ASYNC_STAR : AsyncMarker.ASYNC;
      } else {
        element.asyncMarker = AsyncMarker.SYNC_STAR;
      }
      if (element.isAbstract) {
        compiler.reportError(asyncModifier,
            MessageKind.ASYNC_MODIFIER_ON_ABSTRACT_METHOD,
            {'modifier': element.asyncMarker});
      } else if (element.isConstructor) {
        compiler.reportError(asyncModifier,
            MessageKind.ASYNC_MODIFIER_ON_CONSTRUCTOR,
            {'modifier': element.asyncMarker});
      } else {
        if (element.isSetter) {
          compiler.reportError(asyncModifier,
              MessageKind.ASYNC_MODIFIER_ON_SETTER,
              {'modifier': element.asyncMarker});

        }
        if (functionExpression.body.asReturn() != null &&
            element.asyncMarker.isYielding) {
          compiler.reportError(asyncModifier,
              MessageKind.YIELDING_MODIFIER_ON_ARROW_BODY,
              {'modifier': element.asyncMarker});
        }
      }
      registry.registerAsyncMarker(element);
      switch (element.asyncMarker) {
      case AsyncMarker.ASYNC:
        compiler.futureClass.ensureResolved(compiler);
        break;
      case AsyncMarker.ASYNC_STAR:
        compiler.streamClass.ensureResolved(compiler);
        break;
      case AsyncMarker.SYNC_STAR:
        compiler.iterableClass.ensureResolved(compiler);
        break;
      }
    }
  }

  bool _isNativeClassOrExtendsNativeClass(ClassElement classElement) {
    assert(classElement != null);
    while (classElement != null) {
      if (classElement.isNative) return true;
      classElement = classElement.superclass;
    }
    return false;
  }

  WorldImpact resolveMethodElementImplementation(
      FunctionElement element, FunctionExpression tree) {
    return compiler.withCurrentElement(element, () {
      if (element.isExternal && tree.hasBody()) {
        error(element,
            MessageKind.EXTERNAL_WITH_BODY,
            {'functionName': element.name});
      }
      if (element.isConstructor) {
        if (tree.returnType != null) {
          error(tree, MessageKind.CONSTRUCTOR_WITH_RETURN_TYPE);
        }
        if (element.isConst &&
            tree.hasBody() &&
            !tree.isRedirectingFactory) {
          error(tree, MessageKind.CONST_CONSTRUCTOR_HAS_BODY);
        }
      }

      ResolverVisitor visitor = visitorFor(element);
      ResolutionRegistry registry = visitor.registry;
      registry.defineFunction(tree, element);
      visitor.setupFunction(tree, element);
      processAsyncMarker(compiler, element, registry);

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
        error(tree, MessageKind.FUNCTION_WITH_INITIALIZER);
      }

      if (!compiler.analyzeSignaturesOnly || tree.isRedirectingFactory) {
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
        Iterable<MixinApplicationElement> mixinUses =
            compiler.world.allMixinUsesOf(enclosingClass);
        ClassElement mixin = enclosingClass;
        for (MixinApplicationElement mixinApplication in mixinUses) {
          checkMixinSuperUses(resolutionTree, mixinApplication, mixin);
        }
      }

      // TODO(9631): support noSuchMethod on native classes.
      if (Elements.isInstanceMethod(element) &&
          element.name == Identifiers.noSuchMethod_ &&
          _isNativeClassOrExtendsNativeClass(enclosingClass)) {
        error(tree, MessageKind.NO_SUCH_METHOD_IN_NATIVE);
      }

      return registry.worldImpact;
    });

  }

  WorldImpact resolveMethodElement(FunctionElementX element) {
    assert(invariant(element, element.isDeclaration));
    return compiler.withCurrentElement(element, () {
      if (compiler.enqueuer.resolution.hasBeenResolved(element)) {
        // TODO(karlklose): Remove the check for [isConstructor]. [elememts]
        // should never be non-null, not even for constructors.
        assert(invariant(element, element.isConstructor,
            message: 'Non-constructor element $element '
                     'has already been analyzed.'));
        return const WorldImpact();
      }
      if (element.isSynthesized) {
        if (element.isGenerativeConstructor) {
          ResolutionRegistry registry =
              new ResolutionRegistry(compiler, _ensureTreeElements(element));
          ConstructorElement constructor = element.asFunctionElement();
          ConstructorElement target = constructor.definingConstructor;
          // Ensure the signature of the synthesized element is
          // resolved. This is the only place where the resolver is
          // seeing this element.
          element.computeSignature(compiler);
          if (!target.isErroneous) {
            registry.registerStaticUse(target);
            registry.registerImplicitSuperCall(target);
          }
          return registry.worldImpact;
        } else {
          assert(element.isDeferredLoaderGetter || element.isErroneous);
          _ensureTreeElements(element);
          return const WorldImpact();
        }
      } else {
        element.parseNode(compiler);
        element.computeType(compiler);
        FunctionElementX implementation = element;
        if (element.isExternal) {
          implementation = compiler.backend.resolveExternalFunction(element);
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
    return new ResolverVisitor(compiler, element,
        new ResolutionRegistry(compiler, _ensureTreeElements(element)),
        useEnclosingScope: useEnclosingScope);
  }

  WorldImpact resolveField(FieldElementX element) {
    VariableDefinitions tree = element.parseNode(compiler);
    if(element.modifiers.isStatic && element.isTopLevel) {
      error(element.modifiers.getStatic(),
            MessageKind.TOP_LEVEL_VARIABLE_DECLARED_STATIC);
    }
    ResolverVisitor visitor = visitorFor(element);
    ResolutionRegistry registry = visitor.registry;
    // TODO(johnniwinther): Maybe remove this when placeholderCollector migrates
    // to the backend ast.
    registry.defineElement(tree.definitions.nodes.head, element);
    // TODO(johnniwinther): Share the resolved type between all variables
    // declared in the same declaration.
    if (tree.type != null) {
      element.variables.type = visitor.resolveTypeAnnotation(tree.type);
    } else {
      element.variables.type = const DynamicType();
    }

    Expression initializer = element.initializer;
    Modifiers modifiers = element.modifiers;
    if (initializer != null) {
      // TODO(johnniwinther): Avoid analyzing initializers if
      // [Compiler.analyzeSignaturesOnly] is set.
      visitor.visit(initializer);
    } else if (modifiers.isConst) {
      compiler.reportError(element, MessageKind.CONST_WITHOUT_INITIALIZER);
    } else if (modifiers.isFinal && !element.isInstanceMember) {
      compiler.reportError(element, MessageKind.FINAL_WITHOUT_INITIALIZER);
    } else {
      registry.registerInstantiatedClass(compiler.nullClass);
    }

    if (Elements.isStaticOrTopLevelField(element)) {
      visitor.addDeferredAction(element, () {
        if (element.modifiers.isConst) {
          element.constant = constantCompiler.compileConstant(element);
        } else {
          constantCompiler.compileVariable(element);
        }
      });
      if (initializer != null) {
        if (!element.modifiers.isConst) {
          // TODO(johnniwinther): Determine the const-ness eagerly to avoid
          // unnecessary registrations.
          registry.registerLazyField();
        }
      }
    }

    // Perform various checks as side effect of "computing" the type.
    element.computeType(compiler);

    return registry.worldImpact;
  }

  DartType resolveTypeAnnotation(Element element, TypeAnnotation annotation) {
    DartType type = resolveReturnType(element, annotation);
    if (type.isVoid) {
      error(annotation, MessageKind.VOID_NOT_ALLOWED);
    }
    return type;
  }

  DartType resolveReturnType(Element element, TypeAnnotation annotation) {
    if (annotation == null) return const DynamicType();
    DartType result = visitorFor(element).resolveTypeAnnotation(annotation);
    if (result == null) {
      // TODO(karklose): warning.
      return const DynamicType();
    }
    return result;
  }

  void resolveRedirectionChain(ConstructorElementX constructor,
                               Spannable node) {
    ConstructorElementX target = constructor;
    InterfaceType targetType;
    List<Element> seen = new List<Element>();
    // Follow the chain of redirections and check for cycles.
    while (target.isRedirectingFactory) {
      if (target.internalEffectiveTarget != null) {
        // We found a constructor that already has been processed.
        targetType = target.effectiveTargetType;
        assert(invariant(target, targetType != null,
            message: 'Redirection target type has not been computed for '
                     '$target'));
        target = target.internalEffectiveTarget;
        break;
      }

      Element nextTarget = target.immediateRedirectionTarget;
      if (seen.contains(nextTarget)) {
        error(node, MessageKind.CYCLIC_REDIRECTING_FACTORY);
        targetType = target.enclosingClass.thisType;
        break;
      }
      seen.add(target);
      target = nextTarget;
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

      // [factory] must already be analyzed but the [TreeElements] might not
      // have been stored in the enqueuer cache yet.
      // TODO(johnniwinther): Store [TreeElements] in the cache before
      // resolution of the element.
      TreeElements treeElements = factory.treeElements;
      assert(invariant(node, treeElements != null,
          message: 'No TreeElements cached for $factory.'));
      FunctionExpression functionNode = factory.parseNode(compiler);
      RedirectingFactoryBody redirectionNode = functionNode.body;
      DartType factoryType = treeElements.getType(redirectionNode);
      if (!factoryType.isDynamic) {
        targetType = targetType.substByContext(factoryType);
      }
      factory.effectiveTarget = target;
      factory.effectiveTargetType = targetType;
    }
  }

  /**
   * Load and resolve the supertypes of [cls].
   *
   * Warning: do not call this method directly. It should only be
   * called by [resolveClass] and [ClassSupertypeResolver].
   */
  void loadSupertypes(BaseClassElementX cls, Spannable from) {
    compiler.withCurrentElement(cls, () => measure(() {
      if (cls.supertypeLoadState == STATE_DONE) return;
      if (cls.supertypeLoadState == STATE_STARTED) {
        compiler.reportError(from, MessageKind.CYCLIC_CLASS_HIERARCHY,
                                 {'className': cls.name});
        cls.supertypeLoadState = STATE_DONE;
        cls.hasIncompleteHierarchy = true;
        cls.allSupertypesAndSelf =
            compiler.objectClass.allSupertypesAndSelf.extendClass(
                cls.computeType(compiler));
        cls.supertype = cls.allSupertypes.head;
        assert(invariant(from, cls.supertype != null,
            message: 'Missing supertype on cyclic class $cls.'));
        cls.interfaces = const Link<DartType>();
        return;
      }
      cls.supertypeLoadState = STATE_STARTED;
      compiler.withCurrentElement(cls, () {
        // TODO(ahe): Cache the node in cls.
        cls.parseNode(compiler).accept(
            new ClassSupertypeResolver(compiler, cls));
        if (cls.supertypeLoadState != STATE_DONE) {
          cls.supertypeLoadState = STATE_DONE;
        }
      });
    }));
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
  _resolveTypeDeclaration(TypeDeclarationElement element,
                          resolveTypeDeclaration()) {
    return compiler.withCurrentElement(element, () {
      return measure(() {
        TypeDeclarationElement previousResolvedTypeDeclaration =
            currentlyResolvedTypeDeclaration;
        currentlyResolvedTypeDeclaration = element;
        var result = resolveTypeDeclaration();
        if (previousResolvedTypeDeclaration == null) {
          do {
            while (!pendingClassesToBeResolved.isEmpty) {
              pendingClassesToBeResolved.removeFirst().ensureResolved(compiler);
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
   * [:element.ensureResolved(compiler):].
   */
  TreeElements resolveClass(BaseClassElementX element) {
    return _resolveTypeDeclaration(element, () {
      // TODO(johnniwinther): Store the mapping in the resolution enqueuer.
      ResolutionRegistry registry =
          new ResolutionRegistry(compiler, _ensureTreeElements(element));
      resolveClassInternal(element, registry);
      return element.treeElements;
    });
  }

  void ensureClassWillBeResolvedInternal(ClassElement element) {
    if (currentlyResolvedTypeDeclaration == null) {
      element.ensureResolved(compiler);
    } else {
      pendingClassesToBeResolved.add(element);
    }
  }

  void resolveClassInternal(BaseClassElementX element,
                            ResolutionRegistry registry) {
    if (!element.isPatch) {
      compiler.withCurrentElement(element, () => measure(() {
        assert(element.resolutionState == STATE_NOT_STARTED);
        element.resolutionState = STATE_STARTED;
        Node tree = element.parseNode(compiler);
        loadSupertypes(element, tree);

        ClassResolverVisitor visitor =
            new ClassResolverVisitor(compiler, element, registry);
        visitor.visit(tree);
        element.resolutionState = STATE_DONE;
        compiler.onClassResolved(element);
        pendingClassesToBePostProcessed.add(element);
      }));
      if (element.isPatched) {
        // Ensure handling patch after origin.
        element.patch.ensureResolved(compiler);
      }
    } else { // Handle patch classes:
      element.resolutionState = STATE_STARTED;
      // Ensure handling origin before patch.
      element.origin.ensureResolved(compiler);
      // Ensure that the type is computed.
      element.computeType(compiler);
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
      metadata.ensureResolved(compiler);
      ConstantValue value =
          compiler.constants.getConstantValue(metadata.constant);
      if (!element.isProxy && compiler.isProxyConstant(value)) {
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
        compiler.withCurrentElement(member, () {
          for (MetadataAnnotation metadata in member.implementation.metadata) {
            metadata.ensureResolved(compiler);
          }
        });
      }
    });

    computeClassMember(element, Identifiers.call);
  }

  void computeClassMembers(ClassElement element) {
    MembersCreator.computeAllClassMembers(compiler, element);
  }

  void computeClassMember(ClassElement element, String name) {
    MembersCreator.computeClassMembersByName(compiler, element, name);
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
      compiler.reportError(
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
      compiler.reportError(mixinApplication,
                               MessageKind.ILLEGAL_MIXIN_OBJECT);
      // Avoid reporting additional errors for the Object class.
      return;
    }

    if (mixin.isEnumClass) {
      // Mixing in an enum has already caused a compile-time error.
      return;
    }

    // Check that the mixed in class has Object as its superclass.
    if (!mixin.superclass.isObject) {
      compiler.reportError(mixin, MessageKind.ILLEGAL_MIXIN_SUPERCLASS);
    }

    // Check that the mixed in class doesn't have any constructors and
    // make sure we aren't mixing in methods that use 'super'.
    mixin.forEachLocalMember((AstElement member) {
      if (member.isGenerativeConstructor && !member.isSynthesized) {
        compiler.reportError(member, MessageKind.ILLEGAL_MIXIN_CONSTRUCTOR);
      } else {
        // Get the resolution tree and check that the resolved member
        // doesn't use 'super'. This is the part of the 'super' mixin
        // check that happens when a function is resolved before the
        // mixin application has been performed.
        // TODO(johnniwinther): Obtain the [TreeElements] for [member]
        // differently.
        if (compiler.enqueuer.resolution.hasBeenResolved(member)) {
          checkMixinSuperUses(
              member.resolvedAst.elements,
              mixinApplication,
              mixin);
        }
      }
    });
  }

  void checkMixinSuperUses(TreeElements resolutionTree,
                           MixinApplicationElement mixinApplication,
                           ClassElement mixin) {
    // TODO(johnniwinther): Avoid the use of [TreeElements] here.
    if (resolutionTree == null) return;
    Iterable<Node> superUses = resolutionTree.superUses;
    if (superUses.isEmpty) return;
    compiler.reportError(mixinApplication,
                         MessageKind.ILLEGAL_MIXIN_WITH_SUPER,
                         {'className': mixin.name});
    // Show the user the problematic uses of 'super' in the mixin.
    for (Node use in superUses) {
      compiler.reportInfo(
          use,
          MessageKind.ILLEGAL_MIXIN_SUPER_USE);
    }
  }

  void checkClassMembers(ClassElement cls) {
    assert(invariant(cls, cls.isDeclaration));
    if (cls.isObject) return;
    // TODO(johnniwinther): Should this be done on the implementation element as
    // well?
    List<Element> constConstructors = <Element>[];
    List<Element> nonFinalInstanceFields = <Element>[];
    cls.forEachMember((holder, member) {
      compiler.withCurrentElement(member, () {
        // Perform various checks as side effect of "computing" the type.
        member.computeType(compiler);

        // Check modifiers.
        if (member.isFunction && member.modifiers.isFinal) {
          compiler.reportError(
              member, MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER);
        }
        if (member.isConstructor) {
          final mismatchedFlagsBits =
              member.modifiers.flags &
              (Modifiers.FLAG_STATIC | Modifiers.FLAG_ABSTRACT);
          if (mismatchedFlagsBits != 0) {
            final mismatchedFlags =
                new Modifiers.withFlags(null, mismatchedFlagsBits);
            compiler.reportError(
                member,
                MessageKind.ILLEGAL_CONSTRUCTOR_MODIFIERS,
                {'modifiers': mismatchedFlags});
          }
          if (member.modifiers.isConst) {
            constConstructors.add(member);
          }
        }
        if (member.isField) {
          if (member.modifiers.isConst && !member.modifiers.isStatic) {
            compiler.reportError(
                member, MessageKind.ILLEGAL_CONST_FIELD_MODIFIER);
          }
          if (!member.modifiers.isStatic && !member.modifiers.isFinal) {
            nonFinalInstanceFields.add(member);
          }
        }
        checkAbstractField(member);
        checkUserDefinableOperator(member);
      });
    });
    if (!constConstructors.isEmpty && !nonFinalInstanceFields.isEmpty) {
      Spannable span = constConstructors.length > 1
          ? cls : constConstructors[0];
      compiler.reportError(span,
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS,
          {'className': cls.name});
      if (constConstructors.length > 1) {
        for (Element constructor in constConstructors) {
          compiler.reportInfo(constructor,
              MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR);
        }
      }
      for (Element field in nonFinalInstanceFields) {
        compiler.reportInfo(field,
            MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD);
      }
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
      compiler.internalError(member,
          "No abstract field for accessor");
    } else if (!identical(lookupElement.kind, ElementKind.ABSTRACT_FIELD)) {
      if (lookupElement.isErroneous || lookupElement.isAmbiguous) return;
      compiler.internalError(member,
          "Inaccessible abstract field for accessor");
    }
    AbstractFieldElement field = lookupElement;

    GetterElementX getter = field.getter;
    if (getter == null) return;
    SetterElementX setter = field.setter;
    if (setter == null) return;
    int getterFlags = getter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    int setterFlags = setter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    if (!identical(getterFlags, setterFlags)) {
      final mismatchedFlags =
        new Modifiers.withFlags(null, getterFlags ^ setterFlags);
      compiler.reportError(
          field.getter,
          MessageKind.GETTER_MISMATCH,
          {'modifiers': mismatchedFlags});
      compiler.reportError(
          field.setter,
          MessageKind.SETTER_MISMATCH,
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
      compiler.internalError(function,
          'Unexpected user defined operator $value');
    }
    checkArity(function, requiredParameterCount, messageKind, isMinus);
  }

  void checkOverrideHashCode(FunctionElement operatorEquals) {
    if (operatorEquals.isAbstract) return;
    ClassElement cls = operatorEquals.enclosingClass;
    Element hashCodeImplementation =
        cls.lookupLocalMember('hashCode');
    if (hashCodeImplementation != null) return;
    compiler.reportHint(
        operatorEquals, MessageKind.OVERRIDE_EQUALS_NOT_HASH_CODE,
        {'class': cls.name});
  }

  void checkArity(FunctionElement function,
                  int requiredParameterCount, MessageKind messageKind,
                  bool isMinus) {
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
      compiler.reportError(
          errorNode, messageKind, {'operatorName': function.name});
    }
    if (signature.optionalParameterCount != 0) {
      Node errorNode =
          node.parameters.nodes.skip(signature.requiredParameterCount).head;
      if (signature.optionalParametersAreNamed) {
        compiler.reportError(
            errorNode,
            MessageKind.OPERATOR_NAMED_PARAMETERS,
            {'operatorName': function.name});
      } else {
        compiler.reportError(
            errorNode,
            MessageKind.OPERATOR_OPTIONAL_PARAMETERS,
            {'operatorName': function.name});
      }
    }
  }

  reportErrorWithContext(Element errorneousElement,
                         MessageKind errorMessage,
                         Element contextElement,
                         MessageKind contextMessage) {
    compiler.reportError(
        errorneousElement,
        errorMessage,
        {'memberName': contextElement.name,
         'className': contextElement.enclosingClass.name});
    compiler.reportInfo(contextElement, contextMessage);
  }


  FunctionSignature resolveSignature(FunctionElementX element) {
    MessageKind defaultValuesError = null;
    if (element.isFactoryConstructor) {
      FunctionExpression body = element.parseNode(compiler);
      if (body.isRedirectingFactory) {
        defaultValuesError = MessageKind.REDIRECTING_FACTORY_WITH_DEFAULT;
      }
    }
    return compiler.withCurrentElement(element, () {
      FunctionExpression node =
          compiler.parser.measure(() => element.parseNode(compiler));
      return measure(() => SignatureResolver.analyze(
          compiler, node.parameters, node.returnType, element,
          new ResolutionRegistry(compiler, _ensureTreeElements(element)),
          defaultValuesError: defaultValuesError,
          createRealParameters: true));
    });
  }

  WorldImpact resolveTypedef(TypedefElementX element) {
    if (element.isResolved) return const WorldImpact();
    compiler.world.allTypedefs.add(element);
    return _resolveTypeDeclaration(element, () {
      ResolutionRegistry registry = new ResolutionRegistry(
          compiler, _ensureTreeElements(element));
      return compiler.withCurrentElement(element, () {
        return measure(() {
          assert(element.resolutionState == STATE_NOT_STARTED);
          element.resolutionState = STATE_STARTED;
          Typedef node =
            compiler.parser.measure(() => element.parseNode(compiler));
          TypedefResolverVisitor visitor =
            new TypedefResolverVisitor(compiler, element, registry);
          visitor.visit(node);
          element.resolutionState = STATE_DONE;
          return registry.worldImpact;
        });
      });
    });
  }

  void resolveMetadataAnnotation(MetadataAnnotationX annotation) {
    compiler.withCurrentElement(annotation.annotatedElement, () => measure(() {
      assert(annotation.resolutionState == STATE_NOT_STARTED);
      annotation.resolutionState = STATE_STARTED;

      Node node = annotation.parseNode(compiler);
      Element annotatedElement = annotation.annotatedElement;
      AnalyzableElement context = annotatedElement.analyzableElement;
      ClassElement classElement = annotatedElement.enclosingClass;
      if (classElement != null) {
        // The annotation is resolved in the scope of [classElement].
        classElement.ensureResolved(compiler);
      }
      assert(invariant(node, context != null,
          message: "No context found for metadata annotation "
                   "on $annotatedElement."));
      ResolverVisitor visitor = visitorFor(context, useEnclosingScope: true);
      ResolutionRegistry registry = visitor.registry;
      node.accept(visitor);
      // TODO(johnniwinther): Avoid passing the [TreeElements] to
      // [compileMetadata].
      annotation.constant =
          constantCompiler.compileMetadata(annotation, node, registry.mapping);
      constantCompiler.evaluate(annotation.constant);
      // TODO(johnniwinther): Register the relation between the annotation
      // and the annotated element instead. This will allow the backend to
      // retrieve the backend constant and only register metadata on the
      // elements for which it is needed. (Issue 17732).
      registry.registerMetadataConstant(annotation, annotatedElement);
      annotation.resolutionState = STATE_DONE;
    }));
  }

  error(Spannable node, MessageKind kind, [arguments = const {}]) {
    compiler.reportError(node, kind, arguments);
  }

  List<MetadataAnnotation> resolveMetadata(Element element,
                                           VariableDefinitions node) {
    List<MetadataAnnotation> metadata = <MetadataAnnotation>[];
    for (Metadata annotation in node.metadata.nodes) {
      ParameterMetadataAnnotation metadataAnnotation =
          new ParameterMetadataAnnotation(annotation);
      metadataAnnotation.annotatedElement = element;
      metadata.add(metadataAnnotation.ensureResolved(compiler));
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
    assert(invariant(this, _treeElements !=null,
        message: "TreeElements have not been computed for $this."));
    return _treeElements;
  }

  void reuseElement() {
    _treeElements = null;
  }
}
