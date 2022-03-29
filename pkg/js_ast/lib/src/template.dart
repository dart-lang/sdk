// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.15

library js_ast.template;

import 'nodes.dart';

class TemplateManager {
  Map<String, Template> expressionTemplates = {};
  Map<String, Template> statementTemplates = {};

  TemplateManager();

  Template? lookupExpressionTemplate(String source) {
    return expressionTemplates[source];
  }

  Template defineExpressionTemplate(String source, Node ast) {
    Template template =
        Template(source, ast, isExpression: true, forceCopy: false);
    expressionTemplates[source] = template;
    return template;
  }

  Template? lookupStatementTemplate(String source) {
    return statementTemplates[source];
  }

  Template defineStatementTemplate(String source, Node ast) {
    Template template =
        Template(source, ast, isExpression: false, forceCopy: false);
    statementTemplates[source] = template;
    return template;
  }
}

/// A Template is created with JavaScript AST containing placeholders (interface
/// InterpolatedNode).
///
/// The [instantiate] method creates an AST that looks like the original with
/// the placeholders replaced by the arguments to [instantiate].
class Template {
  final String? source;
  final bool isExpression;
  final bool forceCopy;
  final Node ast;

  final Instantiator instantiator;

  final int positionalArgumentCount;

  // Names of named holes, empty if there are no named holes.
  final List<String> holeNames;

  bool get isPositional => holeNames.isEmpty;

  Template._(this.source, this.ast,
      {required this.instantiator,
      required this.isExpression,
      required this.forceCopy,
      required this.positionalArgumentCount,
      this.holeNames = const []});

  factory Template(String? source, Node ast,
      {bool isExpression = true, bool forceCopy = false}) {
    assert(isExpression ? ast is Expression : ast is Statement);

    final generator = InstantiatorGeneratorVisitor(forceCopy);
    final instantiator = generator.compile(ast);
    final positionalArgumentCount = generator.analysis.count;
    final names = generator.analysis.holeNames;
    final holeNames = names.toList(growable: false);

    return Template._(source, ast,
        instantiator: instantiator,
        isExpression: isExpression,
        forceCopy: forceCopy,
        positionalArgumentCount: positionalArgumentCount,
        holeNames: holeNames);
  }

  factory Template.withExpressionResult(Expression ast) {
    assert(_checkNoPlaceholders(ast));
    return Template._(null, ast,
        instantiator: (arguments) => ast,
        isExpression: true,
        forceCopy: false,
        positionalArgumentCount: 0);
  }

  factory Template.withStatementResult(Statement ast) {
    assert(_checkNoPlaceholders(ast));
    return Template._(null, ast,
        instantiator: (arguments) => ast,
        isExpression: false,
        forceCopy: false,
        positionalArgumentCount: 0);
  }

  static bool _checkNoPlaceholders(Node ast) {
    InstantiatorGeneratorVisitor generator =
        InstantiatorGeneratorVisitor(false);
    generator.compile(ast);
    return generator.analysis.count == 0;
  }

  /// Instantiates the template with the given [arguments].
  ///
  /// This method fills in the holes with the given arguments. The [arguments]
  /// must be either a [List] or a [Map].
  Node instantiate(Object arguments) {
    if (arguments is List) {
      if (arguments.length != positionalArgumentCount) {
        throw 'Wrong number of template arguments, given ${arguments.length}, '
            'expected $positionalArgumentCount'
            ', source: "$source"';
      }
      return instantiator(arguments);
    }
    if (arguments is Map) {
      if (holeNames.length < arguments.length) {
        // This search is in O(n), but we only do it in case of an error, and the
        // number of holes should be quite limited.
        String unusedNames = arguments.keys
            .where((name) => !holeNames.contains(name))
            .join(", ");
        throw "Template arguments has unused mappings: $unusedNames";
      }
      if (!holeNames.every((String name) => arguments.containsKey(name))) {
        String notFound =
            holeNames.where((name) => !arguments.containsKey(name)).join(", ");
        throw "Template arguments is missing mappings for: $notFound";
      }
      return instantiator(arguments);
    }
    throw ArgumentError.value(arguments, 'arguments', 'Must be a List or Map');
  }
}

/// An Instantiator is a Function that generates a JS AST tree or List of
/// trees.
///
/// [arguments] is a List for positional templates, or Map for named templates.
typedef Instantiator = /*Node|Iterable<Node>*/ Function(dynamic arguments);

/// InstantiatorGeneratorVisitor compiles a template.  This class compiles a
/// tree containing [InterpolatedNode]s into a function that will create a copy
/// of the tree with the interpolated nodes substituted with provided values.
class InstantiatorGeneratorVisitor implements NodeVisitor<Instantiator> {
  final bool forceCopy;

  InterpolatedNodeAnalysis analysis = InterpolatedNodeAnalysis();

  /// The entire tree is cloned if [forceCopy] is true.
  InstantiatorGeneratorVisitor(this.forceCopy);

  Instantiator compile(Node node) {
    analysis.visit(node);
    Instantiator result = visit(node);
    return result;
  }

  static Never error(String message) {
    throw message;
  }

  static Instantiator same(Node node) => (arguments) => node;
  static Null makeNull(arguments) => null;

  Instantiator visit(Node node) {
    if (forceCopy || analysis.containsInterpolatedNodes(node)) {
      return node.accept(this);
    }
    return same(node);
  }

  Instantiator visitNullable(Node? node) {
    if (node == null) return makeNull;
    return visit(node);
  }

  Instantiator visitSplayable(Node node) {
    // TODO(sra): Process immediate [InterpolatedNode]s, permitting splaying.
    return visit(node);
  }

  Instantiator visitNode(Node node) {
    throw 'Unimplemented InstantiatorGeneratorVisitor for $node';
  }

  static RegExp identifierRE = RegExp(r'^[A-Za-z_$][A-Za-z_$0-9]*$');

  static Expression convertStringToVariableUse(String value) {
    assert(identifierRE.hasMatch(value));
    return VariableUse(value);
  }

  static Expression convertStringToVariableDeclaration(String value) {
    assert(identifierRE.hasMatch(value));
    return VariableDeclaration(value);
  }

  @override
  Instantiator visitInterpolatedExpression(InterpolatedExpression node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Expression) return value;
      if (value is String) return convertStringToVariableUse(value);
      throw error(
          'Interpolated value #$nameOrPosition is not an Expression: $value');
    };
  }

  @override
  Instantiator visitInterpolatedDeclaration(InterpolatedDeclaration node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Declaration) return value;
      if (value is String) return convertStringToVariableDeclaration(value);
      throw error(
          'Interpolated value #$nameOrPosition is not a declaration: $value');
    };
  }

  Instantiator visitSplayableExpression(Node node) {
    if (node is InterpolatedExpression) {
      var nameOrPosition = node.nameOrPosition;
      return (arguments) {
        var value = arguments[nameOrPosition];
        Expression toExpression(item) {
          if (item is Expression) return item;
          if (item is String) return convertStringToVariableUse(item);
          throw error('Interpolated value #$nameOrPosition is not '
              'an Expression or List of Expressions: $value');
        }

        if (value is Iterable) return value.map(toExpression);
        return toExpression(value);
      };
    }
    return visit(node);
  }

  @override
  Instantiator visitInterpolatedLiteral(InterpolatedLiteral node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Literal || value is DeferredExpression) return value;
      error('Interpolated value #$nameOrPosition is not a Literal: $value');
    };
  }

  @override
  Instantiator visitInterpolatedParameter(InterpolatedParameter node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];

      Parameter toParameter(item) {
        if (item is Parameter) return item;
        if (item is String) return Parameter(item);
        throw error('Interpolated value #$nameOrPosition is not a Parameter or'
            ' List of Parameters: $value');
      }

      if (value is Iterable) return value.map(toParameter);
      return toParameter(value);
    };
  }

  @override
  Instantiator visitInterpolatedSelector(InterpolatedSelector node) {
    // A selector is an expression, as in `a[selector]`.
    // A String argument converted into a LiteralString, so `a.#` with argument
    // 'foo' generates `a["foo"]` which prints as `a.foo`.
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Expression) return value;
      if (value is String) return LiteralString(value);
      throw error(
          'Interpolated value #$nameOrPosition is not a selector: $value');
    };
  }

  @override
  Instantiator visitInterpolatedStatement(InterpolatedStatement node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Node) return value.toStatement();
      throw error(
          'Interpolated value #$nameOrPosition is not a Statement: $value');
    };
  }

  Instantiator visitSplayableStatement(Node node) {
    if (node is InterpolatedStatement) {
      var nameOrPosition = node.nameOrPosition;
      return (arguments) {
        var value = arguments[nameOrPosition];
        Statement toStatement(item) {
          if (item is Statement) return item;
          if (item is Expression) return item.toStatement();
          throw error('Interpolated value #$nameOrPosition is not '
              'a Statement or List of Statements: $value');
        }

        if (value is Iterable) return value.map(toStatement);
        return toStatement(value);
      };
    }
    return visit(node);
  }

  @override
  Instantiator visitProgram(Program node) {
    List<Instantiator> instantiators =
        node.body.map(visitSplayableStatement).toList();
    return (arguments) {
      return Program(splayStatements(instantiators, arguments));
    };
  }

  List<Statement> splayStatements(List<Instantiator> instantiators, arguments) {
    var statements = <Statement>[];
    for (var instantiator in instantiators) {
      final node = instantiator(arguments);
      if (node is EmptyStatement) continue;
      if (node is Iterable) {
        statements.addAll(node as Iterable<Statement>);
      } else if (node is Block /*&& !node.isScope*/) {
        statements.addAll(node.statements);
      } else if (node is Statement) {
        statements.add(node);
      } else {
        error('Not splayable as statement: $node');
      }
    }
    return statements;
  }

  @override
  Instantiator visitBlock(Block node) {
    List<Instantiator> instantiators =
        node.statements.map(visitSplayableStatement).toList();
    return (arguments) {
      return Block(splayStatements(instantiators, arguments));
    };
  }

  @override
  Instantiator visitExpressionStatement(ExpressionStatement node) {
    Instantiator buildExpression = visit(node.expression);
    return (arguments) {
      return buildExpression(arguments).toStatement();
    };
  }

  @override
  Instantiator visitEmptyStatement(EmptyStatement node) =>
      (arguments) => EmptyStatement();

  @override
  Instantiator visitIf(If node) {
    final condition = node.condition;
    if (condition is InterpolatedExpression) {
      return visitIfConditionalCompilation(node, condition);
    } else {
      return visitIfNormal(node);
    }
  }

  Instantiator visitIfConditionalCompilation(
      If node, InterpolatedExpression condition) {
    final nameOrPosition = condition.nameOrPosition;
    Instantiator makeThen = visit(node.then);
    Instantiator makeOtherwise = visit(node.otherwise);
    return (arguments) {
      // Allow booleans to be used for conditional compilation.
      var value = arguments[nameOrPosition];
      if (value is bool) {
        return value ? makeThen(arguments) : makeOtherwise(arguments);
      }
      Expression newCondition;
      if (value is Expression) {
        newCondition = value;
      } else if (value is String) {
        newCondition = convertStringToVariableUse(value);
      } else {
        error('Interpolated value #$nameOrPosition '
            'is not an Expression: $value');
      }
      return If(newCondition, makeThen(arguments), makeOtherwise(arguments));
    };
  }

  Instantiator visitIfNormal(If node) {
    Instantiator makeCondition = visit(node.condition);
    Instantiator makeThen = visit(node.then);
    Instantiator makeOtherwise = visit(node.otherwise);
    return (arguments) {
      return If(makeCondition(arguments), makeThen(arguments),
          makeOtherwise(arguments));
    };
  }

  @override
  Instantiator visitFor(For node) {
    Instantiator makeInit = visitNullable(node.init);
    Instantiator makeCondition = visitNullable(node.condition);
    Instantiator makeUpdate = visitNullable(node.update);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return For(makeInit(arguments), makeCondition(arguments),
          makeUpdate(arguments), makeBody(arguments));
    };
  }

  @override
  Instantiator visitForIn(ForIn node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    Instantiator makeObject = visit(node.object);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return ForIn(makeLeftHandSide(arguments), makeObject(arguments),
          makeBody(arguments));
    };
  }

  TODO(String name) {
    throw UnimplementedError('$this.$name');
  }

  @override
  Instantiator visitWhile(While node) {
    Instantiator makeCondition = visit(node.condition);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return While(makeCondition(arguments), makeBody(arguments));
    };
  }

  @override
  Instantiator visitDo(Do node) {
    Instantiator makeBody = visit(node.body);
    Instantiator makeCondition = visit(node.condition);
    return (arguments) {
      return Do(makeBody(arguments), makeCondition(arguments));
    };
  }

  @override
  Instantiator visitContinue(Continue node) =>
      (arguments) => Continue(node.targetLabel);

  @override
  Instantiator visitBreak(Break node) => (arguments) => Break(node.targetLabel);

  @override
  Instantiator visitReturn(Return node) {
    Instantiator makeExpression = visitNullable(node.value);
    return (arguments) => Return(makeExpression(arguments));
  }

  @override
  Instantiator visitDartYield(DartYield node) {
    Instantiator makeExpression = visit(node.expression);
    return (arguments) => DartYield(makeExpression(arguments), node.hasStar);
  }

  @override
  Instantiator visitThrow(Throw node) {
    Instantiator makeExpression = visit(node.expression);
    return (arguments) => Throw(makeExpression(arguments));
  }

  @override
  Instantiator visitTry(Try node) {
    Instantiator makeBody = visit(node.body);
    Instantiator makeCatch = visitNullable(node.catchPart);
    Instantiator makeFinally = visitNullable(node.finallyPart);
    return (arguments) =>
        Try(makeBody(arguments), makeCatch(arguments), makeFinally(arguments));
  }

  @override
  Instantiator visitCatch(Catch node) {
    Instantiator makeDeclaration = visit(node.declaration);
    Instantiator makeBody = visit(node.body);
    return (arguments) =>
        Catch(makeDeclaration(arguments), makeBody(arguments));
  }

  @override
  Instantiator visitSwitch(Switch node) {
    Instantiator makeKey = visit(node.key);
    Iterable<Instantiator> makeCases = node.cases.map(visit);
    return (arguments) {
      return Switch(
          makeKey(arguments),
          makeCases
              .map<SwitchClause>((Instantiator makeCase) => makeCase(arguments))
              .toList());
    };
  }

  @override
  Instantiator visitCase(Case node) {
    Instantiator makeExpression = visit(node.expression);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return Case(makeExpression(arguments), makeBody(arguments));
    };
  }

  @override
  Instantiator visitDefault(Default node) {
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return Default(makeBody(arguments));
    };
  }

  @override
  Instantiator visitFunctionDeclaration(FunctionDeclaration node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeFunction = visit(node.function);
    return (arguments) =>
        FunctionDeclaration(makeName(arguments), makeFunction(arguments));
  }

  @override
  Instantiator visitLabeledStatement(LabeledStatement node) {
    Instantiator makeBody = visit(node.body);
    return (arguments) => LabeledStatement(node.label, makeBody(arguments));
  }

  @override
  Instantiator visitLiteralStatement(LiteralStatement node) =>
      TODO('visitLiteralStatement');
  @override
  Instantiator visitLiteralExpression(LiteralExpression node) =>
      TODO('visitLiteralExpression');

  @override
  Instantiator visitVariableDeclarationList(VariableDeclarationList node) {
    List<Instantiator> declarationMakers =
        node.declarations.map(visit).toList();
    return (arguments) {
      List<VariableInitialization> declarations = [];
      for (Instantiator instantiator in declarationMakers) {
        var result = instantiator(arguments);
        declarations.add(result);
      }
      return VariableDeclarationList(declarations);
    };
  }

  @override
  Instantiator visitAssignment(Assignment node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    String? op = node.op;
    Instantiator makeValue = visit(node.value);
    return (arguments) {
      return Assignment.compound(
          makeLeftHandSide(arguments), op, makeValue(arguments));
    };
  }

  @override
  Instantiator visitVariableInitialization(VariableInitialization node) {
    Instantiator makeDeclaration = visit(node.declaration);
    Instantiator makeValue = visitNullable(node.value);
    return (arguments) {
      return VariableInitialization(
          makeDeclaration(arguments), makeValue(arguments));
    };
  }

  @override
  Instantiator visitConditional(Conditional cond) {
    Instantiator makeCondition = visit(cond.condition);
    Instantiator makeThen = visit(cond.then);
    Instantiator makeOtherwise = visit(cond.otherwise);
    return (arguments) => Conditional(makeCondition(arguments),
        makeThen(arguments), makeOtherwise(arguments));
  }

  @override
  Instantiator visitNew(New node) =>
      handleCallOrNew(node, (target, arguments) => New(target, arguments));

  @override
  Instantiator visitCall(Call node) =>
      handleCallOrNew(node, (target, arguments) => Call(target, arguments));

  Instantiator handleCallOrNew(Call node, finish(target, arguments)) {
    Instantiator makeTarget = visit(node.target);
    Iterable<Instantiator> argumentMakers =
        node.arguments.map(visitSplayableExpression).toList();

    // TODO(sra): Avoid copying call arguments if no interpolation or forced
    // copying.
    return (arguments) {
      Node target = makeTarget(arguments);
      List<Expression> callArguments = splay(argumentMakers, arguments);
      return finish(target, callArguments.toList(growable: false));
    };
  }

  @override
  Instantiator visitBinary(Binary node) {
    Instantiator makeLeft = visit(node.left);
    Instantiator makeRight = visit(node.right);
    String op = node.op;
    return (arguments) => Binary(op, makeLeft(arguments), makeRight(arguments));
  }

  @override
  Instantiator visitPrefix(Prefix node) {
    Instantiator makeOperand = visit(node.argument);
    String op = node.op;
    return (arguments) => Prefix(op, makeOperand(arguments));
  }

  @override
  Instantiator visitPostfix(Postfix node) {
    Instantiator makeOperand = visit(node.argument);
    String op = node.op;
    return (arguments) => Postfix(op, makeOperand(arguments));
  }

  @override
  Instantiator visitVariableUse(VariableUse node) =>
      (arguments) => VariableUse(node.name);

  @override
  Instantiator visitThis(This node) => (arguments) => This();

  @override
  Instantiator visitVariableDeclaration(VariableDeclaration node) =>
      (arguments) => VariableDeclaration(node.name);

  @override
  Instantiator visitParameter(Parameter node) =>
      (arguments) => Parameter(node.name);

  @override
  Instantiator visitAccess(PropertyAccess node) {
    Instantiator makeReceiver = visit(node.receiver);
    Instantiator makeSelector = visit(node.selector);
    return (arguments) =>
        PropertyAccess(makeReceiver(arguments), makeSelector(arguments));
  }

  @override
  Instantiator visitNamedFunction(NamedFunction node) {
    Instantiator makeDeclaration = visit(node.name);
    Instantiator makeFunction = visit(node.function);
    return (arguments) =>
        NamedFunction(makeDeclaration(arguments), makeFunction(arguments));
  }

  @override
  Instantiator visitFun(Fun node) {
    List<Instantiator> paramMakers = node.params.map(visitSplayable).toList();
    Instantiator makeBody = visit(node.body);
    // TODO(sra): Avoid copying params if no interpolation or forced copying.
    return (arguments) {
      List<Parameter> params = splayParameters(paramMakers, arguments);
      Block body = makeBody(arguments);
      return Fun(params, body);
    };
  }

  @override
  Instantiator visitArrowFunction(ArrowFunction node) {
    List<Instantiator> paramMakers = node.params.map(visitSplayable).toList();
    Instantiator makeBody = visit(node.body);
    // TODO(sra): Avoid copying params if no interpolation or forced copying.
    return (arguments) {
      List<Parameter> params = splayParameters(paramMakers, arguments);
      // Either a Block or Expression.
      Node body = makeBody(arguments);
      return ArrowFunction(params, body);
    };
  }

  List<Parameter> splayParameters(List<Instantiator> instantiators, arguments) {
    // TODO(sra): This will be different when parameters include destructuring
    // and default values.
    return splay<Parameter>(instantiators, arguments);
  }

  List<T> splay<T>(Iterable<Instantiator> instantiators, arguments) {
    List<T> results = [];
    for (Instantiator instantiator in instantiators) {
      var result = instantiator(arguments);
      if (result is Iterable) {
        for (final item in result) {
          results.add(item as T);
        }
      } else {
        results.add(result as T);
      }
    }
    return results;
  }

  @override
  Instantiator visitDeferredExpression(DeferredExpression node) => same(node);

  @override
  Instantiator visitDeferredStatement(DeferredStatement node) => same(node);

  @override
  Instantiator visitDeferredNumber(DeferredNumber node) => same(node);

  @override
  Instantiator visitDeferredString(DeferredString node) => (arguments) => node;

  @override
  Instantiator visitLiteralBool(LiteralBool node) =>
      (arguments) => LiteralBool(node.value);

  @override
  Instantiator visitLiteralString(LiteralString node) =>
      (arguments) => LiteralString(node.value);

  @override
  Instantiator visitLiteralNumber(LiteralNumber node) =>
      (arguments) => LiteralNumber(node.value);

  @override
  Instantiator visitLiteralNull(LiteralNull node) =>
      (arguments) => LiteralNull();

  @override
  Instantiator visitStringConcatenation(StringConcatenation node) {
    List<Instantiator> partMakers =
        node.parts.map(visit).toList(growable: false);
    return (arguments) {
      List<Literal> parts = [
        for (final instantiator in partMakers)
          instantiator(arguments) as Literal
      ];
      return StringConcatenation(parts);
    };
  }

  @override
  Instantiator visitName(Name node) => same(node);

  @override
  Instantiator visitParentheses(Parentheses node) {
    Instantiator makeEnclosed = visit(node.enclosed);
    return (arguments) {
      Expression enclosed = makeEnclosed(arguments);
      return Parentheses(enclosed);
    };
  }

  @override
  Instantiator visitArrayInitializer(ArrayInitializer node) {
    // TODO(sra): Implement splicing?
    List<Instantiator> elementMakers =
        node.elements.map(visit).toList(growable: false);
    return (arguments) {
      List<Expression> elements = elementMakers
          .map<Expression>(
              (Instantiator instantiator) => instantiator(arguments))
          .toList(growable: false);
      return ArrayInitializer(elements);
    };
  }

  @override
  Instantiator visitArrayHole(ArrayHole node) {
    return (arguments) => ArrayHole();
  }

  @override
  Instantiator visitObjectInitializer(ObjectInitializer node) {
    List<Instantiator> propertyMakers =
        node.properties.map(visitSplayable).toList();
    bool isOneLiner = node.isOneLiner;
    return (arguments) {
      List<Property> properties = splay(propertyMakers, arguments);
      return ObjectInitializer(properties, isOneLiner: isOneLiner);
    };
  }

  @override
  Instantiator visitProperty(Property node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeValue = visit(node.value);
    return (arguments) {
      return Property(makeName(arguments), makeValue(arguments));
    };
  }

  @override
  Instantiator visitMethodDefinition(MethodDefinition node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeFunction = visit(node.function);
    return (arguments) {
      return MethodDefinition(makeName(arguments), makeFunction(arguments));
    };
  }

  @override
  Instantiator visitRegExpLiteral(RegExpLiteral node) =>
      (arguments) => RegExpLiteral(node.pattern);

  @override
  Instantiator visitComment(Comment node) => TODO('visitComment');

  @override
  Instantiator visitAwait(Await node) {
    Instantiator makeExpression = visit(node.expression);
    return (arguments) {
      return Await(makeExpression(arguments));
    };
  }
}

/// InterpolatedNodeAnalysis determines which AST trees contain
/// [InterpolatedNode]s, and the names of the named interpolated nodes.
class InterpolatedNodeAnalysis extends BaseVisitorVoid {
  final Set<Node> containsInterpolatedNode = {};
  final Set<String> holeNames = {};
  int count = 0;

  InterpolatedNodeAnalysis();

  bool containsInterpolatedNodes(Node node) =>
      containsInterpolatedNode.contains(node);

  void visit(Node node) {
    node.accept(this);
  }

  @override
  void visitNode(Node node) {
    int before = count;
    node.visitChildren(this);
    if (count != before) containsInterpolatedNode.add(node);
  }

  @override
  visitInterpolatedNode(InterpolatedNode node) {
    containsInterpolatedNode.add(node);
    if (node.isNamed) holeNames.add(node.nameOrPosition);
    ++count;
  }
}
