// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class TypeCheckerTask extends CompilerTask {
  TypeCheckerTask(Compiler compiler) : super(compiler);
  String get name => "Type checker";

  void check(TreeElements elements) {
    Element element = elements.currentElement;
    compiler.withCurrentElement(element, () {
      measure(() {
        Node tree = element.parseNode(compiler);
        Visitor visitor =
            new TypeCheckerVisitor(compiler, elements, compiler.types);
        tree.accept(visitor);
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
  static const MemberKind PROPERTY = const MemberKind("property");

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

  DartType computeType(Compiler compiler);

  /// Returns [: true :] if the element can be access as an invocation.
  bool isCallable(Compiler compiler) {
    if (element.isAbstractField()) {
      AbstractFieldElement abstractFieldElement = element;
      if (abstractFieldElement.getter == null) {
        // Setters cannot be invoked as function invocations.
        return false;
      }
    }
    return compiler.types.isAssignable(
        computeType(compiler), compiler.functionClass.computeType(compiler));
  }
}

/// An access of a instance member.
class MemberAccess extends ElementAccess {
  final Member member;

  MemberAccess(Member this.member);

  Element get element => member.element;

  DartType computeType(Compiler compiler) => member.computeType(compiler);

  String toString() => 'MemberAccess($member)';
}

/// An access of an unresolved element.
class DynamicAccess implements ElementAccess {
  const DynamicAccess();

  Element get element => null;

  DartType computeType(Compiler compiler) => compiler.types.dynamicType;

  bool isCallable(Compiler compiler) => true;

  String toString() => 'DynamicAccess';
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
    if (element.isGetter()) {
      FunctionType functionType = element.computeType(compiler);
      return functionType.returnType;
    } else if (element.isSetter()) {
      FunctionType functionType = element.computeType(compiler);
      return functionType.parameterTypes.head;
    } else {
      return element.computeType(compiler);
    }
  }

  String toString() => 'ResolvedAccess($element)';
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
  final Element element;
  TypeLiteralAccess(Element this.element) {
    assert(element != null);
  }

  DartType computeType(Compiler compiler) =>
      compiler.typeClass.computeType(compiler);

  String toString() => 'TypeLiteralAccess($element)';
}

class TypeCheckerVisitor extends Visitor<DartType> {
  final Compiler compiler;
  final TreeElements elements;
  final Types types;

  Node lastSeenNode;
  DartType expectedReturnType;
  final ClassElement currentClass;

  Link<DartType> cascadeTypes = const Link<DartType>();

  DartType intType;
  DartType doubleType;
  DartType boolType;
  DartType stringType;
  DartType objectType;
  DartType listType;

  TypeCheckerVisitor(this.compiler, TreeElements elements, this.types)
      : this.elements = elements,
        currentClass = elements.currentElement != null
            ? elements.currentElement.getEnclosingClass() : null {
    intType = compiler.intClass.computeType(compiler);
    doubleType = compiler.doubleClass.computeType(compiler);
    boolType = compiler.boolClass.computeType(compiler);
    stringType = compiler.stringClass.computeType(compiler);
    objectType = compiler.objectClass.computeType(compiler);
    listType = compiler.listClass.computeType(compiler);
  }

  LibraryElement get currentLibrary => elements.currentElement.getLibrary();

  reportTypeWarning(Node node, MessageKind kind, [Map arguments = const {}]) {
    compiler.reportWarning(node, new TypeWarning(kind, arguments));
  }

  reportTypeInfo(Spannable node, MessageKind kind, [Map arguments = const {}]) {
    compiler.reportDiagnostic(compiler.spanFromSpannable(node),
        'Info: ${kind.message(arguments)}', api.Diagnostic.INFO);
  }

  // TODO(karlklose): remove these functions.
  DartType unhandledStatement() => StatementType.NOT_RETURNING;
  DartType unhandledExpression() => types.dynamicType;

  DartType analyzeNonVoid(Node node) {
    DartType type = analyze(node);
    if (type == types.voidType) {
      reportTypeWarning(node, MessageKind.VOID_EXPRESSION);
    }
    return type;
  }

  DartType analyzeWithDefault(Node node, DartType defaultValue) {
    return node != null ? analyze(node) : defaultValue;
  }

  DartType analyze(Node node) {
    if (node == null) {
      final String error = 'unexpected node: null';
      if (lastSeenNode != null) {
        compiler.internalError(error, node: lastSeenNode);
      } else {
        compiler.cancel(error);
      }
    } else {
      lastSeenNode = node;
    }
    DartType result = node.accept(this);
    if (result == null) {
      compiler.internalError('type is null', node: node);
    }
    return result;
  }

  /**
   * Check if a value of type t can be assigned to a variable,
   * parameter or return value of type s.
   */
  bool checkAssignable(Node node, DartType from, DartType to) {
    if (!types.isAssignable(from, to)) {
      reportTypeWarning(node, MessageKind.NOT_ASSIGNABLE,
                        {'fromType': from, 'toType': to});
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
    if (node.expression.asCascadeReceiver() == null) {
      // TODO(karlklose): bug: expressions of the form e..x = y do not have
      // a CascadeReceiver as expression currently.
      return types.dynamicType;
    }
    return popCascadeType();
  }

  DartType visitCascadeReceiver(CascadeReceiver node) {
    DartType type = analyze(node.expression);
    pushCascadeType(type);
    return type;
  }

  DartType visitDoWhile(DoWhile node) {
    StatementType bodyType = analyze(node.body);
    checkCondition(node.condition);
    return bodyType.join(StatementType.NOT_RETURNING);
  }

  DartType visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    analyze(expression);
    return (expression.asThrow() != null)
        ? StatementType.RETURNING
        : StatementType.NOT_RETURNING;
  }

  /** Dart Programming Language Specification: 11.5.1 For Loop */
  DartType visitFor(For node) {
    analyzeWithDefault(node.initializer, StatementType.NOT_RETURNING);
    if (node.condition != null) {
      checkCondition(node.condition);
    }
    analyzeWithDefault(node.update, StatementType.NOT_RETURNING);
    StatementType bodyType = analyze(node.body);
    return bodyType.join(StatementType.NOT_RETURNING);
  }

  DartType visitFunctionDeclaration(FunctionDeclaration node) {
    analyze(node.function);
    return StatementType.NOT_RETURNING;
  }

  DartType visitFunctionExpression(FunctionExpression node) {
    DartType type;
    DartType returnType;
    DartType previousType;
    final FunctionElement element = elements[node];
    if (Elements.isUnresolved(element)) return types.dynamicType;
    if (identical(element.kind, ElementKind.GENERATIVE_CONSTRUCTOR) ||
        identical(element.kind, ElementKind.GENERATIVE_CONSTRUCTOR_BODY)) {
      type = types.dynamicType;
      returnType = types.voidType;
    } else {
      FunctionType functionType = computeType(element);
      returnType = functionType.returnType;
      type = functionType;
    }
    DartType previous = expectedReturnType;
    expectedReturnType = returnType;
    StatementType bodyType = analyze(node.body);
    if (returnType != types.voidType && returnType != types.dynamicType
        && bodyType != StatementType.RETURNING) {
      MessageKind kind;
      if (bodyType == StatementType.MAYBE_RETURNING) {
        kind = MessageKind.MAYBE_MISSING_RETURN;
      } else {
        kind = MessageKind.MISSING_RETURN;
      }
      reportTypeWarning(node.name, kind);
    }
    expectedReturnType = previous;
    return type;
  }

  DartType visitIdentifier(Identifier node) {
    if (node.isThis()) {
      return currentClass.computeType(compiler);
    } else if (node.isSuper()) {
      return currentClass.supertype;
    } else {
      Element element = elements[node];
      assert(invariant(node, element != null,
          message: 'Missing element for identifier'));
      assert(invariant(node, element.isVariable() ||
                             element.isParameter() ||
                             element.isField(),
          message: 'Unexpected context element ${element}'));
      return element.computeType(compiler);
    }
  }

  DartType visitIf(If node) {
    checkCondition(node.condition);
    StatementType thenType = analyze(node.thenPart);
    StatementType elseType = node.hasElsePart ? analyze(node.elsePart)
                                              : StatementType.NOT_RETURNING;
    return thenType.join(elseType);
  }

  void checkPrivateAccess(Node node, Element element, SourceString name) {
    if (name != null &&
        name.isPrivate() &&
        element.getLibrary() != currentLibrary) {
      reportTypeWarning(
          node,
          MessageKind.PRIVATE_ACCESS,
          {'name': name,
           'libraryName': element.getLibrary().getLibraryOrScriptName()});
    }

  }

  ElementAccess lookupMember(Node node, DartType type, SourceString name,
                             MemberKind memberKind) {
    if (identical(type, types.dynamicType)) {
      return const DynamicAccess();
    }
    Member member = type.lookupMember(name);
    if (member != null) {
      checkPrivateAccess(node, member.element, name);
      return new MemberAccess(member);
    }
    switch (memberKind) {
      case MemberKind.METHOD:
        reportTypeWarning(node, MessageKind.METHOD_NOT_FOUND,
            {'className': type.name, 'memberName': name});
        break;
      case MemberKind.OPERATOR:
        reportTypeWarning(node, MessageKind.OPERATOR_NOT_FOUND,
            {'className': type.name, 'memberName': name});
        break;
      case MemberKind.PROPERTY:
        reportTypeWarning(node, MessageKind.PROPERTY_NOT_FOUND,
            {'className': type.name, 'memberName': name});
        break;
    }
    return const DynamicAccess();
  }

  DartType lookupMemberType(Node node, DartType type, SourceString name,
                            MemberKind memberKind) {
    return lookupMember(node, type, name, memberKind).computeType(compiler);
  }

  void analyzeArguments(Send send, Element element, DartType type,
                        [LinkBuilder<DartType> argumentTypes]) {
    Link<Node> arguments = send.arguments;
    DartType unaliasedType = type.unalias(compiler);
    if (identical(unaliasedType.kind, TypeKind.FUNCTION)) {
      assert(invariant(send, element != null, message: 'No element for $send'));
      bool error = false;
      FunctionType funType = unaliasedType;
      Link<DartType> parameterTypes = funType.parameterTypes;
      Link<DartType> optionalParameterTypes = funType.optionalParameterTypes;
      while (!arguments.isEmpty) {
        Node argument = arguments.head;
        NamedArgument namedArgument = argument.asNamedArgument();
        if (namedArgument != null) {
          argument = namedArgument.expression;
          SourceString argumentName = namedArgument.name.source;
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
          if (parameterTypes.isEmpty) {
            if (optionalParameterTypes.isEmpty) {
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
                                   argumentType, optionalParameterTypes.head)) {
                error = true;
              }
              optionalParameterTypes = optionalParameterTypes.tail;
            }
          } else {
            DartType argumentType = analyze(argument);
            if (argumentTypes != null) argumentTypes.addLast(argumentType);
            if (!checkAssignable(argument, argumentType, parameterTypes.head)) {
              error = true;
            }
            parameterTypes = parameterTypes.tail;
          }
        }
        arguments = arguments.tail;
      }
      if (!parameterTypes.isEmpty) {
        error = true;
        // TODO(johnniwinther): Provide better information on the called
        // function.
        reportTypeWarning(send, MessageKind.MISSING_ARGUMENT,
            {'argumentType': parameterTypes.head});
      }
      if (error) {
        reportTypeInfo(element, MessageKind.THIS_IS_THE_METHOD);
      }
    } else {
      while(!arguments.isEmpty) {
        DartType argumentType = analyze(arguments.head);
        if (argumentTypes != null) argumentTypes.addLast(argumentType);
        arguments = arguments.tail;
      }
    }
  }

  DartType analyzeInvocation(Send node, ElementAccess elementAccess,
                             [LinkBuilder<DartType> argumentTypes]) {
    DartType type = elementAccess.computeType(compiler);
    if (elementAccess.isCallable(compiler)) {
      analyzeArguments(node, elementAccess.element, type, argumentTypes);
    } else {
      reportTypeWarning(node, MessageKind.NOT_CALLABLE,
          {'elementName': elementAccess.element.name});
      analyzeArguments(node, elementAccess.element, types.dynamicType,
                       argumentTypes);
    }
    if (identical(type.kind, TypeKind.FUNCTION)) {
      FunctionType funType = type;
      return funType.returnType;
    } else {
      return types.dynamicType;
    }
  }

  /**
   * Computes the [ElementAccess] for [name] on the [node] possibly using the
   * [element] provided for [node] by the resolver.
   */
  ElementAccess computeAccess(Send node, SourceString name, Element element,
                              MemberKind memberKind) {
    if (node.receiver != null) {
      Element receiverElement = elements[node.receiver];
      if (receiverElement != null) {
        if (receiverElement.isPrefix()) {
          assert(invariant(node, element != null,
              message: 'Prefixed node has no element.'));
          return computeResolvedAccess(node, name, element, memberKind);
        }
      }
      // e.foo() for some expression e.
      DartType receiverType = analyze(node.receiver);
      if (receiverType.isDynamic ||
          receiverType.isMalformed ||
          receiverType.isVoid) {
        return const DynamicAccess();
      }
      TypeKind receiverKind = receiverType.kind;
      if (identical(receiverKind, TypeKind.TYPEDEF)) {
        // TODO(johnniwinther): handle typedefs.
        return const DynamicAccess();
      }
      if (identical(receiverKind, TypeKind.FUNCTION)) {
        // TODO(johnniwinther): handle functions.
        return const DynamicAccess();
      }
      if (identical(receiverKind, TypeKind.TYPE_VARIABLE)) {
        // TODO(johnniwinther): handle type variables.
        return const DynamicAccess();
      }
      assert(invariant(node.receiver,
          identical(receiverKind, TypeKind.INTERFACE),
          message: "interface type expected, got ${receiverKind}"));
      return lookupMember(node, receiverType, name, memberKind);
    } else {
      return computeResolvedAccess(node, name, element, memberKind);
    }
  }

  /**
   * Computes the [ElementAccess] for [name] on the [node] using the [element]
   * provided for [node] by the resolver.
   */
  ElementAccess computeResolvedAccess(Send node, SourceString name,
                                      Element element, MemberKind memberKind) {
    if (Elements.isUnresolved(element)) {
      // foo() where foo is unresolved.
      return const DynamicAccess();
    } else if (element.isMember()) {
      // foo() where foo is an instance member.
      return lookupMember(node, currentClass.computeType(compiler),
          name, memberKind);
    } else if (element.isFunction()) {
      // foo() where foo is a method in the same class.
      return createResolvedAccess(node, name, element);
    } else if (element.isVariable() ||
        element.isParameter() ||
        element.isField()) {
      // foo() where foo is a field in the same class.
      return createResolvedAccess(node, name, element);
    } else if (element.impliesType()) {
      // The literal `Foo` where Foo is a class, a typedef, or a type variable.
      if (elements.getType(node) != null) {
        assert(invariant(node, identical(compiler.typeClass,
            elements.getType(node).element),
            message: 'Expected type literal type: '
              '${elements.getType(node)}'));
        return new TypeLiteralAccess(element);
      }
      return createResolvedAccess(node, name, element);
    } else if (element.isGetter() || element.isSetter()) {
      return createResolvedAccess(node, name, element);
    } else {
      compiler.internalErrorOnElement(
          element, 'unexpected element kind ${element.kind}');
    }
  }

  ElementAccess createResolvedAccess(Send node, SourceString name,
                                     Element element) {
    checkPrivateAccess(node, element, name);
    return new ResolvedAccess(element);
  }

  /**
   * Computes the type of the access of [name] on the [node] possibly using the
   * [element] provided for [node] by the resolver.
   */
  DartType computeAccessType(Send node, SourceString name, Element element,
                             MemberKind memberKind) {
    DartType type =
        computeAccess(node, name, element, memberKind).computeType(compiler);
    if (type == null) {
      compiler.internalError('type is null on access of $name on $node',
                             node: node);
    }
    return type;
  }

  DartType visitSend(Send node) {
    Element element = elements[node];

    if (Elements.isClosureSend(node, element)) {
      if (element != null) {
        // foo() where foo is a local or a parameter.
        return analyzeInvocation(node, new ResolvedAccess(element));
      } else {
        // exp() where exp is some complex expression like (o) or foo().
        DartType type = analyze(node.selector);
        return analyzeInvocation(node, new TypeAccess(type));
      }
    }

    Identifier selector = node.selector.asIdentifier();
    String name = selector.source.stringValue;

    if (node.isOperator && identical(name, 'is')) {
      analyze(node.receiver);
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
      } else if (identical(name, '||') ||
                 identical(name, '&&')) {
        checkAssignable(receiver, receiverType, boolType);
        final Node argument = node.arguments.head;
        final DartType argumentType = analyze(argument);
        checkAssignable(argument, argumentType, boolType);
        return boolType;
      } else if (identical(name, '!')) {
        checkAssignable(receiver, receiverType, boolType);
        return boolType;
      } else if (identical(name, '?')) {
        return boolType;
      }
      SourceString operatorName = selector.source;
      if (identical(name, '-') && node.arguments.isEmpty) {
        operatorName = const SourceString('unary-');
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

      ElementAccess access = lookupMember(node, receiverType,
                                          operatorName, MemberKind.OPERATOR);
      LinkBuilder<DartType> argumentTypesBuilder = new LinkBuilder<DartType>();
      DartType resultType =
          analyzeInvocation(node, access, argumentTypesBuilder);
      if (identical(receiverType.element, compiler.intClass)) {
        if (identical(name, '+') ||
            identical(operatorName, const SourceString('-')) ||
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
          computeAccess(node, selector.source, element, MemberKind.PROPERTY);
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
  DartType firstType(Link<DartType> link) {
    return link.isEmpty ? types.dynamicType : link.head;
  }

  /**
   * Returns the second type in the list or [:dynamic:] if the list is too
   * short.
   */
  DartType secondType(Link<DartType> link) {
    return link.isEmpty || link.tail.isEmpty
        ? types.dynamicType : link.tail.head;
  }

  /**
   * Checks [: target o= value :] for some operator o, and returns the type
   * of the result. This method also handles increment/decrement expressions
   * like [: target++ :].
   */
  DartType checkAssignmentOperator(SendSet node,
                                   SourceString operatorName,
                                   Node valueNode,
                                   DartType value) {
    assert(invariant(node, !node.isIndex));
    Element element = elements[node];
    Identifier selector = node.selector;
    DartType target =
        computeAccessType(node, selector.source, element, MemberKind.PROPERTY);
    // [operator] is the type of operator+ or operator- on [target].
    DartType operator =
        lookupMemberType(node, target, operatorName, MemberKind.OPERATOR);
    if (operator is FunctionType) {
      FunctionType operatorType = operator;
      // [result] is the type of target o value.
      DartType result = operatorType.returnType;
      DartType operatorArgument = firstType(operatorType.parameterTypes);
      // Check target o value.
      bool validValue = checkAssignable(valueNode, value, operatorArgument);
      if (validValue || !(node.isPrefix || node.isPostfix)) {
        // Check target = result.
        checkAssignable(node.assignmentOperator, result, target);
      }
      return node.isPostfix ? target : result;
    }
    return types.dynamicType;
  }

  /**
   * Checks [: base[key] o= value :] for some operator o, and returns the type
   * of the result. This method also handles increment/decrement expressions
   * like [: base[key]++ :].
   */
  DartType checkIndexAssignmentOperator(SendSet node,
                                        SourceString operatorName,
                                        Node valueNode,
                                        DartType value) {
    assert(invariant(node, node.isIndex));
    final DartType base = analyze(node.receiver);
    final Node keyNode = node.arguments.head;
    final DartType key = analyze(keyNode);

    // [indexGet] is the type of operator[] on [base].
    DartType indexGet = lookupMemberType(
        node, base, const SourceString('[]'), MemberKind.OPERATOR);
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
            node, base, const SourceString('[]='), MemberKind.OPERATOR);
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
    return types.dynamicType;
  }

  visitSendSet(SendSet node) {
    Element element = elements[node];
    Identifier selector = node.selector;
    final name = node.assignmentOperator.source.stringValue;
    if (identical(name, '=')) {
      // e1 = value
      if (node.isIndex) {
         // base[key] = value
        final DartType base = analyze(node.receiver);
        final Node keyNode = node.arguments.head;
        final DartType key = analyze(keyNode);
        final Node valueNode = node.arguments.tail.head;
        final DartType value = analyze(valueNode);
        DartType indexSet = lookupMemberType(
            node, base, const SourceString('[]='), MemberKind.OPERATOR);
        if (indexSet is FunctionType) {
          FunctionType indexSetType = indexSet;
          DartType indexSetKey = firstType(indexSetType.parameterTypes);
          checkAssignable(keyNode, key, indexSetKey);
          DartType indexSetValue = secondType(indexSetType.parameterTypes);
          checkAssignable(node.assignmentOperator, value, indexSetValue);
        }
        return value;
      } else {
        // target = value
        DartType target = computeAccessType(node, selector.source,
                                            element, MemberKind.PROPERTY);
        final Node valueNode = node.arguments.head;
        final DartType value = analyze(valueNode);
        checkAssignable(node.assignmentOperator, value, target);
        return value;
      }
    } else if (identical(name, '++') || identical(name, '--')) {
      // e++ or e--
      SourceString operatorName = identical(name, '++')
          ? const SourceString('+') : const SourceString('-');
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
      SourceString operatorName;
      switch (name) {
        case '+=': operatorName = const SourceString('+'); break;
        case '-=': operatorName = const SourceString('-'); break;
        case '*=': operatorName = const SourceString('*'); break;
        case '/=': operatorName = const SourceString('/'); break;
        case '%=': operatorName = const SourceString('%'); break;
        case '~/=': operatorName = const SourceString('~/'); break;
        case '&=': operatorName = const SourceString('&'); break;
        case '|=': operatorName = const SourceString('|'); break;
        case '^=': operatorName = const SourceString('^'); break;
        case '<<=': operatorName = const SourceString('<<'); break;
        case '>>=': operatorName = const SourceString('>>'); break;
        default:
          compiler.internalError(
              'Unexpected assignment operator $name', node: node);
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
    return types.dynamicType;
  }

  DartType visitNewExpression(NewExpression node) {
    Element element = elements[node.send];
    if (Elements.isUnresolved(element)) return types.dynamicType;

    ClassElement enclosingClass = element.getEnclosingClass();
    SourceString name = Elements.deconstructConstructorName(
        element.name, enclosingClass);
    checkPrivateAccess(node, element, name);
    DartType constructorType = computeType(element);
    DartType newType = elements.getType(node);
    // TODO(johnniwinther): Use [:lookupMember:] to account for type variable
    // substitution of parameter types.
    if (identical(newType.kind, TypeKind.INTERFACE)) {
      InterfaceType newInterfaceType = newType;
      constructorType = constructorType.subst(
          newInterfaceType.typeArguments,
          newInterfaceType.element.typeVariables);
    }
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
      checkAssignable(element, elementType, listElementType);
    }
    return listType;
  }

  DartType visitNodeList(NodeList node) {
    DartType type = StatementType.NOT_RETURNING;
    bool reportedDeadCode = false;
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      DartType nextType = analyze(link.head);
      if (type == StatementType.RETURNING) {
        if (!reportedDeadCode) {
          reportTypeWarning(link.head, MessageKind.UNREACHABLE_CODE);
          reportedDeadCode = true;
        }
      } else if (type == StatementType.MAYBE_RETURNING){
        if (nextType == StatementType.RETURNING) {
          type = nextType;
        }
      } else {
        type = nextType;
      }
    }
    return type;
  }

  DartType visitRethrow(Rethrow node) {
    return StatementType.RETURNING;
  }

  /** Dart Programming Language Specification: 11.10 Return */
  DartType visitReturn(Return node) {
    if (identical(node.getBeginToken().stringValue, 'native')) {
      return StatementType.RETURNING;
    }
    if (node.isRedirectingFactoryBody) {
      // TODO(lrn): Typecheck the body. It must refer to the constructor
      // of a subtype.
      return StatementType.RETURNING;
    }

    final expression = node.expression;
    final isVoidFunction = (identical(expectedReturnType, types.voidType));

    // Executing a return statement return e; [...] It is a static type warning
    // if the type of e may not be assigned to the declared return type of the
    // immediately enclosing function.
    if (expression != null) {
      final expressionType = analyze(expression);
      if (isVoidFunction
          && !types.isAssignable(expressionType, types.voidType)) {
        reportTypeWarning(expression, MessageKind.RETURN_VALUE_IN_VOID);
      } else {
        checkAssignable(expression, expressionType, expectedReturnType);
      }

    // Let f be the function immediately enclosing a return statement of the
    // form 'return;' It is a static warning if both of the following conditions
    // hold:
    // - f is not a generative constructor.
    // - The return type of f may not be assigned to void.
    } else if (!types.isAssignable(expectedReturnType, types.voidType)) {
      reportTypeWarning(node, MessageKind.RETURN_NOTHING,
                        {'returnType': expectedReturnType});
    }
    return StatementType.RETURNING;
  }

  DartType visitThrow(Throw node) {
    // TODO(johnniwinther): Handle reachability.
    analyze(node.expression);
    return types.dynamicType;
  }

  // TODO(johnniwinther): Remove this.
  DartType computeType(Element element) {
    if (Elements.isUnresolved(element)) return types.dynamicType;
    DartType result = element.computeType(compiler);
    return (result != null) ? result : types.dynamicType;
  }

  DartType visitTypeAnnotation(TypeAnnotation node) {
    return elements.getType(node);
  }

  DartType visitVariableDefinitions(VariableDefinitions node) {
    DartType type = analyzeWithDefault(node.type, types.dynamicType);
    if (type == types.voidType) {
      reportTypeWarning(node.type, MessageKind.VOID_VARIABLE);
      type = types.dynamicType;
    }
    for (Link<Node> link = node.definitions.nodes; !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      compiler.ensure(definition is Identifier || definition is SendSet);
      if (definition is SendSet) {
        SendSet initialization = definition;
        DartType initializer = analyzeNonVoid(initialization.arguments.head);
        checkAssignable(initialization.assignmentOperator, initializer, type);
      }
    }
    return StatementType.NOT_RETURNING;
  }

  DartType visitWhile(While node) {
    checkCondition(node.condition);
    StatementType bodyType = analyze(node.body);
    Expression cond = node.condition.asParenthesizedExpression().expression;
    if (cond.asLiteralBool() != null && cond.asLiteralBool().value == true) {
      // If the condition is a constant boolean expression denoting true,
      // control-flow always enters the loop body.
      // TODO(karlklose): this should be StatementType.RETURNING unless there
      // is a break in the loop body that has the loop or a label outside the
      // loop as a target.
      return bodyType;
    } else {
      return bodyType.join(StatementType.NOT_RETURNING);
    }
  }

  DartType visitParenthesizedExpression(ParenthesizedExpression node) {
    return analyze(node.expression);
  }

  DartType visitConditional(Conditional node) {
    checkCondition(node.condition);
    DartType thenType = analyzeNonVoid(node.thenExpression);
    DartType elseType = analyzeNonVoid(node.elseExpression);
    if (types.isSubtype(thenType, elseType)) {
      return thenType;
    } else if (types.isSubtype(elseType, thenType)) {
      return elseType;
    } else {
      return objectType;
    }
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
    return StatementType.NOT_RETURNING;
  }

  visitBreakStatement(BreakStatement node) {
    return StatementType.NOT_RETURNING;
  }

  visitContinueStatement(ContinueStatement node) {
    return StatementType.NOT_RETURNING;
  }

  visitForIn(ForIn node) {
    analyze(node.expression);
    StatementType bodyType = analyze(node.body);
    return bodyType.join(StatementType.NOT_RETURNING);
  }

  visitLabeledStatement(LabeledStatement node) {
    return analyze(node.statement);
  }

  visitLiteralMap(LiteralMap node) {
    InterfaceType mapType = elements.getType(node);
    DartType mapKeyType = firstType(mapType.typeArguments);
    DartType mapValueType = secondType(mapType.typeArguments);
    for (Link<Node> link = node.entries.nodes;
         !link.isEmpty;
         link = link.tail) {
      LiteralMapEntry entry = link.head;
      DartType keyType = analyze(entry.key);
      checkAssignable(entry.key, keyType, mapKeyType);
      DartType valueType = analyze(entry.value);
      checkAssignable(entry.value, valueType, mapValueType);
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
    // TODO(johnniwinther): Check assignability to constants.
    DartType expressionType = analyze(node.expression);
    for (SwitchCase switchCase in node.cases) {
      for (Node labelOrCase in switchCase.labelsAndCases) {
        CaseMatch caseMatch = labelOrCase.asCaseMatch();
        if (caseMatch == null) continue;

        DartType caseType = analyze(caseMatch.expression);
        checkAssignable(caseMatch, expressionType, caseType);
      }
      analyze(switchCase);
    }
    return StatementType.NOT_RETURNING;
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
    return StatementType.NOT_RETURNING;
  }

  visitCatchBlock(CatchBlock node) {
    return analyze(node.block);
  }

  visitTypedef(Typedef node) {
    // Do not typecheck [Typedef] nodes.
  }

  visitNode(Node node) {
    compiler.internalError(
        'Unexpected node ${node.getObjectDescription()} in the type checker.',
        node: node);
  }
}
