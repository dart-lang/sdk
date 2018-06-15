// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
        for (var e in result) exprs.add(e as T);
      } else {
        exprs.add(result as T);
      }
    }
    return exprs;
  }

  Instantiator<Literal> visitInterpolatedLiteral(InterpolatedLiteral node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Literal) return value;
      throw StateError(
          'Interpolated value #$nameOrPosition is not a Literal: $value');
    };
  }

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
        for (var n in node) statements.add(n as Statement);
      } else if (node is Block && !node.isScope) {
        statements.addAll(node.statements);
      } else {
        statements.add((node as Node).toStatement());
      }
    }
    return statements;
  }

  Instantiator<Block> visitBlock(Block node) {
    var instantiators = node.statements.map(visitSplayableStatement).toList();
    return (a) => Block(splayStatements(instantiators, a));
  }

  Instantiator<Statement> visitExpressionStatement(ExpressionStatement node) {
    Instantiator<Expression> makeExpression = visit(node.expression);
    return (a) => makeExpression(a).toStatement();
  }

  Instantiator<DebuggerStatement> visitDebuggerStatement(node) =>
      (a) => DebuggerStatement();

  Instantiator<EmptyStatement> visitEmptyStatement(EmptyStatement node) =>
      (a) => EmptyStatement();

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
    Instantiator<Statement> makeThen = visit(node.then);
    Instantiator<Statement> makeOtherwise = visit(node.otherwise);
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
    Instantiator<Expression> makeCondition = visit(node.condition);
    Instantiator<Statement> makeThen = visit(node.then);
    Instantiator<Statement> makeOtherwise = visit(node.otherwise);
    return (a) => If(makeCondition(a), makeThen(a), makeOtherwise(a));
  }

  Instantiator<Statement> visitFor(For node) {
    Instantiator<Expression> makeInit = visitNullable(node.init);
    Instantiator<Expression> makeCondition = visitNullable(node.condition);
    Instantiator<Expression> makeUpdate = visitNullable(node.update);
    Instantiator<Statement> makeBody = visit(node.body);
    return (a) => For(makeInit(a), makeCondition(a),
        makeUpdate(a)?.toVoidExpression(), makeBody(a));
  }

  Instantiator<ForIn> visitForIn(ForIn node) {
    Instantiator<Expression> makeLeftHandSide = visit(node.leftHandSide);
    Instantiator<Expression> makeObject = visit(node.object);
    Instantiator<Statement> makeBody = visit(node.body);
    return (a) => ForIn(makeLeftHandSide(a), makeObject(a), makeBody(a));
  }

  Instantiator<ForOf> visitForOf(ForOf node) {
    Instantiator<Expression> makeLeftHandSide = visit(node.leftHandSide);
    Instantiator<Expression> makeObject = visit(node.iterable);
    Instantiator<Statement> makeBody = visit(node.body);
    return (a) => ForOf(makeLeftHandSide(a), makeObject(a), makeBody(a));
  }

  Instantiator<While> visitWhile(While node) {
    Instantiator<Expression> makeCondition = visit(node.condition);
    Instantiator<Statement> makeBody = visit(node.body);
    return (a) => While(makeCondition(a), makeBody(a));
  }

  Instantiator<Do> visitDo(Do node) {
    Instantiator<Statement> makeBody = visit(node.body);
    Instantiator<Expression> makeCondition = visit(node.condition);
    return (a) => Do(makeBody(a), makeCondition(a));
  }

  Instantiator<Continue> visitContinue(Continue node) =>
      (a) => Continue(node.targetLabel);

  Instantiator<Break> visitBreak(Break node) => (a) => Break(node.targetLabel);

  Instantiator<Statement> visitReturn(Return node) {
    if (node.value == null) return (args) => Return();
    Instantiator<Expression> makeExpression = visit(node.value);
    return (a) => makeExpression(a).toReturn();
  }

  Instantiator<DartYield> visitDartYield(DartYield node) {
    Instantiator<Expression> makeExpression = visit(node.expression);
    return (a) => DartYield(makeExpression(a), node.hasStar);
  }

  Instantiator<Throw> visitThrow(Throw node) {
    Instantiator<Expression> makeExpression = visit(node.expression);
    return (a) => Throw(makeExpression(a));
  }

  Instantiator<Try> visitTry(Try node) {
    Instantiator<Block> makeBody = visit(node.body);
    Instantiator<Catch> makeCatch = visitNullable(node.catchPart);
    Instantiator<Block> makeFinally = visitNullable(node.finallyPart);
    return (a) => Try(makeBody(a), makeCatch(a), makeFinally(a));
  }

  Instantiator<Catch> visitCatch(Catch node) {
    Instantiator<Identifier> makeDeclaration = visit(node.declaration);
    Instantiator<Block> makeBody = visit(node.body);
    return (a) => Catch(makeDeclaration(a), makeBody(a));
  }

  Instantiator<Switch> visitSwitch(Switch node) {
    Instantiator<Expression> makeKey = visit(node.key);
    var makeCases = node.cases.map(visitSwitchCase).toList();
    return (a) => Switch(makeKey(a), makeCases.map((m) => m(a)).toList());
  }

  Instantiator<SwitchCase> visitSwitchCase(SwitchCase node) {
    Instantiator<Expression> makeExpression = visitNullable(node.expression);
    Instantiator<Block> makeBody = visit(node.body);
    return (arguments) {
      return SwitchCase(makeExpression(arguments), makeBody(arguments));
    };
  }

  Instantiator<FunctionDeclaration> visitFunctionDeclaration(
      FunctionDeclaration node) {
    Instantiator<Identifier> makeName = visit(node.name);
    Instantiator<Fun> makeFunction = visit(node.function);
    return (a) => FunctionDeclaration(makeName(a), makeFunction(a));
  }

  Instantiator<LabeledStatement> visitLabeledStatement(LabeledStatement node) {
    Instantiator<Statement> makeBody = visit(node.body);
    return (a) => LabeledStatement(node.label, makeBody(a));
  }

  Instantiator visitLiteralStatement(LiteralStatement node) => visitNode(node);
  Instantiator visitLiteralExpression(LiteralExpression node) =>
      visitNode(node);

  Instantiator<VariableDeclarationList> visitVariableDeclarationList(
      VariableDeclarationList node) {
    var declarationMakers =
        node.declarations.map(visitVariableInitialization).toList();
    return (a) => VariableDeclarationList(
        node.keyword, declarationMakers.map((m) => m(a)).toList());
  }

  Instantiator<Expression> visitAssignment(Assignment node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    String op = node.op;
    Instantiator makeValue = visitNullable(node.value);
    return (arguments) {
      return makeValue(arguments)
          .toAssignExpression(makeLeftHandSide(arguments), op);
    };
  }

  Instantiator<VariableInitialization> visitVariableInitialization(
      VariableInitialization node) {
    Instantiator<VariableBinding> makeDeclaration = visit(node.declaration);
    Instantiator<Expression> makeValue = visitNullable(node.value);
    return (a) => VariableInitialization(makeDeclaration(a), makeValue(a));
  }

  Instantiator<Conditional> visitConditional(Conditional cond) {
    Instantiator<Expression> makeCondition = visit(cond.condition);
    Instantiator<Expression> makeThen = visit(cond.then);
    Instantiator<Expression> makeOtherwise = visit(cond.otherwise);
    return (a) => Conditional(makeCondition(a), makeThen(a), makeOtherwise(a));
  }

  Instantiator<Call> visitNew(New node) => handleCallOrNew(node, true);

  Instantiator<Call> visitCall(Call node) => handleCallOrNew(node, false);

  Instantiator<Call> handleCallOrNew(Call node, bool isNew) {
    Instantiator<Expression> makeTarget = visit(node.target);
    var argumentMakers = node.arguments.map(visitSplayableExpression).toList();

    // TODO(sra): Avoid copying call arguments if no interpolation or forced
    // copying.
    return (a) {
      var target = makeTarget(a);
      var callArgs = splayNodes<Expression>(argumentMakers, a);
      return isNew ? New(target, callArgs) : Call(target, callArgs);
    };
  }

  Instantiator<Binary> visitBinary(Binary node) {
    Instantiator<Expression> makeLeft = visit(node.left);
    Instantiator<Expression> makeRight = visit(node.right);
    String op = node.op;
    return (a) => Binary(op, makeLeft(a), makeRight(a));
  }

  Instantiator<Prefix> visitPrefix(Prefix node) {
    Instantiator<Expression> makeOperand = visit(node.argument);
    String op = node.op;
    return (a) => Prefix(op, makeOperand(a));
  }

  Instantiator<Postfix> visitPostfix(Postfix node) {
    Instantiator<Expression> makeOperand = visit(node.argument);
    String op = node.op;
    return (a) => Postfix(op, makeOperand(a));
  }

  Instantiator<This> visitThis(This node) => (a) => This();
  Instantiator<Super> visitSuper(Super node) => (a) => Super();

  Instantiator<Identifier> visitIdentifier(Identifier node) =>
      (a) => Identifier(node.name);

  Instantiator<Spread> visitSpread(Spread node) {
    var maker = visit(node.argument);
    return (a) => Spread(maker(a) as Expression);
  }

  Instantiator<Yield> visitYield(Yield node) {
    var maker = visitNullable(node.value);
    return (a) => Yield(maker(a) as Expression, star: node.star);
  }

  Instantiator<RestParameter> visitRestParameter(RestParameter node) {
    var maker = visit(node.parameter);
    return (a) => RestParameter(maker(a) as Identifier);
  }

  Instantiator<PropertyAccess> visitAccess(PropertyAccess node) {
    Instantiator<Expression> makeReceiver = visit(node.receiver);
    Instantiator<Expression> makeSelector = visit(node.selector);
    return (a) => PropertyAccess(makeReceiver(a), makeSelector(a));
  }

  Instantiator<NamedFunction> visitNamedFunction(NamedFunction node) {
    Instantiator<Identifier> makeDeclaration = visit(node.name);
    Instantiator<Fun> makeFunction = visit(node.function);
    return (a) => NamedFunction(makeDeclaration(a), makeFunction(a));
  }

  Instantiator<Fun> visitFun(Fun node) {
    var paramMakers = node.params.map(visitSplayable).toList();
    Instantiator<Block> makeBody = visit(node.body);
    return (a) => Fun(splayNodes(paramMakers, a), makeBody(a),
        isGenerator: node.isGenerator, asyncModifier: node.asyncModifier);
  }

  Instantiator<ArrowFun> visitArrowFun(ArrowFun node) {
    var paramMakers = node.params.map(visitSplayable).toList();
    Instantiator makeBody = visit(node.body as Node);
    return (a) => ArrowFun(splayNodes(paramMakers, a), makeBody(a));
  }

  Instantiator<LiteralBool> visitLiteralBool(LiteralBool node) =>
      (a) => LiteralBool(node.value);

  Instantiator<LiteralString> visitLiteralString(LiteralString node) =>
      (a) => LiteralString(node.value);

  Instantiator<LiteralNumber> visitLiteralNumber(LiteralNumber node) =>
      (a) => LiteralNumber(node.value);

  Instantiator<LiteralNull> visitLiteralNull(LiteralNull node) =>
      (a) => LiteralNull();

  Instantiator<ArrayInitializer> visitArrayInitializer(ArrayInitializer node) {
    var makers = node.elements.map(visitSplayableExpression).toList();
    return (a) => ArrayInitializer(splayNodes(makers, a));
  }

  Instantiator visitArrayHole(ArrayHole node) {
    return (arguments) => ArrayHole();
  }

  Instantiator<ObjectInitializer> visitObjectInitializer(
      ObjectInitializer node) {
    var propertyMakers = node.properties.map(visitSplayable).toList();
    return (a) => ObjectInitializer(splayNodes(propertyMakers, a));
  }

  Instantiator<Property> visitProperty(Property node) {
    Instantiator<Expression> makeName = visit(node.name);
    Instantiator<Expression> makeValue = visit(node.value);
    return (a) => Property(makeName(a), makeValue(a));
  }

  Instantiator<RegExpLiteral> visitRegExpLiteral(RegExpLiteral node) =>
      (a) => RegExpLiteral(node.pattern);

  Instantiator<TemplateString> visitTemplateString(TemplateString node) {
    var makeElements = node.interpolations.map(visit).toList();
    return (a) => TemplateString(node.strings, splayNodes(makeElements, a));
  }

  Instantiator<TaggedTemplate> visitTaggedTemplate(TaggedTemplate node) {
    Instantiator<Expression> makeTag = visit(node.tag);
    var makeTemplate = visitTemplateString(node.template);
    return (a) => TaggedTemplate(makeTag(a), makeTemplate(a));
  }

  Instantiator visitClassDeclaration(ClassDeclaration node) {
    var makeClass = visitClassExpression(node.classExpr);
    return (a) => ClassDeclaration(makeClass(a));
  }

  Instantiator<ClassExpression> visitClassExpression(ClassExpression node) {
    var makeMethods = node.methods.map(visitSplayableExpression).toList();
    Instantiator<Identifier> makeName = visit(node.name);
    Instantiator<Expression> makeHeritage = visit(node.heritage);

    return (a) => ClassExpression(
        makeName(a), makeHeritage(a), splayNodes(makeMethods, a));
  }

  Instantiator<Method> visitMethod(Method node) {
    Instantiator<Expression> makeName = visit(node.name);
    Instantiator<Fun> makeFunction = visit(node.function);
    return (a) => Method(makeName(a), makeFunction(a),
        isGetter: node.isGetter,
        isSetter: node.isSetter,
        isStatic: node.isStatic);
  }

  Instantiator<Comment> visitComment(Comment node) =>
      (a) => Comment(node.comment);

  Instantiator<CommentExpression> visitCommentExpression(
      CommentExpression node) {
    Instantiator<Expression> makeExpr = visit(node.expression);
    return (a) => CommentExpression(node.comment, makeExpr(a));
  }

  Instantiator<Await> visitAwait(Await node) {
    Instantiator<Expression> makeExpr = visit(node.expression);
    return (a) => Await(makeExpr(a));
  }

  // Note: these are not supported yet in the interpolation grammar.
  Instantiator visitModule(Module node) => throw UnimplementedError();
  Instantiator visitNameSpecifier(NameSpecifier node) =>
      throw UnimplementedError();

  Instantiator visitImportDeclaration(ImportDeclaration node) =>
      throw UnimplementedError();

  Instantiator visitExportDeclaration(ExportDeclaration node) =>
      throw UnimplementedError();

  Instantiator visitExportClause(ExportClause node) =>
      throw UnimplementedError();

  Instantiator visitAnyTypeRef(AnyTypeRef node) => throw UnimplementedError();

  Instantiator visitUnknownTypeRef(UnknownTypeRef node) =>
      throw UnimplementedError();

  Instantiator visitArrayTypeRef(ArrayTypeRef node) =>
      throw UnimplementedError();

  Instantiator visitFunctionTypeRef(FunctionTypeRef node) =>
      throw UnimplementedError();

  Instantiator visitGenericTypeRef(GenericTypeRef node) =>
      throw UnimplementedError();

  Instantiator visitQualifiedTypeRef(QualifiedTypeRef node) =>
      throw UnimplementedError();

  Instantiator visitOptionalTypeRef(OptionalTypeRef node) =>
      throw UnimplementedError();

  Instantiator visitRecordTypeRef(RecordTypeRef node) =>
      throw UnimplementedError();

  Instantiator visitUnionTypeRef(UnionTypeRef node) =>
      throw UnimplementedError();

  @override
  Instantiator<DestructuredVariable> visitDestructuredVariable(
      DestructuredVariable node) {
    Instantiator<Identifier> makeName = visitNullable(node.name);
    Instantiator<Expression> makeProperty = visitNullable(node.property);
    Instantiator<BindingPattern> makeStructure = visitNullable(node.structure);
    Instantiator<Expression> makeDefaultValue =
        visitNullable(node.defaultValue);
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

  void visitNode(Node node) {
    int before = count;
    node.visitChildren(this);
    if (count != before) containsInterpolatedNode.add(node);
    return null;
  }

  visitInterpolatedNode(InterpolatedNode node) {
    containsInterpolatedNode.add(node);
    if (node.isNamed) holeNames.add(node.nameOrPosition as String);
    ++count;
  }
}
