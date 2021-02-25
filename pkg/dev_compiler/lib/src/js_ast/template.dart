// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// ignore_for_file: slash_for_doc_comments, omit_local_variable_types
// ignore_for_file: always_declare_return_types, prefer_collection_literals
// ignore_for_file: prefer_single_quotes, prefer_generic_function_type_aliases

part of js_ast;

class TemplateManager {
  Map<String, Template> expressionTemplates = Map<String, Template>();
  Map<String, Template> statementTemplates = Map<String, Template>();

  TemplateManager();

  Template lookupExpressionTemplate(String source) {
    return expressionTemplates[source];
  }

  Template defineExpressionTemplate(String source, Node ast) {
    Template template =
        Template(source, ast, isExpression: true, forceCopy: false);
    expressionTemplates[source] = template;
    return template;
  }

  Template lookupStatementTemplate(String source) {
    return statementTemplates[source];
  }

  Template defineStatementTemplate(String source, Node ast) {
    Template template =
        Template(source, ast, isExpression: false, forceCopy: false);
    statementTemplates[source] = template;
    return template;
  }
}

/**
 * A Template is created with JavaScript AST containing placeholders (interface
 * InterpolatedNode).  The [instantiate] method creates an AST that looks like
 * the original with the placeholders replaced by the arguments to
 * [instantiate].
 */
class Template {
  final String source;
  final bool isExpression;
  final bool forceCopy;
  final Node ast;

  Instantiator instantiator;

  int positionalArgumentCount = -1;

  // Null, unless there are named holes.
  List<String> holeNames;
  bool get isPositional => holeNames == null;

  Template(this.source, this.ast,
      {this.isExpression = true, this.forceCopy = false}) {
    _compile();
  }

  Template.withExpressionResult(this.ast)
      : source = null,
        isExpression = true,
        forceCopy = false {
    assert(ast is Expression);
    assert(_checkNoPlaceholders());
    positionalArgumentCount = 0;
    instantiator = (arguments) => ast;
  }

  Template.withStatementResult(this.ast)
      : source = null,
        isExpression = false,
        forceCopy = false {
    assert(ast is Statement);
    assert(_checkNoPlaceholders());
    positionalArgumentCount = 0;
    instantiator = (arguments) => ast;
  }

  bool _checkNoPlaceholders() {
    var generator = InstantiatorGeneratorVisitor(false);
    generator.compile(ast);
    return generator.analysis.count == 0;
  }

  void _compile() {
    var generator = InstantiatorGeneratorVisitor(forceCopy);
    instantiator = generator.compile(ast);
    positionalArgumentCount = generator.analysis.count;
    Set<String> names = generator.analysis.holeNames;
    holeNames = names.toList(growable: false);
  }

  /// Instantiates the template with the given [arguments].
  ///
  /// This method fills in the holes with the given arguments. The [arguments]
  /// must be either a [List] or a [Map].
  Node instantiate(var arguments) {
    if (arguments is List) {
      if (arguments.length != positionalArgumentCount) {
        throw 'Wrong number of template arguments, given ${arguments.length}, '
            'expected $positionalArgumentCount:\n$source';
      }
      return instantiator(arguments) as Node;
    }
    if (arguments is Map) {
      if (holeNames.length < arguments.length) {
        // This search is in O(n), but we only do it in case of an new StateError, and the
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
      return instantiator(arguments) as Node;
    }
    throw ArgumentError.value(arguments, 'must be a List or Map');
  }
}

/**
 * An Instantiator is a Function that generates a JS AST tree or List of
 * trees. [arguments] is a List for positional templates, or Map for
 * named templates.
 */
typedef T Instantiator<T>(arguments);

/**
 * InstantiatorGeneratorVisitor compiles a template.  This class compiles a tree
 * containing [InterpolatedNode]s into a function that will create a copy of the
 * tree with the interpolated nodes substituted with provided values.
 */
class InstantiatorGeneratorVisitor implements NodeVisitor<Instantiator> {
  final bool forceCopy;

  final analysis = InterpolatedNodeAnalysis();

  /**
   * The entire tree is cloned if [forceCopy] is true.
   */
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

  Instantiator visitNullable<T extends Node>(T node) {
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
    return (a) => Program(splayStatements(instantiators, a));
  }

  List<Statement> splayStatements(List<Instantiator> instantiators, arguments) {
    var statements = <Statement>[];
    for (var instantiator in instantiators) {
      var node = instantiator(arguments);
      if (node is EmptyStatement) continue;
      if (node is Iterable) {
        for (var n in node) {
          statements.add(n as Statement);
        }
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
    return (a) => Block(splayStatements(instantiators, a));
  }

  @override
  Instantiator<Statement> visitExpressionStatement(ExpressionStatement node) {
    var makeExpression = visit(node.expression) as Instantiator<Expression>;
    return (a) => makeExpression(a).toStatement();
  }

  @override
  Instantiator<DebuggerStatement> visitDebuggerStatement(node) =>
      (a) => DebuggerStatement();

  @override
  Instantiator<EmptyStatement> visitEmptyStatement(EmptyStatement node) =>
      (a) => EmptyStatement();

  @override
  Instantiator<Statement> visitIf(If node) {
    var condition = node.condition;
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
      // Allow bools to be used for conditional compliation.
      var nameOrPosition = condition.nameOrPosition;
      var value = arguments[nameOrPosition];
      if (value is bool) {
        return value ? makeThen(arguments) : makeOtherwise(arguments);
      }
      var cond = value is String ? Identifier(value) : value as Expression;
      return If(cond, makeThen(arguments), makeOtherwise(arguments));
    };
  }

  Instantiator<Statement> visitIfNormal(If node) {
    var makeCondition = visit(node.condition) as Instantiator<Expression>;
    var makeThen = visit(node.then) as Instantiator<Statement>;
    var makeOtherwise = visit(node.otherwise) as Instantiator<Statement>;
    return (a) => If(makeCondition(a), makeThen(a), makeOtherwise(a));
  }

  @override
  Instantiator<Statement> visitFor(For node) {
    var makeInit = visitNullable(node.init) as Instantiator<Expression>;
    var makeCondition =
        visitNullable(node.condition) as Instantiator<Expression>;
    var makeUpdate = visitNullable(node.update) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (a) => For(makeInit(a), makeCondition(a),
        makeUpdate(a)?.toVoidExpression(), makeBody(a));
  }

  @override
  Instantiator<ForIn> visitForIn(ForIn node) {
    var makeLeftHandSide = visit(node.leftHandSide) as Instantiator<Expression>;
    var makeObject = visit(node.object) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (a) => ForIn(makeLeftHandSide(a), makeObject(a), makeBody(a));
  }

  @override
  Instantiator<ForOf> visitForOf(ForOf node) {
    var makeLeftHandSide = visit(node.leftHandSide) as Instantiator<Expression>;
    var makeObject = visit(node.iterable) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (a) => ForOf(makeLeftHandSide(a), makeObject(a), makeBody(a));
  }

  @override
  Instantiator<While> visitWhile(While node) {
    var makeCondition = visit(node.condition) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (a) => While(makeCondition(a), makeBody(a));
  }

  @override
  Instantiator<Do> visitDo(Do node) {
    var makeBody = visit(node.body) as Instantiator<Statement>;
    var makeCondition = visit(node.condition) as Instantiator<Expression>;
    return (a) => Do(makeBody(a), makeCondition(a));
  }

  @override
  Instantiator<Continue> visitContinue(Continue node) =>
      (a) => Continue(node.targetLabel);

  @override
  Instantiator<Break> visitBreak(Break node) => (a) => Break(node.targetLabel);

  @override
  Instantiator<Statement> visitReturn(Return node) {
    if (node.value == null) return (args) => Return();
    var makeExpression = visit(node.value) as Instantiator<Expression>;
    return (a) => makeExpression(a).toReturn();
  }

  @override
  Instantiator<DartYield> visitDartYield(DartYield node) {
    var makeExpression = visit(node.expression) as Instantiator<Expression>;
    return (a) => DartYield(makeExpression(a), node.hasStar);
  }

  @override
  Instantiator<Throw> visitThrow(Throw node) {
    var makeExpression = visit(node.expression) as Instantiator<Expression>;
    return (a) => Throw(makeExpression(a));
  }

  @override
  Instantiator<Try> visitTry(Try node) {
    var makeBody = visit(node.body) as Instantiator<Block>;
    var makeCatch = visitNullable(node.catchPart) as Instantiator<Catch>;
    var makeFinally = visitNullable(node.finallyPart) as Instantiator<Block>;
    return (a) => Try(makeBody(a), makeCatch(a), makeFinally(a));
  }

  @override
  Instantiator<Catch> visitCatch(Catch node) {
    var makeDeclaration = visit(node.declaration) as Instantiator<Identifier>;
    var makeBody = visit(node.body) as Instantiator<Block>;
    return (a) => Catch(makeDeclaration(a), makeBody(a));
  }

  @override
  Instantiator<Switch> visitSwitch(Switch node) {
    var makeKey = visit(node.key) as Instantiator<Expression>;
    var makeCases = node.cases.map(visitSwitchCase).toList();
    return (a) => Switch(makeKey(a), makeCases.map((m) => m(a)).toList());
  }

  @override
  Instantiator<SwitchCase> visitSwitchCase(SwitchCase node) {
    var makeExpression =
        visitNullable(node.expression) as Instantiator<Expression>;
    var makeBody = visit(node.body) as Instantiator<Block>;
    return (arguments) {
      return SwitchCase(makeExpression(arguments), makeBody(arguments));
    };
  }

  @override
  Instantiator<FunctionDeclaration> visitFunctionDeclaration(
      FunctionDeclaration node) {
    var makeName = visit(node.name) as Instantiator<Identifier>;
    var makeFunction = visit(node.function) as Instantiator<Fun>;
    return (a) => FunctionDeclaration(makeName(a), makeFunction(a));
  }

  @override
  Instantiator<LabeledStatement> visitLabeledStatement(LabeledStatement node) {
    var makeBody = visit(node.body) as Instantiator<Statement>;
    return (a) => LabeledStatement(node.label, makeBody(a));
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
    return (a) => VariableDeclarationList(
        node.keyword, declarationMakers.map((m) => m(a)).toList());
  }

  @override
  Instantiator<Expression> visitAssignment(Assignment node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    String op = node.op;
    Instantiator makeValue = visitNullable(node.value);
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
    var makeValue = visitNullable(node.value) as Instantiator<Expression>;
    return (a) => VariableInitialization(makeDeclaration(a), makeValue(a));
  }

  @override
  Instantiator<Conditional> visitConditional(Conditional cond) {
    var makeCondition = visit(cond.condition) as Instantiator<Expression>;
    var makeThen = visit(cond.then) as Instantiator<Expression>;
    var makeOtherwise = visit(cond.otherwise) as Instantiator<Expression>;
    return (a) => Conditional(makeCondition(a), makeThen(a), makeOtherwise(a));
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
    return (a) {
      var target = makeTarget(a);
      var callArgs = splayNodes<Expression>(argumentMakers, a);
      return isNew ? New(target, callArgs) : Call(target, callArgs);
    };
  }

  @override
  Instantiator<Binary> visitBinary(Binary node) {
    var makeLeft = visit(node.left) as Instantiator<Expression>;
    var makeRight = visit(node.right) as Instantiator<Expression>;
    String op = node.op;
    return (a) => Binary(op, makeLeft(a), makeRight(a));
  }

  @override
  Instantiator<Prefix> visitPrefix(Prefix node) {
    var makeOperand = visit(node.argument) as Instantiator<Expression>;
    String op = node.op;
    return (a) => Prefix(op, makeOperand(a));
  }

  @override
  Instantiator<Postfix> visitPostfix(Postfix node) {
    var makeOperand = visit(node.argument) as Instantiator<Expression>;
    String op = node.op;
    return (a) => Postfix(op, makeOperand(a));
  }

  @override
  Instantiator<This> visitThis(This node) => (a) => This();
  @override
  Instantiator<Super> visitSuper(Super node) => (a) => Super();

  @override
  Instantiator<Identifier> visitIdentifier(Identifier node) =>
      (a) => Identifier(node.name);

  @override
  Instantiator<Spread> visitSpread(Spread node) {
    var maker = visit(node.argument);
    return (a) => Spread(maker(a) as Expression);
  }

  @override
  Instantiator<Yield> visitYield(Yield node) {
    var maker = visitNullable(node.value);
    return (a) => Yield(maker(a) as Expression, star: node.star);
  }

  @override
  Instantiator<RestParameter> visitRestParameter(RestParameter node) {
    var maker = visit(node.parameter);
    return (a) => RestParameter(maker(a) as Identifier);
  }

  @override
  Instantiator<PropertyAccess> visitAccess(PropertyAccess node) {
    var makeReceiver = visit(node.receiver) as Instantiator<Expression>;
    var makeSelector = visit(node.selector) as Instantiator<Expression>;
    return (a) => PropertyAccess(makeReceiver(a), makeSelector(a));
  }

  @override
  Instantiator<NamedFunction> visitNamedFunction(NamedFunction node) {
    var makeDeclaration = visit(node.name) as Instantiator<Identifier>;
    var makeFunction = visit(node.function) as Instantiator<Fun>;
    return (a) => NamedFunction(makeDeclaration(a), makeFunction(a));
  }

  @override
  Instantiator<Fun> visitFun(Fun node) {
    var paramMakers = node.params.map(visitSplayable).toList();
    var makeBody = visit(node.body) as Instantiator<Block>;
    return (a) => Fun(splayNodes(paramMakers, a), makeBody(a),
        isGenerator: node.isGenerator, asyncModifier: node.asyncModifier);
  }

  @override
  Instantiator<ArrowFun> visitArrowFun(ArrowFun node) {
    var paramMakers = node.params.map(visitSplayable).toList();
    Instantiator makeBody = visit(node.body);
    return (a) => ArrowFun(splayNodes(paramMakers, a), makeBody(a) as Node);
  }

  @override
  Instantiator<LiteralBool> visitLiteralBool(LiteralBool node) =>
      (a) => LiteralBool(node.value);

  @override
  Instantiator<LiteralString> visitLiteralString(LiteralString node) =>
      (a) => LiteralString(node.value);

  @override
  Instantiator<LiteralNumber> visitLiteralNumber(LiteralNumber node) =>
      (a) => LiteralNumber(node.value);

  @override
  Instantiator<LiteralNull> visitLiteralNull(LiteralNull node) =>
      (a) => LiteralNull();

  @override
  Instantiator<ArrayInitializer> visitArrayInitializer(ArrayInitializer node) {
    var makers = node.elements.map(visitSplayableExpression).toList();
    return (a) => ArrayInitializer(splayNodes(makers, a));
  }

  @override
  Instantiator visitArrayHole(ArrayHole node) {
    return (arguments) => ArrayHole();
  }

  @override
  Instantiator<ObjectInitializer> visitObjectInitializer(
      ObjectInitializer node) {
    var propertyMakers = node.properties.map(visitSplayable).toList();
    return (a) => ObjectInitializer(splayNodes(propertyMakers, a));
  }

  @override
  Instantiator<Property> visitProperty(Property node) {
    var makeName = visit(node.name) as Instantiator<Expression>;
    var makeValue = visit(node.value) as Instantiator<Expression>;
    return (a) => Property(makeName(a), makeValue(a));
  }

  @override
  Instantiator<RegExpLiteral> visitRegExpLiteral(RegExpLiteral node) =>
      (a) => RegExpLiteral(node.pattern);

  @override
  Instantiator<TemplateString> visitTemplateString(TemplateString node) {
    var makeElements = node.interpolations.map(visit).toList();
    return (a) => TemplateString(node.strings, splayNodes(makeElements, a));
  }

  @override
  Instantiator<TaggedTemplate> visitTaggedTemplate(TaggedTemplate node) {
    var makeTag = visit(node.tag) as Instantiator<Expression>;
    var makeTemplate = visitTemplateString(node.template);
    return (a) => TaggedTemplate(makeTag(a), makeTemplate(a));
  }

  @override
  Instantiator visitClassDeclaration(ClassDeclaration node) {
    var makeClass = visitClassExpression(node.classExpr);
    return (a) => ClassDeclaration(makeClass(a));
  }

  @override
  Instantiator<ClassExpression> visitClassExpression(ClassExpression node) {
    var makeMethods = node.methods.map(visitSplayableExpression).toList();
    var makeName = visit(node.name) as Instantiator<Identifier>;
    var makeHeritage = visit(node.heritage) as Instantiator<Expression>;

    return (a) => ClassExpression(
        makeName(a), makeHeritage(a), splayNodes(makeMethods, a));
  }

  @override
  Instantiator<Method> visitMethod(Method node) {
    var makeName = visit(node.name) as Instantiator<Expression>;
    var makeFunction = visit(node.function) as Instantiator<Fun>;
    return (a) => Method(makeName(a), makeFunction(a),
        isGetter: node.isGetter,
        isSetter: node.isSetter,
        isStatic: node.isStatic);
  }

  @override
  Instantiator<Comment> visitComment(Comment node) =>
      (a) => Comment(node.comment);

  @override
  Instantiator<CommentExpression> visitCommentExpression(
      CommentExpression node) {
    var makeExpr = visit(node.expression) as Instantiator<Expression>;
    return (a) => CommentExpression(node.comment, makeExpr(a));
  }

  @override
  Instantiator<Await> visitAwait(Await node) {
    var makeExpr = visit(node.expression) as Instantiator<Expression>;
    return (a) => Await(makeExpr(a));
  }

  // Note: these are not supported yet in the interpolation grammar.
  @override
  Instantiator visitModule(Module node) => throw UnimplementedError();
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
    var makeName = visitNullable(node.name) as Instantiator<Identifier>;
    var makeProperty = visitNullable(node.property) as Instantiator<Expression>;
    var makeStructure =
        visitNullable(node.structure) as Instantiator<BindingPattern>;
    var makeDefaultValue =
        visitNullable(node.defaultValue) as Instantiator<Expression>;
    return (a) => DestructuredVariable(
        name: makeName(a),
        property: makeProperty(a),
        structure: makeStructure(a),
        defaultValue: makeDefaultValue(a));
  }

  @override
  Instantiator<ArrayBindingPattern> visitArrayBindingPattern(
      ArrayBindingPattern node) {
    List<Instantiator> makeVars = node.variables.map(this.visit).toList();
    return (a) => ArrayBindingPattern(splayNodes(makeVars, a));
  }

  @override
  Instantiator visitObjectBindingPattern(ObjectBindingPattern node) {
    List<Instantiator> makeVars = node.variables.map(this.visit).toList();
    return (a) => ObjectBindingPattern(splayNodes(makeVars, a));
  }

  @override
  Instantiator visitSimpleBindingPattern(SimpleBindingPattern node) =>
      (a) => SimpleBindingPattern(Identifier(node.name.name));
}

/**
 * InterpolatedNodeAnalysis determines which AST trees contain
 * [InterpolatedNode]s, and the names of the named interpolated nodes.
 */
class InterpolatedNodeAnalysis extends BaseVisitor {
  final Set<Node> containsInterpolatedNode = Set<Node>();
  final Set<String> holeNames = Set<String>();
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
    return null;
  }

  @override
  visitInterpolatedNode(InterpolatedNode node) {
    containsInterpolatedNode.add(node);
    if (node.isNamed) holeNames.add(node.nameOrPosition as String);
    ++count;
  }
}
