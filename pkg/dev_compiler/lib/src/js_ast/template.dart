// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

class TemplateManager {
  Map<String, Template> expressionTemplates = new Map<String, Template>();
  Map<String, Template> statementTemplates = new Map<String, Template>();

  TemplateManager();

  Template lookupExpressionTemplate(String source) {
    return expressionTemplates[source];
  }

  Template defineExpressionTemplate(String source, Node ast) {
    Template template =
        new Template(source, ast, isExpression: true, forceCopy: false);
    expressionTemplates[source] = template;
    return template;
  }

  Template lookupStatementTemplate(String source) {
    return statementTemplates[source];
  }

  Template defineStatementTemplate(String source, Node ast) {
    Template template =
        new Template(source, ast, isExpression: false, forceCopy: false);
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
      {this.isExpression: true, this.forceCopy: false}) {
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
    InstantiatorGeneratorVisitor generator =
        new InstantiatorGeneratorVisitor(false);
    generator.compile(ast);
    return generator.analysis.count == 0;
  }

  void _compile() {
    InstantiatorGeneratorVisitor generator =
        new InstantiatorGeneratorVisitor(forceCopy);
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
      return instantiator(arguments);
    }
    assert(arguments is Map);
    if (holeNames.length < arguments.length) {
      // This search is in O(n), but we only do it in case of an error, and the
      // number of holes should be quite limited.
      String unusedNames =
          arguments.keys.where((name) => !holeNames.contains(name)).join(", ");
      throw "Template arguments has unused mappings: $unusedNames";
    }
    if (!holeNames.every((String name) => arguments.containsKey(name))) {
      String notFound =
          holeNames.where((name) => !arguments.containsKey(name)).join(", ");
      throw "Template arguments is missing mappings for: $notFound";
    }
    return instantiator(arguments);
  }
}

/**
 * An Instantiator is a Function that generates a JS AST tree or List of
 * trees. [arguments] is a List for positional templates, or Map for
 * named templates.
 */
typedef Instantiator(var arguments);

/**
 * InstantiatorGeneratorVisitor compiles a template.  This class compiles a tree
 * containing [InterpolatedNode]s into a function that will create a copy of the
 * tree with the interpolated nodes substituted with provided values.
 */
class InstantiatorGeneratorVisitor implements NodeVisitor<Instantiator> {
  final bool forceCopy;

  InterpolatedNodeAnalysis analysis = new InterpolatedNodeAnalysis();

  /**
   * The entire tree is cloned if [forceCopy] is true.
   */
  InstantiatorGeneratorVisitor(this.forceCopy);

  Instantiator compile(Node node) {
    analysis.visit(node);
    Instantiator result = visit(node);
    return result;
  }

  static error(String message) {
    throw message;
  }

  static Instantiator same(Node node) => (arguments) => node;
  static Node makeNull(arguments) => null;

  Instantiator visit(Node node) {
    if (forceCopy || analysis.containsInterpolatedNodes(node)) {
      return node.accept(this);
    }
    return same(node);
  }

  Instantiator visitNullable(Node node) {
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

  Instantiator visitInterpolatedExpression(InterpolatedExpression node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Expression) return value;
      if (value is String) return new Identifier(value);
      error('Interpolated value #$nameOrPosition is not an Expression: $value');
    };
  }

  Instantiator visitSplayableExpression(Node node) {
    if (node is InterpolatedExpression) {
      var nameOrPosition = node.nameOrPosition;
      return (arguments) {
        var value = arguments[nameOrPosition];
        Expression toExpression(item) {
          if (item is Expression) return item;
          if (item is String) return new Identifier(item);
          return error('Interpolated value #$nameOrPosition is not '
              'an Expression or List of Expressions: $value');
        }

        if (value is Iterable) return value.map(toExpression);
        return toExpression(value);
      };
    }
    return visit(node);
  }

  Instantiator visitInterpolatedLiteral(InterpolatedLiteral node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Literal) return value;
      error('Interpolated value #$nameOrPosition is not a Literal: $value');
    };
  }

  Instantiator visitInterpolatedParameter(InterpolatedParameter node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];

      Parameter toIdentifier(item) {
        if (item is Parameter) return item;
        if (item is String) return new Identifier(item);
        return error('Interpolated value #$nameOrPosition is not an Identifier'
            ' or List of Identifiers: $value');
      }

      if (value is Iterable) return value.map(toIdentifier);
      return toIdentifier(value);
    };
  }

  Instantiator visitInterpolatedSelector(InterpolatedSelector node) {
    // A selector is an expression, as in `a[selector]`.
    // A String argument converted into a LiteralString, so `a.#` with argument
    // 'foo' generates `a["foo"]` which prints as `a.foo`.
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Expression) return value;
      if (value is String) return new LiteralString('"$value"');
      error('Interpolated value #$nameOrPosition is not a selector: $value');
    };
  }

  Instantiator visitInterpolatedStatement(InterpolatedStatement node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      if (value is Node) return value.toStatement();
      error('Interpolated value #$nameOrPosition is not a Statement: $value');
    };
  }

  Instantiator visitInterpolatedMethod(InterpolatedMethod node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var value = arguments[nameOrPosition];
      Method toMethod(item) {
        if (item is Method) return item;
        return error('Interpolated value #$nameOrPosition is not a Method '
            'or List of Methods: $value');
      }

      if (value is Iterable) return value.map(toMethod);
      return toMethod(value);
    };
  }

  Instantiator visitInterpolatedIdentifier(InterpolatedIdentifier node) {
    var nameOrPosition = node.nameOrPosition;
    return (arguments) {
      var item = arguments[nameOrPosition];
      if (item is Identifier) return item;
      if (item is String) return new Identifier(item);
      return error('Interpolated value #$nameOrPosition is not a '
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
          ;
          return error('Interpolated value #$nameOrPosition is not '
              'a Statement or List of Statements: $value');
        }

        if (value is Iterable) return value.map(toStatement);
        return toStatement(value);
      };
    }
    return visit(node);
  }

  Instantiator visitProgram(Program node) {
    List instantiators = node.body.map(visitSplayableStatement).toList();
    return (arguments) {
      List<Statement> statements = <Statement>[];
      void add(node) {
        if (node is EmptyStatement) return;
        if (node is Iterable) {
          for (var n in node) statements.add(n);
        } else {
          statements.add(node.toStatement());
        }
      }

      for (Instantiator instantiator in instantiators) {
        add(instantiator(arguments));
      }
      return new Program(statements);
    };
  }

  Instantiator visitBlock(Block node) {
    List instantiators = node.statements.map(visitSplayableStatement).toList();
    return (arguments) {
      List<Statement> statements = <Statement>[];
      void add(node) {
        if (node is EmptyStatement) return;
        if (node is Iterable) {
          for (var n in node) statements.add(n);
        } else if (node is Block) {
          statements.addAll(node.statements);
        } else {
          statements.add(node.toStatement());
        }
      }

      for (Instantiator instantiator in instantiators) {
        add(instantiator(arguments));
      }
      return new Block(statements);
    };
  }

  Instantiator visitExpressionStatement(ExpressionStatement node) {
    Instantiator buildExpression = visit(node.expression);
    return (arguments) {
      return buildExpression(arguments).toStatement();
    };
  }

  Instantiator visitEmptyStatement(EmptyStatement node) =>
      (arguments) => new EmptyStatement();

  Instantiator visitIf(If node) {
    if (node.condition is InterpolatedExpression) {
      return visitIfConditionalCompilation(node);
    } else {
      return visitIfNormal(node);
    }
  }

  Instantiator visitIfConditionalCompilation(If node) {
    // Special version of visitInterpolatedExpression that permits bools.
    compileCondition(InterpolatedExpression node) {
      var nameOrPosition = node.nameOrPosition;
      return (arguments) {
        var value = arguments[nameOrPosition];
        if (value is bool) return value;
        if (value is Expression) return value;
        if (value is String) return new Identifier(value);
        error('Interpolated value #$nameOrPosition '
            'is not an Expression: $value');
      };
    }

    var makeCondition = compileCondition(node.condition);
    Instantiator makeThen = visit(node.then);
    Instantiator makeOtherwise = visit(node.otherwise);
    return (arguments) {
      var condition = makeCondition(arguments);
      if (condition is bool) {
        if (condition == true) {
          return makeThen(arguments);
        } else {
          return makeOtherwise(arguments);
        }
      }
      return new If(condition, makeThen(arguments), makeOtherwise(arguments));
    };
  }

  Instantiator visitIfNormal(If node) {
    Instantiator makeCondition = visit(node.condition);
    Instantiator makeThen = visit(node.then);
    Instantiator makeOtherwise = visit(node.otherwise);
    return (arguments) {
      return new If(makeCondition(arguments), makeThen(arguments),
          makeOtherwise(arguments));
    };
  }

  Instantiator visitFor(For node) {
    Instantiator makeInit = visitNullable(node.init);
    Instantiator makeCondition = visitNullable(node.condition);
    Instantiator makeUpdate = visitNullable(node.update);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new For(makeInit(arguments), makeCondition(arguments),
          makeUpdate(arguments), makeBody(arguments));
    };
  }

  Instantiator visitForIn(ForIn node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    Instantiator makeObject = visit(node.object);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new ForIn(makeLeftHandSide(arguments), makeObject(arguments),
          makeBody(arguments));
    };
  }

  Instantiator visitForOf(ForOf node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    Instantiator makeObject = visit(node.iterable);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new ForOf(makeLeftHandSide(arguments), makeObject(arguments),
          makeBody(arguments));
    };
  }

  TODO(String name) {
    throw new UnimplementedError('$this.$name');
  }

  Instantiator visitWhile(While node) {
    Instantiator makeCondition = visit(node.condition);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new While(makeCondition(arguments), makeBody(arguments));
    };
  }

  Instantiator visitDo(Do node) {
    Instantiator makeBody = visit(node.body);
    Instantiator makeCondition = visit(node.condition);
    return (arguments) {
      return new Do(makeBody(arguments), makeCondition(arguments));
    };
  }

  Instantiator visitContinue(Continue node) =>
      (arguments) => new Continue(node.targetLabel);

  Instantiator visitBreak(Break node) =>
      (arguments) => new Break(node.targetLabel);

  Instantiator visitReturn(Return node) {
    Instantiator makeExpression = visitNullable(node.value);
    return (arguments) => new Return(makeExpression(arguments));
  }

  Instantiator visitDartYield(DartYield node) {
    Instantiator makeExpression = visit(node.expression);
    return (arguments) =>
        new DartYield(makeExpression(arguments), node.hasStar);
  }

  Instantiator visitThrow(Throw node) {
    Instantiator makeExpression = visit(node.expression);
    return (arguments) => new Throw(makeExpression(arguments));
  }

  Instantiator visitTry(Try node) {
    Instantiator makeBody = visit(node.body);
    Instantiator makeCatch = visitNullable(node.catchPart);
    Instantiator makeFinally = visitNullable(node.finallyPart);
    return (arguments) => new Try(
        makeBody(arguments), makeCatch(arguments), makeFinally(arguments));
  }

  Instantiator visitCatch(Catch node) {
    Instantiator makeDeclaration = visit(node.declaration);
    Instantiator makeBody = visit(node.body);
    return (arguments) =>
        new Catch(makeDeclaration(arguments), makeBody(arguments));
  }

  Instantiator visitSwitch(Switch node) {
    Instantiator makeKey = visit(node.key);
    Iterable<Instantiator> makeCases = node.cases.map(visit);
    return (arguments) {
      return new Switch(
          makeKey(arguments),
          makeCases
              .map((makeCase) => makeCase(arguments) as SwitchClause)
              .toList());
    };
  }

  Instantiator visitCase(Case node) {
    Instantiator makeExpression = visit(node.expression);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new Case(makeExpression(arguments), makeBody(arguments));
    };
  }

  Instantiator visitDefault(Default node) {
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new Default(makeBody(arguments));
    };
  }

  Instantiator visitFunctionDeclaration(FunctionDeclaration node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeFunction = visit(node.function);
    return (arguments) =>
        new FunctionDeclaration(makeName(arguments), makeFunction(arguments));
  }

  Instantiator visitLabeledStatement(LabeledStatement node) {
    Instantiator makeBody = visit(node.body);
    return (arguments) => new LabeledStatement(node.label, makeBody(arguments));
  }

  Instantiator visitLiteralStatement(LiteralStatement node) =>
      TODO('visitLiteralStatement');
  Instantiator visitLiteralExpression(LiteralExpression node) =>
      TODO('visitLiteralExpression');

  Instantiator visitVariableDeclarationList(VariableDeclarationList node) {
    List<Instantiator> declarationMakers =
        node.declarations.map(visit).toList();
    return (arguments) {
      List<VariableInitialization> declarations = <VariableInitialization>[];
      for (Instantiator instantiator in declarationMakers) {
        var result = instantiator(arguments);
        declarations.add(result);
      }
      return new VariableDeclarationList(node.keyword, declarations);
    };
  }

  Instantiator visitAssignment(Assignment node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    String op = node.op;
    Instantiator makeValue = visitNullable(node.value);
    return (arguments) {
      return new Assignment.compound(
          makeLeftHandSide(arguments), op, makeValue(arguments));
    };
  }

  Instantiator visitVariableInitialization(VariableInitialization node) {
    Instantiator makeDeclaration = visit(node.declaration);
    Instantiator makeValue = visitNullable(node.value);
    return (arguments) {
      return new VariableInitialization(
          makeDeclaration(arguments), makeValue(arguments));
    };
  }

  Instantiator visitConditional(Conditional cond) {
    Instantiator makeCondition = visit(cond.condition);
    Instantiator makeThen = visit(cond.then);
    Instantiator makeOtherwise = visit(cond.otherwise);
    return (arguments) => new Conditional(makeCondition(arguments),
        makeThen(arguments), makeOtherwise(arguments));
  }

  Instantiator visitNew(New node) => handleCallOrNew(node,
      (target, arguments) => new New(target, arguments as List<Expression>));

  Instantiator visitCall(Call node) => handleCallOrNew(node,
      (target, arguments) => new Call(target, arguments as List<Expression>));

  Instantiator handleCallOrNew(Call node, finish(target, arguments)) {
    Instantiator makeTarget = visit(node.target);
    Iterable<Instantiator> argumentMakers =
        node.arguments.map(visitSplayableExpression).toList();

    // TODO(sra): Avoid copying call arguments if no interpolation or forced
    // copying.
    return (arguments) {
      Node target = makeTarget(arguments);
      List<Expression> callArguments = <Expression>[];
      for (Instantiator instantiator in argumentMakers) {
        var result = instantiator(arguments);
        if (result is Iterable) {
          for (var r in result) callArguments.add(r);
        } else {
          callArguments.add(result);
        }
      }
      return finish(target, callArguments.toList(growable: false));
    };
  }

  Instantiator visitBinary(Binary node) {
    Instantiator makeLeft = visit(node.left);
    Instantiator makeRight = visit(node.right);
    String op = node.op;
    return (arguments) =>
        new Binary(op, makeLeft(arguments), makeRight(arguments));
  }

  Instantiator visitPrefix(Prefix node) {
    Instantiator makeOperand = visit(node.argument);
    String op = node.op;
    return (arguments) => new Prefix(op, makeOperand(arguments));
  }

  Instantiator visitPostfix(Postfix node) {
    Instantiator makeOperand = visit(node.argument);
    String op = node.op;
    return (arguments) => new Postfix(op, makeOperand(arguments));
  }

  Instantiator visitThis(This node) => (arguments) => new This();
  Instantiator visitSuper(Super node) => (arguments) => new Super();

  Instantiator visitIdentifier(Identifier node) =>
      (arguments) => new Identifier(node.name);

  Instantiator visitSpread(Spread node) =>
      (args) => new Spread(visit(node.argument)(args));

  Instantiator visitYield(Yield node) =>
      (args) => new Yield(node.value != null ? visit(node.value)(args) : null,
          star: node.star);

  Instantiator visitRestParameter(RestParameter node) =>
      (args) => new RestParameter(visit(node.parameter)(args));

  Instantiator visitAccess(PropertyAccess node) {
    Instantiator makeReceiver = visit(node.receiver);
    Instantiator makeSelector = visit(node.selector);
    return (arguments) =>
        new PropertyAccess(makeReceiver(arguments), makeSelector(arguments));
  }

  Instantiator visitNamedFunction(NamedFunction node) {
    Instantiator makeDeclaration = visit(node.name);
    Instantiator makeFunction = visit(node.function);
    return (arguments) =>
        new NamedFunction(makeDeclaration(arguments), makeFunction(arguments));
  }

  Instantiator visitFunctionExpression(FunctionExpression node) {
    List<Instantiator> paramMakers = node.params.map(visitSplayable).toList();
    Instantiator makeBody = visit(node.body);
    // TODO(sra): Avoid copying params if no interpolation or forced copying.
    return (arguments) {
      List<Parameter> params = <Parameter>[];
      for (Instantiator instantiator in paramMakers) {
        var result = instantiator(arguments);
        if (result is Iterable) {
          for (var r in result) params.add(r);
        } else {
          params.add(result);
        }
      }
      var body = makeBody(arguments);
      if (node is ArrowFun) {
        return new ArrowFun(params, body);
      } else if (node is Fun) {
        return new Fun(params, body,
            isGenerator: node.isGenerator, asyncModifier: node.asyncModifier);
      } else {
        throw "Unknown FunctionExpression type ${node.runtimeType}: $node";
      }
    };
  }

  Instantiator visitFun(Fun node) => visitFunctionExpression(node);

  Instantiator visitArrowFun(ArrowFun node) => visitFunctionExpression(node);

  Instantiator visitLiteralBool(LiteralBool node) =>
      (arguments) => new LiteralBool(node.value);

  Instantiator visitLiteralString(LiteralString node) =>
      (arguments) => new LiteralString(node.value);

  Instantiator visitLiteralNumber(LiteralNumber node) =>
      (arguments) => new LiteralNumber(node.value);

  Instantiator visitLiteralNull(LiteralNull node) =>
      (arguments) => new LiteralNull();

  Instantiator visitArrayInitializer(ArrayInitializer node) {
    // TODO(sra): Implement splicing?
    List<Instantiator> elementMakers =
        node.elements.map(visit).toList(growable: false);
    return (arguments) {
      List<Expression> elements = elementMakers
          .map((instantiator) => instantiator(arguments) as Expression)
          .toList(growable: false);
      return new ArrayInitializer(elements);
    };
  }

  Instantiator visitArrayHole(ArrayHole node) {
    return (arguments) => new ArrayHole();
  }

  Instantiator visitObjectInitializer(ObjectInitializer node) {
    List<Instantiator> propertyMakers =
        node.properties.map(visitSplayable).toList();
    return (arguments) {
      List<Property> properties = <Property>[];
      for (Instantiator instantiator in propertyMakers) {
        var result = instantiator(arguments);
        if (result is Iterable) {
          for (var r in result) properties.add(r);
        } else {
          properties.add(result);
        }
      }
      return new ObjectInitializer(properties);
    };
  }

  Instantiator visitProperty(Property node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeValue = visit(node.value);
    return (arguments) {
      return new Property(makeName(arguments), makeValue(arguments));
    };
  }

  Instantiator visitRegExpLiteral(RegExpLiteral node) =>
      (arguments) => new RegExpLiteral(node.pattern);

  Instantiator visitTemplateString(TemplateString node) {
    Iterable<Instantiator> makeElements = node.interpolations.map(visit);
    return (arguments) => new TemplateString(node.strings,
        makeElements.map((m) => m(arguments)).toList(growable: false));
  }

  Instantiator visitTaggedTemplate(TaggedTemplate node) {
    Instantiator makeTag = visit(node.tag);
    Instantiator makeTemplate = visit(node.template);
    return (arguments) {
      return new TaggedTemplate(makeTag(arguments), makeTemplate(arguments));
    };
  }

  Instantiator visitClassDeclaration(ClassDeclaration node) {
    Instantiator makeClass = visit(node.classExpr);
    return (arguments) {
      return new ClassDeclaration(makeClass(arguments));
    };
  }

  Instantiator visitClassExpression(ClassExpression node) {
    List<Instantiator> makeMethods =
        node.methods.map(visitSplayableExpression).toList(growable: true);
    Instantiator makeName = visit(node.name);
    Instantiator makeHeritage = visit(node.heritage);

    return (arguments) {
      var methods = <Method>[];
      for (Instantiator instantiator in makeMethods) {
        var result = instantiator(arguments);
        if (result is Iterable) {
          for (var r in result) methods.add(r);
        } else {
          methods.add(result);
        }
      }
      return new ClassExpression(
          makeName(arguments), makeHeritage(arguments), methods);
    };
  }

  Instantiator visitMethod(Method node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeFunction = visit(node.function);
    return (arguments) {
      return new Method(makeName(arguments), makeFunction(arguments),
          isGetter: node.isGetter,
          isSetter: node.isSetter,
          isStatic: node.isStatic);
    };
  }

  Instantiator visitComment(Comment node) =>
      (arguments) => new Comment(node.comment);

  Instantiator visitCommentExpression(CommentExpression node) {
    Instantiator makeExpr = visit(node.expression);
    return (arguments) {
      return new CommentExpression(node.comment, makeExpr(arguments));
    };
  }

  Instantiator visitAwait(Await node) {
    Instantiator makeExpression = visit(node.expression);
    return (arguments) {
      return new Await(makeExpression(arguments));
    };
  }

  // Note: these are not supported yet in the interpolation grammar.
  Instantiator visitModule(Module node) => throw new UnimplementedError();
  Instantiator visitNameSpecifier(NameSpecifier node) =>
      throw new UnimplementedError();

  Instantiator visitImportDeclaration(ImportDeclaration node) =>
      throw new UnimplementedError();

  Instantiator visitExportDeclaration(ExportDeclaration node) =>
      throw new UnimplementedError();

  Instantiator visitExportClause(ExportClause node) =>
      throw new UnimplementedError();

  Instantiator visitAnyTypeRef(AnyTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitUnknownTypeRef(UnknownTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitArrayTypeRef(ArrayTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitFunctionTypeRef(FunctionTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitGenericTypeRef(GenericTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitQualifiedTypeRef(QualifiedTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitOptionalTypeRef(OptionalTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitRecordTypeRef(RecordTypeRef node) =>
      throw new UnimplementedError();

  Instantiator visitUnionTypeRef(UnionTypeRef node) =>
      throw new UnimplementedError();

  @override
  Instantiator visitDestructuredVariable(DestructuredVariable node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeStructure = visit(node.structure);
    Instantiator makeDefaultValue = visit(node.defaultValue);
    return (arguments) {
      return new DestructuredVariable(
          name: makeName(arguments),
          structure: makeStructure(arguments),
          defaultValue: makeDefaultValue(arguments));
    };
  }

  @override
  Instantiator visitArrayBindingPattern(ArrayBindingPattern node) {
    List<Instantiator> makeVars = node.variables.map(this.visit).toList();
    return (arguments) {
      return new ArrayBindingPattern(
          makeVars.map((m) => m(arguments) as DestructuredVariable).toList());
    };
  }

  @override
  Instantiator visitObjectBindingPattern(ObjectBindingPattern node) {
    List<Instantiator> makeVars = node.variables.map(this.visit).toList();
    return (arguments) {
      return new ObjectBindingPattern(
          makeVars.map((m) => m(arguments) as DestructuredVariable).toList());
    };
  }

  @override
  Instantiator visitSimpleBindingPattern(SimpleBindingPattern node) =>
      (arguments) => new SimpleBindingPattern(new Identifier(node.name.name));
}

/**
 * InterpolatedNodeAnalysis determines which AST trees contain
 * [InterpolatedNode]s, and the names of the named interpolated nodes.
 */
class InterpolatedNodeAnalysis extends BaseVisitor {
  final Set<Node> containsInterpolatedNode = new Set<Node>();
  final Set<String> holeNames = new Set<String>();
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
    if (node.isNamed) holeNames.add(node.nameOrPosition);
    ++count;
  }
}
