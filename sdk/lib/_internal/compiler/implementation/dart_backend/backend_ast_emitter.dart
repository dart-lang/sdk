// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library backend_ast_emitter;

import 'tree_ir_nodes.dart' as tree;
import 'backend_ast_nodes.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart' as modelx;
import '../universe/universe.dart';
import '../tree/tree.dart' as tree show Modifiers;

/// Translates the dart_tree IR to Dart backend AST.
Expression emit(tree.FunctionDefinition definition) {
  return new ASTEmitter().emit(definition);
}

/// Translates the dart_tree IR to Dart backend AST.
/// An instance of this class should only be used once; a fresh emitter
/// must be created for each function to be emitted.
class ASTEmitter extends tree.Visitor<dynamic, Expression> {
  /// Variables to be hoisted at the top of the current function.
  List<VariableDeclaration> variables = <VariableDeclaration>[];

  /// Maps variables to their name.
  Map<tree.Variable, String> variableNames = <tree.Variable, String>{};

  /// Maps local constants to their name.
  Map<VariableElement, String> constantNames = <VariableElement, String>{};

  /// Variables that have had their declaration created.
  Set<tree.Variable> declaredVariables = new Set<tree.Variable>();

  /// Variable names that have already been used. Used to avoid name clashes.
  Set<String> usedVariableNames;

  /// Statements emitted by the most recent call to [visitStatement].
  List<Statement> statementBuffer = <Statement>[];

  /// The function currently being emitted.
  FunctionElement functionElement;

  /// Bookkeeping object needed to synthesize a variable declaration.
  modelx.VariableList variableList
      = new modelx.VariableList(tree.Modifiers.EMPTY);

  /// Input to [visitStatement]. Denotes the statement that will execute next
  /// if the statements produced by [visitStatement] complete normally.
  /// Set to null if control will fall over the end of the method.
  tree.Statement fallthrough = null;

  /// Labels that could not be eliminated using fallthrough.
  Set<tree.Label> usedLabels = new Set<tree.Label>();

  /// The first dart_tree statement that is not converted to a variable
  /// initializer.
  tree.Statement firstStatement;

  /// Emitter for the enclosing function, or null if the current function is
  /// not a local function.
  ASTEmitter parent;

  ASTEmitter() : usedVariableNames = new Set<String>();

  ASTEmitter.inner(ASTEmitter parent)
      : this.parent = parent,
        usedVariableNames = parent.usedVariableNames;

  FunctionExpression emit(tree.FunctionDefinition definition) {
    functionElement = definition.element;

    Parameters parameters = emitRootParameters(definition);

    // Declare parameters.
    for (tree.Variable param in definition.parameters) {
      variableNames[param] = param.element.name;
      usedVariableNames.add(param.element.name);
      declaredVariables.add(param);
    }

    Statement body;
    if (definition.isAbstract) {
      body = new EmptyStatement();
    } else {
      firstStatement = definition.body;
      visitStatement(definition.body);
      removeTrailingReturn();

      // Some of the variable declarations have already been added
      // if their first assignment could be pulled into the initializer.
      // Add the remaining variable declarations now.
      for (tree.Variable variable in variableNames.keys) {
        if (!declaredVariables.contains(variable)) {
          addDeclaration(variable);
        }
      }

      // Add constant declarations.
      List<VariableDeclaration> constants = <VariableDeclaration>[];
      for (ConstDeclaration constDecl in definition.localConstants) {
        if (!constantNames.containsKey(constDecl.element))
          continue; // Discard unused constants declarations.
        String name = getConstantName(constDecl.element);
        Expression value = emitConstant(constDecl.expression);
        VariableDeclaration decl = new VariableDeclaration(name, value);
        decl.element = constDecl.element;
        constants.add(decl);
      }

      List<Statement> bodyParts = [];
      if (constants.length > 0) {
        bodyParts.add(new VariableDeclarations(constants, isConst: true));
      }
      if (variables.length > 0) {
        bodyParts.add(new VariableDeclarations(variables));
      }
      bodyParts.addAll(statementBuffer);

      body = new Block(bodyParts);
    }
    FunctionType functionType = functionElement.type;

    return new FunctionExpression(
        parameters,
        body,
        name: functionElement.name,
        returnType: emitOptionalType(functionType.returnType),
        isGetter: functionElement.isGetter,
        isSetter: functionElement.isSetter)
        ..element = functionElement;
  }

  void addDeclaration(tree.Variable variable, [Expression initializer]) {
    assert(!declaredVariables.contains(variable));
    String name = getVariableName(variable);
    VariableDeclaration decl = new VariableDeclaration(name, initializer);
    decl.element = variable.element;
    declaredVariables.add(variable);
    variables.add(decl);
  }

  /// Removes a trailing "return null" from [statementBuffer].
  void removeTrailingReturn() {
    if (statementBuffer.isEmpty) return;
    if (statementBuffer.last is! Return) return;
    Return ret = statementBuffer.last;
    Expression expr = ret.expression;
    if (expr is Literal && expr.value.isNull) {
      statementBuffer.removeLast();
    }
  }

  /// TODO(johnniwinther): Remove this when issue 21283 has been resolved.
  int pseudoNameCounter = 0;

  Parameter emitParameter(DartType type,
                          {String name,
                           Element element,
                           ConstantExpression defaultValue}) {
    if (name == null && element != null) {
      name = element.name;
    }
    if (name == null) {
      name = '_${pseudoNameCounter++}';
    }
    Parameter parameter;
    if (type.isFunctionType) {
      FunctionType functionType = type;
      TypeAnnotation returnType = emitOptionalType(functionType.returnType);
      Parameters innerParameters = emitParametersFromType(functionType);
      parameter = new Parameter.function(name, returnType, innerParameters);
    } else {
      TypeAnnotation typeAnnotation = emitOptionalType(type);
      parameter = new Parameter(name, type: typeAnnotation);
    }
    parameter.element = element;
    if (defaultValue != null && !defaultValue.value.isNull) {
      parameter.defaultValue = emitConstant(defaultValue);
    }
    return parameter;
  }

  Parameters emitParametersFromType(FunctionType functionType) {
    if (functionType.namedParameters.isEmpty) {
      return new Parameters(
          emitParameters(functionType.parameterTypes),
          emitParameters(functionType.optionalParameterTypes),
          false);
    } else {
      return new Parameters(
          emitParameters(functionType.parameterTypes),
          emitParameters(functionType.namedParameterTypes,
                         names: functionType.namedParameters),
          true);
    }
  }

  List<Parameter> emitParameters(
      Iterable<DartType> parameterTypes,
      {Iterable<String> names: const <String>[],
       Iterable<ConstantExpression> defaultValues: const <ConstantExpression>[],
       Iterable<Element> elements: const <Element>[]}) {
    Iterator<String> name = names.iterator;
    Iterator<ConstantExpression> defaultValue = defaultValues.iterator;
    Iterator<Element> element = elements.iterator;
    return parameterTypes.map((DartType type) {
      name.moveNext();
      defaultValue.moveNext();
      element.moveNext();
      return emitParameter(type,
                           name: name.current,
                           defaultValue: defaultValue.current,
                           element: element.current);
    }).toList();
  }

  /// Emits parameters that are not nested inside other parameters.
  /// Root parameters can have default values, while inner parameters cannot.
  Parameters emitRootParameters(tree.FunctionDefinition function) {
    FunctionType functionType = function.element.type;
    List<Parameter> required = emitParameters(
        functionType.parameterTypes,
        elements: function.parameters.map((p) => p.element));
    bool optionalParametersAreNamed = !functionType.namedParameters.isEmpty;
    List<Parameter> optional = emitParameters(
        optionalParametersAreNamed
            ? functionType.namedParameterTypes
            : functionType.optionalParameterTypes,
        defaultValues: function.defaultParameterValues,
        elements: function.parameters.skip(required.length)
            .map((p) => p.element));
    return new Parameters(required, optional, optionalParametersAreNamed);
  }

  /// True if the two expressions are a reference to the same variable.
  bool isSameVariable(Receiver e1, Receiver e2) {
    return e1 is Identifier &&
           e2 is Identifier &&
           e1.element is VariableElement &&
           e1.element == e2.element;
  }

  Expression makeAssignment(Expression target, Expression value) {
    // Try to print as compound assignment or increment
    if (value is BinaryOperator && isCompoundableOperator(value.operator)) {
      Expression leftOperand = value.left;
      Expression rightOperand = value.right;
      bool valid = false;
      if (isSameVariable(target, leftOperand)) {
        valid = true;
      } else if (target is FieldExpression &&
                 leftOperand is FieldExpression &&
                 isSameVariable(target.object, leftOperand.object) &&
                 target.fieldName == leftOperand.fieldName) {
        valid = true;
      } else if (target is IndexExpression &&
                 leftOperand is IndexExpression &&
                 isSameVariable(target.object, leftOperand.object) &&
                 isSameVariable(target.index, leftOperand.index)) {
        valid = true;
      }
      if (valid) {
        if (rightOperand is Literal && rightOperand.value.isOne &&
            (value.operator == '+' || value.operator == '-')) {
          return new Increment.prefix(target, value.operator + value.operator);
        } else {
          return new Assignment(target, value.operator + '=', rightOperand);
        }
      }
    }
    // Fall back to regular assignment
    return new Assignment(target, '=', value);
  }

  void visitExpressionStatement(tree.ExpressionStatement stmt) {
    Expression e = visitExpression(stmt.expression);
    statementBuffer.add(new ExpressionStatement(e));
    visitStatement(stmt.next);
  }

  void visitLabeledStatement(tree.LabeledStatement stmt) {
    List<Statement> savedBuffer = statementBuffer;
    tree.Statement savedFallthrough = fallthrough;
    statementBuffer = <Statement>[];
    fallthrough = stmt.next;
    visitStatement(stmt.body);
    if (usedLabels.remove(stmt.label)) {
      savedBuffer.add(new LabeledStatement(stmt.label.name,
                                           new Block(statementBuffer)));
    } else {
      savedBuffer.add(new Block(statementBuffer));
    }
    fallthrough = savedFallthrough;
    statementBuffer = savedBuffer;
    visitStatement(stmt.next);
  }

  /// Generates a name for the given variable and synthesizes an element for it,
  /// if necessary.
  String getVariableName(tree.Variable variable) {
    // If the variable belongs to an enclosing function, ask the parent emitter
    // for the variable name.
    if (variable.host.element != functionElement) {
      return parent.getVariableName(variable);
    }

    // Get the name if we already have one.
    String name = variableNames[variable];
    if (name != null) {
      return name;
    }

    // Synthesize a variable name that isn't used elsewhere.
    // The [usedVariableNames] set is shared between nested emitters,
    // so this also prevents clash with variables in an enclosing/inner scope.
    // The renaming phase after codegen will further prefix local variables
    // so they cannot clash with top-level variables or fields.
    String prefix = variable.element == null ? 'v' : variable.element.name;
    int counter = 0;
    name = variable.element == null ? '$prefix$counter' : variable.element.name;
    while (!usedVariableNames.add(name)) {
      ++counter;
      name = '$prefix$counter';
    }
    variableNames[variable] = name;

    // Synthesize an element for the variable
    if (variable.element == null || name != variable.element.name) {
      // TODO(johnniwinther): Replace by synthetic [Entity].
      variable.element = new modelx.LocalVariableElementX.synthetic(
          name,
          functionElement,
          variableList);
    }
    return name;
  }

  String getConstantName(VariableElement element) {
    assert(element.kind == ElementKind.VARIABLE);
    if (element.enclosingElement != functionElement) {
      return parent.getConstantName(element);
    }
    String name = constantNames[element];
    if (name != null) {
      return name;
    }
    String prefix = element.name;
    int counter = 0;
    name = element.name;
    while (!usedVariableNames.add(name)) {
      ++counter;
      name = '$prefix$counter';
    }
    constantNames[element] = name;
    return name;
  }

  bool isNullLiteral(Expression exp) => exp is Literal && exp.value.isNull;

  void visitAssign(tree.Assign stmt) {
    // Try to emit a local function declaration. This is useful for functions
    // that may occur in expression context, but could not be inlined anywhere.
    if (stmt.variable.element is FunctionElement &&
        stmt.definition is tree.FunctionExpression &&
        !declaredVariables.contains(stmt.variable)) {
      tree.FunctionExpression functionExp = stmt.definition;
      FunctionExpression function = makeSubFunction(functionExp.definition);
      FunctionDeclaration decl = new FunctionDeclaration(function);
      statementBuffer.add(decl);
      declaredVariables.add(stmt.variable);
      visitStatement(stmt.next);
      return;
    }

    bool isFirstOccurrence = (variableNames[stmt.variable] == null);
    bool isDeclaredHere = stmt.variable.host.element == functionElement;
    String name = getVariableName(stmt.variable);
    Expression definition = visitExpression(stmt.definition);

    // Try to pull into initializer.
    if (firstStatement == stmt && isFirstOccurrence && isDeclaredHere) {
      if (isNullLiteral(definition)) definition = null;
      addDeclaration(stmt.variable, definition);
      firstStatement = stmt.next;
      visitStatement(stmt.next);
      return;
    }

    // Emit a variable declaration if we are required to do so.
    // This is to ensure that a fresh closure variable is created.
    if (stmt.isDeclaration) {
      assert(isFirstOccurrence);
      assert(isDeclaredHere);
      if (isNullLiteral(definition)) definition = null;
      VariableDeclaration decl = new VariableDeclaration(name, definition)
                                     ..element = stmt.variable.element;
      declaredVariables.add(stmt.variable);
      statementBuffer.add(new VariableDeclarations([decl]));
      visitStatement(stmt.next);
      return;
    }

    statementBuffer.add(new ExpressionStatement(makeAssignment(
        visitVariable(stmt.variable),
        definition)));
    visitStatement(stmt.next);
  }

  void visitReturn(tree.Return stmt) {
    Expression inner = visitExpression(stmt.value);
    statementBuffer.add(new Return(inner));
  }

  void visitBreak(tree.Break stmt) {
    tree.Statement fall = fallthrough;
    if (stmt.target.binding.next == fall) {
      // Fall through to break target
    } else if (fall is tree.Break && fall.target == stmt.target) {
      // Fall through to equivalent break
    } else {
      usedLabels.add(stmt.target);
      statementBuffer.add(new Break(stmt.target.name));
    }
  }

  void visitContinue(tree.Continue stmt) {
    tree.Statement fall = fallthrough;
    if (stmt.target.binding == fall) {
      // Fall through to continue target
    } else if (fall is tree.Continue && fall.target == stmt.target) {
      // Fall through to equivalent continue
    } else {
      usedLabels.add(stmt.target);
      statementBuffer.add(new Continue(stmt.target.name));
    }
  }

  void visitIf(tree.If stmt) {
    Expression condition = visitExpression(stmt.condition);
    List<Statement> savedBuffer = statementBuffer;
    List<Statement> thenBuffer = statementBuffer = <Statement>[];
    visitStatement(stmt.thenStatement);
    List<Statement> elseBuffer = statementBuffer = <Statement>[];
    visitStatement(stmt.elseStatement);
    savedBuffer.add(
        new If(condition, new Block(thenBuffer), new Block(elseBuffer)));
    statementBuffer = savedBuffer;
  }

  void visitWhileTrue(tree.WhileTrue stmt) {
    List<Statement> savedBuffer = statementBuffer;
    tree.Statement savedFallthrough = fallthrough;
    statementBuffer = <Statement>[];
    fallthrough = stmt;

    visitStatement(stmt.body);
    Statement body = new Block(statementBuffer);
    Statement statement = new While(new Literal(new TrueConstantValue()),
                                    body);
    if (usedLabels.remove(stmt.label)) {
      statement = new LabeledStatement(stmt.label.name, statement);
    }
    savedBuffer.add(statement);

    statementBuffer = savedBuffer;
    fallthrough = savedFallthrough;
  }

  void visitWhileCondition(tree.WhileCondition stmt) {
    Expression condition = visitExpression(stmt.condition);

    List<Statement> savedBuffer = statementBuffer;
    tree.Statement savedFallthrough = fallthrough;
    statementBuffer = <Statement>[];
    fallthrough = stmt;

    visitStatement(stmt.body);
    Statement body = new Block(statementBuffer);
    Statement statement;
    statement = new While(condition, body);
    if (usedLabels.remove(stmt.label)) {
      statement = new LabeledStatement(stmt.label.name, statement);
    }
    savedBuffer.add(statement);

    statementBuffer = savedBuffer;
    fallthrough = savedFallthrough;

    visitStatement(stmt.next);
  }

  Expression visitConstant(tree.Constant exp) {
    return emitConstant(exp.expression);
  }

  Expression visitThis(tree.This exp) {
    return new This();
  }

  Expression visitReifyTypeVar(tree.ReifyTypeVar exp) {
    return new ReifyTypeVar(exp.typeVariable.name)
               ..element = exp.typeVariable;
  }

  Expression visitLiteralList(tree.LiteralList exp) {
    return new LiteralList(
        exp.values.map(visitExpression).toList(growable: false),
        typeArgument: emitOptionalType(exp.type.typeArguments.single));
  }

  Expression visitLiteralMap(tree.LiteralMap exp) {
    List<LiteralMapEntry> entries = new List<LiteralMapEntry>.generate(
        exp.values.length,
        (i) => new LiteralMapEntry(visitExpression(exp.keys[i]),
                                   visitExpression(exp.values[i])));
    List<TypeAnnotation> typeArguments = exp.type.treatAsRaw
        ? null
        : exp.type.typeArguments.map(createTypeAnnotation).toList(growable: false);
    return new LiteralMap(entries, typeArguments: typeArguments);
  }

  Expression visitTypeOperator(tree.TypeOperator exp) {
    return new TypeOperator(visitExpression(exp.receiver),
                            exp.operator,
                            createTypeAnnotation(exp.type));
  }

  List<Argument> emitArguments(tree.Invoke exp) {
    List<tree.Expression> args = exp.arguments;
    int positionalArgumentCount = exp.selector.positionalArgumentCount;
    List<Argument> result = new List<Argument>.generate(positionalArgumentCount,
        (i) => visitExpression(exp.arguments[i]));
    for (int i = 0; i < exp.selector.namedArgumentCount; ++i) {
      result.add(new NamedArgument(exp.selector.namedArguments[i],
          visitExpression(exp.arguments[positionalArgumentCount + i])));
    }
    return result;
  }

  Expression visitInvokeStatic(tree.InvokeStatic exp) {
    switch (exp.selector.kind) {
      case SelectorKind.GETTER:
        return new Identifier(exp.target.name)..element = exp.target;

      case SelectorKind.SETTER:
        return new Assignment(
            new Identifier(exp.target.name)..element = exp.target,
            '=',
            visitExpression(exp.arguments[0]));

      case SelectorKind.CALL:
        return new CallStatic(null, exp.target.name, emitArguments(exp))
                   ..element = exp.target;

      default:
        throw "Unexpected selector kind: ${exp.selector.kind}";
    }
  }

  Expression emitMethodCall(tree.Invoke exp, Receiver receiver) {
    List<Argument> args = emitArguments(exp);
    switch (exp.selector.kind) {
      case SelectorKind.CALL:
        if (exp.selector.name == "call") {
          return new CallFunction(receiver, args);
        }
        return new CallMethod(receiver, exp.selector.name, args);

      case SelectorKind.OPERATOR:
        if (args.length == 0) {
          String name = exp.selector.name;
          if (name == 'unary-') {
            name = '-';
          }
          return new UnaryOperator(name, receiver);
        }
        return new BinaryOperator(receiver, exp.selector.name, args[0]);

      case SelectorKind.GETTER:
        return new FieldExpression(receiver, exp.selector.name);

      case SelectorKind.SETTER:
        return makeAssignment(
            new FieldExpression(receiver, exp.selector.name),
            args[0]);

      case SelectorKind.INDEX:
        Expression e = new IndexExpression(receiver, args[0]);
        if (args.length == 2) {
          e = makeAssignment(e, args[1]);
        }
        return e;

      default:
        throw "Unexpected selector in InvokeMethod: ${exp.selector.kind}";
    }
  }

  Expression visitInvokeMethod(tree.InvokeMethod exp) {
    Expression receiver = visitExpression(exp.receiver);
    return emitMethodCall(exp, receiver);
  }

  Expression visitInvokeSuperMethod(tree.InvokeSuperMethod exp) {
    return emitMethodCall(exp, new SuperReceiver());
  }

  Expression visitInvokeConstructor(tree.InvokeConstructor exp) {
    List args = emitArguments(exp);
    FunctionElement constructor = exp.target;
    String name = constructor.name.isEmpty ? null : constructor.name;
    return new CallNew(createTypeAnnotation(exp.type),
                       args,
                       constructorName: name,
                       isConst: exp.constant != null)
               ..constructor = constructor
               ..dartType = exp.type;
  }

  Expression visitConcatenateStrings(tree.ConcatenateStrings exp) {
    List args = exp.arguments.map(visitExpression).toList(growable:false);
    return new StringConcat(args);
  }

  Expression visitConditional(tree.Conditional exp) {
    return new Conditional(
        visitExpression(exp.condition),
        visitExpression(exp.thenExpression),
        visitExpression(exp.elseExpression));
  }

  Expression visitLogicalOperator(tree.LogicalOperator exp) {
    return new BinaryOperator(visitExpression(exp.left),
                              exp.operator,
                              visitExpression(exp.right));
  }

  Expression visitNot(tree.Not exp) {
    return new UnaryOperator('!', visitExpression(exp.operand));
  }

  Expression visitVariable(tree.Variable exp) {
    return new Identifier(getVariableName(exp))
               ..element = exp.element;
  }

  FunctionExpression makeSubFunction(tree.FunctionDefinition function) {
    return new ASTEmitter.inner(this).emit(function);
  }

  Expression visitFunctionExpression(tree.FunctionExpression exp) {
    return makeSubFunction(exp.definition)..name = null;
  }

  void visitFunctionDeclaration(tree.FunctionDeclaration node) {
    assert(variableNames[node.variable] == null);
    String name = getVariableName(node.variable);
    FunctionExpression inner = makeSubFunction(node.definition);
    inner.name = name;
    FunctionDeclaration decl = new FunctionDeclaration(inner);
    declaredVariables.add(node.variable);
    statementBuffer.add(decl);
    visitStatement(node.next);
  }

  /// Like [createTypeAnnotation] except the dynamic type is converted to null.
  TypeAnnotation emitOptionalType(DartType type) {
    if (type.treatAsDynamic) {
      return null;
    } else {
      return createTypeAnnotation(type);
    }
  }

  Expression emitConstant(ConstantExpression exp) {
    return new ConstantEmitter(this).visit(exp);
  }
}

TypeAnnotation createTypeAnnotation(DartType type) {
  if (type is GenericType) {
    if (type.treatAsRaw) {
      return new TypeAnnotation(type.element.name)..dartType = type;
    }
    return new TypeAnnotation(
        type.element.name,
        type.typeArguments.map(createTypeAnnotation).toList(growable:false))
        ..dartType = type;
  } else if (type is VoidType) {
    return new TypeAnnotation('void')
        ..dartType = type;
  } else if (type is TypeVariableType) {
    return new TypeAnnotation(type.name)
        ..dartType = type;
  } else if (type is DynamicType) {
    return new TypeAnnotation("dynamic")
        ..dartType = type;
  } else if (type is MalformedType) {
    return new TypeAnnotation(type.name)
        ..dartType = type;
  } else {
    throw "Unsupported type annotation: $type";
  }
}

class ConstantEmitter extends ConstantExpressionVisitor<Expression> {
  ASTEmitter parent;
  ConstantEmitter(this.parent);

  Expression handlePrimitiveConstant(PrimitiveConstantValue value) {
    // Num constants may be negative, while literals must be non-negative:
    // Literals are non-negative in the specification, and a negated literal
    // parses as a call to unary `-`. The AST unparser assumes literals are
    // non-negative and relies on this to avoid incorrectly generating `--`,
    // the predecrement operator.
    // Translate such constants into their positive value wrapped by
    // the unary minus operator.
    if (value.isNum) {
      NumConstantValue numConstant = value;
      if (numConstant.primitiveValue.isNegative) {
        return negatedLiteral(numConstant);
      }
    }
    return new Literal(value);
  }

  @override
  Expression visitPrimitive(PrimitiveConstantExpression exp) {
    return handlePrimitiveConstant(exp.value);
  }

  /// Given a negative num constant, returns the corresponding positive
  /// literal wrapped by a unary minus operator.
  Expression negatedLiteral(NumConstantValue constant) {
    assert(constant.primitiveValue.isNegative);
    NumConstantValue positiveConstant;
    if (constant.isInt) {
      positiveConstant = new IntConstantValue(-constant.primitiveValue);
    } else if (constant.isDouble) {
      positiveConstant = new DoubleConstantValue(-constant.primitiveValue);
    } else {
      throw "Unexpected type of NumConstant: $constant";
    }
    return new UnaryOperator('-', new Literal(positiveConstant));
  }

  @override
  Expression visitList(ListConstantExpression exp) {
    return new LiteralList(
        exp.values.map(visit).toList(growable: false),
        isConst: true,
        typeArgument: parent.emitOptionalType(exp.type.typeArguments.single));
  }

  @override
  Expression visitMap(MapConstantExpression exp) {
    List<LiteralMapEntry> entries = new List<LiteralMapEntry>.generate(
        exp.values.length,
        (i) => new LiteralMapEntry(visit(exp.keys[i]),
                                   visit(exp.values[i])));
    List<TypeAnnotation> typeArguments = exp.type.treatAsRaw
        ? null
        : exp.type.typeArguments.map(createTypeAnnotation).toList();
    return new LiteralMap(entries, isConst: true, typeArguments: typeArguments);
  }

  @override
  Expression visitConstructor(ConstructedConstantExpresssion exp) {
    int positionalArgumentCount = exp.selector.positionalArgumentCount;
    List<Argument> args = new List<Argument>.generate(
        positionalArgumentCount,
        (i) => visit(exp.arguments[i]));
    for (int i = 0; i < exp.selector.namedArgumentCount; ++i) {
      args.add(new NamedArgument(exp.selector.namedArguments[i],
          visit(exp.arguments[positionalArgumentCount + i])));
    }

    FunctionElement constructor = exp.target;
    String name = constructor.name.isEmpty ? null : constructor.name;
    return new CallNew(createTypeAnnotation(exp.type),
                       args,
                       constructorName: name,
                       isConst: true)
               ..constructor = constructor
               ..dartType = exp.type;
  }

  @override
  Expression visitConcatenate(ConcatenateConstantExpression exp) {
    return new StringConcat(exp.arguments.map(visit).toList(growable: false));
  }

  @override
  Expression visitSymbol(SymbolConstantExpression exp) {
    return new LiteralSymbol(exp.name);
  }

  @override
  Expression visitType(TypeConstantExpression exp) {
    DartType type = exp.type;
    return new LiteralType(type.name)
               ..type = type;
  }

  @override
  Expression visitVariable(VariableConstantExpression exp) {
    Element element = exp.element;
    if (element.kind != ElementKind.VARIABLE) {
      return new Identifier(element.name)..element = element;
    }
    String name = parent.getConstantName(element);
    return new Identifier(name)
               ..element = element;
  }

  @override
  Expression visitFunction(FunctionConstantExpression exp) {
    return new Identifier(exp.element.name)
               ..element = exp.element;
  }

  @override
  Expression visitBinary(BinaryConstantExpression exp) {
    return handlePrimitiveConstant(exp.value);
  }

  @override
  Expression visitConditional(ConditionalConstantExpression exp) {
    if (exp.condition.value.isTrue) {
      return exp.trueExp.accept(this);
    } else {
      return exp.falseExp.accept(this);
    }
  }

  @override
  Expression visitUnary(UnaryConstantExpression exp) {
    return handlePrimitiveConstant(exp.value);
  }
}

/// Moves function parameters into a separate variable if one of its uses is
/// shadowed by an inner function parameter.
/// This artifact is necessary because function parameters cannot be renamed.
class UnshadowParameters extends tree.RecursiveVisitor {

  /// Maps parameter names to their bindings.
  Map<String, tree.Variable> environment = <String, tree.Variable>{};

  /// Parameters that are currently shadowed by another parameter.
  Set<tree.Variable> shadowedParameters = new Set<tree.Variable>();

  /// Parameters that are used in a context where it is shadowed.
  Set<tree.Variable> hasShadowedUse = new Set<tree.Variable>();

  void unshadow(tree.FunctionDefinition definition) {
    if (definition.isAbstract) return;

    visitFunctionDefinition(definition);
  }

  visitFunctionDefinition(tree.FunctionDefinition definition) {
    var oldShadow = shadowedParameters;
    var oldEnvironment = environment;
    environment = new Map<String, tree.Variable>.from(environment);
    shadowedParameters = new Set<tree.Variable>.from(shadowedParameters);
    for (tree.Variable param in definition.parameters) {
      tree.Variable oldVariable = environment[param.element.name];
      if (oldVariable != null) {
        shadowedParameters.add(oldVariable);
      }
      environment[param.element.name] = param;
    }
    visitStatement(definition.body);
    environment = oldEnvironment;
    shadowedParameters = oldShadow;

    for (int i=0; i<definition.parameters.length; i++) {
      tree.Variable param = definition.parameters[i];
      if (hasShadowedUse.remove(param)) {
        tree.Variable newParam = new tree.Variable(definition, param.element);
        definition.parameters[i] = newParam;
        definition.body = new tree.Assign(param, newParam, definition.body);
        newParam.writeCount = 1; // Being a parameter counts as a write.
      }
    }
  }

  visitVariable(tree.Variable variable) {
    if (shadowedParameters.contains(variable)) {
      hasShadowedUse.add(variable);
    }
  }

}
