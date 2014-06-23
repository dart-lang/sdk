// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_codegen;

import 'dart_tree.dart' as tree;
import 'dart_printer.dart';
import 'dart_tree_printer.dart' show TreePrinter;
import '../tree/tree.dart' as frontend;
import '../dart2jslib.dart' as dart2js;
import '../elements/elements.dart';
import '../dart_types.dart';
import '../elements/modelx.dart' as modelx;
import '../universe/universe.dart';
import '../tree/tree.dart' as tree show Modifiers;

/// Translates the dart_tree IR to Dart frontend AST.
frontend.FunctionExpression emit(FunctionElement element,
                                 dart2js.TreeElementMapping treeElements,
                                 tree.FunctionDefinition definition) {
  FunctionExpression fn = new ASTEmitter().emit(element, definition);
  return new TreePrinter(treeElements).makeExpression(fn);
}

/// Translates the dart_tree IR to Dart backend AST.
class ASTEmitter extends tree.Visitor<dynamic, Expression> {
  /// Variables to be hoisted at the top of the current function.
  List<VariableDeclaration> variables;

  /// Maps variables to their name.
  /// These variables have had their declaration inserted in [variables].
  Map<tree.Variable, String> variableNames;

  /// Variable names that have already been used. Used to avoid name clashes.
  Set<String> usedVariableNames;

  /// Statements emitted by the most recent call to [visitStatement].
  List<Statement> statementBuffer;

  /// The function currently being emitted.
  FunctionElement functionElement;

  /// Bookkeeping object needed to synthesize a variable declaration.
  modelx.VariableList variableList;

  /// Input to [visitStatement]. Denotes the statement that will execute next
  /// if the statements produced by [visitStatement] complete normally.
  /// Set to null if control will fall over the end of the method.
  tree.Statement fallthrough;

  /// Labels that could not be eliminated using fallthrough.
  Set<tree.Label> usedLabels;

  FunctionExpression emit(FunctionElement element,
                          tree.FunctionDefinition definition) {
    functionElement = element;
    variables = <VariableDeclaration>[];
    statementBuffer = <Statement>[];
    variableNames = <tree.Variable, String>{};
    usedVariableNames = new Set<String>();
    variableList = new modelx.VariableList(tree.Modifiers.EMPTY);
    fallthrough = null;
    usedLabels = new Set<tree.Label>();

    Parameters parameters = emitParameters(definition.parameters);
    visitStatement(definition.body);
    removeTrailingReturn();
    Statement body = new Block(statementBuffer);
    if (variables.length > 0) {
      Statement head = new VariableDeclarations(variables);
      body = new Block([head, body]);
    }

    FunctionType functionType = element.type;

    variables = null;
    statementBuffer = null;
    functionElement = null;
    variableList = null;
    variableNames = null;
    usedVariableNames = null;
    usedLabels = null;

    return new FunctionExpression(
        parameters,
        body,
        name: element.name,
        returnType: emitOptionalType(functionType.returnType))
        ..element = element;
  }

  /// Removes a trailing "return null" from [statementBuffer].
  void removeTrailingReturn() {
    if (statementBuffer.isEmpty) return;
    if (statementBuffer.last is! Return) return;
    Return ret = statementBuffer.last;
    Expression expr = ret.expression;
    if (expr is Literal && expr.value is dart2js.NullConstant) {
      statementBuffer.removeLast();
    }
  }

  Parameter emitParameterFromElement(ParameterElement element, [String name]) {
    if (name == null) {
      name = element.name;
    }
    if (element.functionSignature != null) {
      FunctionSignature signature = element.functionSignature;
      TypeAnnotation returnType = emitOptionalType(signature.type.returnType);
      Parameters innerParameters = new Parameters(
          signature.requiredParameters.mapToList(emitParameterFromElement),
          signature.optionalParameters.mapToList(emitParameterFromElement),
          signature.optionalParametersAreNamed);
      return new Parameter.function(name, returnType, innerParameters)
                 ..element = element;
    } else {
      TypeAnnotation type = emitOptionalType(element.type);
      return new Parameter(name, type:type)
                 ..element = element;
    }
  }

  Parameter emitParameter(tree.Variable param) {
    return emitParameterFromElement(param.element, getVariableName(param));
  }

  Parameters emitParameters(List<tree.Variable> params) {
    return new Parameters(params.map(emitParameter).toList(growable:false));
  }

  /// True if the two expressions are a reference to the same variable.
  bool isSameVariable(Expression e1, Expression e2) {
    // TODO(asgerf): Using the annotated element isn't the best way to do this
    // since elements are supposed to go away from codegen when we discard the
    // old backend.
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
    String name = variableNames[variable];
    if (name != null) {
      return name;
    }
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
      variable.element = new modelx.VariableElementX(
          name,
          ElementKind.VARIABLE,
          functionElement,
          variableList,
          null);
    }
    if (variable.element is! ParameterElement) {
      variables.add(new VariableDeclaration(name)
                        ..element = variable.element);
    }
    return name;
  }

  void visitAssign(tree.Assign stmt) {
    String name = getVariableName(stmt.variable);
    statementBuffer.add(new ExpressionStatement(makeAssignment(
        visitVariable(stmt.variable),
        visitExpression(stmt.definition))));
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
    List<Expression> updates = stmt.updates.reversed
                                           .map(visitExpression)
                                           .toList(growable:false);

    List<Statement> savedBuffer = statementBuffer;
    tree.Statement savedFallthrough = fallthrough;
    statementBuffer = <Statement>[];
    fallthrough = stmt;

    visitStatement(stmt.body);
    Statement body = new Block(statementBuffer);
    Statement statement = new For(null, null, updates, body);
    if (usedLabels.remove(stmt.label.name)) {
      statement = new LabeledStatement(stmt.label.name, statement);
    }
    savedBuffer.add(statement);

    statementBuffer = savedBuffer;
    fallthrough = savedFallthrough;
  }

  void visitWhileCondition(tree.WhileCondition stmt) {
    Expression condition = visitExpression(stmt.condition);
    List<Expression> updates = stmt.updates.reversed
                                           .map(visitExpression)
                                           .toList(growable:false);

    List<Statement> savedBuffer = statementBuffer;
    tree.Statement savedFallthrough = fallthrough;
    statementBuffer = <Statement>[];
    fallthrough = stmt;

    visitStatement(stmt.body);
    Statement body = new Block(statementBuffer);
    Statement statement;
    if (updates.isEmpty) {
      // while(E) is the same as for(;E;), but the former is nicer
      statement = new While(condition, body);
    } else {
      statement = new For(null, condition, updates, body);
    }
    if (usedLabels.remove(stmt.label.name)) {
      statement = new LabeledStatement(stmt.label.name, statement);
    }
    savedBuffer.add(statement);

    statementBuffer = savedBuffer;
    fallthrough = savedFallthrough;

    visitStatement(stmt.next);
  }

  Expression visitConstant(tree.Constant exp) {
    return emitConstant(exp.value);
  }

  Expression visitLiteralList(tree.LiteralList exp) {
    return new LiteralList(
        exp.values.map(visitExpression).toList(growable: false),
        isConst: exp.constant != null,
        typeArgument: emitOptionalType(exp.type.typeArguments.single));
  }

  Expression visitLiteralMap(tree.LiteralMap exp) {
    List<LiteralMapEntry> entries = new List<LiteralMapEntry>.generate(
        exp.values.length,
        (i) => new LiteralMapEntry(visitExpression(exp.keys[i]),
                                   visitExpression(exp.values[i])));
    List<TypeAnnotation> typeArguments = exp.type.treatAsRaw
        ? null
        : exp.type.typeArguments.mapToList(emitType);
    return new LiteralMap(entries,
                          isConst: exp.constant != null,
                          typeArguments: typeArguments);
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

  Expression visitInvokeMethod(tree.InvokeMethod exp) {
    Expression receiver = visitExpression(exp.receiver);
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

  Expression visitInvokeConstructor(tree.InvokeConstructor exp) {
    List args = emitArguments(exp);
    FunctionElement constructor = exp.target;
    String name = constructor.name.isEmpty ? null : constructor.name;
    return new CallNew(emitType(exp.type),
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

  TypeAnnotation emitType(DartType type) {
    if (type is GenericType) { // TODO(asgerf): faster Link.map
      return new TypeAnnotation(
          type.element.name,
          type.typeArguments.mapToList(emitType, growable:false))
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
      // treat malformed types as dynamic
      return new TypeAnnotation("dynamic")
          ..dartType = const DynamicType();
    } else {
      throw "Unsupported type annotation: $type";
    }
  }

  /// Like [emitType] except the dynamic type is converted to null.
  TypeAnnotation emitOptionalType(DartType type) {
    if (type.treatAsDynamic) {
      return null;
    } else {
      return emitType(type);
    }
  }

  Expression emitConstant(dart2js.Constant constant) {
    if (constant is dart2js.PrimitiveConstant) {
      return new Literal(constant);
    } else if (constant is dart2js.ConstructedConstant &&
               constant.isLiteralSymbol) {
      dart2js.StringConstant nameConstant = constant.fields[0];
      String nameString = nameConstant.value.slowToString();
      return new LiteralSymbol(nameString);
    } else if (constant is dart2js.FunctionConstant) {
      return new Identifier(constant.element.name)
                 ..element = constant.element;
    } else if (constant is dart2js.TypeConstant) {
      GenericType type = constant.representedType;
      return new Identifier(type.name)
                 ..element = type.element;
    } else {
      throw "Unsupported constant: $constant";
    }
  }
}

