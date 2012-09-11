// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TypeCheckerTask extends CompilerTask {
  TypeCheckerTask(Compiler compiler) : super(compiler);
  String get name => "Type checker";

  static const bool LOG_FAILURES = false;

  void check(Node tree, TreeElements elements) {
    measure(() {
      Visitor visitor =
          new TypeCheckerVisitor(compiler, elements, compiler.types);
      try {
        tree.accept(visitor);
      } on CancelTypeCheckException catch (e) {
        if (LOG_FAILURES) {
          // Do not warn about unimplemented features; log message instead.
          compiler.log("'${e.node}': ${e.reason}");
        }
      }
    });
  }
}

abstract class DartType implements Hashable {
  abstract SourceString get name;
  abstract Element get element;

  /**
   * Returns the unaliased type of this type.
   *
   * The unaliased type of a typedef'd type is the unaliased type to which its
   * name is bound. The unaliased version of any other type is the type itself.
   *
   * For example, the unaliased type of [: typedef A Func<A,B>(B b) :] is the
   * function type [: (B) -> A :] and the unaliased type of
   * [: Func<int,String> :] is the function type [: (String) -> int :].
   */
  abstract DartType unalias(Compiler compiler);

  abstract bool equals(other);
}

class TypeVariableType implements DartType {
  final TypeVariableElement element;

  TypeVariableType(this.element);

  SourceString get name => element.name;

  DartType unalias(Compiler compiler) => this;

  int hashCode() => 17 * element.hashCode();

  bool equals(other) {
    if (other is !TypeVariableType) return false;
    return other.element == element;
  }

  String toString() => name.slowToString();
}

/**
 * A statement type tracks whether a statement returns or may return.
 */
class StatementType implements DartType {
  final String stringName;
  Element get element => null;

  SourceString get name => new SourceString(stringName);

  const StatementType(this.stringName);

  static const RETURNING = const StatementType('<returning>');
  static const NOT_RETURNING = const StatementType('<not returning>');
  static const MAYBE_RETURNING = const StatementType('<maybe returning>');

  /** Combine the information about two control-flow edges that are joined. */
  StatementType join(StatementType other) {
    return (this === other) ? this : MAYBE_RETURNING;
  }

  DartType unalias(Compiler compiler) => this;

  int hashCode() => 17 * stringName.hashCode();

  bool equals(other) {
    if (other is !StatementType) return false;
    return other.stringName == stringName;
  }

  String toString() => stringName;
}

class VoidType implements DartType {
  const VoidType(this.element);
  SourceString get name => element.name;
  final VoidElement element;

  DartType unalias(Compiler compiler) => this;

  int hashCode() => 1729;

  bool equals(other) => other is VoidType;

  String toString() => name.slowToString();
}

class InterfaceType implements DartType {
  final Element element;
  final Link<DartType> arguments;

  const InterfaceType(this.element,
                      [this.arguments = const EmptyLink<DartType>()]);

  SourceString get name => element.name;

  DartType unalias(Compiler compiler) => this;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add(name.slowToString());
    if (!arguments.isEmpty()) {
      sb.add('<');
      arguments.printOn(sb, ', ');
      sb.add('>');
    }
    return sb.toString();
  }

  int hashCode() {
    int hash = element.hashCode();
    for (Link<DartType> arguments = this.arguments;
         !arguments.isEmpty();
         arguments = arguments.tail) {
      int argumentHash = arguments.head != null ? arguments.head.hashCode() : 0;
      hash = 17 * hash + 3 * argumentHash;
    }
    return hash;
  }

  bool equals(other) {
    if (other is !InterfaceType) return false;
    return arguments == other.arguments;
  }
}

class FunctionType implements DartType {
  final Element element;
  DartType returnType;
  Link<DartType> parameterTypes;

  FunctionType(DartType this.returnType, Link<DartType> this.parameterTypes,
               Element this.element);

  DartType unalias(Compiler compiler) => this;

  String toString() {
    StringBuffer sb = new StringBuffer();
    bool first = true;
    sb.add('(');
    parameterTypes.printOn(sb, ', ');
    sb.add(') -> ${returnType}');
    return sb.toString();
  }

  SourceString get name => const SourceString('Function');

  int computeArity() {
    int arity = 0;
    parameterTypes.forEach((_) { arity++; });
    return arity;
  }

  void initializeFrom(FunctionType other) {
    assert(returnType === null);
    assert(parameterTypes === null);
    returnType = other.returnType;
    parameterTypes = other.parameterTypes;
  }

  int hashCode() {
    int hash = 17 * element.hashCode() + 3 * returnType.hashCode();
    for (Link<DartType> parameters = parameterTypes;
         !parameters.isEmpty();
        parameters = parameters.tail) {
      hash = 17 * hash + 3 * parameters.head.hashCode();
    }
    return hash;
  }

  bool equals(other) {
    if (other is !FunctionType) return false;
    return returnType == other.returnType
           && parameterTypes == other.parameterTypes;
  }
}

class TypedefType implements DartType {
  final TypedefElement element;
  final Link<DartType> typeArguments;

  const TypedefType(this.element,
      [this.typeArguments = const EmptyLink<DartType>()]);

  SourceString get name => element.name;

  DartType unalias(Compiler compiler) {
    // TODO(ahe): This should be [ensureResolved].
    compiler.resolveTypedef(element);
    return element.alias.unalias(compiler);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add(name.slowToString());
    if (!typeArguments.isEmpty()) {
      sb.add('<');
      typeArguments.printOn(sb, ', ');
      sb.add('>');
    }
    return sb.toString();
  }

  int hashCode() => 17 * element.hashCode();

  bool equals(other) {
    if (other is !TypedefType) return false;
    return other.element == element;
  }
}

class Types {
  final Compiler compiler;
  // TODO(karlklose): should we have a class Void?
  final VoidType voidType;
  final InterfaceType dynamicType;

  Types(Compiler compiler, Element dynamicElement)
    : this.with(compiler, dynamicElement,
                new LibraryElement(new Script(null, null)));

  Types.with(Compiler this.compiler,
             Element dynamicElement,
             LibraryElement library)
    : voidType = new VoidType(new VoidElement(library)),
      dynamicType = new InterfaceType(dynamicElement);

  /** Returns true if t is a subtype of s */
  bool isSubtype(DartType t, DartType s) {
    if (t === s ||
        t === dynamicType ||
        s === dynamicType ||
        s.element === compiler.objectClass ||
        t.element === compiler.nullClass) {
      return true;
    }
    t = t.unalias(compiler);
    s = s.unalias(compiler);

    if (t is VoidType) {
      return false;
    } else if (t is InterfaceType) {
      if (s is !InterfaceType) return false;
      ClassElement tc = t.element;
      if (tc === s.element) return true;
      for (Link<DartType> supertypes = tc.allSupertypes;
           supertypes != null && !supertypes.isEmpty();
           supertypes = supertypes.tail) {
        DartType supertype = supertypes.head;
        if (supertype.element === s.element) return true;
      }
      return false;
    } else if (t is FunctionType) {
      if (s.element === compiler.functionClass) return true;
      if (s is !FunctionType) return false;
      FunctionType tf = t;
      FunctionType sf = s;
      Link<DartType> tps = tf.parameterTypes;
      Link<DartType> sps = sf.parameterTypes;
      while (!tps.isEmpty() && !sps.isEmpty()) {
        if (!isAssignable(tps.head, sps.head)) return false;
        tps = tps.tail;
        sps = sps.tail;
      }
      if (!tps.isEmpty() || !sps.isEmpty()) return false;
      if (!isAssignable(sf.returnType, tf.returnType)) return false;
      return true;
    } else if (t is TypeVariableType) {
      if (s is !TypeVariableType) return false;
      return (t.element === s.element);
    } else {
      throw 'internal error: unknown type kind';
    }
  }

  bool isAssignable(DartType r, DartType s) {
    return isSubtype(r, s) || isSubtype(s, r);
  }
}

class CancelTypeCheckException {
  final Node node;
  final String reason;

  CancelTypeCheckException(this.node, this.reason);
}

class TypeCheckerVisitor implements Visitor<DartType> {
  final Compiler compiler;
  final TreeElements elements;
  final Types types;

  Node lastSeenNode;
  DartType expectedReturnType;
  ClassElement currentClass;

  Link<DartType> cascadeTypes = const EmptyLink<DartType>();

  DartType intType;
  DartType doubleType;
  DartType boolType;
  DartType stringType;
  DartType objectType;
  DartType listType;

  TypeCheckerVisitor(this.compiler, this.elements, this.types) {
    intType = compiler.intClass.computeType(compiler);
    doubleType = compiler.doubleClass.computeType(compiler);
    boolType = compiler.boolClass.computeType(compiler);
    stringType = compiler.stringClass.computeType(compiler);
    objectType = compiler.objectClass.computeType(compiler);
    listType = compiler.listClass.computeType(compiler);
  }

  DartType fail(node, [reason]) {
    String message = 'cannot type-check';
    if (reason !== null) {
      message = '$message: $reason';
    }
    throw new CancelTypeCheckException(node, message);
  }

  reportTypeWarning(Node node, MessageKind kind, [List arguments = const []]) {
    compiler.reportWarning(node, new TypeWarning(kind, arguments));
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
    return node !== null ? analyze(node) : defaultValue;
  }

  DartType analyze(Node node) {
    if (node == null) {
      final String error = 'internal error: unexpected node: null';
      if (lastSeenNode != null) {
        fail(null, error);
      } else {
        compiler.cancel(error);
      }
    } else {
      lastSeenNode = node;
    }
    DartType result = node.accept(this);
    // TODO(karlklose): record type?
    if (result === null) {
      fail(node, 'internal error: type is null');
    }
    return result;
  }

  /**
   * Check if a value of type t can be assigned to a variable,
   * parameter or return value of type s.
   */
  checkAssignable(Node node, DartType s, DartType t) {
    if (!types.isAssignable(s, t)) {
      reportTypeWarning(node, MessageKind.NOT_ASSIGNABLE, [s, t]);
    }
  }

  checkCondition(Expression condition) {
    checkAssignable(condition, boolType, analyze(condition));
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

  DartType visitClassNode(ClassNode node) {
    fail(node);
  }

  DartType visitDoWhile(DoWhile node) {
    StatementType bodyType = analyze(node.body);
    checkCondition(node.condition);
    return bodyType.join(StatementType.NOT_RETURNING);
  }

  DartType visitExpressionStatement(ExpressionStatement node) {
    analyze(node.expression);
    return StatementType.NOT_RETURNING;
  }

  /** Dart Programming Language Specification: 11.5.1 For Loop */
  DartType visitFor(For node) {
    analyzeWithDefault(node.initializer, StatementType.NOT_RETURNING);
    checkCondition(node.condition);
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
    if (element.kind === ElementKind.GENERATIVE_CONSTRUCTOR ||
        element.kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
      type = types.dynamicType;
      returnType = types.voidType;
    } else {
      FunctionType functionType = computeType(element);
      returnType = functionType.returnType;
      type = functionType;
    }
    DartType previous = expectedReturnType;
    expectedReturnType = returnType;
    if (element.isMember()) currentClass = element.getEnclosingClass();
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
    } else {
      // This is an identifier of a formal parameter.
      return types.dynamicType;
    }
  }

  DartType visitIf(If node) {
    checkCondition(node.condition);
    StatementType thenType = analyze(node.thenPart);
    StatementType elseType = node.hasElsePart ? analyze(node.elsePart)
                                              : StatementType.NOT_RETURNING;
    return thenType.join(elseType);
  }

  DartType visitLoop(Loop node) {
    return unhandledStatement();
  }

  DartType lookupMethodType(Node node, ClassElement classElement,
                        SourceString name) {
    Element member = classElement.lookupLocalMember(name);
    if (member === null) {
      classElement.ensureResolved(compiler);
      for (Link<DartType> supertypes = classElement.allSupertypes;
           !supertypes.isEmpty() && member === null;
           supertypes = supertypes.tail) {
        ClassElement lookupTarget = supertypes.head.element;
        member = lookupTarget.lookupLocalMember(name);
      }
    }
    if (member !== null && member.kind == ElementKind.FUNCTION) {
      return computeType(member);
    }
    reportTypeWarning(node, MessageKind.METHOD_NOT_FOUND,
                      [classElement.name, name]);
    return types.dynamicType;
  }

  void analyzeArguments(Send send, DartType type) {
    Link<Node> arguments = send.arguments;
    if (type === null || type === types.dynamicType) {
      while(!arguments.isEmpty()) {
        analyze(arguments.head);
        arguments = arguments.tail;
      }
    } else {
      FunctionType funType = type;
      Link<DartType> parameterTypes = funType.parameterTypes;
      while (!arguments.isEmpty() && !parameterTypes.isEmpty()) {
        checkAssignable(arguments.head, parameterTypes.head,
                        analyze(arguments.head));
        arguments = arguments.tail;
        parameterTypes = parameterTypes.tail;
      }
      if (!arguments.isEmpty()) {
        reportTypeWarning(arguments.head, MessageKind.ADDITIONAL_ARGUMENT);
      } else if (!parameterTypes.isEmpty()) {
        reportTypeWarning(send, MessageKind.MISSING_ARGUMENT,
                          [parameterTypes.head]);
      }
    }
  }

  DartType visitSend(Send node) {
    Element element = elements[node];

    if (Elements.isClosureSend(node, element)) {
      // TODO(karlklose): Finish implementation.
      return types.dynamicType;
    }

    Identifier selector = node.selector.asIdentifier();
    String name = selector.source.stringValue;

    if (node.isOperator && name === 'is') {
      analyze(node.receiver);
      return boolType;
    } else if (node.isOperator) {
      final Node firstArgument = node.receiver;
      final DartType firstArgumentType = analyze(node.receiver);
      final arguments = node.arguments;
      final Node secondArgument = arguments.isEmpty() ? null : arguments.head;
      final DartType secondArgumentType =
          analyzeWithDefault(secondArgument, null);

      if (name === '+' || name === '=' || name === '-'
          || name === '*' || name === '/' || name === '%'
          || name === '~/' || name === '|' || name ==='&'
          || name === '^' || name === '~'|| name === '<<'
          || name === '>>' || name === '[]') {
        return types.dynamicType;
      } else if (name === '<' || name === '>' || name === '<='
                 || name === '>=' || name === '==' || name === '!='
                 || name === '===' || name === '!==') {
        return boolType;
      } else if (name === '||' || name === '&&' || name === '!') {
        checkAssignable(firstArgument, boolType, firstArgumentType);
        if (!arguments.isEmpty()) {
          // TODO(karlklose): check number of arguments in validator.
          checkAssignable(secondArgument, boolType, secondArgumentType);
        }
        return boolType;
      }
      fail(selector, 'unexpected operator ${name}');

    } else if (node.isPropertyAccess) {
      if (node.receiver !== null) {
        // TODO(karlklose): we cannot handle fields.
        return unhandledExpression();
      }
      if (element === null) return types.dynamicType;
      return computeType(element);

    } else if (node.isFunctionObjectInvocation) {
      fail(node.receiver, 'function object invocation unimplemented');

    } else {
      FunctionType computeFunType() {
        if (node.receiver !== null) {
          DartType receiverType = analyze(node.receiver);
          if (receiverType.element == compiler.dynamicClass) return null;
          if (receiverType === null) {
            fail(node.receiver, 'receivertype is null');
          }
          if (receiverType.element.kind === ElementKind.GETTER) {
            FunctionType getterType  = receiverType;
            receiverType = getterType.returnType;
          }
          ElementKind receiverKind = receiverType.element.kind;
          if (receiverKind === ElementKind.TYPEDEF) {
            // TODO(karlklose): handle typedefs.
            return null;
          }
          if (receiverKind === ElementKind.TYPE_VARIABLE) {
            // TODO(karlklose): handle type variables.
            return null;
          }
          if (receiverKind !== ElementKind.CLASS) {
            fail(node.receiver, 'unexpected receiver kind: ${receiverKind}');
          }
          ClassElement classElement = receiverType.element;
          // TODO(karlklose): substitute type arguments.
          DartType memberType =
            lookupMethodType(selector, classElement, selector.source);
          if (memberType.element === compiler.dynamicClass) return null;
          return memberType;
        } else {
          if (Elements.isUnresolved(element)) {
            fail(node, 'unresolved ${node.selector}');
          } else if (element.kind === ElementKind.FUNCTION) {
            return computeType(element);
          } else if (element.kind === ElementKind.FOREIGN) {
            return null;
          } else if (element.kind === ElementKind.VARIABLE
                     || element.kind === ElementKind.FIELD) {
            // TODO(karlklose): handle object invocations.
            return null;
          } else {
            fail(node, 'unexpected element kind ${element.kind}');
          }
        }
      }
      FunctionType funType = computeFunType();
      analyzeArguments(node, funType);
      return (funType !== null) ? funType.returnType : types.dynamicType;
    }
  }

  visitSendSet(SendSet node) {
    Identifier selector = node.selector;
    final name = node.assignmentOperator.source.stringValue;
    if (name === '++' || name === '--') {
      final Element element = elements[node.selector];
      final DartType receiverType = computeType(element);
      // TODO(karlklose): this should be the return type instead of int.
      return node.isPrefix ? intType : receiverType;
    } else {
      DartType targetType = computeType(elements[node]);
      Node value = node.arguments.head;
      checkAssignable(value, targetType, analyze(value));
      return targetType;
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
    analyzeArguments(node.send, computeType(element));
    return analyze(node.send.selector);
  }

  DartType visitLiteralList(LiteralList node) {
    return listType;
  }

  DartType visitNodeList(NodeList node) {
    DartType type = StatementType.NOT_RETURNING;
    bool reportedDeadCode = false;
    for (Link<Node> link = node.nodes; !link.isEmpty(); link = link.tail) {
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

  DartType visitOperator(Operator node) {
    fail(node, 'internal error');
  }

  /** Dart Programming Language Specification: 11.10 Return */
  DartType visitReturn(Return node) {
    if (node.getBeginToken().stringValue === 'native') {
      return StatementType.RETURNING;
    }

    final expression = node.expression;
    final isVoidFunction = (expectedReturnType === types.voidType);

    // Executing a return statement return e; [...] It is a static type warning
    // if the type of e may not be assigned to the declared return type of the
    // immediately enclosing function.
    if (expression !== null) {
      final expressionType = analyze(expression);
      if (isVoidFunction
          && !types.isAssignable(expressionType, types.voidType)) {
        reportTypeWarning(expression, MessageKind.RETURN_VALUE_IN_VOID,
                          [expressionType]);
      } else {
        checkAssignable(expression, expectedReturnType, expressionType);
      }

    // Let f be the function immediately enclosing a return statement of the
    // form 'return;' It is a static warning if both of the following conditions
    // hold:
    // - f is not a generative constructor.
    // - The return type of f may not be assigned to void.
    } else if (!types.isAssignable(expectedReturnType, types.voidType)) {
      reportTypeWarning(node, MessageKind.RETURN_NOTHING, [expectedReturnType]);
    }
    return StatementType.RETURNING;
  }

  DartType visitThrow(Throw node) {
    if (node.expression !== null) analyze(node.expression);
    return StatementType.RETURNING;
  }

  DartType computeType(Element element) {
    if (Elements.isUnresolved(element)) return types.dynamicType;
    DartType result = element.computeType(compiler);
    return (result !== null) ? result : types.dynamicType;
  }

  DartType visitTypeAnnotation(TypeAnnotation node) {
    return elements.getType(node);
  }

  visitTypeVariable(TypeVariable node) {
    return types.dynamicType;
  }

  DartType visitVariableDefinitions(VariableDefinitions node) {
    DartType type = analyzeWithDefault(node.type, types.dynamicType);
    if (type == types.voidType) {
      reportTypeWarning(node.type, MessageKind.VOID_VARIABLE);
      type = types.dynamicType;
    }
    for (Link<Node> link = node.definitions.nodes; !link.isEmpty();
         link = link.tail) {
      Node initialization = link.head;
      compiler.ensure(initialization is Identifier
                      || initialization is Send);
      if (initialization is Send) {
        DartType initializer = analyzeNonVoid(link.head);
        checkAssignable(node, type, initializer);
      }
    }
    return StatementType.NOT_RETURNING;
  }

  DartType visitWhile(While node) {
    checkCondition(node.condition);
    StatementType bodyType = analyze(node.body);
    Expression cond = node.condition.asParenthesizedExpression().expression;
    if (cond.asLiteralBool() !== null && cond.asLiteralBool().value == true) {
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

  DartType visitModifiers(Modifiers node) {}

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

  visitLabel(Label node) { }

  visitLabeledStatement(LabeledStatement node) {
    return node.statement.accept(this);
  }

  visitLiteralMap(LiteralMap node) {
    return unhandledExpression();
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    return unhandledExpression();
  }

  visitNamedArgument(NamedArgument node) {
    return unhandledExpression();
  }

  visitSwitchStatement(SwitchStatement node) {
    return unhandledStatement();
  }

  visitSwitchCase(SwitchCase node) {
    return unhandledStatement();
  }

  visitCaseMatch(CaseMatch node) {
    return unhandledStatement();
  }

  visitTryStatement(TryStatement node) {
    return unhandledStatement();
  }

  visitScriptTag(ScriptTag node) {
    return unhandledExpression();
  }

  visitCatchBlock(CatchBlock node) {
    return unhandledStatement();
  }

  visitTypedef(Typedef node) {
    return unhandledStatement();
  }
}
