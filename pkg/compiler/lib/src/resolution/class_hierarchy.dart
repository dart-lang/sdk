// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.class_hierarchy;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../core_types.dart' show CoreClasses, CoreTypes;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart'
    show
        BaseClassElementX,
        ErroneousElementX,
        MixinApplicationElementX,
        SynthesizedConstructorElementX,
        TypeVariableElementX,
        UnnamedMixinApplicationElementX;
import '../ordered_typeset.dart' show OrderedTypeSet, OrderedTypeSetBuilder;
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/feature.dart' show Feature;
import '../util/util.dart' show Link, Setlet;
import 'enum_creator.dart';
import 'members.dart' show lookupInScope;
import 'registry.dart' show ResolutionRegistry;
import 'resolution_common.dart' show CommonResolverVisitor, MappingVisitor;
import 'scope.dart' show Scope, TypeDeclarationScope;

class TypeDefinitionVisitor extends MappingVisitor<DartType> {
  Scope scope;
  final TypeDeclarationElement enclosingElement;
  TypeDeclarationElement get element => enclosingElement;

  TypeDefinitionVisitor(Resolution resolution, TypeDeclarationElement element,
      ResolutionRegistry registry)
      : this.enclosingElement = element,
        scope = Scope.buildEnclosingScope(element),
        super(resolution, registry);

  CoreTypes get coreTypes => resolution.coreTypes;

  DartType get objectType => coreTypes.objectType;

  void resolveTypeVariableBounds(NodeList node) {
    if (node == null) return;

    Setlet<String> nameSet = new Setlet<String>();
    // Resolve the bounds of type variables.
    Iterator<DartType> types = element.typeVariables.iterator;
    Link<Node> nodeLink = node.nodes;
    while (!nodeLink.isEmpty) {
      types.moveNext();
      TypeVariableType typeVariable = types.current;
      String typeName = typeVariable.name;
      TypeVariable typeNode = nodeLink.head;
      registry.useType(typeNode, typeVariable);
      if (nameSet.contains(typeName)) {
        reporter.reportErrorMessage(
            typeNode,
            MessageKind.DUPLICATE_TYPE_VARIABLE_NAME,
            {'typeVariableName': typeName});
      }
      nameSet.add(typeName);

      TypeVariableElementX variableElement = typeVariable.element;
      if (typeNode.bound != null) {
        DartType boundType =
            typeResolver.resolveTypeAnnotation(this, typeNode.bound);
        variableElement.boundCache = boundType;

        void checkTypeVariableBound() {
          Link<TypeVariableElement> seenTypeVariables =
              const Link<TypeVariableElement>();
          seenTypeVariables = seenTypeVariables.prepend(variableElement);
          DartType bound = boundType;
          while (bound.isTypeVariable) {
            TypeVariableElement element = bound.element;
            if (seenTypeVariables.contains(element)) {
              if (identical(element, variableElement)) {
                // Only report an error on the checked type variable to avoid
                // generating multiple errors for the same cyclicity.
                reporter.reportWarningMessage(
                    typeNode.name,
                    MessageKind.CYCLIC_TYPE_VARIABLE,
                    {'typeVariableName': variableElement.name});
              }
              break;
            }
            seenTypeVariables = seenTypeVariables.prepend(element);
            bound = element.bound;
          }
        }

        addDeferredAction(element, checkTypeVariableBound);
      } else {
        variableElement.boundCache = objectType;
      }
      nodeLink = nodeLink.tail;
    }
    assert(!types.moveNext());
  }
}

/**
 * The implementation of [ResolverTask.resolveClass].
 *
 * This visitor has to be extra careful as it is building the basic
 * element information, and cannot safely look at other elements as
 * this may lead to cycles.
 *
 * This visitor can assume that the supertypes have already been
 * resolved, but it cannot call [ResolverTask.resolveClass] directly
 * or indirectly (through [ClassElement.ensureResolved]) for any other
 * types.
 */
class ClassResolverVisitor extends TypeDefinitionVisitor {
  BaseClassElementX get element => enclosingElement;

  ClassResolverVisitor(Resolution resolution, ClassElement classElement,
      ResolutionRegistry registry)
      : super(resolution, classElement, registry);

  DartType visitClassNode(ClassNode node) {
    if (element == null) {
      throw reporter.internalError(node, 'element is null');
    }
    if (element.resolutionState != STATE_STARTED) {
      throw reporter.internalError(
          element, 'cyclic resolution of class $element');
    }

    element.computeType(resolution);
    scope = new TypeDeclarationScope(scope, element);
    // TODO(ahe): It is not safe to call resolveTypeVariableBounds yet.
    // As a side-effect, this may get us back here trying to
    // resolve this class again.
    resolveTypeVariableBounds(node.typeParameters);

    // Setup the supertype for the element (if there is a cycle in the
    // class hierarchy, it has already been set to Object).
    if (element.supertype == null && node.superclass != null) {
      MixinApplication superMixin = node.superclass.asMixinApplication();
      if (superMixin != null) {
        DartType supertype = resolveSupertype(element, superMixin.superclass);
        Link<Node> link = superMixin.mixins.nodes;
        while (!link.isEmpty) {
          supertype =
              applyMixin(supertype, checkMixinType(link.head), link.head);
          link = link.tail;
        }
        element.supertype = supertype;
      } else {
        element.supertype = resolveSupertype(element, node.superclass);
      }
    }
    // If the super type isn't specified, we provide a default.  The language
    // specifies [Object] but the backend can pick a specific 'implementation'
    // of Object - the JavaScript backend chooses between Object and
    // Interceptor.
    if (element.supertype == null) {
      ClassElement superElement = registry.defaultSuperclass(element);
      // Avoid making the superclass (usually Object) extend itself.
      if (element != superElement) {
        if (superElement == null) {
          reporter.internalError(
              node, "Cannot resolve default superclass for $element.");
        } else {
          superElement.ensureResolved(resolution);
        }
        element.supertype = superElement.computeType(resolution);
      }
    }

    if (element.interfaces == null) {
      element.interfaces = resolveInterfaces(node.interfaces, node.superclass);
    } else {
      assert(invariant(element, element.hasIncompleteHierarchy));
    }
    calculateAllSupertypes(element);

    if (!element.hasConstructor) {
      Element superMember = element.superclass.localLookup('');
      if (superMember == null) {
        MessageKind kind = MessageKind.CANNOT_FIND_UNNAMED_CONSTRUCTOR;
        Map arguments = {'className': element.superclass.name};
        // TODO(ahe): Why is this a compile-time error? Or if it is an error,
        // why do we bother to registerThrowNoSuchMethod below?
        reporter.reportErrorMessage(node, kind, arguments);
        superMember = new ErroneousElementX(kind, arguments, '', element);
        registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      } else if (!superMember.isGenerativeConstructor) {
        MessageKind kind = MessageKind.SUPER_CALL_TO_FACTORY;
        Map arguments = {'className': element.superclass.name};
        // TODO(ahe): Why is this a compile-time error? Or if it is an error,
        // why do we bother to registerThrowNoSuchMethod below?
        reporter.reportErrorMessage(node, kind, arguments);
        superMember = new ErroneousElementX(kind, arguments, '', element);
        registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      } else {
        ConstructorElement superConstructor = superMember;
        superConstructor.computeType(resolution);
        if (!CallStructure.NO_ARGS
            .signatureApplies(superConstructor.functionSignature)) {
          MessageKind kind = MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT;
          reporter.reportErrorMessage(node, kind);
          superMember = new ErroneousElementX(kind, {}, '', element);
        }
      }
      FunctionElement constructor =
          new SynthesizedConstructorElementX.forDefault(superMember, element);
      if (superMember.isMalformed) {
        ErroneousElement erroneousElement = superMember;
        resolution.registerCompileTimeError(
            constructor,
            reporter.createMessage(node, erroneousElement.messageKind,
                erroneousElement.messageArguments));
      }
      element.setDefaultConstructor(constructor, reporter);
    }
    return element.computeType(resolution);
  }

  @override
  DartType visitEnum(Enum node) {
    if (element == null) {
      throw reporter.internalError(node, 'element is null');
    }
    if (element.resolutionState != STATE_STARTED) {
      throw reporter.internalError(
          element, 'cyclic resolution of class $element');
    }

    InterfaceType enumType = element.computeType(resolution);
    element.supertype = objectType;
    element.interfaces = const Link<DartType>();
    calculateAllSupertypes(element);

    if (node.names.nodes.isEmpty) {
      reporter.reportErrorMessage(
          node, MessageKind.EMPTY_ENUM_DECLARATION, {'enumName': element.name});
    }

    EnumCreator creator =
        new EnumCreator(reporter, resolution.coreTypes, element);
    creator.createMembers();
    return enumType;
  }

  /// Resolves the mixed type for [mixinNode] and checks that the mixin type
  /// is a valid, non-blacklisted interface type. The mixin type is returned.
  DartType checkMixinType(TypeAnnotation mixinNode) {
    DartType mixinType = resolveType(mixinNode);
    if (isBlackListed(mixinType)) {
      reporter.reportErrorMessage(
          mixinNode, MessageKind.CANNOT_MIXIN, {'type': mixinType});
    } else if (mixinType.isTypeVariable) {
      reporter.reportErrorMessage(mixinNode, MessageKind.CLASS_NAME_EXPECTED);
    } else if (mixinType.isMalformed) {
      reporter.reportErrorMessage(mixinNode, MessageKind.CANNOT_MIXIN_MALFORMED,
          {'className': element.name, 'malformedType': mixinType});
    } else if (mixinType.isEnumType) {
      reporter.reportErrorMessage(mixinNode, MessageKind.CANNOT_MIXIN_ENUM,
          {'className': element.name, 'enumType': mixinType});
    }
    return mixinType;
  }

  DartType visitNamedMixinApplication(NamedMixinApplication node) {
    if (element == null) {
      throw reporter.internalError(node, 'element is null');
    }
    if (element.resolutionState != STATE_STARTED) {
      throw reporter.internalError(
          element, 'cyclic resolution of class $element');
    }

    if (identical(node.classKeyword.stringValue, 'typedef')) {
      // TODO(aprelev@gmail.com): Remove this deprecation diagnostic
      // together with corresponding TODO in parser.dart.
      reporter.reportWarningMessage(
          node.classKeyword, MessageKind.DEPRECATED_TYPEDEF_MIXIN_SYNTAX);
    }

    element.computeType(resolution);
    scope = new TypeDeclarationScope(scope, element);
    resolveTypeVariableBounds(node.typeParameters);

    // Generate anonymous mixin application elements for the
    // intermediate mixin applications (excluding the last).
    DartType supertype = resolveSupertype(element, node.superclass);
    Link<Node> link = node.mixins.nodes;
    while (!link.tail.isEmpty) {
      supertype = applyMixin(supertype, checkMixinType(link.head), link.head);
      link = link.tail;
    }
    doApplyMixinTo(element, supertype, checkMixinType(link.head));
    return element.computeType(resolution);
  }

  DartType applyMixin(DartType supertype, DartType mixinType, Node node) {
    String superName = supertype.name;
    String mixinName = mixinType.name;
    MixinApplicationElementX mixinApplication =
        new UnnamedMixinApplicationElementX("${superName}+${mixinName}",
            element, resolution.idGenerator.getNextFreeId(), node);
    // Create synthetic type variables for the mixin application.
    List<DartType> typeVariables = <DartType>[];
    int index = 0;
    for (TypeVariableType type in element.typeVariables) {
      TypeVariableElementX typeVariableElement = new TypeVariableElementX(
          type.name, mixinApplication, index, type.element.node);
      TypeVariableType typeVariable = new TypeVariableType(typeVariableElement);
      typeVariables.add(typeVariable);
      index++;
    }
    // Setup bounds on the synthetic type variables.
    for (TypeVariableType type in element.typeVariables) {
      TypeVariableType typeVariable = typeVariables[type.element.index];
      TypeVariableElementX typeVariableElement = typeVariable.element;
      typeVariableElement.typeCache = typeVariable;
      typeVariableElement.boundCache =
          type.element.bound.subst(typeVariables, element.typeVariables);
    }
    // Setup this and raw type for the mixin application.
    mixinApplication.computeThisAndRawType(resolution, typeVariables);
    // Substitute in synthetic type variables in super and mixin types.
    supertype = supertype.subst(typeVariables, element.typeVariables);
    mixinType = mixinType.subst(typeVariables, element.typeVariables);

    doApplyMixinTo(mixinApplication, supertype, mixinType);
    mixinApplication.resolutionState = STATE_DONE;
    mixinApplication.supertypeLoadState = STATE_DONE;
    // Replace the synthetic type variables by the original type variables in
    // the returned type (which should be the type actually extended).
    InterfaceType mixinThisType = mixinApplication.thisType;
    return mixinThisType.subst(
        element.typeVariables, mixinThisType.typeArguments);
  }

  bool isDefaultConstructor(FunctionElement constructor) {
    if (constructor.name != '') return false;
    constructor.computeType(resolution);
    return constructor.functionSignature.parameterCount == 0;
  }

  FunctionElement createForwardingConstructor(
      ConstructorElement target, ClassElement enclosing) {
    FunctionElement constructor =
        new SynthesizedConstructorElementX.notForDefault(
            target.name, target, enclosing);
    constructor.computeType(resolution);
    return constructor;
  }

  void doApplyMixinTo(MixinApplicationElementX mixinApplication,
      DartType supertype, DartType mixinType) {
    Node node = mixinApplication.parseNode(resolution.parsingContext);

    if (mixinApplication.supertype != null) {
      // [supertype] is not null if there was a cycle.
      assert(invariant(node, reporter.hasReportedError));
      supertype = mixinApplication.supertype;
      assert(invariant(node, supertype.isObject));
    } else {
      mixinApplication.supertype = supertype;
    }

    // Named mixin application may have an 'implements' clause.
    NamedMixinApplication namedMixinApplication =
        node.asNamedMixinApplication();
    Link<DartType> interfaces = (namedMixinApplication != null)
        ? resolveInterfaces(
            namedMixinApplication.interfaces, namedMixinApplication.superclass)
        : const Link<DartType>();

    // The class that is the result of a mixin application implements
    // the interface of the class that was mixed in so always prepend
    // that to the interface list.
    if (mixinApplication.interfaces == null) {
      if (mixinType.isInterfaceType) {
        // Avoid malformed types in the interfaces.
        interfaces = interfaces.prepend(mixinType);
      }
      mixinApplication.interfaces = interfaces;
    } else {
      assert(
          invariant(mixinApplication, mixinApplication.hasIncompleteHierarchy));
    }

    ClassElement superclass = supertype.element;
    if (mixinType.kind != TypeKind.INTERFACE) {
      mixinApplication.hasIncompleteHierarchy = true;
      mixinApplication.allSupertypesAndSelf = superclass.allSupertypesAndSelf;
      return;
    }

    assert(mixinApplication.mixinType == null);
    mixinApplication.mixinType = resolveMixinFor(mixinApplication, mixinType);

    // Create forwarding constructors for constructor defined in the superclass
    // because they are now hidden by the mixin application.
    superclass.forEachLocalMember((Element member) {
      if (!member.isGenerativeConstructor) return;
      FunctionElement forwarder =
          createForwardingConstructor(member, mixinApplication);
      if (Name.isPrivateName(member.name) &&
          mixinApplication.library != superclass.library) {
        // Do not create a forwarder to the super constructor, because the mixin
        // application is in a different library than the constructor in the
        // super class and it is not possible to call that constructor from the
        // library using the mixin application.
        return;
      }
      mixinApplication.addConstructor(forwarder);
    });
    calculateAllSupertypes(mixinApplication);
  }

  InterfaceType resolveMixinFor(
      MixinApplicationElement mixinApplication, DartType mixinType) {
    ClassElement mixin = mixinType.element;
    mixin.ensureResolved(resolution);

    // Check for cycles in the mixin chain.
    ClassElement previous = mixinApplication; // For better error messages.
    ClassElement current = mixin;
    while (current != null && current.isMixinApplication) {
      MixinApplicationElement currentMixinApplication = current;
      if (currentMixinApplication == mixinApplication) {
        reporter.reportErrorMessage(
            mixinApplication,
            MessageKind.ILLEGAL_MIXIN_CYCLE,
            {'mixinName1': current.name, 'mixinName2': previous.name});
        // We have found a cycle in the mixin chain. Return null as
        // the mixin for this application to avoid getting into
        // infinite recursion when traversing members.
        return null;
      }
      previous = current;
      current = currentMixinApplication.mixin;
    }
    return mixinType;
  }

  DartType resolveType(TypeAnnotation node) {
    return typeResolver.resolveTypeAnnotation(this, node);
  }

  DartType resolveSupertype(ClassElement cls, TypeAnnotation superclass) {
    DartType supertype = resolveType(superclass);
    if (supertype != null) {
      if (supertype.isMalformed) {
        reporter.reportErrorMessage(
            superclass,
            MessageKind.CANNOT_EXTEND_MALFORMED,
            {'className': element.name, 'malformedType': supertype});
        return objectType;
      } else if (supertype.isEnumType) {
        reporter.reportErrorMessage(superclass, MessageKind.CANNOT_EXTEND_ENUM,
            {'className': element.name, 'enumType': supertype});
        return objectType;
      } else if (!supertype.isInterfaceType) {
        reporter.reportErrorMessage(
            superclass.typeName, MessageKind.CLASS_NAME_EXPECTED);
        return objectType;
      } else if (isBlackListed(supertype)) {
        reporter.reportErrorMessage(
            superclass, MessageKind.CANNOT_EXTEND, {'type': supertype});
        return objectType;
      }
    }
    return supertype;
  }

  Link<DartType> resolveInterfaces(NodeList interfaces, Node superclass) {
    Link<DartType> result = const Link<DartType>();
    if (interfaces == null) return result;
    for (Link<Node> link = interfaces.nodes; !link.isEmpty; link = link.tail) {
      DartType interfaceType = resolveType(link.head);
      if (interfaceType != null) {
        if (interfaceType.isMalformed) {
          reporter.reportErrorMessage(
              superclass,
              MessageKind.CANNOT_IMPLEMENT_MALFORMED,
              {'className': element.name, 'malformedType': interfaceType});
        } else if (interfaceType.isEnumType) {
          reporter.reportErrorMessage(
              superclass,
              MessageKind.CANNOT_IMPLEMENT_ENUM,
              {'className': element.name, 'enumType': interfaceType});
        } else if (!interfaceType.isInterfaceType) {
          // TODO(johnniwinther): Handle dynamic.
          TypeAnnotation typeAnnotation = link.head;
          reporter.reportErrorMessage(
              typeAnnotation.typeName, MessageKind.CLASS_NAME_EXPECTED);
        } else {
          if (interfaceType == element.supertype) {
            reporter.reportErrorMessage(
                superclass,
                MessageKind.DUPLICATE_EXTENDS_IMPLEMENTS,
                {'type': interfaceType});
            reporter.reportErrorMessage(
                link.head,
                MessageKind.DUPLICATE_EXTENDS_IMPLEMENTS,
                {'type': interfaceType});
          }
          if (result.contains(interfaceType)) {
            reporter.reportErrorMessage(link.head,
                MessageKind.DUPLICATE_IMPLEMENTS, {'type': interfaceType});
          }
          result = result.prepend(interfaceType);
          if (isBlackListed(interfaceType)) {
            reporter.reportErrorMessage(link.head, MessageKind.CANNOT_IMPLEMENT,
                {'type': interfaceType});
          }
        }
      }
    }
    return result;
  }

  /**
   * Compute the list of all supertypes.
   *
   * The elements of this list are ordered as follows: first the supertype that
   * the class extends, then the implemented interfaces, and then the supertypes
   * of these.  The class [Object] appears only once, at the end of the list.
   *
   * For example, for a class `class C extends S implements I1, I2`, we compute
   *   supertypes(C) = [S, I1, I2] ++ supertypes(S) ++ supertypes(I1)
   *                   ++ supertypes(I2),
   * where ++ stands for list concatenation.
   *
   * This order makes sure that if a class implements an interface twice with
   * different type arguments, the type used in the most specific class comes
   * first.
   */
  void calculateAllSupertypes(BaseClassElementX cls) {
    if (cls.allSupertypesAndSelf != null) return;
    final DartType supertype = cls.supertype;
    if (supertype != null) {
      cls.allSupertypesAndSelf = new OrderedTypeSetBuilder(cls,
              reporter: reporter, objectType: coreTypes.objectType)
          .createOrderedTypeSet(supertype, cls.interfaces);
    } else {
      assert(cls == resolution.coreClasses.objectClass);
      cls.allSupertypesAndSelf =
          new OrderedTypeSet.singleton(cls.computeType(resolution));
    }
  }

  isBlackListed(DartType type) {
    LibraryElement lib = element.library;
    return !identical(lib, resolution.commonElements.coreLibrary) &&
        !resolution.target.isTargetSpecificLibrary(lib) &&
        (type.isDynamic ||
            type == coreTypes.boolType ||
            type == coreTypes.numType ||
            type == coreTypes.intType ||
            type == coreTypes.doubleType ||
            type == coreTypes.stringType ||
            type == coreTypes.nullType);
  }
}

class ClassSupertypeResolver extends CommonResolverVisitor {
  Scope context;
  ClassElement classElement;

  ClassSupertypeResolver(Resolution resolution, ClassElement cls)
      : context = Scope.buildEnclosingScope(cls),
        this.classElement = cls,
        super(resolution);

  CoreClasses get coreClasses => resolution.coreClasses;

  void loadSupertype(ClassElement element, Node from) {
    if (!element.isResolved) {
      resolution.resolver.loadSupertypes(element, from);
      element.ensureResolved(resolution);
    }
  }

  void visitNodeList(NodeList node) {
    if (node != null) {
      for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
        link.head.accept(this);
      }
    }
  }

  void visitClassNode(ClassNode node) {
    if (node.superclass == null) {
      if (classElement != coreClasses.objectClass) {
        loadSupertype(coreClasses.objectClass, node);
      }
    } else {
      node.superclass.accept(this);
    }
    visitNodeList(node.interfaces);
  }

  void visitEnum(Enum node) {
    loadSupertype(coreClasses.objectClass, node);
  }

  void visitMixinApplication(MixinApplication node) {
    node.superclass.accept(this);
    visitNodeList(node.mixins);
  }

  void visitNamedMixinApplication(NamedMixinApplication node) {
    node.superclass.accept(this);
    visitNodeList(node.mixins);
    visitNodeList(node.interfaces);
  }

  void visitTypeAnnotation(TypeAnnotation node) {
    node.typeName.accept(this);
  }

  void visitIdentifier(Identifier node) {
    Element element = lookupInScope(reporter, node, context, node.source);
    if (element != null && element.isClass) {
      loadSupertype(element, node);
    }
  }

  void visitSend(Send node) {
    Identifier prefix = node.receiver.asIdentifier();
    if (prefix == null) {
      reporter.reportErrorMessage(
          node.receiver, MessageKind.NOT_A_PREFIX, {'node': node.receiver});
      return;
    }
    Element element = lookupInScope(reporter, prefix, context, prefix.source);
    if (element == null || !identical(element.kind, ElementKind.PREFIX)) {
      reporter.reportErrorMessage(
          node.receiver, MessageKind.NOT_A_PREFIX, {'node': node.receiver});
      return;
    }
    PrefixElement prefixElement = element;
    Identifier selector = node.selector.asIdentifier();
    var e = prefixElement.lookupLocalMember(selector.source);
    if (e == null || !e.impliesType) {
      reporter.reportErrorMessage(node.selector,
          MessageKind.CANNOT_RESOLVE_TYPE, {'typeName': node.selector});
      return;
    }
    loadSupertype(e, node);
  }
}
