// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library backend_ast_emitter;

import '../tree_ir/tree_ir_nodes.dart' as tree;
import 'backend_ast_nodes.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart' as modelx;
import '../universe/universe.dart';
import '../tree/tree.dart' as tree show Modifiers;

/// Translates the dart_tree IR to Dart backend AST.
ExecutableDefinition emit(tree.ExecutableDefinition definition) {
  return new ASTEmitter().emit(definition, new BuilderContext<Statement>());
}

// TODO(johnniwinther): Split into function/block state.
class BuilderContext<T> {
  /// Builder context for the enclosing function, or null if the current
  /// function is not a local function.
  BuilderContext<T> _parent;

  /// Variables to be hoisted at the top of the current function.
  final List<VariableDeclaration> variables = <VariableDeclaration>[];

  /// Maps variables to their name.
  final Map<tree.Variable, String> variableNames = <tree.Variable, String>{};

  /// Maps local constants to their name.
  final Map<VariableElement, String> constantNames =
      <VariableElement, String>{};

  /// Variables that have had their declaration created.
  final Set<tree.Variable> declaredVariables = new Set<tree.Variable>();

  /// Variable names that have already been used. Used to avoid name clashes.
  final Set<String> usedVariableNames;

  /// Statements emitted by the most recent call to [visitStatement].
  List<T> _statementBuffer = <T>[];

  /// The element currently being emitted.
  ExecutableElement currentElement;

  /// Bookkeeping object needed to synthesize a variable declaration.
  final modelx.VariableList variableList
      = new modelx.VariableList(tree.Modifiers.EMPTY);

  /// Input to [visitStatement]. Denotes the statement that will execute next
  /// if the statements produced by [visitStatement] complete normally.
  /// Set to null if control will fall over the end of the method.
  tree.Statement fallthrough = null;

  /// Labels that could not be eliminated using fallthrough.
  final Set<tree.Label> _usedLabels = new Set<tree.Label>();

  /// The first dart_tree statement that is not converted to a variable
  /// initializer.
  tree.Statement firstStatement;

  BuilderContext() : usedVariableNames = new Set<String>();

  BuilderContext.inner(BuilderContext<T> parent)
      : this._parent = parent,
        usedVariableNames = parent.usedVariableNames;

  // TODO(johnniwinther): Fully encapsulate handling of parameter, variable
  // and local funciton declarations.
  void addDeclaration(tree.Variable variable, [Expression initializer]) {
    assert(!declaredVariables.contains(variable));
    String name = getVariableName(variable);
    VariableDeclaration decl = new VariableDeclaration(name, initializer);
    decl.element = variable.element;
    declaredVariables.add(variable);
    variables.add(decl);
  }

  /// Generates a name for the given variable and synthesizes an element for it,
  /// if necessary.
  String getVariableName(tree.Variable variable) {
    // If the variable belongs to an enclosing function, ask the parent emitter
    // for the variable name.
    if (variable.host != currentElement) {
      return _parent.getVariableName(variable);
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
      variable.element = new _SyntheticLocalVariableElement(
          name,
          currentElement,
          variableList);
    }
    return name;
  }

  String getConstantName(VariableElement element) {
    assert(element.kind == ElementKind.VARIABLE);
    if (element.enclosingElement != currentElement) {
      return _parent.getConstantName(element);
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

  List<T> inSubcontext(f(BuilderContext<T> subcontext),
                       {tree.Statement fallthrough}) {
    List<T> savedBuffer = this._statementBuffer;
    tree.Statement savedFallthrough = this.fallthrough;
    List<T> buffer = this._statementBuffer = <T>[];
    if (fallthrough != null) {
      this.fallthrough = fallthrough;
    }
    f(this);
    this.fallthrough = savedFallthrough;
    this._statementBuffer = savedBuffer;
    return buffer;
  }

  /// Removes a trailing "return null" from the current block.
  void removeTrailingReturn(bool isReturnNull(T statement)) {
    if (_statementBuffer.isEmpty) return;
    if (isReturnNull(_statementBuffer.last)) {
      _statementBuffer.removeLast();
    }
  }

  /// Register [label] as used.
  void useLabel(tree.Label label) {
    _usedLabels.add(label);
  }

  /// Remove [label] and return `true` if it was used.
  bool removeUsedLabel(tree.Label label) {
    return _usedLabels.remove(label);
  }

  /// Add [statement] to the current block.
  void addStatement(T statement) {
    _statementBuffer.add(statement);
  }

  /// The statements in the current block.
  Iterable<T> get statements => _statementBuffer;
}


/// Translates the dart_tree IR to Dart backend AST.
/// An instance of this class should only be used once; a fresh emitter
/// must be created for each function to be emitted.
class ASTEmitter
    extends tree.Visitor1<dynamic, Expression, BuilderContext<Statement>> {

  ExecutableDefinition emit(tree.ExecutableDefinition definition,
                            BuilderContext<Statement> context) {
    if (definition is tree.FieldDefinition) {
      return emitField(definition, context);
    }
    assert(definition is tree.FunctionDefinition);
    return emitFunction(definition, context);
  }

  FieldDefinition emitField(tree.FieldDefinition definition,
                            BuilderContext<Statement> context) {
    context.currentElement = definition.element;
    Expression initializer;
    if (definition.hasInitializer) {
      visitStatement(definition.body, context);
      List<Statement> bodyParts;
      for (tree.Variable variable in context.variableNames.keys) {
        if (!context.declaredVariables.contains(variable)) {
          context.addDeclaration(variable);
        }
      }
      if (context.variables.length > 0) {
        bodyParts = new List<Statement>();
        bodyParts.add(new VariableDeclarations(context.variables));
        bodyParts.addAll(context.statements);
      } else {
        bodyParts = context.statements;
      }
      initializer = ensureExpression(bodyParts);
    }

    return new FieldDefinition(definition.element, initializer);
  }

  /// Returns an expression that will evaluate all of [bodyParts].
  /// If [bodyParts] is a single [Return] return its value.
  /// Otherwise wrap the body-parts in an immediately invoked closure.
  Expression ensureExpression(List<Statement> bodyParts) {
    if (bodyParts.length == 1) {
      Statement onlyStatement = bodyParts.single;
      if (onlyStatement is Return) {
        return onlyStatement.expression;
      }
    }
    Statement body = new Block(bodyParts);
    FunctionExpression function =
        new FunctionExpression(new Parameters([]), body);
    function.element = null;
    return new CallFunction(function, []);
  }

  FunctionExpression emitFunction(tree.FunctionDefinition definition,
                                  BuilderContext<Statement> context) {
    context.currentElement = definition.element;

    Parameters parameters = emitRootParameters(definition, context);

    // Declare parameters.
    for (tree.Variable param in definition.parameters) {
      context.variableNames[param] = param.element.name;
      context.usedVariableNames.add(param.element.name);
      context.declaredVariables.add(param);
    }

    Statement body;
    if (definition.isAbstract) {
      body = new EmptyStatement();
    } else {
      context.firstStatement = definition.body;
      visitStatement(definition.body, context);
      context.removeTrailingReturn((Statement statement) {
        if (statement is Return) {
          Expression expr = statement.expression;
          if (expr is Literal && expr.value.isNull) {
            return true;
          }
        }
        return false;
      });

      // Some of the variable declarations have already been added
      // if their first assignment could be pulled into the initializer.
      // Add the remaining variable declarations now.
      for (tree.Variable variable in context.variableNames.keys) {
        if (!context.declaredVariables.contains(variable)) {
          context.addDeclaration(variable);
        }
      }

      // Add constant declarations.
      List<VariableDeclaration> constants = <VariableDeclaration>[];
      for (ConstDeclaration constDecl in definition.localConstants) {
        if (!context.constantNames.containsKey(constDecl.element)) {
          continue; // Discard unused constants declarations.
        }
        String name = context.getConstantName(constDecl.element);
        Expression value =
            ConstantEmitter.createExpression(constDecl.expression, context);
        VariableDeclaration decl = new VariableDeclaration(name, value);
        decl.element = constDecl.element;
        constants.add(decl);
      }

      List<Statement> bodyParts = [];
      if (constants.length > 0) {
        bodyParts.add(new VariableDeclarations(constants, isConst: true));
      }
      if (context.variables.length > 0) {
        bodyParts.add(new VariableDeclarations(context.variables));
      }
      bodyParts.addAll(context.statements);

      body = new Block(bodyParts);
    }
    FunctionType functionType = context.currentElement.type;

    return new FunctionExpression(
        parameters,
        body,
        name: context.currentElement.name,
        returnType: TypeGenerator.createOptionalType(functionType.returnType),
        isGetter: context.currentElement.isGetter,
        isSetter: context.currentElement.isSetter)
        ..element = context.currentElement;
  }

  /// Emits parameters that are not nested inside other parameters.
  /// Root parameters can have default values, while inner parameters cannot.
  Parameters emitRootParameters(tree.FunctionDefinition function,
                                BuilderContext<Statement> context) {
    FunctionType functionType = function.element.type;
    List<Parameter> required = TypeGenerator.createParameters(
        functionType.parameterTypes,
        context: context,
        elements: function.parameters.map((p) => p.element));
    bool optionalParametersAreNamed = !functionType.namedParameters.isEmpty;
    List<Parameter> optional = TypeGenerator.createParameters(
        optionalParametersAreNamed
            ? functionType.namedParameterTypes
            : functionType.optionalParameterTypes,
        context: context,
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

  Block visitInSubContext(tree.Statement statement,
                          BuilderContext<Statement> context,
                          {tree.Statement fallthrough}) {
    return new Block(context.inSubcontext(
        (BuilderContext<Statement> subcontext) {
      visitStatement(statement, subcontext);
    }, fallthrough: fallthrough));
  }

  void addLabeledStatement(tree.Label label,
                           Statement statement,
                           BuilderContext<Statement> context) {
    if (context.removeUsedLabel(label)) {
      context.addStatement(new LabeledStatement(label.name, statement));
    } else {
      context.addStatement(statement);
    }
  }

  @override
  void visitExpressionStatement(tree.ExpressionStatement stmt,
                                BuilderContext<Statement> context) {
    Expression e = visitExpression(stmt.expression, context);
    context.addStatement(new ExpressionStatement(e));

    visitStatement(stmt.next, context);
  }

  @override
  void visitLabeledStatement(tree.LabeledStatement stmt,
                             BuilderContext<Statement> context) {
    Block block = visitInSubContext(stmt.body, context, fallthrough: stmt.next);
    addLabeledStatement(stmt.label, block, context);

    visitStatement(stmt.next, context);
  }

  bool isNullLiteral(Expression exp) => exp is Literal && exp.value.isNull;

  @override
  void visitAssign(tree.Assign stmt,
                   BuilderContext<Statement> context) {
    // Try to emit a local function declaration. This is useful for functions
    // that may occur in expression context, but could not be inlined anywhere.
    if (stmt.variable.element is FunctionElement &&
        stmt.definition is tree.FunctionExpression &&
        !context.declaredVariables.contains(stmt.variable)) {
      tree.FunctionExpression functionExp = stmt.definition;
      FunctionExpression function =
          makeSubFunction(functionExp.definition, context);
      FunctionDeclaration decl = new FunctionDeclaration(function);
      context.addStatement(decl);
      context.declaredVariables.add(stmt.variable);

      visitStatement(stmt.next, context);
      return;
    }

    bool isFirstOccurrence = (context.variableNames[stmt.variable] == null);
    bool isDeclaredHere = stmt.variable.host == context.currentElement;
    String name = context.getVariableName(stmt.variable);
    Expression definition = visitExpression(stmt.definition, context);

    // Try to pull into initializer.
    if (context.firstStatement == stmt && isFirstOccurrence && isDeclaredHere) {
      if (isNullLiteral(definition)) definition = null;
      context.addDeclaration(stmt.variable, definition);
      context.firstStatement = stmt.next;
      visitStatement(stmt.next, context);
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
      context.declaredVariables.add(stmt.variable);
      context.addStatement(new VariableDeclarations([decl]));
      visitStatement(stmt.next, context);
      return;
    }

    context.addStatement(new ExpressionStatement(makeAssignment(
        visitVariable(stmt.variable, context),
        definition)));
    visitStatement(stmt.next, context);
  }

  @override
  void visitReturn(tree.Return stmt,
                   BuilderContext<Statement> context) {
    Expression inner = visitExpression(stmt.value, context);
    context.addStatement(new Return(inner));
  }

  @override
  void visitBreak(tree.Break stmt,
                  BuilderContext<Statement> context) {
    tree.Statement fall = context.fallthrough;
    if (stmt.target.binding.next == fall) {
      // Fall through to break target
    } else if (fall is tree.Break && fall.target == stmt.target) {
      // Fall through to equivalent break
    } else {
      context.useLabel(stmt.target);
      context.addStatement(new Break(stmt.target.name));
    }
  }

  @override
  void visitContinue(tree.Continue stmt,
                     BuilderContext<Statement> context) {
    tree.Statement fall = context.fallthrough;
    if (stmt.target.binding == fall) {
      // Fall through to continue target
    } else if (fall is tree.Continue && fall.target == stmt.target) {
      // Fall through to equivalent continue
    } else {
      context.useLabel(stmt.target);
      context.addStatement(new Continue(stmt.target.name));
    }
  }

  @override
  void visitIf(tree.If stmt,
               BuilderContext<Statement> context) {
    Expression condition = visitExpression(stmt.condition, context);
    Block thenBlock = visitInSubContext(stmt.thenStatement, context);
    Block elseBlock= visitInSubContext(stmt.elseStatement, context);
    context.addStatement(new If(condition, thenBlock, elseBlock));
  }

  @override
  void visitWhileTrue(tree.WhileTrue stmt,
                      BuilderContext<Statement> context) {
    Block body = visitInSubContext(stmt.body, context, fallthrough: stmt);
    Statement statement =
        new While(new Literal(new TrueConstantValue()), body);
    addLabeledStatement(stmt.label, statement, context);
  }

  @override
  void visitWhileCondition(tree.WhileCondition stmt,
                           BuilderContext<Statement> context) {
    Expression condition = visitExpression(stmt.condition, context);
    Block body = visitInSubContext(stmt.body, context, fallthrough: stmt);
    Statement statement = new While(condition, body);
    addLabeledStatement(stmt.label, statement, context);

    visitStatement(stmt.next, context);
  }

  @override
  Expression visitConstant(tree.Constant exp,
                           BuilderContext<Statement> context) {
    return ConstantEmitter.createExpression(exp.expression, context);
  }

  @override
  Expression visitThis(tree.This exp,
                       BuilderContext<Statement> context) {
    return new This();
  }

  @override
  Expression visitReifyTypeVar(tree.ReifyTypeVar exp,
                               BuilderContext<Statement> context) {
    return new ReifyTypeVar(exp.typeVariable.name)
               ..element = exp.typeVariable;
  }

  List<Expression> visitExpressions(List<tree.Expression> expressions,
                                    BuilderContext<Statement> context) {
    return expressions.map((expression) => visitExpression(expression, context))
        .toList(growable: false);
  }

  @override
  Expression visitLiteralList(tree.LiteralList exp,
                              BuilderContext<Statement> context) {
    return new LiteralList(visitExpressions(exp.values, context),
        typeArgument:
            TypeGenerator.createOptionalType(exp.type.typeArguments.single));
  }

  @override
  Expression visitLiteralMap(tree.LiteralMap exp,
                             BuilderContext<Statement> context) {
    List<LiteralMapEntry> entries = new List<LiteralMapEntry>.generate(
        exp.entries.length,
        (i) => new LiteralMapEntry(
            visitExpression(exp.entries[i].key, context),
            visitExpression(exp.entries[i].value, context)));
    List<TypeAnnotation> typeArguments = exp.type.treatAsRaw
        ? null
        : exp.type.typeArguments.map(TypeGenerator.createType)
             .toList(growable: false);
    return new LiteralMap(entries, typeArguments: typeArguments);
  }

  @override
  Expression visitTypeOperator(tree.TypeOperator exp,
                               BuilderContext<Statement> context) {
    return new TypeOperator(visitExpression(exp.receiver, context),
                            exp.operator,
                            TypeGenerator.createType(exp.type));
  }

  List<Argument> emitArguments(tree.Invoke exp,
                               BuilderContext<Statement> context) {
    List<tree.Expression> args = exp.arguments;
    int positionalArgumentCount = exp.selector.positionalArgumentCount;
    List<Argument> result = new List<Argument>.generate(positionalArgumentCount,
        (i) => visitExpression(exp.arguments[i], context));
    for (int i = 0; i < exp.selector.namedArgumentCount; ++i) {
      result.add(new NamedArgument(exp.selector.namedArguments[i],
          visitExpression(
              exp.arguments[positionalArgumentCount + i], context)));
    }
    return result;
  }

  @override
  Expression visitInvokeStatic(tree.InvokeStatic exp,
                               BuilderContext<Statement> context) {
    switch (exp.selector.kind) {
      case SelectorKind.GETTER:
        return new Identifier(exp.target.name)..element = exp.target;

      case SelectorKind.SETTER:
        return new Assignment(
            new Identifier(exp.target.name)..element = exp.target,
            '=',
            visitExpression(exp.arguments[0], context));

      case SelectorKind.CALL:
        return new CallStatic(
            null, exp.target.name, emitArguments(exp, context))
                   ..element = exp.target;

      default:
        throw "Unexpected selector kind: ${exp.selector.kind}";
    }
  }

  Expression emitMethodCall(tree.Invoke exp, Receiver receiver,
                            BuilderContext<Statement> context) {
    List<Argument> args = emitArguments(exp, context);
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

  @override
  Expression visitInvokeMethod(tree.InvokeMethod exp,
                               BuilderContext<Statement> context) {
    Expression receiver = visitExpression(exp.receiver, context);
    return emitMethodCall(exp, receiver, context);
  }

  @override
  Expression visitInvokeSuperMethod(tree.InvokeSuperMethod exp,
                                    BuilderContext<Statement> context) {
    return emitMethodCall(exp, new SuperReceiver(), context);
  }

  @override
  Expression visitInvokeConstructor(tree.InvokeConstructor exp,
                                    BuilderContext<Statement> context) {
    List args = emitArguments(exp, context);
    FunctionElement constructor = exp.target;
    String name = constructor.name.isEmpty ? null : constructor.name;
    return new CallNew(TypeGenerator.createType(exp.type),
                       args,
                       constructorName: name,
                       isConst: exp.constant != null)
               ..constructor = constructor
               ..dartType = exp.type;
  }

  @override
  Expression visitConcatenateStrings(tree.ConcatenateStrings exp,
                                     BuilderContext<Statement> context) {
    return new StringConcat(visitExpressions(exp.arguments, context));
  }

  @override
  Expression visitConditional(tree.Conditional exp,
                              BuilderContext<Statement> context) {
    return new Conditional(
        visitExpression(exp.condition, context),
        visitExpression(exp.thenExpression, context),
        visitExpression(exp.elseExpression, context));
  }

  @override
  Expression visitLogicalOperator(tree.LogicalOperator exp,
                                  BuilderContext<Statement> context) {
    return new BinaryOperator(visitExpression(exp.left, context),
                              exp.operator,
                              visitExpression(exp.right, context));
  }

  @override
  Expression visitNot(tree.Not exp,
                      BuilderContext<Statement> context) {
    return new UnaryOperator('!', visitExpression(exp.operand, context));
  }

  @override
  Expression visitVariable(tree.Variable exp,
                           BuilderContext<Statement> context) {
    return new Identifier(context.getVariableName(exp))
               ..element = exp.element;
  }

  FunctionExpression makeSubFunction(tree.FunctionDefinition function,
                                     BuilderContext<Statement> context) {
    return emit(function, new BuilderContext<Statement>.inner(context));
  }

  @override
  Expression visitFunctionExpression(tree.FunctionExpression exp,
                                     BuilderContext<Statement> context) {
    return makeSubFunction(exp.definition, context)..name = null;
  }

  @override
  void visitFunctionDeclaration(tree.FunctionDeclaration node,
                                BuilderContext<Statement> context) {
    assert(context.variableNames[node.variable] == null);
    String name = context.getVariableName(node.variable);
    FunctionExpression inner = makeSubFunction(node.definition, context);
    inner.name = name;
    FunctionDeclaration decl = new FunctionDeclaration(inner);
    context.declaredVariables.add(node.variable);
    context.addStatement(decl);
    visitStatement(node.next, context);
  }
}

class TypeGenerator {

  /// TODO(johnniwinther): Remove this when issue 21283 has been resolved.
  static int pseudoNameCounter = 0;

  static Parameter emitParameter(DartType type,
                                 BuilderContext<Statement> context,
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
      TypeAnnotation returnType = createOptionalType(functionType.returnType);
      Parameters innerParameters =
          createParametersFromType(functionType);
      parameter = new Parameter.function(name, returnType, innerParameters);
    } else {
      TypeAnnotation typeAnnotation = createOptionalType(type);
      parameter = new Parameter(name, type: typeAnnotation);
    }
    parameter.element = element;
    if (defaultValue != null && !defaultValue.value.isNull) {
      parameter.defaultValue =
          ConstantEmitter.createExpression(defaultValue, context);
    }
    return parameter;
  }

  static Parameters createParametersFromType(FunctionType functionType) {
    pseudoNameCounter = 0;
    if (functionType.namedParameters.isEmpty) {
      return new Parameters(
          createParameters(functionType.parameterTypes),
          createParameters(functionType.optionalParameterTypes),
          false);
    } else {
      return new Parameters(
          createParameters(functionType.parameterTypes),
          createParameters(functionType.namedParameterTypes,
                         names: functionType.namedParameters),
          true);
    }
  }

  static List<Parameter> createParameters(
      Iterable<DartType> parameterTypes,
      {BuilderContext<Statement> context,
       Iterable<String> names: const <String>[],
       Iterable<ConstantExpression> defaultValues: const <ConstantExpression>[],
       Iterable<Element> elements: const <Element>[]}) {
    Iterator<String> name = names.iterator;
    Iterator<ConstantExpression> defaultValue = defaultValues.iterator;
    Iterator<Element> element = elements.iterator;
    return parameterTypes.map((DartType type) {
      name.moveNext();
      defaultValue.moveNext();
      element.moveNext();
      return emitParameter(type, context,
                           name: name.current,
                           defaultValue: defaultValue.current,
                           element: element.current);
    }).toList();
  }

  /// Like [createTypeAnnotation] except the dynamic type is converted to null.
  static TypeAnnotation createOptionalType(DartType type) {
    if (type.treatAsDynamic) {
      return null;
    } else {
      return createType(type);
    }
  }

  /// Creates the [TypeAnnotation] for a [type] that is not function type.
  static TypeAnnotation createType(DartType type) {
    if (type is GenericType) {
      if (type.treatAsRaw) {
        return new TypeAnnotation(type.element.name)..dartType = type;
      }
      return new TypeAnnotation(
          type.element.name,
          type.typeArguments.map(createType).toList(growable:false))
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

}


class ConstantEmitter
    extends ConstantExpressionVisitor<BuilderContext<Statement>, Expression> {
  const ConstantEmitter();

  /// Creates the [Expression] for the constant [exp].
  static Expression createExpression(ConstantExpression exp,
                                     BuilderContext<Statement> context) {
    return const ConstantEmitter().visit(exp, context);
  }

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

  List<Expression> visitExpressions(List<ConstantExpression> expressions,
                                    BuilderContext<Statement> context) {
    return expressions.map((expression) => visit(expression, context))
        .toList(growable: false);
  }

  @override
  Expression visitPrimitive(PrimitiveConstantExpression exp,
                            BuilderContext<Statement> context) {
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
  Expression visitList(ListConstantExpression exp,
                       BuilderContext<Statement> context) {
    return new LiteralList(
        visitExpressions(exp.values, context),
        isConst: true,
        typeArgument:
            TypeGenerator.createOptionalType(exp.type.typeArguments.single));
  }

  @override
  Expression visitMap(MapConstantExpression exp,
                      BuilderContext<Statement> context) {
    List<LiteralMapEntry> entries = new List<LiteralMapEntry>.generate(
        exp.values.length,
        (i) => new LiteralMapEntry(visit(exp.keys[i], context),
                                   visit(exp.values[i], context)));
    List<TypeAnnotation> typeArguments = exp.type.treatAsRaw
        ? null
        : exp.type.typeArguments.map(TypeGenerator.createType).toList();
    return new LiteralMap(entries, isConst: true, typeArguments: typeArguments);
  }

  @override
  Expression visitConstructed(ConstructedConstantExpresssion exp,
                              BuilderContext<Statement> context) {
    int positionalArgumentCount = exp.selector.positionalArgumentCount;
    List<Argument> args = new List<Argument>.generate(
        positionalArgumentCount,
        (i) => visit(exp.arguments[i], context));
    for (int i = 0; i < exp.selector.namedArgumentCount; ++i) {
      args.add(new NamedArgument(exp.selector.namedArguments[i],
          visit(exp.arguments[positionalArgumentCount + i], context)));
    }

    FunctionElement constructor = exp.target;
    String name = constructor.name.isEmpty ? null : constructor.name;
    return new CallNew(TypeGenerator.createType(exp.type),
                       args,
                       constructorName: name,
                       isConst: true)
               ..constructor = constructor
               ..dartType = exp.type;
  }

  @override
  Expression visitConcatenate(ConcatenateConstantExpression exp,
                              BuilderContext<Statement> context) {

    return new StringConcat(visitExpressions(exp.arguments, context));
  }

  @override
  Expression visitSymbol(SymbolConstantExpression exp,
                         BuilderContext<Statement> context) {
    return new LiteralSymbol(exp.name);
  }

  @override
  Expression visitType(TypeConstantExpression exp,
                       BuilderContext<Statement> context) {
    DartType type = exp.type;
    return new LiteralType(type.name)
               ..type = type;
  }

  @override
  Expression visitVariable(VariableConstantExpression exp,
                           BuilderContext<Statement> context) {
    Element element = exp.element;
    if (element.kind != ElementKind.VARIABLE) {
      return new Identifier(element.name)..element = element;
    }
    String name = context.getConstantName(element);
    return new Identifier(name)
               ..element = element;
  }

  @override
  Expression visitFunction(FunctionConstantExpression exp,
                           BuilderContext<Statement> context) {
    return new Identifier(exp.element.name)
               ..element = exp.element;
  }

  @override
  Expression visitBinary(BinaryConstantExpression exp,
                         BuilderContext<Statement> context) {
    return handlePrimitiveConstant(exp.value);
  }

  @override
  Expression visitConditional(ConditionalConstantExpression exp,
                              BuilderContext<Statement> context) {
    if (exp.condition.value.isTrue) {
      return exp.trueExp.accept(this);
    } else {
      return exp.falseExp.accept(this);
    }
  }

  @override
  Expression visitUnary(UnaryConstantExpression exp,
                        BuilderContext<Statement> context) {
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

  void unshadow(tree.ExecutableDefinition definition) {
    // Fields have no parameters.
    if (definition is tree.FieldDefinition) return;
    visitFunctionDefinition(definition);
  }

  visitFunctionDefinition(tree.FunctionDefinition definition) {
    if (definition.isAbstract) return;
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
        tree.Variable newParam = new tree.Variable(definition.element,
            param.element);
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

// TODO(johnniwinther): Remove this when the dart `backend_ast` does not need
// [Element] for entities.
class _SyntheticLocalVariableElement extends modelx.VariableElementX
    implements LocalVariableElement {

  _SyntheticLocalVariableElement(String name,
                                 ExecutableElement enclosingElement,
                                 modelx.VariableList variables)
      : super(name, ElementKind.VARIABLE, enclosingElement, variables, null);

  ExecutableElement get executableContext => enclosingElement;

  ExecutableElement get memberContext => executableContext.memberContext;

  bool get isLocal => true;

  LibraryElement get implementationLibrary => enclosingElement.library;
}
