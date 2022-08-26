// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: omit_local_variable_types

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
    var generator = InstantiatorGeneratorVisitor(false);
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
      return instantiator(arguments) as Node;
    }
    if (arguments is Map) {
      if (holeNames.length < arguments.length) {
        // This search is in O(n), but we only do it in case of an error, and
        // the number of holes should be quite limited.
        String unusedNames = arguments.keys
            .where((name) => !holeNames.contains(name))
            .join(', ');
        throw 'Template arguments has unused mappings: $unusedNames';
      }
      if (!holeNames.every((String name) => arguments.containsKey(name))) {
        String notFound =
            holeNames.where((name) => !arguments.containsKey(name)).join(', ');
        throw 'Template arguments is missing mappings for: $notFound';
      }
      return instantiator(arguments) as Node;
    }
    throw ArgumentError.value(arguments, 'arguments', 'Must be a List or Map');
  }
}

/// An Instantiator is a Function that generates a JS AST tree or List of
/// trees.
///
/// [arguments] is a List for positional templates, or Map for named templates.
typedef Instantiator<T> = T Function(dynamic);

/// InstantiatorGeneratorVisitor compiles a template.  This class compiles a
/// tree containing [InterpolatedNode]s into a function that will create a copy
/// of the tree with the interpolated nodes substituted with provided values.
class InstantiatorGeneratorVisitor implements NodeVisitor<Instantiator> {
  final bool forceCopy;

  final analysis = InterpolatedNodeAnalysis();

  /// The entire tree is cloned if [forceCopy] is true.
  InstantiatorGeneratorVisitor(this.forceCopy);

  Instantiator compile(Node node) {
    analysis.visit(node);
    return visit(node);
  }

  static Instantiator<T> same<T extends Node>(T node) => (arguments) => node;
  static Null makeNull(arguments) => null;

  Instantiator visit<T extends Node>(T node) {
    if (forceCopy || analysis.containsInterpolatedNodes(node)) {
      return node.accept(this);
    }
    return same<T>(node);
  }

  Instantiator visitNullable<T extends Node>(T? node) {
    return node == null ? makeNull : visit(node);
  }

  Instantiator visitSplayable(Node node) {
    // TODO(jmesserly): parameters and methods always support splaying because
    // they appear in lists. So this method is equivalent to
    // `visitSplayableExpression`.
    return visitSplayableExpression(node);
  }

  Instantiator visitNode(Node node) {
    throw UnimplementedError('visit${node.runtimeType}');
  }

  @override
  Instantiator<Expression> visitInterpolatedExpression(
      InterpolatedExpression node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Expression) return value;
      if (value is String) return Identifier(value);
      throw StateError(
          'Interpolated value #$nameOrPosition is not an Expression: $value');
    };
  }

  Instantiator visitSplayableExpression(Node node) {
    if (node is InterpolatedExpression) {
      var nameOrPosition = node.nameOrPosition;
      return (arguments) {
        var value = arguments[nameOrPosition];
        Expression toExpression(item) {
          if (item is Expression) return item;
          if (item is String) return Identifier(item);
          throw StateError('Interpolated value #$nameOrPosition is not '
              'an Expression or List of Expressions: $value');
        }

        if (value is Iterable) return value.map(toExpression);
        return toExpression(value);
      };
    }
    return visit(node);
  }

  List<T> splayNodes<T extends Node>(List<Instantiator> makers, args) {
    var exprs = <T>[];
    for (var instantiator in makers) {
      var result = instantiator(args);
      if (result is Iterable) {
        for (var e in result) {
          exprs.add(e as T);
        }
      } else {
        exprs.add(result as T);
      }
    }
    return exprs;
  }

  @override
  Instantiator<Literal> visitInterpolatedLiteral(InterpolatedLiteral node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Literal) return value;
      throw StateError(
          'Interpolated value #$nameOrPosition is not a Literal: $value');
    };
  }

  @override
  Instantiator visitInterpolatedParameter(InterpolatedParameter node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];

      Parameter toIdentifier(item) {
        if (item is Parameter) return item;
        if (item is String) return Identifier(item);
        throw StateError(
            'Interpolated value #$nameOrPosition is not an Identifier'
            ' or List of Identifiers: $value');
      }

      if (value is Iterable) return value.map(toIdentifier);
      return toIdentifier(value);
    };
  }

  @override
  Instantiator<Expression> visitInterpolatedSelector(
      InterpolatedSelector node) {
    // A selector is an expression, as in `a[selector]`.
    // A String argument converted into a LiteralString, so `a.#` with argument
    // 'foo' generates `a["foo"]` which prints as `a.foo`.
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Expression) return value;
      if (value is String) return LiteralString('"$value"');
      throw StateError(
          'Interpolated value #$nameOrPosition is not a selector: $value');
    };
  }

  @override
  Instantiator<Statement> visitInterpolatedStatement(
      InterpolatedStatement node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Node) return value.toStatement();
      throw StateError(
          'Interpolated value #$nameOrPosition is not a Statement: $value');
    };
  }

  @override
  Instantiator visitInterpolatedMethod(InterpolatedMethod node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      Method toMethod(item) {
        if (item is Method) return item;
        throw StateError('Interpolated value #$nameOrPosition is not a Method '
            'or List of Methods: $value');
      }

      if (value is Iterable) return value.map(toMethod);
      return toMethod(value);
    };
  }

  @override
  Instantiator<Identifier> visitInterpolatedIdentifier(
      InterpolatedIdentifier node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var item = arguments[nameOrPosition];
      if (item is Identifier) return item;
      if (item is String) return Identifier(item);
      throw StateError('Interpolated value #$nameOrPosition is not a '
          'Identifier or String: $item');
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
          throw StateError('Interpolated value #$nameOrPosition is not '
              'a Statement or List of Statements: $value');
        }

        if (value is Iterable) return value.map(toStatement);
        return toStatement(value);
      };
    }
    return visit(node);
  }

  @override
  Instantiator<Program> visitProgram(Program node) {
    var instantiators = node.body.map(visitSplayableStatement).toList();
    return (arguments) => Program(splayStatements(instantiators, arguments));
  }

  List<Statement> splayStatements(List<Instantiator> instantiators, arguments) {
    var statements = <Statement>[];
    for (var instantiator in instantiators) {
      var node = instantiator(arguments);
      if (node is EmptyStatement) continue;
      if (node is Iterable) {
        statements.addAll(node as Iterable<Statement>);
      } else if (node is Block && !node.isScope) {
        statements.addAll(node.statements);
      } else {
        statements.add((node as Node).toStatement());
      }
    }
    return statements;
  }

  @override
  Instantiator<Block> visitBlock(Block node) {
    var instantiators = node.statements.map(visitSplayableStatement).toList();
    return (arguments) => Block(splayStatements(instantiators, arguments));
  }

  @override
  Instantiator<Statement> visitExpressionStatement(ExpressionStatement node) {
    var makeExpression = visit(node.expression) as Instantiator<Expression>;
    return (arguments) => makeExpression(arguments).toStatement();
  }

  @override
  Instantiator<DebuggerStatement> visitDebuggerStatement(node) =>
      (arguments) => DebuggerStatement();

  @override
  Instantiator<EmptyStatement> visitEmptyStatement(EmptyStatement node) =>
      (arguments) => EmptyStatement();

  @override
  Instantiator<Statement> visitIf(If node) {
    final condition = node.condition;
    if (condition is InterpolatedExpression) {
      return visitIfConditionalCompilation(node, condition);
    } else {
      return visitIfNormal(node);
    }
  }

  Instantiator<Statement> visitIfConditionalCompilation(
      If node, InterpolatedExpression condition) {
    var makeThen = visit(node.then) as Instantiator<Statement>;
    var makeOtherwise = visit(node.otherwise) as Instantiator<Statement>;
    return (arguments) {
      // Allow booleans to be used for conditional compilation.
      var nameOrPosition = condition.nameOrPosition;
      var value = arguments[nameOrPosition];
      if (value is bool) {
        return value ? makeThen(arguments) : makeOtherwise(arguments);
      }
      var newCondition =
          value is String ? Identifier(value) : value as Expression;
      return If(newCondition, makeThen(arguments), makeOtherwise(arguments));
    };
  }

  Instantiator<Statement> visitIfNormal(If node) {
    var makeCondition = visit(node.condition) as Instantiator<Expression>;
    var makeThen = visit(node.then) as Instantiator<Statement>;
    var makeOtherwise = visit(node.otherwise) as Instantiator<Statement>;
    return (arguments) => If(makeCondition(arguments), makeThen(arguments),
        makeOtherwise(arguments));
  }

  @override
  Instantiator<Statement> visitFor(For node) {
    var makeInit = visitNullable(node.init) as Instantiator<Expression>;
    var makeCondition =
        visitNullable(node.condition) as Instantiator<Expression>;
    var makeUpdate = visitNullable(node.update) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (arguments) => For(makeInit(arguments), makeCondition(arguments),
        makeUpdate(arguments).toVoidExpression(), makeBody(arguments));
  }

  @override
  Instantiator<ForIn> visitForIn(ForIn node) {
    var makeLeftHandSide = visit(node.leftHandSide) as Instantiator<Expression>;
    var makeObject = visit(node.object) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (arguments) => ForIn(makeLeftHandSide(arguments),
        makeObject(arguments), makeBody(arguments));
  }

  @override
  Instantiator<ForOf> visitForOf(ForOf node) {
    var makeLeftHandSide = visit(node.leftHandSide) as Instantiator<Expression>;
    var makeObject = visit(node.iterable) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (arguments) => ForOf(makeLeftHandSide(arguments),
        makeObject(arguments), makeBody(arguments));
  }

  @override
  Instantiator<While> visitWhile(While node) {
    var makeCondition = visit(node.condition) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (arguments) => While(makeCondition(arguments), makeBody(arguments));
  }

  @override
  Instantiator<Do> visitDo(Do node) {
    var makeBody = visit(node.body) as Instantiator<Statement>;
    var makeCondition = visit(node.condition) as Instantiator<Expression>;
    return (arguments) => Do(makeBody(arguments), makeCondition(arguments));
  }

  @override
  Instantiator<Continue> visitContinue(Continue node) =>
      (arguments) => Continue(node.targetLabel);

  @override
  Instantiator<Break> visitBreak(Break node) =>
      (arguments) => Break(node.targetLabel);

  @override
  Instantiator<Statement> visitReturn(Return node) {
    if (node.value == null) return (args) => Return();
    var makeExpression = visit(node.value!) as Instantiator<Expression>;
    return (arguments) => makeExpression(arguments).toReturn();
  }

  @override
  Instantiator<DartYield> visitDartYield(DartYield node) {
    var makeExpression = visit(node.expression) as Instantiator<Expression>;
    return (arguments) => DartYield(makeExpression(arguments), node.hasStar);
  }

  @override
  Instantiator<Throw> visitThrow(Throw node) {
    var makeExpression = visit(node.expression) as Instantiator<Expression>;
    return (arguments) => Throw(makeExpression(arguments));
  }

  @override
  Instantiator<Try> visitTry(Try node) {
    var makeBody = visit(node.body) as Instantiator<Block>;
    var makeCatch = visitNullable(node.catchPart) as Instantiator<Catch?>;
    var makeFinally = visitNullable(node.finallyPart) as Instantiator<Block?>;
    return (arguments) =>
        Try(makeBody(arguments), makeCatch(arguments), makeFinally(arguments));
  }

  @override
  Instantiator<Catch> visitCatch(Catch node) {
    var makeDeclaration = visit(node.declaration) as Instantiator<Identifier>;
    var makeBody = visit(node.body) as Instantiator<Block>;
    return (arguments) =>
        Catch(makeDeclaration(arguments), makeBody(arguments));
  }

  @override
  Instantiator<Switch> visitSwitch(Switch node) {
    var makeKey = visit(node.key) as Instantiator<Expression>;
    var makeCases =
        node.cases.map((c) => visit(c) as Instantiator<SwitchClause>);
    return (arguments) => Switch(makeKey(arguments),
        makeCases.map((makeCase) => makeCase(arguments)).toList());
  }

  @override
  Instantiator<Case> visitCase(Case node) {
    var makeExpression = visit(node.expression) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Block>;
    return (arguments) {
      return Case(makeExpression(arguments), makeBody(arguments));
    };
  }

  @override
  Instantiator<Default> visitDefault(Default node) {
    var makeBody = visit(node.body) as Instantiator<Block>;
    return (arguments) {
      return Default(makeBody(arguments));
    };
  }

  @override
  Instantiator<FunctionDeclaration> visitFunctionDeclaration(
      FunctionDeclaration node) {
    var makeName = visit(node.name) as Instantiator<Identifier>;
    var makeFunction = visit(node.function) as Instantiator<Fun>;
    return (arguments) =>
        FunctionDeclaration(makeName(arguments), makeFunction(arguments));
  }

  @override
  Instantiator<LabeledStatement> visitLabeledStatement(LabeledStatement node) {
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (arguments) => LabeledStatement(node.label, makeBody(arguments));
  }

  @override
  Instantiator visitLiteralStatement(LiteralStatement node) => visitNode(node);
  @override
  Instantiator visitLiteralExpression(LiteralExpression node) =>
      visitNode(node);

  @override
  Instantiator<VariableDeclarationList> visitVariableDeclarationList(
      VariableDeclarationList node) {
    var declarationMakers =
        node.declarations.map(visitVariableInitialization).toList();
    return (arguments) => VariableDeclarationList(
        node.keyword, declarationMakers.map((m) => m(arguments)).toList());
  }

  @override
  Instantiator<Expression> visitAssignment(Assignment node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    String? op = node.op;
    Instantiator makeValue = visit(node.value);
    return (arguments) {
      return makeValue(arguments)
          .toAssignExpression(makeLeftHandSide(arguments), op) as Expression;
    };
  }

  @override
  Instantiator<VariableInitialization> visitVariableInitialization(
      VariableInitialization node) {
    var makeDeclaration =
        visit(node.declaration) as Instantiator<VariableBinding>;
    var makeValue = visitNullable(node.value) as Instantiator<Expression?>;
    return (arguments) => VariableInitialization(
        makeDeclaration(arguments), makeValue(arguments));
  }

  @override
  Instantiator<Conditional> visitConditional(Conditional cond) {
    var makeCondition = visit(cond.condition) as Instantiator<Expression>;
    var makeThen = visit(cond.then) as Instantiator<Expression>;
    var makeOtherwise = visit(cond.otherwise) as Instantiator<Expression>;
    return (arguments) => Conditional(makeCondition(arguments),
        makeThen(arguments), makeOtherwise(arguments));
  }

  @override
  Instantiator<Call> visitNew(New node) => handleCallOrNew(node, true);

  @override
  Instantiator<Call> visitCall(Call node) => handleCallOrNew(node, false);

  Instantiator<Call> handleCallOrNew(Call node, bool isNew) {
    var makeTarget = visit(node.target) as Instantiator<Expression>;
    var argumentMakers = node.arguments.map(visitSplayableExpression).toList();

    // TODO(sra): Avoid copying call arguments if no interpolation or forced
    // copying.
    return (arguments) {
      var target = makeTarget(arguments);
      var callArgs = splayNodes<Expression>(argumentMakers, arguments);
      return isNew ? New(target, callArgs) : Call(target, callArgs);
    };
  }

  @override
  Instantiator<Binary> visitBinary(Binary node) {
    var makeLeft = visit(node.left) as Instantiator<Expression>;
    var makeRight = visit(node.right) as Instantiator<Expression>;
    String op = node.op;
    return (arguments) => Binary(op, makeLeft(arguments), makeRight(arguments));
  }

  @override
  Instantiator<Prefix> visitPrefix(Prefix node) {
    var makeOperand = visit(node.argument) as Instantiator<Expression>;
    String op = node.op;
    return (arguments) => Prefix(op, makeOperand(arguments));
  }

  @override
  Instantiator<Postfix> visitPostfix(Postfix node) {
    var makeOperand = visit(node.argument) as Instantiator<Expression>;
    String op = node.op;
    return (arguments) => Postfix(op, makeOperand(arguments));
  }

  @override
  Instantiator<This> visitThis(This node) => (arguments) => This();
  @override
  Instantiator<Super> visitSuper(Super node) => (arguments) => Super();

  @override
  Instantiator<Identifier> visitIdentifier(Identifier node) =>
      (arguments) => Identifier(node.name);

  @override
  Instantiator<Spread> visitSpread(Spread node) {
    var maker = visit(node.argument);
    return (arguments) => Spread(maker(arguments) as Expression);
  }

  @override
  Instantiator<Yield> visitYield(Yield node) {
    var maker = visitNullable(node.value);
    return (arguments) =>
        Yield(maker(arguments) as Expression, star: node.star);
  }

  @override
  Instantiator<RestParameter> visitRestParameter(RestParameter node) {
    var maker = visit(node.parameter);
    return (arguments) => RestParameter(maker(arguments) as Identifier);
  }

  @override
  Instantiator<PropertyAccess> visitAccess(PropertyAccess node) {
    var makeReceiver = visit(node.receiver) as Instantiator<Expression>;
    var makeSelector = visit(node.selector) as Instantiator<Expression>;
    return (arguments) =>
        PropertyAccess(makeReceiver(arguments), makeSelector(arguments));
  }

  @override
  Instantiator<NamedFunction> visitNamedFunction(NamedFunction node) {
    var makeDeclaration = visit(node.name) as Instantiator<Identifier>;
    var makeFunction = visit(node.function) as Instantiator<Fun>;
    return (arguments) =>
        NamedFunction(makeDeclaration(arguments), makeFunction(arguments));
  }

  @override
  Instantiator<Fun> visitFun(Fun node) {
    var paramMakers = node.params.map(visitSplayable).toList();
    var makeBody = visit(node.body) as Instantiator<Block>;
    return (arguments) => Fun(
        splayNodes(paramMakers, arguments), makeBody(arguments),
        isGenerator: node.isGenerator, asyncModifier: node.asyncModifier);
  }

  @override
  Instantiator<ArrowFun> visitArrowFun(ArrowFun node) {
    var paramMakers = node.params.map(visitSplayable).toList();
    Instantiator makeBody = visit(node.body);
    return (arguments) => ArrowFun(
        splayNodes(paramMakers, arguments), makeBody(arguments) as Node);
  }

  @override
  Instantiator<LiteralBool> visitLiteralBool(LiteralBool node) =>
      (arguments) => LiteralBool(node.value);

  @override
  Instantiator<LiteralString> visitLiteralString(LiteralString node) =>
      (arguments) => LiteralString(node.value);

  @override
  Instantiator<LiteralNumber> visitLiteralNumber(LiteralNumber node) =>
      (arguments) => LiteralNumber(node.value);

  @override
  Instantiator<LiteralNull> visitLiteralNull(LiteralNull node) =>
      (arguments) => LiteralNull();

  @override
  Instantiator<ArrayInitializer> visitArrayInitializer(ArrayInitializer node) {
    var makers = node.elements.map(visitSplayableExpression).toList();
    return (arguments) => ArrayInitializer(splayNodes(makers, arguments));
  }

  @override
  Instantiator<ArrayHole> visitArrayHole(ArrayHole node) {
    return (arguments) => ArrayHole();
  }

  @override
  Instantiator<ObjectInitializer> visitObjectInitializer(
      ObjectInitializer node) {
    var propertyMakers = node.properties.map(visitSplayable).toList();
    return (arguments) =>
        ObjectInitializer(splayNodes(propertyMakers, arguments));
  }

  @override
  Instantiator<Property> visitProperty(Property node) {
    var makeName = visit(node.name) as Instantiator<Expression>;
    var makeValue = visit(node.value) as Instantiator<Expression>;
    return (arguments) => Property(makeName(arguments), makeValue(arguments));
  }

  @override
  Instantiator<RegExpLiteral> visitRegExpLiteral(RegExpLiteral node) =>
      (arguments) => RegExpLiteral(node.pattern);

  @override
  Instantiator<TemplateString> visitTemplateString(TemplateString node) {
    var makeElements = node.interpolations.map(visit).toList();
    return (arguments) =>
        TemplateString(node.strings, splayNodes(makeElements, arguments));
  }

  @override
  Instantiator<TaggedTemplate> visitTaggedTemplate(TaggedTemplate node) {
    var makeTag = visit(node.tag) as Instantiator<Expression>;
    var makeTemplate = visitTemplateString(node.template);
    return (arguments) =>
        TaggedTemplate(makeTag(arguments), makeTemplate(arguments));
  }

  @override
  Instantiator<ClassDeclaration> visitClassDeclaration(ClassDeclaration node) {
    var makeClass = visitClassExpression(node.classExpr);
    return (arguments) => ClassDeclaration(makeClass(arguments));
  }

  @override
  Instantiator<ClassExpression> visitClassExpression(ClassExpression node) {
    var makeMethods = node.methods.map(visitSplayableExpression).toList();
    var makeName = visit(node.name) as Instantiator<Identifier>;
    var makeHeritage =
        visitNullable(node.heritage) as Instantiator<Expression?>;

    return (arguments) => ClassExpression(makeName(arguments),
        makeHeritage(arguments), splayNodes(makeMethods, arguments));
  }

  @override
  Instantiator<Method> visitMethod(Method node) {
    var makeName = visit(node.name) as Instantiator<Expression>;
    var makeFunction = visit(node.function) as Instantiator<Fun>;
    return (arguments) => Method(makeName(arguments), makeFunction(arguments),
        isGetter: node.isGetter,
        isSetter: node.isSetter,
        isStatic: node.isStatic);
  }

  @override
  Instantiator<Comment> visitComment(Comment node) =>
      (arguments) => Comment(node.comment);

  @override
  Instantiator<CommentExpression> visitCommentExpression(
      CommentExpression node) {
    var makeExpr = visit(node.expression) as Instantiator<Expression>;
    return (arguments) => CommentExpression(node.comment, makeExpr(arguments));
  }

  @override
  Instantiator<Await> visitAwait(Await node) {
    var makeExpr = visit(node.expression) as Instantiator<Expression>;
    return (arguments) => Await(makeExpr(arguments));
  }

  @override
  Instantiator visitNameSpecifier(NameSpecifier node) =>
      throw UnimplementedError();

  @override
  Instantiator visitImportDeclaration(ImportDeclaration node) =>
      throw UnimplementedError();

  @override
  Instantiator visitExportDeclaration(ExportDeclaration node) =>
      throw UnimplementedError();

  @override
  Instantiator visitExportClause(ExportClause node) =>
      throw UnimplementedError();

  @override
  Instantiator<DestructuredVariable> visitDestructuredVariable(
      DestructuredVariable node) {
    var makeName = visit(node.name) as Instantiator<Identifier>;
    var makeProperty =
        visitNullable(node.property) as Instantiator<Expression?>;
    var makeStructure =
        visitNullable(node.structure) as Instantiator<BindingPattern?>;
    var makeDefaultValue =
        visitNullable(node.defaultValue) as Instantiator<Expression?>;
    return (arguments) => DestructuredVariable(
        name: makeName(arguments),
        property: makeProperty(arguments),
        structure: makeStructure(arguments),
        defaultValue: makeDefaultValue(arguments));
  }

  @override
  Instantiator<ArrayBindingPattern> visitArrayBindingPattern(
      ArrayBindingPattern node) {
    List<Instantiator> makeVars = node.variables.map(visit).toList();
    return (arguments) => ArrayBindingPattern(splayNodes(makeVars, arguments));
  }

  @override
  Instantiator<ObjectBindingPattern> visitObjectBindingPattern(
      ObjectBindingPattern node) {
    List<Instantiator> makeVars = node.variables.map(visit).toList();
    return (arguments) => ObjectBindingPattern(splayNodes(makeVars, arguments));
  }

  @override
  Instantiator<SimpleBindingPattern> visitSimpleBindingPattern(
          SimpleBindingPattern node) =>
      (arguments) => SimpleBindingPattern(Identifier(node.name.name));
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
  void visitInterpolatedNode(InterpolatedNode node) {
    containsInterpolatedNode.add(node);
    if (node.isNamed) holeNames.add(node.nameOrPosition as String);
    ++count;
  }
}
