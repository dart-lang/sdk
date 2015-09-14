// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.typechecker;

import 'common/names.dart' show
    Identifiers;
import 'common/tasks.dart' show
    CompilerTask;
import 'compiler.dart' show
    Compiler;
import 'constants/expressions.dart';
import 'constants/values.dart';
import 'core_types.dart';
import 'dart_types.dart';
import 'diagnostics/invariant.dart' show
    invariant;
import 'diagnostics/messages.dart';
import 'diagnostics/spannable.dart' show
    Spannable;
import 'elements/elements.dart' show
    AbstractFieldElement,
    AstElement,
    AsyncMarker,
    ClassElement,
    ConstructorElement,
    Element,
    Elements,
    EnumClassElement,
    ExecutableElement,
    FieldElement,
    FunctionElement,
    GetterElement,
    InitializingFormalElement,
    LibraryElement,
    Member,
    MemberSignature,
    Name,
    ParameterElement,
    PrivateName,
    PublicName,
    ResolvedAst,
    SetterElement,
    TypeDeclarationElement,
    TypedElement,
    TypedefElement,
    VariableElement;
import 'resolution/tree_elements.dart' show
    TreeElements;
import 'resolution/class_members.dart' show
    MembersCreator;
import 'tree/tree.dart';
import 'util/util.dart' show
    Link,
    LinkBuilder;
import '../compiler_new.dart' as api;

class TypeCheckerTask extends CompilerTask {
  TypeCheckerTask(Compiler compiler) : super(compiler);
  String get name => "Type checker";

  void check(AstElement element) {
    if (element.isClass) return;
    if (element.isTypedef) return;
    ResolvedAst resolvedAst = element.resolvedAst;
    compiler.withCurrentElement(element.implementation, () {
      measure(() {
        TypeCheckerVisitor visitor = new TypeCheckerVisitor(
            compiler, resolvedAst.elements, compiler.types);
        if (element.isField) {
          visitor.analyzingInitializer = true;
        }
        resolvedAst.node.accept(visitor);
      });
    });
  }
}

/**
 * Class used to report different warnings for differrent kinds of members.
 */
class MemberKind {
  static const MemberKind METHOD = const MemberKind("method");
  static const MemberKind OPERATOR = const MemberKind("operator");
  static const MemberKind GETTER = const MemberKind("getter");
  static const MemberKind SETTER = const MemberKind("setter");

  final String name;

  const MemberKind(this.name);

  String toString() => name;
}

/**
 * [ElementAccess] represents the access of [element], either as a property
 * access or invocation.
 */
abstract class ElementAccess {
  Element get element;

  String get name => element.name;

  DartType computeType(Compiler compiler);

  /// Returns [: true :] if the element can be access as an invocation.
  bool isCallable(Compiler compiler) {
    if (element != null && element.isAbstractField) {
      AbstractFieldElement abstractFieldElement = element;
      if (abstractFieldElement.getter == null) {
        // Setters cannot be invoked as function invocations.
        return false;
      }
    }
    return compiler.types.isAssignable(
        computeType(compiler), compiler.coreTypes.functionType);
  }
}

/// An access of a instance member.
class MemberAccess extends ElementAccess {
  final MemberSignature member;

  MemberAccess(MemberSignature this.member);

  Element get element => member.declarations.first.element;

  DartType computeType(Compiler compiler) => member.type;

  String toString() => 'MemberAccess($member)';
}

/// An access of an unresolved element.
class DynamicAccess implements ElementAccess {
  const DynamicAccess();

  Element get element => null;

  String get name => 'dynamic';

  DartType computeType(Compiler compiler) => const DynamicType();

  bool isCallable(Compiler compiler) => true;

  String toString() => 'DynamicAccess';
}

/// An access of the `assert` method.
class AssertAccess implements ElementAccess {
  const AssertAccess();

  Element get element => null;

  String get name => 'assert';

  DartType computeType(Compiler compiler) {
    return new FunctionType.synthesized(
        const VoidType(),
        <DartType>[const DynamicType()]);
  }

  bool isCallable(Compiler compiler) => true;

  String toString() => 'AssertAccess';
}

/**
 * An access of a resolved top-level or static property or function, or an
 * access of a resolved element through [:this:].
 */
class ResolvedAccess extends ElementAccess {
  final Element element;

  ResolvedAccess(Element this.element) {
    assert(element != null);
  }

  DartType computeType(Compiler compiler) {
    if (element.isGetter) {
      GetterElement getter = element;
      FunctionType functionType = getter.computeType(compiler);
      return functionType.returnType;
    } else if (element.isSetter) {
      SetterElement setter = element;
      FunctionType functionType = setter.computeType(compiler);
      if (functionType.parameterTypes.length != 1) {
        // TODO(johnniwinther,karlklose): this happens for malformed static
        // setters. Treat them the same as instance members.
        return const DynamicType();
      }
      return functionType.parameterTypes.first;
    } else if (element.isTypedef || element.isClass) {
      TypeDeclarationElement typeDeclaration = element;
      typeDeclaration.computeType(compiler);
      return typeDeclaration.thisType;
    } else {
      TypedElement typedElement = element;
      typedElement.computeType(compiler);
      return typedElement.type;
    }
  }

  String toString() => 'ResolvedAccess($element)';
}

/// An access to a promoted variable.
class PromotedAccess extends ElementAccess {
  final VariableElement element;
  final DartType type;

  PromotedAccess(VariableElement this.element, DartType this.type) {
    assert(element != null);
    assert(type != null);
  }

  DartType computeType(Compiler compiler) => type;

  String toString() => 'PromotedAccess($element,$type)';
}

/**
 * An access of a resolved top-level or static property or function, or an
 * access of a resolved element through [:this:].
 */
class TypeAccess extends ElementAccess {
  final DartType type;
  TypeAccess(DartType this.type) {
    assert(type != null);
  }

  Element get element => type.element;

  DartType computeType(Compiler compiler) => type;

  String toString() => 'TypeAccess($type)';
}

/**
 * An access of a type literal.
 */
class TypeLiteralAccess extends ElementAccess {
  final DartType type;

  TypeLiteralAccess(this.type) {
    assert(type != null);
  }

  Element get element => type.element;

  String get name => type.name;

  DartType computeType(Compiler compiler) => compiler.typeClass.rawType;

  String toString() => 'TypeLiteralAccess($type)';
}


/// An access to the 'call' method of a function type.
class FunctionCallAccess implements ElementAccess {
  final Element element;
  final DartType type;

  const FunctionCallAccess(this.element, this.type);

  String get name => 'call';

  DartType computeType(Compiler compiler) => type;

  bool isCallable(Compiler compiler) => true;

  String toString() => 'FunctionAccess($element, $type)';
}


/// An is-expression that potentially promotes a variable.
class TypePromotion {
  final Send node;
  final VariableElement variable;
  final DartType type;
  final List<TypePromotionMessage> messages = <TypePromotionMessage>[];

  TypePromotion(this.node, this.variable, this.type);

  bool get isValid => messages.isEmpty;

  TypePromotion copy() {
    return new TypePromotion(node, variable, type)..messages.addAll(messages);
  }

  void addHint(Spannable spannable, MessageKind kind, [Map arguments]) {
    messages.add(new TypePromotionMessage(api.Diagnostic.HINT,
        spannable, kind, arguments));
  }

  void addInfo(Spannable spannable, MessageKind kind, [Map arguments]) {
    messages.add(new TypePromotionMessage(api.Diagnostic.INFO,
        spannable, kind, arguments));
  }

  String toString() {
    return 'Promote ${variable} to ${type}${isValid ? '' : ' (invalid)'}';
  }
}

/// A hint or info message attached to a type promotion.
class TypePromotionMessage {
  api.Diagnostic diagnostic;
  Spannable spannable;
  MessageKind messageKind;
  Map messageArguments;

  TypePromotionMessage(this.diagnostic, this.spannable, this.messageKind,
                       [this.messageArguments]);
}

class TypeCheckerVisitor extends Visitor<DartType> {
  final Compiler compiler;
  final TreeElements elements;
  final Types types;

  Node lastSeenNode;
  DartType expectedReturnType;
  AsyncMarker currentAsyncMarker = AsyncMarker.SYNC;

  final ClassElement currentClass;

  /// The immediately enclosing field, method or constructor being analyzed.
  ExecutableElement executableContext;

  CoreTypes get coreTypes => compiler.coreTypes;

  InterfaceType get intType => coreTypes.intType;
  InterfaceType get doubleType => coreTypes.doubleType;
  InterfaceType get boolType => coreTypes.boolType;
  InterfaceType get stringType => coreTypes.stringType;

  DartType thisType;
  DartType superType;

  Link<DartType> cascadeTypes = const Link<DartType>();

  bool analyzingInitializer = false;

  Map<Node, List<TypePromotion>> shownTypePromotionsMap =
      new Map<Node, List<TypePromotion>>();

  Map<VariableElement, Link<TypePromotion>> typePromotionsMap =
      new Map<VariableElement, Link<TypePromotion>>();

  Set<TypePromotion> reportedTypePromotions = new Set<TypePromotion>();

  void showTypePromotion(Node node, TypePromotion typePromotion) {
    List<TypePromotion> shownTypePromotions =
        shownTypePromotionsMap.putIfAbsent(node, () => <TypePromotion>[]);
    shownTypePromotions.add(typePromotion);
  }

  void registerKnownTypePromotion(TypePromotion typePromotion) {
    VariableElement variable = typePromotion.variable;
    Link<TypePromotion> knownTypes =
        typePromotionsMap.putIfAbsent(variable,
                                      () => const Link<TypePromotion>());
    typePromotionsMap[variable] = knownTypes.prepend(typePromotion);
  }

  void unregisterKnownTypePromotion(TypePromotion typePromotion) {
    VariableElement variable = typePromotion.variable;
    Link<TypePromotion> knownTypes = typePromotionsMap[variable].tail;
    if (knownTypes.isEmpty) {
      typePromotionsMap.remove(variable);
    } else {
      typePromotionsMap[variable] = knownTypes;
    }
  }

  List<TypePromotion> getShownTypePromotionsFor(Node node) {
    List<TypePromotion> shownTypePromotions = shownTypePromotionsMap[node];
    return shownTypePromotions != null ? shownTypePromotions : const [];
  }

  TypePromotion getKnownTypePromotion(VariableElement element) {
    Link<TypePromotion> promotions = typePromotionsMap[element];
    if (promotions != null) {
      while (!promotions.isEmpty) {
        TypePromotion typePromotion = promotions.head;
        if (typePromotion.isValid) {
          return typePromotion;
        }
        promotions = promotions.tail;
      }
    }
    return null;
  }

  DartType getKnownType(VariableElement element) {
    TypePromotion typePromotion = getKnownTypePromotion(element);
    if (typePromotion != null) return typePromotion.type;
    return element.type;
  }

  TypeCheckerVisitor(this.compiler, TreeElements elements, this.types)
      : this.elements = elements,
        this.executableContext = elements.analyzedElement,
        this.currentClass = elements.analyzedElement != null
            ? elements.analyzedElement.enclosingClass : null {

    if (currentClass != null) {
      thisType = currentClass.thisType;
      superType = currentClass.supertype;
    } else {
      // If these are used, an error should have been reported by the resolver.
      thisType = const DynamicType();
      superType = const DynamicType();
    }
  }

  LibraryElement get currentLibrary => elements.analyzedElement.library;

  reportTypeWarning(Spannable spannable, MessageKind kind,
                    [Map arguments = const {}]) {
    compiler.reportWarning(spannable, kind, arguments);
  }

  reportMessage(Spannable spannable, MessageKind kind,
                Map arguments,
                {bool isHint: false}) {
    if (isHint) {
      compiler.reportHint(spannable, kind, arguments);
    } else {
      compiler.reportWarning(spannable, kind, arguments);
    }
  }

  reportTypeInfo(Spannable spannable, MessageKind kind,
                 [Map arguments = const {}]) {
    compiler.reportInfo(spannable, kind, arguments);
  }

  reportTypePromotionHint(TypePromotion typePromotion) {
    if (!reportedTypePromotions.contains(typePromotion)) {
      reportedTypePromotions.add(typePromotion);
      for (TypePromotionMessage message in typePromotion.messages) {
        switch (message.diagnostic) {
          case api.Diagnostic.HINT:
            compiler.reportHint(message.spannable,
                                message.messageKind,
                                message.messageArguments);
            break;
          case api.Diagnostic.INFO:
            compiler.reportInfo(message.spannable,
                                message.messageKind,
                                message.messageArguments);
            break;
        }
      }
    }
  }

  // TODO(karlklose): remove these functions.
  DartType unhandledExpression() => const DynamicType();

  DartType analyzeNonVoid(Node node) {
    DartType type = analyze(node);
    if (type.isVoid) {
      reportTypeWarning(node, MessageKind.VOID_EXPRESSION);
    }
    return type;
  }

  DartType analyzeWithDefault(Node node, DartType defaultValue) {
    return node != null ? analyze(node) : defaultValue;
  }

  /// If [inInitializer] is true, assignment should be interpreted as write to
  /// a field and not to a setter.
  DartType analyze(Node node, {bool inInitializer: false}) {
    if (node == null) {
      final String error = 'Unexpected node: null';
      if (lastSeenNode != null) {
        compiler.internalError(lastSeenNode, error);
      } else {
        compiler.internalError(executableContext, error);
      }
    } else {
      lastSeenNode = node;
    }
    bool previouslyInitializer = analyzingInitializer;
    analyzingInitializer = inInitializer;
    DartType result = node.accept(this);
    analyzingInitializer = previouslyInitializer;
    if (result == null) {
      compiler.internalError(node, 'Type is null.');
    }
    return result;
  }

  void checkTypePromotion(Node node, TypePromotion typePromotion,
                          {bool checkAccesses: false}) {
    VariableElement variable = typePromotion.variable;
    String variableName = variable.name;
    List<Node> potentialMutationsIn =
        elements.getPotentialMutationsIn(node, variable);
    if (!potentialMutationsIn.isEmpty) {
      typePromotion.addHint(typePromotion.node,
          MessageKind.POTENTIAL_MUTATION,
          {'variableName': variableName, 'shownType': typePromotion.type});
      for (Node mutation in potentialMutationsIn) {
        typePromotion.addInfo(mutation,
            MessageKind.POTENTIAL_MUTATION_HERE,
            {'variableName': variableName});
      }
    }
    List<Node> potentialMutationsInClosures =
        elements.getPotentialMutationsInClosure(variable);
    if (!potentialMutationsInClosures.isEmpty) {
      typePromotion.addHint(typePromotion.node,
          MessageKind.POTENTIAL_MUTATION_IN_CLOSURE,
          {'variableName': variableName, 'shownType': typePromotion.type});
      for (Node mutation in potentialMutationsInClosures) {
        typePromotion.addInfo(mutation,
            MessageKind.POTENTIAL_MUTATION_IN_CLOSURE_HERE,
            {'variableName': variableName});
      }
    }
    if (checkAccesses) {
      List<Node> accesses = elements.getAccessesByClosureIn(node, variable);
      List<Node> mutations = elements.getPotentialMutations(variable);
      if (!accesses.isEmpty && !mutations.isEmpty) {
        typePromotion.addHint(typePromotion.node,
            MessageKind.ACCESSED_IN_CLOSURE,
            {'variableName': variableName, 'shownType': typePromotion.type});
        for (Node access in accesses) {
          typePromotion.addInfo(access,
              MessageKind.ACCESSED_IN_CLOSURE_HERE,
              {'variableName': variableName});
        }
        for (Node mutation in mutations) {
          typePromotion.addInfo(mutation,
              MessageKind.POTENTIAL_MUTATION_HERE,
              {'variableName': variableName});
        }
      }
    }
  }

  /// Show type promotions from [left] and [right] in [node] given that the
  /// promoted variables are not potentially mutated in [right].
  void reshowTypePromotions(Node node, Node left, Node right) {
    for (TypePromotion typePromotion in  getShownTypePromotionsFor(left)) {
      typePromotion = typePromotion.copy();
      checkTypePromotion(right, typePromotion);
      showTypePromotion(node, typePromotion);
    }

    for (TypePromotion typePromotion in getShownTypePromotionsFor(right)) {
      typePromotion = typePromotion.copy();
      checkTypePromotion(right, typePromotion);
      showTypePromotion(node, typePromotion);
    }
  }

  /// Analyze [node] in the context of the known types shown in [context].
  DartType analyzeInPromotedContext(Node context, Node node) {
    Link<TypePromotion> knownForNode = const Link<TypePromotion>();
    for (TypePromotion typePromotion in  getShownTypePromotionsFor(context)) {
      typePromotion = typePromotion.copy();
      checkTypePromotion(node, typePromotion, checkAccesses: true);
      knownForNode = knownForNode.prepend(typePromotion);
      registerKnownTypePromotion(typePromotion);
    }

    final DartType type = analyze(node);

    while (!knownForNode.isEmpty) {
      unregisterKnownTypePromotion(knownForNode.head);
      knownForNode = knownForNode.tail;
    }

    return type;
  }

  /**
   * Check if a value of type [from] can be assigned to a variable, parameter or
   * return value of type [to].  If `isConst == true`, an error is emitted in
   * checked mode, otherwise a warning is issued.
   */
  bool checkAssignable(Spannable spannable, DartType from, DartType to,
                       {bool isConst: false}) {
    if (!types.isAssignable(from, to)) {
      if (compiler.enableTypeAssertions && isConst) {
        compiler.reportError(spannable, MessageKind.NOT_ASSIGNABLE,
                             {'fromType': from, 'toType': to});
      } else {
        reportTypeWarning(spannable, MessageKind.NOT_ASSIGNABLE,
                          {'fromType': from, 'toType': to});
      }
      return false;
    }
    return true;
  }

  checkCondition(Expression condition) {
    checkAssignable(condition, analyze(condition), boolType);
  }

  void pushCascadeType(DartType type) {
    cascadeTypes = cascadeTypes.prepend(type);
  }

  DartType popCascadeType() {
    DartType type = cascadeTypes.head;
    cascadeTypes = cascadeTypes.tail;
    return type;
  }

  DartType visitBlock(Block node) {
    return analyze(node.statements);
  }

  DartType visitCascade(Cascade node) {
    analyze(node.expression);
    return popCascadeType();
  }

  DartType visitCascadeReceiver(CascadeReceiver node) {
    DartType type = analyze(node.expression);
    pushCascadeType(type);
    return type;
  }

  DartType visitDoWhile(DoWhile node) {
    analyze(node.body);
    checkCondition(node.condition);
    return const StatementType();
  }

  DartType visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    analyze(expression);
    return const StatementType();
  }

  /** Dart Programming Language Specification: 11.5.1 For Loop */
  DartType visitFor(For node) {
    if (node.initializer != null) {
      analyze(node.initializer);
    }
    if (node.condition != null) {
      checkCondition(node.condition);
    }
    if (node.update != null) {
      analyze(node.update);
    }
    return analyze(node.body);
  }

  DartType visitFunctionDeclaration(FunctionDeclaration node) {
    analyze(node.function);
    return const StatementType();
  }

  DartType visitFunctionExpression(FunctionExpression node) {
    DartType type;
    DartType returnType;
    final FunctionElement element = elements.getFunctionDefinition(node);
    assert(invariant(node, element != null,
                     message: 'FunctionExpression with no element'));
    if (Elements.isUnresolved(element)) return const DynamicType();
    if (element.isGenerativeConstructor) {
      type = const DynamicType();
      returnType = const VoidType();

      element.functionSignature.forEachParameter((ParameterElement parameter) {
        if (parameter.isInitializingFormal) {
          InitializingFormalElement fieldParameter = parameter;
          checkAssignable(parameter, parameter.type,
              fieldParameter.fieldElement.computeType(compiler));
        }
      });
      if (node.initializers != null) {
        analyze(node.initializers, inInitializer: true);
      }
    } else {
      FunctionType functionType = element.computeType(compiler);
      returnType = functionType.returnType;
      type = functionType;
    }
    ExecutableElement previousExecutableContext = executableContext;
    DartType previousReturnType = expectedReturnType;
    expectedReturnType = returnType;
    AsyncMarker previousAsyncMarker = currentAsyncMarker;

    executableContext = element;
    currentAsyncMarker = element.asyncMarker;
    analyze(node.body);

    executableContext = previousExecutableContext;
    expectedReturnType = previousReturnType;
    currentAsyncMarker = previousAsyncMarker;
    return type;
  }

  DartType visitIdentifier(Identifier node) {
    if (node.isThis()) {
      return thisType;
    } else if (node.isSuper()) {
      return superType;
    } else {
      TypedElement element = elements[node];
      assert(invariant(node, element != null,
          message: 'Missing element for identifier'));
      assert(invariant(node, element.isVariable ||
                             element.isParameter ||
                             element.isField,
          message: 'Unexpected context element ${element}'));
      return element.computeType(compiler);
    }
  }

  DartType visitIf(If node) {
    Expression condition = node.condition.expression;
    Statement thenPart = node.thenPart;

    checkCondition(node.condition);
    analyzeInPromotedContext(condition, thenPart);
    if (node.elsePart != null) {
      analyze(node.elsePart);
    }
    return const StatementType();
  }

  void checkPrivateAccess(Node node, Element element, String name) {
    if (name != null &&
        Name.isPrivateName(name) &&
        element.library != currentLibrary) {
      reportTypeWarning(
          node,
          MessageKind.PRIVATE_ACCESS,
          {'name': name,
           'libraryName': element.library.getLibraryOrScriptName()});
    }

  }

  ElementAccess lookupMember(Node node, DartType receiverType, String name,
                             MemberKind memberKind, Element receiverElement,
                             {bool lookupClassMember: false,
                              bool isHint: false}) {
    if (receiverType.treatAsDynamic) {
      return const DynamicAccess();
    }

    Name memberName = new Name(name, currentLibrary,
        isSetter: memberKind == MemberKind.SETTER);

    // Lookup the class or interface member [name] in [interface].
    MemberSignature lookupMemberSignature(Name name, InterfaceType interface) {
      MembersCreator.computeClassMembersByName(
          compiler, interface.element, name.text);
      return lookupClassMember || analyzingInitializer
          ? interface.lookupClassMember(name)
          : interface.lookupInterfaceMember(name);
    }

    // Compute the access of [name] on [type]. This function takes the special
    // 'call' method into account.
    ElementAccess getAccess(Name name,
                            DartType unaliasedBound, InterfaceType interface) {
      MemberSignature member = lookupMemberSignature(memberName, interface);
      if (member != null) {
        return new MemberAccess(member);
      }
      if (name == const PublicName('call')) {
        if (unaliasedBound.isFunctionType) {
          // This is an access the implicit 'call' method of a function type.
          return new FunctionCallAccess(receiverElement, unaliasedBound);
        }
        if (types.isSubtype(interface, compiler.functionClass.rawType)) {
          // This is an access of the special 'call' method implicitly defined
          // on 'Function'. This method can be called with any arguments, which
          // we ensure by giving it the type 'dynamic'.
          return new FunctionCallAccess(null, const DynamicType());
        }
      }
      return null;
    }

    DartType unaliasedBound =
        Types.computeUnaliasedBound(compiler, receiverType);
    if (unaliasedBound.treatAsDynamic) {
      return new DynamicAccess();
    }
    InterfaceType interface =
        Types.computeInterfaceType(compiler, unaliasedBound);
    ElementAccess access = getAccess(memberName, unaliasedBound, interface);
    if (access != null) {
      return access;
    }
    if (receiverElement != null &&
        (receiverElement.isVariable || receiverElement.isParameter)) {
      Link<TypePromotion> typePromotions = typePromotionsMap[receiverElement];
      if (typePromotions != null) {
        while (!typePromotions.isEmpty) {
          TypePromotion typePromotion = typePromotions.head;
          if (!typePromotion.isValid) {
            DartType unaliasedBound =
                Types.computeUnaliasedBound(compiler, typePromotion.type);
            if (!unaliasedBound.treatAsDynamic) {
              InterfaceType interface =
                  Types.computeInterfaceType(compiler, unaliasedBound);
              if (getAccess(memberName, unaliasedBound, interface) != null) {
                reportTypePromotionHint(typePromotion);
              }
            }
          }
          typePromotions = typePromotions.tail;
        }
      }
    }
    // We didn't find a member with the correct name.  If this lookup is for a
    // super or redirecting initializer, the resolver has already emitted an
    // error message.  If the target is a proxy, no warning needs to be emitted.
    // Otherwise, try to emit the most precise warning.
    if (!interface.element.isProxy && !analyzingInitializer) {
      bool foundPrivateMember = false;
      if (memberName.isPrivate) {
        void findPrivateMember(MemberSignature member) {
          if (memberName.isSimilarTo(member.name)) {
            PrivateName privateName = member.name;
            reportMessage(
                 node,
                 MessageKind.PRIVATE_ACCESS,
                 {'name': name,
                  'libraryName': privateName.library.getLibraryOrScriptName()},
                 isHint: isHint);
            foundPrivateMember = true;
          }
        }
        // TODO(johnniwinther): Avoid computation of all class members.
        MembersCreator.computeAllClassMembers(compiler, interface.element);
        if (lookupClassMember) {
          interface.element.forEachClassMember(findPrivateMember);
        } else {
          interface.element.forEachInterfaceMember(findPrivateMember);
        }

      }
      if (!foundPrivateMember) {
        switch (memberKind) {
          case MemberKind.METHOD:
            reportMessage(node, MessageKind.METHOD_NOT_FOUND,
                {'className': receiverType.name, 'memberName': name},
                isHint: isHint);
            break;
          case MemberKind.OPERATOR:
            reportMessage(node, MessageKind.OPERATOR_NOT_FOUND,
                {'className': receiverType.name, 'memberName': name},
                isHint: isHint);
            break;
          case MemberKind.GETTER:
            if (lookupMemberSignature(memberName.setter, interface) != null) {
              // A setter is present so warn explicitly about the missing
              // getter.
              reportMessage(node, MessageKind.GETTER_NOT_FOUND,
                  {'className': receiverType.name, 'memberName': name},
                  isHint: isHint);
            } else if (name == 'await') {
              Map arguments = {'className': receiverType.name};
              String functionName = executableContext.name;
              MessageKind kind;
              if (functionName == '') {
                kind = MessageKind.AWAIT_MEMBER_NOT_FOUND_IN_CLOSURE;
              } else {
                kind = MessageKind.AWAIT_MEMBER_NOT_FOUND;
                arguments['functionName'] = functionName;
              }
              reportMessage(node, kind, arguments, isHint: isHint);
            } else {
              reportMessage(node, MessageKind.MEMBER_NOT_FOUND,
                  {'className': receiverType.name, 'memberName': name},
                  isHint: isHint);
            }
            break;
          case MemberKind.SETTER:
            reportMessage(node, MessageKind.SETTER_NOT_FOUND,
                {'className': receiverType.name, 'memberName': name},
                isHint: isHint);
            break;
        }
      }
    }
    return const DynamicAccess();
  }

  DartType lookupMemberType(Node node, DartType type, String name,
                            MemberKind memberKind,
                            {bool isHint: false}) {
    return lookupMember(node, type, name, memberKind, null, isHint: isHint)
        .computeType(compiler);
  }

  void analyzeArguments(Send send, Element element, DartType type,
                        [LinkBuilder<DartType> argumentTypes]) {
    Link<Node> arguments = send.arguments;
    DartType unaliasedType = type.unalias(compiler);
    if (identical(unaliasedType.kind, TypeKind.FUNCTION)) {
      bool error = false;
      FunctionType funType = unaliasedType;
      Iterator<DartType> parameterTypes = funType.parameterTypes.iterator;
      Iterator<DartType> optionalParameterTypes =
          funType.optionalParameterTypes.iterator;
      while (!arguments.isEmpty) {
        Node argument = arguments.head;
        NamedArgument namedArgument = argument.asNamedArgument();
        if (namedArgument != null) {
          argument = namedArgument.expression;
          String argumentName = namedArgument.name.source;
          DartType namedParameterType =
              funType.getNamedParameterType(argumentName);
          if (namedParameterType == null) {
            error = true;
            // TODO(johnniwinther): Provide better information on the called
            // function.
            reportTypeWarning(argument, MessageKind.NAMED_ARGUMENT_NOT_FOUND,
                {'argumentName': argumentName});

            DartType argumentType = analyze(argument);
            if (argumentTypes != null) argumentTypes.addLast(argumentType);
          } else {
            DartType argumentType = analyze(argument);
            if (argumentTypes != null) argumentTypes.addLast(argumentType);
            if (!checkAssignable(argument, argumentType, namedParameterType)) {
              error = true;
            }
          }
        } else {
          if (!parameterTypes.moveNext()) {
            if (!optionalParameterTypes.moveNext()) {
              error = true;
              // TODO(johnniwinther): Provide better information on the
              // called function.
              reportTypeWarning(argument, MessageKind.ADDITIONAL_ARGUMENT);

              DartType argumentType = analyze(argument);
              if (argumentTypes != null) argumentTypes.addLast(argumentType);
            } else {
              DartType argumentType = analyze(argument);
              if (argumentTypes != null) argumentTypes.addLast(argumentType);
              if (!checkAssignable(argument,
                                   argumentType,
                                   optionalParameterTypes.current)) {
                error = true;
              }
            }
          } else {
            DartType argumentType = analyze(argument);
            if (argumentTypes != null) argumentTypes.addLast(argumentType);
            if (!checkAssignable(argument, argumentType,
                                 parameterTypes.current)) {
              error = true;
            }
          }
        }
        arguments = arguments.tail;
      }
      if (parameterTypes.moveNext()) {
        error = true;
        // TODO(johnniwinther): Provide better information on the called
        // function.
        reportTypeWarning(send, MessageKind.MISSING_ARGUMENT,
            {'argumentType': parameterTypes.current});
      }
      if (error) {
        // TODO(johnniwinther): Improve access to declaring element and handle
        // synthesized member signatures. Currently function typed instance
        // members provide no access to their own name.
        if (element == null) {
          element = type.element;
        } else if (type.isTypedef) {
          reportTypeInfo(element,
              MessageKind.THIS_IS_THE_DECLARATION,
              {'name': element.name});
          element = type.element;
        }
        if (element != null) {
          reportTypeInfo(element, MessageKind.THIS_IS_THE_METHOD);
        }
      }
    } else {
      while(!arguments.isEmpty) {
        DartType argumentType = analyze(arguments.head);
        if (argumentTypes != null) argumentTypes.addLast(argumentType);
        arguments = arguments.tail;
      }
    }
  }

  // Analyze the invocation [node] of [elementAccess].
  //
  // If provided [argumentTypes] is filled with the argument types during
  // analysis.
  DartType analyzeInvocation(Send node, ElementAccess elementAccess,
                             [LinkBuilder<DartType> argumentTypes]) {
    DartType type = elementAccess.computeType(compiler);
    if (elementAccess.isCallable(compiler)) {
      analyzeArguments(node, elementAccess.element, type, argumentTypes);
    } else {
      reportTypeWarning(node, MessageKind.NOT_CALLABLE,
          {'elementName': elementAccess.name});
      analyzeArguments(node, elementAccess.element, const DynamicType(),
                       argumentTypes);
    }
    type = type.unalias(compiler);
    if (identical(type.kind, TypeKind.FUNCTION)) {
      FunctionType funType = type;
      return funType.returnType;
    } else {
      return const DynamicType();
    }
  }

  /**
   * Computes the [ElementAccess] for [name] on the [node] possibly using the
   * [element] provided for [node] by the resolver.
   */
  ElementAccess computeAccess(Send node, String name, Element element,
                              MemberKind memberKind,
                              {bool lookupClassMember: false}) {
    if (element != null && element.isErroneous) {
      // An error has already been reported for this node.
      return const DynamicAccess();
    }
    if (node.receiver != null) {
      Element receiverElement = elements[node.receiver];
      if (receiverElement != null) {
        if (receiverElement.isPrefix) {
          if (node.isConditional) {
            // Skip cases like `prefix?.topLevel`.
            return const DynamicAccess();
          }
          assert(invariant(node, element != null,
              message: 'Prefixed node has no element.'));
          return computeResolvedAccess(node, name, element, memberKind);
        }
      }
      // e.foo() for some expression e.
      DartType receiverType = analyze(node.receiver);
      if (receiverType.treatAsDynamic || receiverType.isVoid) {
        return const DynamicAccess();
      }
      return lookupMember(node, receiverType, name, memberKind,
          elements[node.receiver],
          lookupClassMember: lookupClassMember ||
              element != null && element.isStatic);
    } else {
      return computeResolvedAccess(node, name, element, memberKind);
    }
  }

  /**
   * Computes the [ElementAccess] for [name] on the [node] using the [element]
   * provided for [node] by the resolver.
   */
  ElementAccess computeResolvedAccess(Send node, String name,
                                      Element element, MemberKind memberKind) {
    if (element == null) {
      // foo() where foo is unresolved.
      return lookupMember(node, thisType, name, memberKind, null);
    } else if (element.isErroneous) {
      // foo() where foo is erroneous.
      return const DynamicAccess();
    } else if (element.impliesType) {
      // The literal `Foo` where Foo is a class, a typedef, or a type variable.
      if (elements.isTypeLiteral(node)) {
        return new TypeLiteralAccess(elements.getTypeLiteralType(node));
      }
      return createResolvedAccess(node, name, element);
    } else if (element.isClassMember) {
      // foo() where foo is a member.
      return lookupMember(node, thisType, name, memberKind, null,
          lookupClassMember: element.isStatic);
    } else if (element.isFunction) {
      // foo() where foo is a method in the same class.
      return createResolvedAccess(node, name, element);
    } else if (element.isVariable ||
        element.isParameter ||
        element.isField) {
      // foo() where foo is a field in the same class.
      return createResolvedAccess(node, name, element);
    } else if (element.isGetter || element.isSetter) {
      return createResolvedAccess(node, name, element);
    } else {
      compiler.internalError(element,
          'Unexpected element kind ${element.kind}.');
      return null;
    }
  }

  ElementAccess createResolvedAccess(Send node, String name,
                                     Element element) {
    checkPrivateAccess(node, element, name);
    return createPromotedAccess(element);
  }

  ElementAccess createPromotedAccess(Element element) {
    if (element.isVariable || element.isParameter) {
      TypePromotion typePromotion = getKnownTypePromotion(element);
      if (typePromotion != null) {
        return new PromotedAccess(element, typePromotion.type);
      }
    }
    return new ResolvedAccess(element);
  }

  /**
   * Computes the type of the access of [name] on the [node] possibly using the
   * [element] provided for [node] by the resolver.
   */
  DartType computeAccessType(Send node, String name, Element element,
                             MemberKind memberKind,
                             {bool lookupClassMember: false}) {
    DartType type =
        computeAccess(node, name, element, memberKind,
            lookupClassMember: lookupClassMember).computeType(compiler);
    if (type == null) {
      compiler.internalError(node, 'Type is null on access of $name on $node.');
    }
    return type;
  }

  /// Compute a version of [shownType] that is more specific that [knownType].
  /// This is used to provided better hints when trying to promote a supertype
  /// to a raw subtype. For instance trying to promote `Iterable<int>` to `List`
  /// we suggest the use of `List<int>`, which would make promotion valid.
  DartType computeMoreSpecificType(DartType shownType,
                                   DartType knownType) {
    if (knownType.isInterfaceType &&
        shownType.isInterfaceType &&
        types.isSubtype(shownType.asRaw(), knownType)) {
      // For the comments in the block, assume the hierarchy:
      //     class A<T, V> {}
      //     class B<S, U> extends A<S, int> {}
      // and a promotion from a [knownType] of `A<double, int>` to a
      // [shownType] of `B`.
      InterfaceType knownInterfaceType = knownType;
      ClassElement shownClass = shownType.element;

      // Compute `B<double, dynamic>` as the subtype of `A<double, int>` using
      // the relation between `A<S, int>` and `A<double, int>`.
      MoreSpecificSubtypeVisitor visitor =
          new MoreSpecificSubtypeVisitor(compiler);
      InterfaceType shownTypeGeneric = visitor.computeMoreSpecific(
          shownClass, knownInterfaceType);

      if (shownTypeGeneric != null &&
          types.isMoreSpecific(shownTypeGeneric, knownType)) {
        // This should be the case but we double-check.
        // TODO(johnniwinther): Ensure that we don't suggest malbounded types.
        return shownTypeGeneric;
      }
    }
    return null;

  }

  DartType visitSend(Send node) {
    if (elements.isAssert(node)) {
      return analyzeInvocation(node, const AssertAccess());
    }

    Element element = elements[node];

    if (element != null && element.isConstructor) {
      DartType receiverType;
      if (node.receiver != null) {
        receiverType = analyze(node.receiver);
      } else if (node.selector.isSuper()) {
        // TODO(johnniwinther): Lookup super-member in class members.
        receiverType = superType;
      } else {
        assert(node.selector.isThis());
        receiverType = thisType;
      }
      DartType constructorType = computeConstructorType(element, receiverType);
      analyzeArguments(node, element, constructorType);
      return const DynamicType();
    }

    Identifier selector = node.selector.asIdentifier();
    if (Elements.isClosureSend(node, element)) {
      if (element != null) {
        // foo() where foo is a local or a parameter.
        return analyzeInvocation(node, createPromotedAccess(element));
      } else {
        // exp() where exp is some complex expression like (o) or foo().
        DartType type = analyze(node.selector);
        return analyzeInvocation(node, new TypeAccess(type));
      }
    } else if (Elements.isErroneous(element) && selector == null) {
      // exp() where exp is an erroneous construct like `new Unresolved()`.
      DartType type = analyze(node.selector);
      return analyzeInvocation(node, new TypeAccess(type));
    }

    String name = selector.source;

    if (node.isOperator && identical(name, 'is')) {
      analyze(node.receiver);
      if (!node.isIsNotCheck) {
        Element variable = elements[node.receiver];
        if (variable == null) {
          // Look for the variable element within parenthesized expressions.
          ParenthesizedExpression parentheses =
              node.receiver.asParenthesizedExpression();
          while (parentheses != null) {
            variable = elements[parentheses.expression];
            if (variable != null) break;
            parentheses = parentheses.expression.asParenthesizedExpression();
          }
        }

        if (variable != null &&
            (variable.isVariable || variable.isParameter)) {
          DartType knownType = getKnownType(variable);
          if (!knownType.isDynamic) {
            DartType shownType = elements.getType(node.arguments.head);
            TypePromotion typePromotion =
                new TypePromotion(node, variable, shownType);
            if (!types.isMoreSpecific(shownType, knownType)) {
              String variableName = variable.name;
              if (!types.isSubtype(shownType, knownType)) {
                typePromotion.addHint(node,
                    MessageKind.NOT_MORE_SPECIFIC_SUBTYPE,
                    {'variableName': variableName,
                     'shownType': shownType,
                     'knownType': knownType});
              } else {
                DartType shownTypeSuggestion =
                    computeMoreSpecificType(shownType, knownType);
                if (shownTypeSuggestion != null) {
                  typePromotion.addHint(node,
                      MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
                      {'variableName': variableName,
                       'shownType': shownType,
                       'shownTypeSuggestion': shownTypeSuggestion,
                       'knownType': knownType});
                } else {
                  typePromotion.addHint(node,
                      MessageKind.NOT_MORE_SPECIFIC,
                      {'variableName': variableName,
                       'shownType': shownType,
                       'knownType': knownType});
                }
              }
            }
            showTypePromotion(node, typePromotion);
          }
        }
      }
      return boolType;
    } if (node.isOperator && identical(name, 'as')) {
      analyze(node.receiver);
      return elements.getType(node.arguments.head);
    } else if (node.isOperator) {
      final Node receiver = node.receiver;
      final DartType receiverType = analyze(receiver);
      if (identical(name, '==') || identical(name, '!=')
          // TODO(johnniwinther): Remove these.
          || identical(name, '===') || identical(name, '!==')) {
        // Analyze argument.
        analyze(node.arguments.head);
        return boolType;
      } else if (identical(name, '||')) {
        checkAssignable(receiver, receiverType, boolType);
        final Node argument = node.arguments.head;
        final DartType argumentType = analyze(argument);
        checkAssignable(argument, argumentType, boolType);
        return boolType;
      } else if (identical(name, '&&')) {
        checkAssignable(receiver, receiverType, boolType);
        final Node argument = node.arguments.head;

        final DartType argumentType =
            analyzeInPromotedContext(receiver, argument);

        reshowTypePromotions(node, receiver, argument);

        checkAssignable(argument, argumentType, boolType);
        return boolType;
      } else if (identical(name, '!')) {
        checkAssignable(receiver, receiverType, boolType);
        return boolType;
      } else if (identical(name, '?')) {
        return boolType;
      } else if (identical(name, '??')) {
        final Node argument = node.arguments.head;
        final DartType argumentType = analyze(argument);
        return types.computeLeastUpperBound(receiverType, argumentType);
      }
      String operatorName = selector.source;
      if (identical(name, '-') && node.arguments.isEmpty) {
        operatorName = 'unary-';
      }
      assert(invariant(node,
                       identical(name, '+') || identical(name, '=') ||
                       identical(name, '-') || identical(name, '*') ||
                       identical(name, '/') || identical(name, '%') ||
                       identical(name, '~/') || identical(name, '|') ||
                       identical(name, '&') || identical(name, '^') ||
                       identical(name, '~')|| identical(name, '<<') ||
                       identical(name, '>>') ||
                       identical(name, '<') || identical(name, '>') ||
                       identical(name, '<=') || identical(name, '>=') ||
                       identical(name, '[]'),
                       message: 'Unexpected operator $name'));

      // TODO(karlklose): handle `void` in expression context by calling
      // [analyzeNonVoid] instead of [analyze].
      ElementAccess access = receiverType.isVoid ? const DynamicAccess()
          : lookupMember(node, receiverType, operatorName,
                         MemberKind.OPERATOR, null);
      LinkBuilder<DartType> argumentTypesBuilder = new LinkBuilder<DartType>();
      DartType resultType =
          analyzeInvocation(node, access, argumentTypesBuilder);
      if (identical(receiverType.element, compiler.intClass)) {
        if (identical(name, '+') ||
            identical(operatorName, '-') ||
            identical(name, '*') ||
            identical(name, '%')) {
          DartType argumentType = argumentTypesBuilder.toLink().head;
          if (identical(argumentType.element, compiler.intClass)) {
            return intType;
          } else if (identical(argumentType.element, compiler.doubleClass)) {
            return doubleType;
          }
        }
      }
      return resultType;
    } else if (node.isPropertyAccess) {
      ElementAccess access =
          computeAccess(node, selector.source, element, MemberKind.GETTER);
      return access.computeType(compiler);
    } else if (node.isFunctionObjectInvocation) {
      return unhandledExpression();
    } else {
      ElementAccess access =
          computeAccess(node, selector.source, element, MemberKind.METHOD);
      return analyzeInvocation(node, access);
    }
  }

  /// Returns the first type in the list or [:dynamic:] if the list is empty.
  DartType firstType(List<DartType> list) {
    return list.isEmpty ? const DynamicType() : list.first;
  }

  /**
   * Returns the second type in the list or [:dynamic:] if the list is too
   * short.
   */
  DartType secondType(List<DartType> list) {
    return list.length < 2 ? const DynamicType() : list[1];
  }

  /**
   * Checks [: target o= value :] for some operator o, and returns the type
   * of the result. This method also handles increment/decrement expressions
   * like [: target++ :].
   */
  DartType checkAssignmentOperator(SendSet node,
                                   String operatorName,
                                   Node valueNode,
                                   DartType value) {
    assert(invariant(node, !node.isIndex));
    Element setterElement = elements[node];
    Element getterElement = elements[node.selector];
    Identifier selector = node.selector;
    DartType getter = computeAccessType(
        node, selector.source, getterElement, MemberKind.GETTER);
    DartType setter = computeAccessType(
        node, selector.source, setterElement, MemberKind.SETTER);
    // [operator] is the type of operator+ or operator- on [target].
    DartType operator =
        lookupMemberType(node, getter, operatorName, MemberKind.OPERATOR);
    if (operator is FunctionType) {
      FunctionType operatorType = operator;
      // [result] is the type of target o value.
      DartType result = operatorType.returnType;
      DartType operatorArgument = firstType(operatorType.parameterTypes);
      // Check target o value.
      bool validValue = checkAssignable(valueNode, value, operatorArgument);
      if (validValue || !(node.isPrefix || node.isPostfix)) {
        // Check target = result.
        checkAssignable(node.assignmentOperator, result, setter);
      }
      return node.isPostfix ? getter : result;
    }
    return const DynamicType();
  }

  /**
   * Checks [: base[key] o= value :] for some operator o, and returns the type
   * of the result. This method also handles increment/decrement expressions
   * like [: base[key]++ :].
   */
  DartType checkIndexAssignmentOperator(SendSet node,
                                        String operatorName,
                                        Node valueNode,
                                        DartType value) {
    assert(invariant(node, node.isIndex));
    final DartType base = analyze(node.receiver);
    final Node keyNode = node.arguments.head;
    final DartType key = analyze(keyNode);

    // [indexGet] is the type of operator[] on [base].
    DartType indexGet = lookupMemberType(
        node, base, '[]', MemberKind.OPERATOR);
    if (indexGet is FunctionType) {
      FunctionType indexGetType = indexGet;
      DartType indexGetKey = firstType(indexGetType.parameterTypes);
      // Check base[key].
      bool validKey = checkAssignable(keyNode, key, indexGetKey);

      // [element] is the type of base[key].
      DartType element = indexGetType.returnType;
      // [operator] is the type of operator o on [element].
      DartType operator = lookupMemberType(
          node, element, operatorName, MemberKind.OPERATOR);
      if (operator is FunctionType) {
        FunctionType operatorType = operator;

        // Check base[key] o value.
        DartType operatorArgument = firstType(operatorType.parameterTypes);
        bool validValue = checkAssignable(valueNode, value, operatorArgument);

        // [result] is the type of base[key] o value.
        DartType result = operatorType.returnType;

        // [indexSet] is the type of operator[]= on [base].
        DartType indexSet = lookupMemberType(
            node, base, '[]=', MemberKind.OPERATOR);
        if (indexSet is FunctionType) {
          FunctionType indexSetType = indexSet;
          DartType indexSetKey = firstType(indexSetType.parameterTypes);
          DartType indexSetValue = secondType(indexSetType.parameterTypes);

          if (validKey || indexGetKey != indexSetKey) {
            // Only check base[key] on []= if base[key] was valid for [] or
            // if the key types differ.
            checkAssignable(keyNode, key, indexSetKey);
          }
          // Check base[key] = result
          if (validValue || !(node.isPrefix || node.isPostfix)) {
            checkAssignable(node.assignmentOperator, result, indexSetValue);
          }
        }
        return node.isPostfix ? element : result;
      }
    }
    return const DynamicType();
  }

  visitSendSet(SendSet node) {
    Element element = elements[node];
    Identifier selector = node.selector;
    final name = node.assignmentOperator.source;
    if (identical(name, '=') || identical(name, '??=')) {
      // e1 = value
      if (node.isIndex) {
         // base[key] = value
        final DartType base = analyze(node.receiver);
        final Node keyNode = node.arguments.head;
        final DartType key = analyze(keyNode);
        final Node valueNode = node.arguments.tail.head;
        final DartType value = analyze(valueNode);
        DartType indexSet = lookupMemberType(
            node, base, '[]=', MemberKind.OPERATOR);
        DartType indexSetValue = const DynamicType();
        if (indexSet is FunctionType) {
          FunctionType indexSetType = indexSet;
          DartType indexSetKey = firstType(indexSetType.parameterTypes);
          checkAssignable(keyNode, key, indexSetKey);
          indexSetValue = secondType(indexSetType.parameterTypes);
          checkAssignable(node.assignmentOperator, value, indexSetValue);
        }
        return identical(name, '=') ? value
            : types.computeLeastUpperBound(value, indexSetValue);
      } else {
        // target = value
        DartType target;
        if (analyzingInitializer) {
          // Field declaration `Foo target = value;` or initializer
          // `this.target = value`. Lookup the getter `target` in the class
          // members.
          target = computeAccessType(node, selector.source, element,
              MemberKind.GETTER, lookupClassMember: true);
        } else {
          // Normal assignment `target = value`.
          target = computeAccessType(
              node, selector.source, element, MemberKind.SETTER);
        }
        final Node valueNode = node.arguments.head;
        final DartType value = analyze(valueNode);
        checkAssignable(node.assignmentOperator, value, target);
        return identical(name, '=') ? value
            : types.computeLeastUpperBound(value, target);
      }
    } else if (identical(name, '++') || identical(name, '--')) {
      // e++ or e--
      String operatorName = identical(name, '++') ? '+' : '-';
      if (node.isIndex) {
        // base[key]++, base[key]--, ++base[key], or --base[key]
        return checkIndexAssignmentOperator(
            node, operatorName, node.assignmentOperator, intType);
      } else {
        // target++, target--, ++target, or --target
        return checkAssignmentOperator(
            node, operatorName, node.assignmentOperator, intType);
      }
    } else {
      // e1 o= e2 for some operator o.
      String operatorName;
      switch (name) {
        case '+=': operatorName = '+'; break;
        case '-=': operatorName = '-'; break;
        case '*=': operatorName = '*'; break;
        case '/=': operatorName = '/'; break;
        case '%=': operatorName = '%'; break;
        case '~/=': operatorName = '~/'; break;
        case '&=': operatorName = '&'; break;
        case '|=': operatorName = '|'; break;
        case '^=': operatorName = '^'; break;
        case '<<=': operatorName = '<<'; break;
        case '>>=': operatorName = '>>'; break;
        default:
          compiler.internalError(node, 'Unexpected assignment operator $name.');
      }
      if (node.isIndex) {
        // base[key] o= value for some operator o.
        final Node valueNode = node.arguments.tail.head;
        final DartType value = analyze(valueNode);
        return checkIndexAssignmentOperator(
            node, operatorName, valueNode, value);
      } else {
        // target o= value for some operator o.
        final Node valueNode = node.arguments.head;
        final DartType value = analyze(valueNode);
        return checkAssignmentOperator(node, operatorName, valueNode, value);
      }
    }
  }

  DartType visitLiteralInt(LiteralInt node) {
    return intType;
  }

  DartType visitLiteralDouble(LiteralDouble node) {
    return doubleType;
  }

  DartType visitLiteralBool(LiteralBool node) {
    return boolType;
  }

  DartType visitLiteralString(LiteralString node) {
    return stringType;
  }

  DartType visitStringJuxtaposition(StringJuxtaposition node) {
    analyze(node.first);
    analyze(node.second);
    return stringType;
  }

  DartType visitLiteralNull(LiteralNull node) {
    return const DynamicType();
  }

  DartType visitLiteralSymbol(LiteralSymbol node) {
    return compiler.symbolClass.rawType;
  }

  DartType computeConstructorType(ConstructorElement constructor,
                                  DartType type) {
    if (Elements.isUnresolved(constructor)) return const DynamicType();
    DartType constructorType = constructor.computeType(compiler);
    if (identical(type.kind, TypeKind.INTERFACE)) {
      if (constructor.isSynthesized) {
        // TODO(johnniwinther): Remove this when synthesized constructors handle
        // type variables correctly.
        InterfaceType interfaceType = type;
        ClassElement receiverElement = interfaceType.element;
        while (receiverElement.isMixinApplication) {
          receiverElement = receiverElement.supertype.element;
        }
        constructorType = constructorType.substByContext(
            interfaceType.asInstanceOf(receiverElement));
      } else {
        constructorType = constructorType.substByContext(type);
      }
    }
    return constructorType;
  }

  DartType visitNewExpression(NewExpression node) {
    Element element = elements[node.send];
    if (Elements.isUnresolved(element)) return const DynamicType();

    checkPrivateAccess(node, element, element.name);

    DartType newType = elements.getType(node);
    DartType constructorType = computeConstructorType(element, newType);
    analyzeArguments(node.send, element, constructorType);
    return newType;
  }

  DartType visitLiteralList(LiteralList node) {
    InterfaceType listType = elements.getType(node);
    DartType listElementType = firstType(listType.typeArguments);
    for (Link<Node> link = node.elements.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node element = link.head;
      DartType elementType = analyze(element);
      checkAssignable(element, elementType, listElementType,
          isConst: node.isConst);
    }
    return listType;
  }

  DartType visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      analyze(link.head, inInitializer: analyzingInitializer);
    }
    return const StatementType();
  }

  DartType visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    // TODO(lrn): Typecheck the body. It must refer to the constructor
    // of a subtype.
    return const StatementType();
  }

  DartType visitRethrow(Rethrow node) {
    return const StatementType();
  }

  /** Dart Programming Language Specification: 11.10 Return */
  DartType visitReturn(Return node) {
    if (identical(node.beginToken.stringValue, 'native')) {
      return const StatementType();
    }

    final Node expression = node.expression;

    // Executing a return statement return e; [...] It is a static type warning
    // if the type of e may not be assigned to the declared return type of the
    // immediately enclosing function.
    if (expression != null) {
      DartType expressionType = analyze(expression);
      if (executableContext.isGenerativeConstructor) {
        // The resolver already emitted an error for this expression.
      } else {
        if (currentAsyncMarker == AsyncMarker.ASYNC) {
          expressionType = coreTypes.futureType(types.flatten(expressionType));
        }
        if (expectedReturnType.isVoid &&
            !types.isAssignable(expressionType, const VoidType())) {
          reportTypeWarning(expression, MessageKind.RETURN_VALUE_IN_VOID);
        } else {
          checkAssignable(expression, expressionType, expectedReturnType);
        }
      }
    } else if (currentAsyncMarker == AsyncMarker.ASYNC) {
      // `return;` is allowed.
    } else if (!types.isAssignable(expectedReturnType, const VoidType())) {
      // Let f be the function immediately enclosing a return statement of the
      // form 'return;' It is a static warning if both of the following
      // conditions hold:
      // - f is not a generative constructor.
      // - The return type of f may not be assigned to void.
      reportTypeWarning(node, MessageKind.RETURN_NOTHING,
                        {'returnType': expectedReturnType});
    }
    return const StatementType();
  }

  DartType visitThrow(Throw node) {
    // TODO(johnniwinther): Handle reachability.
    analyze(node.expression);
    return const DynamicType();
  }

  DartType visitAwait(Await node) {
    DartType expressionType = analyze(node.expression);
    return types.flatten(expressionType);
  }

  DartType visitYield(Yield node) {
    DartType resultType = analyze(node.expression);
    if (!node.hasStar) {
      if (currentAsyncMarker.isAsync) {
        resultType = coreTypes.streamType(resultType);
      } else {
        resultType = coreTypes.iterableType(resultType);
      }
    } else {
      if (currentAsyncMarker.isAsync) {
        // The static type of expression must be assignable to Stream.
        checkAssignable(node, resultType, coreTypes.streamType());
      } else {
        // The static type of expression must be assignable to Iterable.
        checkAssignable(node, resultType, coreTypes.iterableType());
      }
    }
    // The static type of the result must be assignable to the declared type.
    checkAssignable(node, resultType, expectedReturnType);
    return const StatementType();
  }

  DartType visitTypeAnnotation(TypeAnnotation node) {
    return elements.getType(node);
  }

  DartType visitVariableDefinitions(VariableDefinitions node) {
    DartType type = analyzeWithDefault(node.type, const DynamicType());
    if (type.isVoid) {
      reportTypeWarning(node.type, MessageKind.VOID_VARIABLE);
      type = const DynamicType();
    }
    for (Link<Node> link = node.definitions.nodes; !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      invariant(definition, definition is Identifier || definition is SendSet,
          message: 'expected identifier or initialization');
      if (definition is SendSet) {
        SendSet initialization = definition;
        DartType initializer = analyzeNonVoid(initialization.arguments.head);
        checkAssignable(initialization.assignmentOperator, initializer, type);
      }
    }
    return const StatementType();
  }

  DartType visitWhile(While node) {
    checkCondition(node.condition);
    analyze(node.body);
    return const StatementType();
  }

  DartType visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    DartType type = analyze(expression);
    for (TypePromotion typePromotion in getShownTypePromotionsFor(expression)) {
      showTypePromotion(node, typePromotion);
    }
    return type;
  }

  DartType visitConditional(Conditional node) {
    Expression condition = node.condition;
    Expression thenExpression = node.thenExpression;

    checkCondition(condition);

    DartType thenType = analyzeInPromotedContext(condition, thenExpression);

    DartType elseType = analyze(node.elseExpression);
    return types.computeLeastUpperBound(thenType, elseType);
  }

  visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return stringType;
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    node.visitChildren(this);
    return stringType;
  }

  visitEmptyStatement(EmptyStatement node) {
    return const StatementType();
  }

  visitBreakStatement(BreakStatement node) {
    return const StatementType();
  }

  visitContinueStatement(ContinueStatement node) {
    return const StatementType();
  }

  DartType computeForInElementType(ForIn node) {
    VariableDefinitions declaredIdentifier =
        node.declaredIdentifier.asVariableDefinitions();
    if (declaredIdentifier != null) {
      return
          analyzeWithDefault(declaredIdentifier.type, const DynamicType());
    } else {
      return analyze(node.declaredIdentifier);
    }
  }

  visitAsyncForIn(AsyncForIn node) {
    DartType elementType = computeForInElementType(node);
    DartType expressionType = analyze(node.expression);
    // TODO(johnniwinther): Move this to _CompilerCoreTypes.
    compiler.streamClass.ensureResolved(compiler);
    DartType streamOfDynamic = coreTypes.streamType();
    if (!types.isAssignable(expressionType, streamOfDynamic)) {
      reportMessage(node.expression,
          MessageKind.NOT_ASSIGNABLE,
          {'fromType': expressionType, 'toType': streamOfDynamic},
          isHint: true);
    } else {
      InterfaceType interfaceType =
          Types.computeInterfaceType(compiler, expressionType);
      if (interfaceType != null) {
        InterfaceType streamType =
            interfaceType.asInstanceOf(compiler.streamClass);
        if (streamType != null) {
          DartType streamElementType = streamType.typeArguments.first;
          if (!types.isAssignable(streamElementType, elementType)) {
            reportMessage(node.expression,
                MessageKind.FORIN_NOT_ASSIGNABLE,
                {'currentType': streamElementType,
                 'expressionType': expressionType,
                 'elementType': elementType},
                isHint: true);
          }
        }
      }
    }
    analyze(node.body);
    return const StatementType();
  }

  visitSyncForIn(SyncForIn node) {
    DartType elementType = computeForInElementType(node);
    DartType expressionType = analyze(node.expression);
    DartType iteratorType = lookupMemberType(node.expression,
        expressionType, Identifiers.iterator, MemberKind.GETTER);
    DartType currentType = lookupMemberType(node.expression,
              iteratorType, Identifiers.current, MemberKind.GETTER,
              isHint: true);
    if (!types.isAssignable(currentType, elementType)) {
      reportMessage(node.expression,
          MessageKind.FORIN_NOT_ASSIGNABLE,
          {'currentType': currentType,
           'expressionType': expressionType,
           'elementType': elementType},
          isHint: true);
    }
    analyze(node.body);
    return const StatementType();
  }

  visitLabeledStatement(LabeledStatement node) {
    return analyze(node.statement);
  }

  visitLiteralMap(LiteralMap node) {
    InterfaceType mapType = elements.getType(node);
    DartType mapKeyType = firstType(mapType.typeArguments);
    DartType mapValueType = secondType(mapType.typeArguments);
    bool isConst = node.isConst;
    for (Link<Node> link = node.entries.nodes;
         !link.isEmpty;
         link = link.tail) {
      LiteralMapEntry entry = link.head;
      DartType keyType = analyze(entry.key);
      checkAssignable(entry.key, keyType, mapKeyType, isConst: isConst);
      DartType valueType = analyze(entry.value);
      checkAssignable(entry.value, valueType, mapValueType, isConst: isConst);
    }
    return mapType;
  }

  visitNamedArgument(NamedArgument node) {
    // Named arguments are visited as part of analyzing invocations of
    // unresolved methods. For instance [: foo(a: 42); :] where 'foo' is neither
    // found in the enclosing scope nor through lookup on 'this' or
    // [: x.foo(b: 42); :] where 'foo' cannot be not found through lookup on
    // the static type of 'x'.
    return analyze(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    // TODO(johnniwinther): Handle reachability based on reachability of
    // switch cases.
    // TODO(johnniwinther): Provide hint of duplicate case constants.

    DartType expressionType = analyze(node.expression);

    // Check that all the case expressions are assignable to the expression.
    bool hasDefaultCase = false;
    for (SwitchCase switchCase in node.cases) {
      if (switchCase.isDefaultCase) {
        hasDefaultCase = true;
      }
      for (Node labelOrCase in switchCase.labelsAndCases) {
        CaseMatch caseMatch = labelOrCase.asCaseMatch();
        if (caseMatch == null) continue;

        DartType caseType = analyze(caseMatch.expression);
        checkAssignable(caseMatch, expressionType, caseType);
      }

      analyze(switchCase);
    }

    if (!hasDefaultCase && expressionType.isEnumType) {
      compiler.enqueuer.resolution.addDeferredAction(executableContext, () {
        Map<ConstantValue, FieldElement> enumValues =
            <ConstantValue, FieldElement>{};
        List<FieldElement> unreferencedFields = <FieldElement>[];
        EnumClassElement enumClass = expressionType.element;
        enumClass.enumValues.forEach((FieldElement field) {
          ConstantValue constantValue =
              compiler.constants.getConstantValueForVariable(field);
          if (constantValue == null) {
            // The field might not have been resolved.
            unreferencedFields.add(field);
          } else {
            enumValues[constantValue] = field;
          }
        });

        for (SwitchCase switchCase in node.cases) {
          for (Node labelOrCase in switchCase.labelsAndCases) {
            CaseMatch caseMatch = labelOrCase.asCaseMatch();
            if (caseMatch != null) {
              ConstantExpression caseConstant =
                  compiler.resolver.constantCompiler.compileNode(
                      caseMatch.expression, elements);
              enumValues.remove(
                  compiler.constants.getConstantValue(caseConstant));
            }
          }
        }
        unreferencedFields.addAll(enumValues.values);
        if (!unreferencedFields.isEmpty) {
          compiler.reportWarning(node, MessageKind.MISSING_ENUM_CASES,
              {'enumType': expressionType,
               'enumValues': unreferencedFields.map((e) => e.name).join(', ')});
        }
      });
    }

    return const StatementType();
  }

  visitSwitchCase(SwitchCase node) {
    return analyze(node.statements);
  }

  visitTryStatement(TryStatement node) {
    // TODO(johnniwinther): Use reachability information of try-block,
    // catch-blocks and finally-block to compute the whether the try statement
    // is returning.
    analyze(node.tryBlock);
    for (CatchBlock catchBlock in node.catchBlocks) {
      analyze(catchBlock);
    }
    analyzeWithDefault(node.finallyBlock, null);
    return const StatementType();
  }

  visitCatchBlock(CatchBlock node) {
    return analyze(node.block);
  }

  visitTypedef(Typedef node) {
    // Do not typecheck [Typedef] nodes.
  }

  visitNode(Node node) {
    compiler.internalError(node,
        'Unexpected node ${node.getObjectDescription()} in the type checker.');
  }
}
