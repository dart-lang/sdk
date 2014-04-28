// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js;

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
  // TODO(sra): Named arguments.

  Template(this.source, this.ast,
           {this.isExpression: true, this.forceCopy: false}) {
    _compile();
  }

  Template.withExpressionResult(this.ast)
      : source = null, isExpression = true, forceCopy = false {
    assert(ast is Expression);
    assert(_checkNoPlaceholders());
    positionalArgumentCount = 0;
    instantiator = (arguments) => ast;
  }

  Template.withStatementResult(this.ast)
      : source = null, isExpression = false, forceCopy = false {
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
  }

  Node instantiate(List arguments) {
    if (arguments is List) {
      if (arguments.length != positionalArgumentCount) {
        throw 'Wrong number of template arguments, given ${arguments.length}, '
            'expected $positionalArgumentCount';
      }
      return instantiator(arguments);
    }
    // TODO(sra): Add named placeholders and a Map of arguments.
    throw new UnimplementedError('Template arguments must be a list');
  }
}

/**
 * An Instantiator is a Function that generates a JS AST tree or List of
 * trees. [arguments] is a List for positional templates, or (TODO) Map for
 * named templates.
 */
typedef Node Instantiator(var arguments);


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

  static RegExp identiferRE = new RegExp(r'^[A-Za-z_$][A-Za-z_$0-9]*$');

  static Expression convertStringToVariableUse(String value) {
    assert(identiferRE.hasMatch(value));
    return new VariableUse(value);
  }

  Instantiator visitInterpolatedExpression(InterpolatedExpression node) {
    int position = node.name;
    return (arguments) {
      var value = arguments[position];
      if (value is Expression) return value;
      if (value is String) return convertStringToVariableUse(value);;
      error('Interpolated value #$position is not an Expression: $value');
    };
  }

  Instantiator visitSplayableExpression(Node node) {
    if (node is InterpolatedExpression) {
      int position = node.name;
      return (arguments) {
        var value = arguments[position];
        Expression toExpression(item) {
          if (item is Expression) return item;
          if (item is String) return convertStringToVariableUse(item);
          error('Interpolated value #$position is not '
              'an Expression or List of Expressions: $value');
        }
        if (value is Iterable) return value.map(toExpression);
        return toExpression(value);
      };
    }
    return visit(node);
  }

  Instantiator visitInterpolatedLiteral(InterpolatedLiteral node) {
    int position = node.name;
    return (arguments) {
      var value = arguments[position];
      if (value is Literal) return value;
      error('Interpolated value #$position is not a Literal: '
          '$value  (${value.runtimeType})');
    };
  }

  Instantiator visitInterpolatedParameter(InterpolatedParameter node) {
    int position = node.name;
    return (arguments) {
      var value = arguments[position];

      Parameter toParameter(item) {
        if (item is Parameter) return item;
        if (item is String) return new Parameter(item);
        error('Interpolated value #$position is not a Parameter or '
            'List of Parameters: $value  (a ${value.runtimeType})');
      }
      if (value is Iterable) return value.map(toParameter);
      return toParameter(value);
    };
  }

  Instantiator visitInterpolatedSelector(InterpolatedSelector node) {
    // A selector is an expression, as in `a[selector]`.
    // A String argument converted into a LiteralString, so `a.#` with argument
    // 'foo' generates `a["foo"]` which prints as `a.foo`.
    int position = node.name;
    return (arguments) {
      var value = arguments[position];
      if (value is Expression) return value;
      if (value is String) return new LiteralString('"$value"');
      error('Interpolated value #$position is not a selector: $value');
    };
  }

  Instantiator visitInterpolatedStatement(InterpolatedStatement node) {
    int position = node.name;
    return (arguments) {
      var value = arguments[position];
      if (value is Node) return value.toStatement();
      error('Interpolated value #$position is not a Statement: $value');
    };
  }

  Instantiator visitSplayableStatement(Node node) {
    if (node is InterpolatedStatement) {
      int position = node.name;
      return (arguments) {
        var value = arguments[position];
        Statement toStatement(item) {
          if (item is Statement) return item;
          if (item is Expression) return item.toStatement();;
          error('Interpolated value #$position is not '
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
          statements.addAll(node);
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
          statements.addAll(node);
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
      int position = node.name;
      return (arguments) {
        var value = arguments[position];
        if (value is bool) return value;
        if (value is Expression) return value;
        if (value is String) return convertStringToVariableUse(value);;
        error('Interpolated value #$position is not an Expression: $value');
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
      return new If(
          condition,
          makeThen(arguments),
          makeOtherwise(arguments));
    };
  }

  Instantiator visitIfNormal(If node) {
    Instantiator makeCondition = visit(node.condition);
    Instantiator makeThen = visit(node.then);
    Instantiator makeOtherwise = visit(node.otherwise);
    return (arguments) {
      return new If(
          makeCondition(arguments),
          makeThen(arguments),
          makeOtherwise(arguments));
    };
  }

  Instantiator visitFor(For node) {
    Instantiator makeInit = visitNullable(node.init);
    Instantiator makeCondition = visitNullable(node.condition);
    Instantiator makeUpdate = visitNullable(node.update);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new For(
          makeInit(arguments), makeCondition(arguments), makeUpdate(arguments),
          makeBody(arguments));
    };
  }

  Instantiator visitForIn(ForIn node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    Instantiator makeObject = visit(node.object);
    Instantiator makeBody = visit(node.body);
    return (arguments) {
      return new ForIn(
          makeLeftHandSide(arguments),
          makeObject(arguments),
          makeBody(arguments));
    };
  }

  TODO(String name) {
    throw new UnimplementedError('${this.runtimeType}.$name');
  }

  Instantiator visitWhile(While node) => TODO('visitWhile');
  Instantiator visitDo(Do node) => TODO('visitDo');

  Instantiator visitContinue(Continue node) =>
      (arguments) => new Continue(node.targetLabel);

  Instantiator visitBreak(Break node) =>
      (arguments) => new Break(node.targetLabel);

  Instantiator visitReturn(Return node) {
    Instantiator makeExpression = visitNullable(node.value);
    return (arguments) => new Return(makeExpression(arguments));
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
    return (arguments) => new Catch(
        makeDeclaration(arguments), makeBody(arguments));
  }

  Instantiator visitSwitch(Switch node) => TODO('visitSwitch');
  Instantiator visitCase(Case node) => TODO('visitCase');
  Instantiator visitDefault(Default node) => TODO('visitDefault');

  Instantiator visitFunctionDeclaration(FunctionDeclaration node) {
    Instantiator makeName = visit(node.name);
    Instantiator makeFunction = visit(node.function);
    return (arguments) =>
        new FunctionDeclaration(makeName(arguments), makeFunction(arguments));
  }

  Instantiator visitLabeledStatement(LabeledStatement node) =>
      TODO('visitLabeledStatement');
  Instantiator visitLiteralStatement(LiteralStatement node) =>
      TODO('visitLiteralStatement');
  Instantiator visitBlob(Blob node) =>
      TODO('visitBlob');
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
      return new VariableDeclarationList(declarations);
    };
  }

  Instantiator visitSequence(Sequence node) => TODO('visitSequence');

  Instantiator visitAssignment(Assignment node) {
    Instantiator makeLeftHandSide = visit(node.leftHandSide);
    String op = node.op;
    Instantiator makeValue = visitNullable(node.value);
    return (arguments) {
      return new Assignment.compound(
          makeLeftHandSide(arguments),
          op,
          makeValue(arguments));
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
    return (arguments) => new Conditional(
        makeCondition(arguments),
        makeThen(arguments),
        makeOtherwise(arguments));
  }

  Instantiator visitNew(New node) =>
      handleCallOrNew(node, (target, arguments) => new New(target, arguments));

  Instantiator visitCall(Call node) =>
      handleCallOrNew(node, (target, arguments) => new Call(target, arguments));

  Instantiator handleCallOrNew(Call node, finish(target, arguments)) {
    Instantiator makeTarget = visit(node.target);
    Iterable<Instantiator> argumentMakers =
        node.arguments.map(visitSplayableExpression).toList();

    return (arguments) {
      Node target = makeTarget(arguments);
      List<Expression> callArguments = <Expression>[];
      for (Instantiator instantiator in argumentMakers) {
        var result = instantiator(arguments);
        if (result is Iterable) {
          callArguments.addAll(result);
        } else {
          callArguments.add(result);
        }
      }
      return finish(target, callArguments);
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

  Instantiator visitVariableUse(VariableUse node) =>
      (arguments) => new VariableUse(node.name);

  Instantiator visitThis(This node) => (arguments) => new This();

  Instantiator visitVariableDeclaration(VariableDeclaration node) =>
      (arguments) => new VariableDeclaration(node.name);

  Instantiator visitParameter(Parameter node) =>
      (arguments) => new Parameter(node.name);

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

  Instantiator visitFun(Fun node) {
    List<Instantiator> paramMakers = node.params.map(visitSplayable).toList();
    Instantiator makeBody = visit(node.body);
    // TODO(sra): Avoid copying params if no interpolation or forced copying.
    return (arguments) {
      List<Parameter> params = <Parameter>[];
      for (Instantiator instantiator in paramMakers) {
        var result = instantiator(arguments);
        if (result is Iterable) {
          params.addAll(result);
        } else {
          params.add(result);
        }
      }
      Statement body = makeBody(arguments);
      return new Fun(params, body);
    };
  }

  Instantiator visitLiteralBool(LiteralBool node) =>
      (arguments) => new LiteralBool(node.value);

  Instantiator visitLiteralString(LiteralString node) =>
      (arguments) => new LiteralString(node.value);

  Instantiator visitLiteralNumber(LiteralNumber node) =>
      (arguments) => new LiteralNumber(node.value);

  Instantiator visitLiteralNull(LiteralNull node) =>
      (arguments) => new LiteralNull();

  Instantiator visitArrayInitializer(ArrayInitializer node) {
    // Assume array has no missing elements.
    // TODO(sra): Splicing?
    List<Instantiator> elementMakers = node.elements
        .map((ArrayElement element) => visit(element.value))
        .toList();
    return (arguments) {
      List<ArrayElement> elements = <ArrayElement>[];
      void add(Expression value) {
        elements.add(new ArrayElement(elements.length, value));
      }
      for (Instantiator instantiator in elementMakers) {
        var result = instantiator(arguments);
        add(result);
      }
      return new ArrayInitializer(elements.length, elements);
    };
  }

  Instantiator visitArrayElement(ArrayElement node) {
    throw 'Should not get here'; // Handled in visitArrayInitializer.
  }

  Instantiator visitObjectInitializer(ObjectInitializer node) {
    List<Instantiator> propertyMakers =
        node.properties.map(visitSplayable).toList();
    bool isOneLiner = node.isOneLiner;
    return (arguments) {
      List<Property> properties = <Property>[];
      for (Instantiator instantiator in propertyMakers) {
        var result = instantiator(arguments);
        if (result is Iterable) {
          properties.addAll(result);
        } else {
          properties.add(result);
        }
      }
      return new ObjectInitializer(properties, isOneLiner: isOneLiner);
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

  Instantiator visitComment(Comment node) => TODO('visitComment');
}

/**
 * InterpolatedNodeAnalysis extract [InterpolatedNode]s from AST.
 */
class InterpolatedNodeAnalysis extends BaseVisitor {
  final Set<Node> containsInterpolatedNode = new Set<Node>();
  final List<InterpolatedNode> interpolatedNodes = <InterpolatedNode>[];
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
    interpolatedNodes.add(node);
    containsInterpolatedNode.add(node);
    ++count;
  }
}
