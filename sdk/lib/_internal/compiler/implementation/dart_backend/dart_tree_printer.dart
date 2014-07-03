// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_tree_printer;

import 'dart_printer.dart';
import '../tree/tree.dart' as tree;
import '../scanner/scannerlib.dart';
import '../util/util.dart';
import '../dart2jslib.dart' as dart2js;
import '../elements/elements.dart' as elements;
import '../dart_types.dart' as types;

/// If true, the unparser will insert a coment in front of every function
/// it emits. This helps indicate which functions were translated by the new
/// backend.
const bool INSERT_NEW_BACKEND_COMMENT = true;

/// Converts backend ASTs to frontend ASTs.
class TreePrinter {
  dart2js.TreeElementMapping treeElements;

  TreePrinter([this.treeElements]);

  void setElement(tree.Node node, elements.Element element, source) {
    if (treeElements != null) {
      if (element == null) {
        throw "Missing element from ${source}";
      }
      treeElements[node] = element;
    }
  }

  void setType(tree.Node node, types.DartType type, source) {
    if (treeElements != null) {
      if (type == null) {
        throw "Missing type from ${source}";
      }
      treeElements.setType(node, type);
    }
  }

  // Group tokens: () [] {} <>
  static BeginGroupToken makeGroup(PrecedenceInfo open, PrecedenceInfo close) {
    BeginGroupToken openTok = new BeginGroupToken(open, -1);
    openTok.endGroup = new SymbolToken(close, -1);
    return openTok;
  }

  final BeginGroupToken openParen = makeGroup(OPEN_PAREN_INFO,
                                              CLOSE_PAREN_INFO);
  final BeginGroupToken openBrace = makeGroup(OPEN_CURLY_BRACKET_INFO,
                                              CLOSE_CURLY_BRACKET_INFO);
  final BeginGroupToken openBracket = makeGroup(OPEN_SQUARE_BRACKET_INFO,
                                                CLOSE_SQUARE_BRACKET_INFO);
  final BeginGroupToken lt = makeGroup(LT_INFO, GT_INFO);

  Token get closeParen => openParen.endGroup;
  Token get closeBrace => openBrace.endGroup;
  Token get closeBracket => openBracket.endGroup;
  Token get gt => lt.endGroup;

  // Symbol tokens
  final Token semicolon = new SymbolToken(SEMICOLON_INFO, -1);
  final Token indexToken = new SymbolToken(INDEX_INFO, -1); // "[]"
  final Token question = new SymbolToken(QUESTION_INFO, -1);
  final Token colon = new SymbolToken(COLON_INFO, -1);
  final Token hash = new SymbolToken(HASH_INFO, -1);
  final Token bang = new SymbolToken(BANG_INFO, -1);
  final Token eq = new SymbolToken(EQ_INFO, -1);

  // Keyword tokens
  static Token makeIdToken(String text) {
    return new StringToken.fromString(IDENTIFIER_INFO, text, -1);
  }
  final Token newToken = makeIdToken('new');
  final Token constToken = makeIdToken('const');
  final Token throwToken = makeIdToken('throw');
  final Token rethrowToken = makeIdToken('rethrow');
  final Token breakToken = makeIdToken('break');
  final Token continueToken = makeIdToken('continue');
  final Token doToken = makeIdToken('do');
  final Token whileToken = makeIdToken('while');
  final Token ifToken = makeIdToken('if');
  final Token elseToken = makeIdToken('else');
  final Token forToken = makeIdToken('for');
  final Token inToken = makeIdToken('in');
  final Token returnToken = makeIdToken('return');
  final Token switchToken = makeIdToken('switch');
  final Token caseToken = makeIdToken('case');
  final Token defaultToken = makeIdToken('default');
  final Token tryToken = makeIdToken('try');
  final Token catchToken = makeIdToken('catch');
  final Token onToken = makeIdToken('on');
  final Token finallyToken = makeIdToken('finally');

  static tree.Identifier makeIdentifier(String name) {
    return new tree.Identifier(
        new StringToken.fromString(IDENTIFIER_INFO, name, -1));
  }

  static tree.Operator makeOperator(String name) {
    return new tree.Operator(
        new StringToken.fromString(IDENTIFIER_INFO, name, -1));
  }

  // Utilities for creating NodeLists
  Link<tree.Node> makeLink(Iterable<tree.Node> nodes) {
    LinkBuilder builder = new LinkBuilder();
    for (tree.Node node in nodes) {
      builder.addLast(node);
    }
    return builder.toLink();
  }

  tree.NodeList blankList() {
    return new tree.NodeList(null, makeLink([]), null, '');
  }
  tree.NodeList singleton(tree.Node node) {
    return new tree.NodeList(null, makeLink([node]), null, '');
  }
  tree.NodeList makeList(String delimiter,
                         Iterable<tree.Node> nodes,
                         { Token open,
                           Token close }) {
    return new tree.NodeList(open, makeLink(nodes), close, delimiter);
  }
  tree.NodeList parenList(String delimiter, Iterable<tree.Node> nodes) {
    return makeList(delimiter, nodes, open: openParen, close: closeParen);
  }
  tree.NodeList bracketList(String delimiter, Iterable<tree.Node> nodes) {
    return makeList(delimiter, nodes, open: openBracket, close: closeBracket);
  }
  tree.NodeList braceList(String delimiter, Iterable<tree.Node> nodes) {
    return makeList(delimiter, nodes, open: openBrace, close: closeBrace);
  }
  tree.NodeList argList(Iterable<tree.Node> nodes) {
    return parenList(',', nodes);
  }
  tree.NodeList typeArgList(Iterable<tree.Node> nodes) {
    return makeList(',', nodes, open: lt, close: gt);
  }

  /// Converts a qualified name into nested Sends.
  tree.Node makeName(String name) {
    if (name == null) {
      return null;
    }
    List<String> names = name.split('.').toList(growable:false);
    tree.Node node = makeIdentifier(names[0]);
    for (int i = 1; i < names.length; i++) {
      node = new tree.Send(node, makeIdentifier(names[i]));
    }
    return node;
  }

  static Token assignmentToken(String operatorName) {
    switch (operatorName) {
      case '=': return new SymbolToken(EQ_INFO, -1);
      case '+=': return new SymbolToken(PLUS_EQ_INFO, -1);
      case '-=': return new SymbolToken(MINUS_EQ_INFO, -1);
      case '*=': return new SymbolToken(STAR_EQ_INFO, -1);
      case '/=': return new SymbolToken(SLASH_EQ_INFO, -1);
      case '~/=': return new SymbolToken(TILDE_SLASH_EQ_INFO, -1);
      case '%=': return new SymbolToken(PERCENT_EQ_INFO, -1);
      case '&=': return new SymbolToken(AMPERSAND_EQ_INFO, -1);
      case '^=': return new SymbolToken(CARET_EQ_INFO, -1);
      case '|=': return new SymbolToken(BAR_EQ_INFO, -1);
      case '>>=': return new SymbolToken(GT_GT_EQ_INFO, -1);
      case '<<=': return new SymbolToken(LT_LT_EQ_INFO, -1);
      default:
        throw "Unrecognized assignment operator: $operatorName";
    }
  }

  static Token binopToken(String operatorName) {
    switch (operatorName) {
      case '+': return new SymbolToken(PLUS_INFO, -1);
      case '-': return new SymbolToken(MINUS_INFO, -1);
      case '*': return new SymbolToken(STAR_INFO, -1);
      case '/': return new SymbolToken(SLASH_INFO, -1);
      case '~/': return new SymbolToken(TILDE_SLASH_INFO, -1);
      case '%': return new SymbolToken(PERCENT_INFO, -1);
      case '&': return new SymbolToken(AMPERSAND_INFO, -1);
      case '^': return new SymbolToken(CARET_INFO, -1);
      case '|': return new SymbolToken(BAR_INFO, -1);
      case '>>': return new SymbolToken(GT_GT_INFO, -1);
      case '<<': return new SymbolToken(LT_LT_INFO, -1);
      case '==': return new SymbolToken(EQ_EQ_INFO, -1);
      case '!=': return new SymbolToken(BANG_EQ_INFO, -1);
      case '>': return new SymbolToken(GT_INFO, -1);
      case '>=': return new SymbolToken(GT_EQ_INFO, -1);
      case '<': return new SymbolToken(LT_INFO, -1);
      case '<=': return new SymbolToken(LT_EQ_INFO, -1);
      case '&&': return new SymbolToken(AMPERSAND_AMPERSAND_INFO, -1);
      case '||': return new SymbolToken(BAR_BAR_INFO, -1);
      default:
        throw "Unrecognized binary operator: $operatorName";
    }
  }

  static Token incrementToken(String operatorName) {
    switch (operatorName) {
      case '++': return new SymbolToken(PLUS_PLUS_INFO, -1);
      case '--': return new SymbolToken(MINUS_MINUS_INFO, -1);
      default:
        throw "Unrecognized increment operator: $operatorName";
    }
  }

  static Token typeOpToken(String operatorName) {
    switch (operatorName) { // "is!" is not an operator in the frontend AST.
      case 'is': return new SymbolToken(IS_INFO, -1);
      case 'as': return new SymbolToken(AS_INFO, -1);
      default:
        throw 'Unrecognized type operator: $operatorName';
    }
  }

  Token unopToken(String operatorName) {
    switch (operatorName) {
      case '-': return new SymbolToken(MINUS_INFO, -1);
      case '~': return new SymbolToken(TILDE_INFO, -1);
      case '!': return bang;
      default:
        throw "Unrecognized unary operator: $operatorName";
    }
  }

  tree.Node makeStaticReceiver(elements.Element element) {
    if (treeElements == null) return null;
    if (element.enclosingElement is elements.ClassElement) {
      tree.Send send = new tree.Send(
          null,
          makeIdentifier(element.enclosingElement.name));
      treeElements[send] = element.enclosingElement;
      return send;
    } else {
      return null;
    }
  }

  tree.Node makeArgument(Argument arg) {
    if (arg is Expression) {
      return makeExpression(arg);
    } else if (arg is NamedArgument) {
      return new tree.NamedArgument(
          makeIdentifier(arg.name),
          colon,
          makeExpression(arg.expression));
    } else {
      throw "Unrecognized argument type: ${arg}";
    }
  }

  tree.Node makeExpression(Expression exp) {
    return makeExp(exp, EXPRESSION);
  }

  /// Converts [exp] to a [tree.Node] that unparses to an expression with
  /// a precedence level of at least [minPrecedence]. The expression will be
  /// wrapped in a parenthesis if necessary.
  tree.Node makeExp(Receiver exp, int minPrecedence, {bool beginStmt: false}) {
    tree.Node result;
    int precedence;
    bool needParen = false;
    if (exp is SuperReceiver) {
      precedence = CALLEE;
      result = makeIdentifier('super');
    } else if (exp is Assignment) {
      Expression left = exp.left;
      tree.Node receiver;
      tree.Node selector;
      tree.NodeList arguments;
      elements.Element element;
      if (left is Identifier) {
        receiver = makeStaticReceiver(left.element);
        selector = makeIdentifier(left.name);
        arguments = singleton(makeExpression(exp.right));
        element = left.element;
      } else if (left is FieldExpression) {
        receiver = makeExp(left.object, PRIMARY, beginStmt: beginStmt);
        selector = makeIdentifier(left.fieldName);
        arguments = singleton(makeExpression(exp.right));
      } else if (left is IndexExpression) {
        receiver = makeExp(left.object, PRIMARY, beginStmt: beginStmt);
        selector = new tree.Operator(indexToken);
        arguments = bracketList(',',
            [makeExpression(left.index), makeExpression(exp.right)]);
      } else {
        throw "Unexpected left-hand side of assignment: ${left}";
      }
      tree.Operator op = new tree.Operator(assignmentToken(exp.operator));
      result = new tree.SendSet(receiver, selector, op, arguments);
      if (left is Identifier) {
        setElement(result, element, exp);
      }
      precedence = EXPRESSION;
    } else if (exp is BinaryOperator) {
      precedence = BINARY_PRECEDENCE[exp.operator];
      int deltaLeft = isAssociativeBinaryOperator(precedence) ? 0 : 1;
      result = new tree.Send(
          makeExp(exp.left, precedence + deltaLeft, beginStmt: beginStmt),
          new tree.Operator(binopToken(exp.operator)),
          singleton(makeExp(exp.right, precedence + 1)));
    } else if (exp is CallFunction) {
      precedence = CALLEE;
      tree.Node selector;
      Expression callee = exp.callee;
      elements.Element element;
      tree.Node receiver;
      if (callee is Identifier) {
        receiver = makeStaticReceiver(callee.element);
        selector = makeIdentifier(callee.name);
        element = callee.element;
      } else {
        selector = makeExp(callee, CALLEE, beginStmt: beginStmt);
      }
      result = new tree.Send(
          receiver,
          selector,
          argList(exp.arguments.map(makeArgument)));
      if (callee is Identifier) {
        setElement(result, element, exp);
      }
    } else if (exp is CallMethod) {
      precedence = CALLEE;
      tree.Node receiver = exp.object is This
          ? null
          : makeExp(exp.object, PRIMARY, beginStmt: beginStmt);
      result = new tree.Send(
          receiver,
          makeIdentifier(exp.methodName),
          argList(exp.arguments.map(makeArgument)));
    } else if (exp is CallNew) {
      precedence = CALLEE;
      tree.Node selector = makeName(exp.type.name);
      if (exp.type.typeArguments.length > 0) {
        selector = new tree.TypeAnnotation(
            selector,
            typeArgList(exp.type.typeArguments.map(makeType)));
        setType(selector, exp.dartType, exp);
      }
      if (exp.constructorName != null) {
        selector = new tree.Send(
            selector,
            makeIdentifier(exp.constructorName));
      }
      tree.Send send = new tree.Send(
          null,
          selector,
          argList(exp.arguments.map(makeArgument)));
      result = new tree.NewExpression(
          exp.isConst ? constToken : newToken,
          send);
      setType(result, exp.dartType, exp);
      setElement(send, exp.constructor, exp);
    } else if (exp is CallStatic) {
      precedence = CALLEE;
      result = new tree.Send(
          makeStaticReceiver(exp.element),
          makeIdentifier(exp.methodName),
          argList(exp.arguments.map(makeArgument)));
      setElement(result, exp.element, exp);
    } else if (exp is Conditional) {
      precedence = CONDITIONAL;
      result = new tree.Conditional(
          makeExp(exp.condition, LOGICAL_OR, beginStmt: beginStmt),
          makeExp(exp.thenExpression, EXPRESSION),
          makeExp(exp.elseExpression, EXPRESSION),
          question,
          colon);
    } else if (exp is FieldExpression) {
      precedence = PRIMARY;
      tree.Node receiver = exp.object is This
          ? null
          : makeExp(exp.object, PRIMARY, beginStmt: beginStmt);
      result = new tree.Send(receiver, makeIdentifier(exp.fieldName));
    } else if (exp is FunctionExpression) {
      precedence = PRIMARY;
      if (beginStmt && exp.name != null) {
        needParen = true; // Do not mistake for function declaration.
      }
      // exp.element can only be null in tests.
      tree.Node body = exp.element != null &&
          exp.element.node.body is tree.EmptyStatement
        ? exp.element.node.body
        : makeFunctionBody(exp.body);
      result = new tree.FunctionExpression(
          functionName(exp),
          makeParameters(exp.parameters),
          body,
          exp.returnType == null || exp.element.isConstructor
            ? null
            : makeType(exp.returnType),
          makeFunctionModifiers(exp),
          null,  // initializers
          null); // get/set
      setElement(result, exp.element, exp);
    } else if (exp is Identifier) {
      precedence = CALLEE;
      result = new tree.Send(
          makeStaticReceiver(exp.element),
          makeIdentifier(exp.name));
      setElement(result, exp.element, exp);
    } else if (exp is Increment) {
      Expression lvalue = exp.expression;
      tree.Node receiver;
      tree.Node selector;
      tree.Node argument;
      bool innerBeginStmt = beginStmt && !exp.isPrefix;
      if (lvalue is Identifier) {
        receiver = makeStaticReceiver(lvalue.element);
        selector = makeIdentifier(lvalue.name);
      } else if (lvalue is FieldExpression) {
        receiver = makeExp(lvalue.object, PRIMARY, beginStmt: innerBeginStmt);
        selector = makeIdentifier(lvalue.fieldName);
      } else if (lvalue is IndexExpression) {
        receiver = makeExp(lvalue.object, PRIMARY, beginStmt: innerBeginStmt);
        selector = new tree.Operator(indexToken);
        argument = makeExpression(lvalue.index);
      } else {
        throw "Unrecognized left-hand side: ${lvalue}";
      }
      tree.Operator op = new tree.Operator(incrementToken(exp.operator));
      if (exp.isPrefix) {
        precedence = UNARY;
        result = new tree.SendSet.prefix(receiver, selector, op, argument);
      } else {
        precedence = POSTFIX_INCREMENT;
        result = new tree.SendSet.postfix(receiver, selector, op, argument);
      }
      if (lvalue is Identifier) {
        setElement(result, lvalue.element, exp);
      }
    } else if (exp is IndexExpression) {
      precedence = CALLEE;
      result = new tree.Send(
          makeExp(exp.object, PRIMARY, beginStmt: beginStmt),
          new tree.Operator(indexToken),
          bracketList(',', [makeExpression(exp.index)]));
    } else if (exp is Literal) {
      precedence = CALLEE;
      dart2js.PrimitiveConstant value = exp.value;
      Token tok = new StringToken.fromString(STRING_INFO, '${value.value}', -1);
      if (value is dart2js.StringConstant) {
        result = unparseStringLiteral(exp);
      } else if (value is dart2js.IntConstant) {
        result = new tree.LiteralInt(tok, null);
      } else if (value is dart2js.DoubleConstant) {
        if (value.value == double.INFINITY) {
          precedence = MULTIPLICATIVE;
          tok = new StringToken.fromString(STRING_INFO, '1/0.0', -1);
        } else if (value.value == double.NEGATIVE_INFINITY) {
          precedence = MULTIPLICATIVE;
          tok = new StringToken.fromString(STRING_INFO, '-1/0.0', -1);
        } else if (value.value.isNaN) {
          precedence = MULTIPLICATIVE;
          tok = new StringToken.fromString(STRING_INFO, '0/0.0', -1);
        }
        result = new tree.LiteralDouble(tok, null);
      } else if (value is dart2js.BoolConstant) {
        result = new tree.LiteralBool(tok, null);
      } else if (value is dart2js.NullConstant) {
        result = new tree.LiteralNull(tok);
      } else {
        throw "Unrecognized constant: ${value}";
      }
    } else if (exp is LiteralList) {
      precedence = PRIMARY;
      tree.NodeList typeArgs = null;
      if (exp.typeArgument != null) {
        typeArgs = typeArgList([makeType(exp.typeArgument)]);
      }
      result = new tree.LiteralList(
          typeArgs,
          bracketList(',', exp.values.map(makeExpression)),
          exp.isConst ? constToken : null);
    } else if (exp is LiteralMap) {
      precedence = PRIMARY;
      if (beginStmt) {
        // The opening brace can be confused with a block statement.
        needParen = true;
      }
      tree.NodeList typeArgs = null;
      if (exp.typeArguments != null && exp.typeArguments.length > 0) {
        typeArgs = typeArgList(exp.typeArguments.map(makeType));
      }
      result = new tree.LiteralMap(
          typeArgs,
          braceList(',', exp.entries.map(makeLiteralMapEntry)),
          exp.isConst ? constToken : null);
    } else if (exp is LiteralSymbol) {
      precedence = PRIMARY;
      result = new tree.LiteralSymbol(
          hash,
          makeList('.', exp.id.split('.').map(makeIdentifier)));
    } else if (exp is LiteralType) {
      precedence = TYPE_LITERAL;
      elements.Element optionalElement = exp.type.element;
      result = new tree.Send(
          optionalElement == null ? null : makeStaticReceiver(optionalElement),
          makeIdentifier(exp.name));
      treeElements.setType(result, exp.type);
      if (optionalElement != null) { // dynamic does not have an element
        setElement(result, optionalElement, exp);
      }
    } else if (exp is ReifyTypeVar) {
      precedence = PRIMARY;
      result = new tree.Send(
          null,
          makeIdentifier(exp.name));
      setElement(result, exp.element, exp);
    } else if (exp is StringConcat) {
      precedence = PRIMARY;
      result = unparseStringLiteral(exp);
    } else if (exp is This) {
      precedence = CALLEE;
      result = makeIdentifier('this');
    } else if (exp is Throw) {
      precedence = EXPRESSION; // ???
      result = new tree.Throw(
          makeExpression(exp.expression),
          throwToken,
          throwToken); // endToken not used by unparser
    } else if (exp is TypeOperator) {
      precedence = RELATIONAL;
      tree.Operator operator;
      tree.Node rightOperand = makeType(exp.type);
      if (exp.operator == 'is!') {
        operator = new tree.Operator(typeOpToken('is'));
        rightOperand = new tree.Send(
            rightOperand,
            new tree.Operator(bang),
            blankList());
      } else {
        operator = new tree.Operator(typeOpToken(exp.operator));
      }
      result = new tree.Send(
          makeExp(exp.expression, BITWISE_OR, beginStmt: beginStmt),
          operator,
          singleton(rightOperand));
    } else if (exp is UnaryOperator) {
      precedence = UNARY;
      result = new tree.Send.prefix(
          makeExp(exp.operand, UNARY),
          new tree.Operator(unopToken(exp.operatorName)));
    } else {
      throw "Unknown expression type: ${exp}";
    }

    needParen = needParen || precedence < minPrecedence;
    if (needParen) {
      result = parenthesize(result);
    }
    return result;
  }

  /// Creates a LiteralString with [verbatim] as the value.
  /// No (un)quoting or (un)escaping will be performed by this method.
  /// The [DartString] inside the literal will be set to null because the
  /// code emitter does not use it.
  tree.LiteralString makeVerbatimStringLiteral(String verbatim) {
    Token tok = new StringToken.fromString(STRING_INFO, verbatim, -1);
    return new tree.LiteralString(tok, null);
  }

  tree.LiteralMapEntry makeLiteralMapEntry(LiteralMapEntry en) {
    return new tree.LiteralMapEntry(
        makeExpression(en.key),
        colon,
        makeExpression(en.value));
  }

  /// A comment token to be inserted when [INSERT_NEW_BACKEND_COMMENT] is true.
  final SymbolToken newBackendComment = new SymbolToken(
      const PrecedenceInfo('/* new backend */ ', 0, OPEN_CURLY_BRACKET_TOKEN),
      -1);

  tree.Node makeFunctionBody(Statement stmt) {
    if (INSERT_NEW_BACKEND_COMMENT) {
      return new tree.Block(makeList('', [makeBlock(stmt)],
                                     open: newBackendComment));
    } else {
      return makeBlock(stmt);
    }
  }

  /// Produces a statement in a context where only blocks are allowed.
  tree.Node makeBlock(Statement stmt) {
    if (stmt is Block)
      return makeStatement(stmt);
    else {
      return new tree.Block(braceList('', [makeStatement(stmt)]));
    }
  }

  /// Adds the given statement to a block. If the statement itself is a block
  /// it will be flattened (if this does not change lexical scoping).
  void addBlockMember(Statement stmt, List<tree.Node> accumulator) {
    if (stmt is Block && !stmt.statements.any(Unparser.definesVariable)) {
      for (Statement innerStmt in stmt.statements) {
        addBlockMember(innerStmt, accumulator);
      }
    } else if (stmt is EmptyStatement) {
      // No need to include empty statements inside blocks
    } else {
      accumulator.add(makeStatement(stmt));
    }
  }

  /// True if [stmt] is equivalent to an empty statement.
  bool isEmptyStatement(Statement stmt) {
    return stmt is EmptyStatement ||
          (stmt is Block && stmt.statements.every(isEmptyStatement));
  }

  tree.Node makeStatement(Statement stmt, {bool shortIf: true}) {
    if (stmt is Block) {
      List<tree.Node> body = <tree.Node>[];
      for (Statement innerStmt in stmt.statements) {
        addBlockMember(innerStmt, body);
      }
      return new tree.Block(braceList('', body));
    } else if (stmt is Break) {
      return new tree.BreakStatement(
          stmt.label == null ? null : makeIdentifier(stmt.label),
          breakToken,
          semicolon);
    } else if (stmt is Continue) {
      return new tree.ContinueStatement(
          stmt.label == null ? null : makeIdentifier(stmt.label),
          continueToken,
          semicolon);
    } else if (stmt is DoWhile) {
      return new tree.DoWhile(
          makeStatement(stmt.body, shortIf: shortIf),
          parenthesize(makeExpression(stmt.condition)),
          doToken,
          whileToken,
          semicolon);
    } else if (stmt is EmptyStatement) {
      return new tree.EmptyStatement(semicolon);
    } else if (stmt is ExpressionStatement) {
      return new tree.ExpressionStatement(
          makeExp(stmt.expression, EXPRESSION, beginStmt: true),
          semicolon);
    } else if (stmt is For) {
      tree.Node initializer;
      if (stmt.initializer is VariableDeclarations) {
        initializer = makeVariableDeclarations(stmt.initializer);
      } else if (stmt.initializer is Expression) {
        initializer = makeExpression(stmt.initializer);
      } else {
        initializer = null;
      }
      tree.Node condition;
      if (stmt.condition != null) {
        condition = new tree.ExpressionStatement(
            makeExpression(stmt.condition),
            semicolon);
      } else {
        condition = new tree.EmptyStatement(semicolon);
      }
      return new tree.For(
          initializer,
          condition,
          makeList(',', stmt.updates.map(makeExpression)),
          makeStatement(stmt.body, shortIf: shortIf),
          forToken);
    } else if (stmt is ForIn) {
      tree.Node left;
      if (stmt.leftHandValue is Identifier) {
        left = makeExpression(stmt.leftHandValue);
      } else {
        left = makeVariableDeclarations(stmt.leftHandValue);
      }
      return new tree.ForIn(
          left,
          makeExpression(stmt.expression),
          makeStatement(stmt.body, shortIf: shortIf),
          forToken,
          inToken);
    } else if (stmt is FunctionDeclaration) {
      return new tree.FunctionDeclaration(new tree.FunctionExpression(
          stmt.name != null ? makeIdentifier(stmt.name) : null,
          makeParameters(stmt.parameters),
          makeFunctionBody(stmt.body),
          stmt.returnType != null ? makeType(stmt.returnType) : null,
          makeEmptyModifiers(), // TODO(asgerf): Function modifiers?
          null,  // initializers
          null)); // get/set
    } else if (stmt is If) {
      if (stmt.elseStatement == null || isEmptyStatement(stmt.elseStatement)) {
        tree.Node node = new tree.If(
            parenthesize(makeExpression(stmt.condition)),
            makeStatement(stmt.thenStatement),
            null, // else statement
            ifToken,
            null); // else token
        if (shortIf)
          return node;
        else
          return new tree.Block(braceList('', [node]));
      } else {
        return new tree.If(
            parenthesize(makeExpression(stmt.condition)),
            makeStatement(stmt.thenStatement, shortIf: false),
            makeStatement(stmt.elseStatement, shortIf: shortIf),
            ifToken,
            elseToken); // else token
      }
    } else if (stmt is LabeledStatement) {
      List<tree.Label> labels = [];
      Statement inner = stmt;
      while (inner is LabeledStatement) {
        LabeledStatement lbl = inner as LabeledStatement;
        labels.add(new tree.Label(makeIdentifier(lbl.label), colon));
        inner = lbl.statement;
      }
      return new tree.LabeledStatement(
          makeList('', labels),
          makeStatement(inner, shortIf: shortIf));
    } else if (stmt is Rethrow) {
      return new tree.Rethrow(rethrowToken, semicolon);
    } else if (stmt is Return) {
      return new tree.Return(
          returnToken,
          semicolon,
          stmt.expression == null ? null : makeExpression(stmt.expression));
    } else if (stmt is Switch) {
      return new tree.SwitchStatement(
          parenthesize(makeExpression(stmt.expression)),
          braceList('', stmt.cases.map(makeSwitchCase)),
          switchToken);
    } else if (stmt is Try) {
      return new tree.TryStatement(
          makeBlock(stmt.tryBlock),
          braceList('', stmt.catchBlocks.map(makeCatchBlock)),
          stmt.finallyBlock == null ? null : makeBlock(stmt.finallyBlock),
          tryToken,
          finallyToken);
    } else if (stmt is VariableDeclarations) {
      return makeVariableDeclarations(stmt, useVar: true, endToken: semicolon);
    } else if (stmt is While) {
      return new tree.While(
          parenthesize(makeExpression(stmt.condition)),
          makeStatement(stmt.body, shortIf: shortIf),
          whileToken);
    } else {
      throw "Unrecognized statement: ${stmt}";
    }
  }

  tree.Node makeVariableDeclaration(VariableDeclaration vd) {
    tree.Node id = makeIdentifier(vd.name);
    setElement(id, vd.element, vd);
    if (vd.initializer == null) {
      return id;
    }
    tree.Node send = new tree.SendSet(
          null,
          id,
          new tree.Operator(eq),
          singleton(makeExpression(vd.initializer)));
    setElement(send, vd.element, vd);
    return send;
  }

  /// If [useVar] is true, the variable definition will use `var` as modifier
  /// if no other modifiers are present.
  /// [endToken] will be used to terminate the declaration list.
  tree.Node makeVariableDeclarations(VariableDeclarations decl,
                                      { bool useVar: false,
                                        Token endToken: null }) {
    return new tree.VariableDefinitions(
        decl.type == null ? null : makeType(decl.type),
        makeVarModifiers(isConst: decl.isConst,
                          isFinal: decl.isFinal,
                          useVar: useVar && decl.type == null),
        makeList(',',
            decl.declarations.map(makeVariableDeclaration),
            close: endToken));
  }

  tree.CatchBlock makeCatchBlock(CatchBlock block) {
    List<tree.VariableDefinitions> formals = [];
    if (block.exceptionVar != null) {
      formals.add(new tree.VariableDefinitions(
          null,
          makeEmptyModifiers(),
          singleton(makeIdentifier(block.exceptionVar))));
    }
    if (block.stackVar != null) {
      formals.add(new tree.VariableDefinitions(
          null,
          makeEmptyModifiers(),
          singleton(makeIdentifier(block.stackVar))));
    }
    return new tree.CatchBlock(
        block.onType == null ? null : makeType(block.onType),
        block.exceptionVar == null ? null : argList(formals),
        makeBlock(block.body),
        block.onType == null ? null : onToken,
        block.exceptionVar == null ? null : catchToken);
  }

  tree.SwitchCase makeSwitchCase(SwitchCase caze) {
    if (caze.isDefaultCase) {
      return new tree.SwitchCase(
          blankList(),
          defaultToken,
          makeList('', caze.statements.map(makeStatement)),
          null); // startToken unused by unparser
    } else {
      return new tree.SwitchCase(
          makeList('', caze.expressions.map(makeCaseMatch)),
          null, // defaultKeyword,
          makeList('', caze.statements.map(makeStatement)),
          null); // startToken unused by unparser
    }
  }

  tree.CaseMatch makeCaseMatch(Expression exp) {
    return new tree.CaseMatch(caseToken, makeExpression(exp), colon);
  }

  tree.TypeAnnotation makeType(TypeAnnotation type) {
    tree.NodeList typeArgs;
    if (type.typeArguments.length > 0) {
      typeArgs = typeArgList(type.typeArguments.map(makeType));
    } else {
      typeArgs = null;
    }
    tree.TypeAnnotation result =
        new tree.TypeAnnotation(makeIdentifier(type.name), typeArgs);
    setType(result, type.dartType, type);
    return result;
  }

  tree.NodeList makeParameters(Parameters params) {
    List<tree.Node> nodes =
        params.requiredParameters.map(makeParameter).toList();
    if (params.hasOptionalParameters) {
      Token assign = params.hasNamedParameters ? colon : eq;
      Token open = params.hasNamedParameters ? openBrace : openBracket;
      Token close = params.hasNamedParameters ? closeBrace : closeBracket;
      Iterable<tree.Node> opt =
          params.optionalParameters.map((p) => makeParameter(p,assign));
      nodes.add(new tree.NodeList(open, makeLink(opt), close, ','));
    }
    return argList(nodes);
  }

  /// [assignOperator] is used for writing the default value.
  tree.Node makeParameter(Parameter param, [Token assignOperator]) {
    if (param.isFunction) {
      tree.Node definition = new tree.FunctionExpression(
          makeIdentifier(param.name),
          makeParameters(param.parameters),
          null, // body
          param.type == null ? null : makeType(param.type),
          makeEmptyModifiers(), // TODO: Function parameter modifiers?
          null, // initializers
          null); // get/set
      setElement(definition, param.element, param);
      if (param.defaultValue != null) {
        return new tree.SendSet(
            null,
            definition,
            new tree.Operator(assignOperator),
            singleton(makeExpression(param.defaultValue)));
      } else {
        return new tree.VariableDefinitions(
            null,
            makeEmptyModifiers(),
            singleton(definition));
      }
    } else {
      tree.Node definition;
      if (param.defaultValue != null) {
        definition = new tree.SendSet(
            null,
            makeIdentifier(param.name),
            new tree.Operator(assignOperator),
            singleton(makeExpression(param.defaultValue)));
      } else {
        definition = makeIdentifier(param.name);
      }
      setElement(definition, param.element, param);
      return new tree.VariableDefinitions(
          param.type == null ? null : makeType(param.type),
          makeEmptyModifiers(), // TODO: Parameter modifiers?
          singleton(definition));
    }
  }

  tree.Modifiers makeEmptyModifiers() {
    return new tree.Modifiers(blankList());
  }

  tree.Modifiers makeVarModifiers({bool isConst: false,
                               bool isFinal: false,
                               bool useVar: false}) {
    List<tree.Node> nodes = [];
    if (isConst) {
      nodes.add(makeIdentifier('const'));
    }
    if (isFinal) {
      nodes.add(makeIdentifier('final'));
    }
    if (useVar && nodes.isEmpty) {
      nodes.add(makeIdentifier('var'));
    }
    return new tree.Modifiers(makeList('', nodes));
  }

  tree.Modifiers makeFunctionModifiers(FunctionExpression exp) {
    if (exp.element == null) return makeEmptyModifiers();
    List<tree.Node> modifiers = new List<tree.Node>();
    if (exp.element is elements.ConstructorElement &&
        exp.element.isFactoryConstructor) {
      modifiers.add(makeIdentifier("factory"));
    }
    if (exp.element.isStatic) {
      modifiers.add(makeIdentifier("static"));
    }
    return new tree.Modifiers(makeList('', modifiers));
  }

  tree.Node functionName(FunctionExpression exp) {
    String name = exp.name;
    if (name == null) return null;
    if (isUserDefinableOperator(name)) {
      return makeOperator("operator$name");
    } else if (name == "unary-") {
      return makeOperator("operator-");
    }
    return makeIdentifier(name);
  }

  tree.Node parenthesize(tree.Node node) {
    return new tree.ParenthesizedExpression(node, openParen);
  }

  tree.Node unparseStringLiteral(Expression exp) {
    StringLiteralOutput output = Unparser.analyzeStringLiteral(exp);
    List parts = output.parts;
    tree.Node printStringChunk(StringChunk chunk) {
      bool raw = chunk.quoting.raw;
      int quoteCode = chunk.quoting.quote;

      List<tree.StringInterpolationPart> literalParts = [];
      tree.LiteralString firstLiteral;
      tree.Node currentInterpolation;

      // sb contains the current unfinished LiteralString
      StringBuffer sb = new StringBuffer();
      if (raw) {
        sb.write('r');
      }
      for (int i = 0; i < chunk.quoting.leftQuoteCharCount; i++) {
        sb.write(chunk.quoting.quoteChar);
      }

      // Print every character and string interpolation
      int startIndex = chunk.previous != null ? chunk.previous.endIndex : 0;
      for (int i = startIndex; i < chunk.endIndex; i++) {
        var part = parts[i];
        if (part is Expression) {
          // Finish the previous string interpolation, if there is one.
          tree.LiteralString lit = makeVerbatimStringLiteral(sb.toString());
          if (currentInterpolation != null) {
            literalParts.add(new tree.StringInterpolationPart(
                currentInterpolation,
                lit));
          } else {
            firstLiteral = lit;
          }
          sb.clear();
          currentInterpolation = makeExpression(part);
        } else {
          int char = part;
          sb.write(Unparser.getEscapedCharacter(char, quoteCode, raw));
        }
      }

      // Print ending quotes
      for (int i = 0; i < chunk.quoting.rightQuoteLength; i++) {
        sb.write(chunk.quoting.quoteChar);
      }

      // Finish the previous string interpolation, if there is one.
      // Then wrap everything in a StringInterpolation, if relevant.
      tree.LiteralString lit = makeVerbatimStringLiteral(sb.toString());
      tree.Node node;
      if (firstLiteral == null) {
        node = lit;
      } else {
        literalParts.add(new tree.StringInterpolationPart(
            currentInterpolation,
            lit));
        node = new tree.StringInterpolation(
            firstLiteral,
            makeList('', literalParts));
      }

      // Juxtapose with the previous string chunks, if any.
      if (chunk.previous != null) {
        return new tree.StringJuxtaposition(
            printStringChunk(chunk.previous),
            node);
      } else {
        return node;
      }
    }
    return printStringChunk(output.chunk);
  }

}
