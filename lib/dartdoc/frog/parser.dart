// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jimhug): Error recovery needs major work!
/**
 * A simple recursive descent parser for the dart language.
 *
 * This parser is designed to be more permissive than the official
 * Dart grammar.  It is expected that many grammar errors would be
 * reported by a later compiler phase.  For example, a class is allowed
 * to extend an arbitrary number of base classes - this can be
 * very clearly detected and is reported in a later compiler phase.
 */
class Parser {
  TokenSource tokenizer;

  final SourceFile source;
  /** Enables diet parse, which skips function bodies. */
  final bool diet;
  /**
   * Throw an IncompleteSourceException if the parser encounters a premature end
   * of file or an incomplete multiline string.
   */
  final bool throwOnIncomplete;

  /** Allow semicolons to be omitted at the end of lines. */
  // TODO(nweiz): make this work for more than just end-of-file
  final bool optionalSemicolons;

  /**
   * Allow the await keyword, when the await transformation is available (see
   * await/awaitc.dart).
   */
  bool get enableAwait() => experimentalAwaitPhase != null;

  /**
   * To resolve ambiguity in initializers between constructor body and lambda
   * expression.
   */
  bool _inhibitLambda = false;

  Token _previousToken;
  Token _peekToken;

  // When we encounter '(' in a method body we need to find the ')' to know it
  // we're parsing a lambda, paren-expr, or argument list. Closure formals are
  // followed by '=>' or '{'. This list is used to cache the tokens after any
  // nested parenthesis we find while peeking.
  // TODO(jmesserly): it's simpler and faster to cache this on the Token itself,
  // but that might add too much complexity for tools that need to invalidate.
  List<Token> _afterParens;
  int _afterParensIndex = 0;

  bool _recover = false;

  Parser(this.source, [this.diet = false, this.throwOnIncomplete = false,
      this.optionalSemicolons = false, int startOffset = 0]) {
    tokenizer = new Tokenizer(source, true, startOffset);
    _peekToken = tokenizer.next();
    _afterParens = <Token>[];
  }

  /** Generate an error if [source] has not been completely consumed. */
  void checkEndOfFile() {
    _eat(TokenKind.END_OF_FILE);
  }

  /** Guard to break out of parser when an unexpected end of file is found. */
  bool isPrematureEndOfFile() {
    if (throwOnIncomplete && _maybeEat(TokenKind.END_OF_FILE)) {
      throw new IncompleteSourceException(_previousToken);
    } else if (_maybeEat(TokenKind.END_OF_FILE)) {
      _error('unexpected end of file', _peekToken.span);
      return true;
    } else {
      return false;
    }
  }

  /**
   * Recovers the parser after an error, by iterating until it finds one of
   * the provide [TokenKind] values.
   */
  bool _recoverTo(int kind1, [int kind2, int kind3]) {
    assert(_recover);
    while (!isPrematureEndOfFile()) {
      int kind = _peek();
      if (kind == kind1 || kind == kind2 || kind == kind3) {
        _recover = false; // Done recovering. Issue errors normally.
        return true;
      }
      _next();
    }
    // End of file without finding a match
    return false;
  }

  ///////////////////////////////////////////////////////////////////
  // Basic support methods
  ///////////////////////////////////////////////////////////////////
  int _peek() => _peekToken.kind;

  Token _next() {
    _previousToken = _peekToken;
    _peekToken = tokenizer.next();
    return _previousToken;
  }

  bool _peekKind(int kind) => _peekToken.kind == kind;

  /* Is the next token a legal identifier?  This includes pseudo-keywords. */
  bool _peekIdentifier() => _isIdentifier(_peekToken.kind);

  bool _isIdentifier(kind) {
    return TokenKind.isIdentifier(kind)
      // Note: 'await' is not a pseudo-keyword. When [enableAwait] is true, it
      // is illegal to consider 'await' an identifier.
      || (!enableAwait && kind == TokenKind.AWAIT);
  }

  bool _maybeEat(int kind) {
    if (_peekToken.kind == kind) {
      _previousToken = _peekToken;
      _peekToken = tokenizer.next();
      return true;
    } else {
      return false;
    }
  }

  void _eat(int kind) {
    if (!_maybeEat(kind)) {
      _errorExpected(TokenKind.kindToString(kind));
    }
  }

  void _eatSemicolon() {
    if (optionalSemicolons && _peekKind(TokenKind.END_OF_FILE)) return;
    _eat(TokenKind.SEMICOLON);
  }

  void _errorExpected(String expected) {
    // Throw an IncompleteSourceException if that's the problem and
    // throwOnIncomplete is true
    if (throwOnIncomplete) isPrematureEndOfFile();
    var tok = _next();
    if (tok is ErrorToken && tok.message != null) {
      // give priority to tokenizer errors
      _error(tok.message, tok.span);
    } else {
      _error('expected $expected, but found $tok', tok.span);
    }
  }

  void _error(String message, [SourceSpan location=null]) {
    // Suppress error messages while we're trying to recover.
    if (_recover) return;

    if (location == null) {
      location = _peekToken.span;
    }
    world.fatal(message, location); // syntax errors are fatal for now
    _recover = true; // start error recovery
  }

  /** Skips from an opening '{' to the syntactically matching '}'. */
  void _skipBlock() {
    int depth = 1;
    _eat(TokenKind.LBRACE);
    while (true) {
      var tok = _next();
      if (tok.kind == TokenKind.LBRACE) {
        depth += 1;
      } else if (tok.kind == TokenKind.RBRACE) {
        depth -= 1;
        if (depth == 0) return;
      } else if (tok.kind == TokenKind.END_OF_FILE) {
        _error('unexpected end of file during diet parse', tok.span);
        return;
      }
    }
  }

  SourceSpan _makeSpan(int start) {
    return new SourceSpan(source, start, _previousToken.end);
  }

  ///////////////////////////////////////////////////////////////////
  // Top level productions
  ///////////////////////////////////////////////////////////////////

  /** Entry point to the parser for parsing a compilation unit (i.e. a file). */
  List<Definition> compilationUnit() {
    var ret = [];
    _maybeEat(TokenKind.HASHBANG);

    while (_peekKind(TokenKind.HASH)) {
      ret.add(directive());
    }
    _recover = false;
    while (!_maybeEat(TokenKind.END_OF_FILE)) {
      ret.add(topLevelDefinition());
    }
    _recover = false;
    return ret;
  }

  directive() {
    int start = _peekToken.start;
    _eat(TokenKind.HASH);
    var name = identifier();
    var args = arguments();
    _eatSemicolon();
    return new DirectiveDefinition(name, args, _makeSpan(start));
  }

  topLevelDefinition() {
    switch (_peek()) {
      case TokenKind.CLASS:
        return classDefinition(TokenKind.CLASS);
      case TokenKind.INTERFACE:
        return classDefinition(TokenKind.INTERFACE);
      case TokenKind.TYPEDEF:
        return functionTypeAlias();
      default:
        return declaration();
    }
  }

  /** Entry point to the parser for an eval unit (i.e. a repl command). */
  evalUnit() {
    switch (_peek()) {
      case TokenKind.CLASS:
        return classDefinition(TokenKind.CLASS);
      case TokenKind.INTERFACE:
        return classDefinition(TokenKind.INTERFACE);
      case TokenKind.TYPEDEF:
        return functionTypeAlias();
      default:
        return statement();
    }
    _recover = false;
  }

  ///////////////////////////////////////////////////////////////////
  // Definition productions
  ///////////////////////////////////////////////////////////////////

  classDefinition(int kind) {
    int start = _peekToken.start;
    _eat(kind);
    var name = identifierForType();

    var typeParams = null;
    if (_peekKind(TokenKind.LT)) {
      typeParams = typeParameters();
    }

    var _extends = null;
    if (_maybeEat(TokenKind.EXTENDS)) {
      _extends = typeList();
    }

    var _implements = null;
    if (_maybeEat(TokenKind.IMPLEMENTS)) {
      _implements = typeList();
    }

    var _native = null;
    if (_maybeEat(TokenKind.NATIVE)) {
      _native = maybeStringLiteral();
      if (_native != null) _native = new NativeType(_native);
    }

    bool oldFactory = _maybeEat(TokenKind.FACTORY);
    var defaultType = null;
    if (oldFactory || _maybeEat(TokenKind.DEFAULT)) {
      // TODO(jmesserly): keep old factory support for now. Remove soon.
      if (oldFactory) {
        world.warning('factory no longer supported, use "default" instead',
            _previousToken.span);
      }

      // Note: this can't be type() because it has type parameters not type
      // arguments.
      var baseType = nameTypeReference();
      var factTypeParams = null;
      if (_peekKind(TokenKind.LT)) {
        factTypeParams = typeParameters();
      }
      defaultType = new DefaultTypeReference(oldFactory,
          baseType, factTypeParams, _makeSpan(baseType.span.start));
    }

    var body = [];
    if (_maybeEat(TokenKind.LBRACE)) {
      while (!_maybeEat(TokenKind.RBRACE)) {
        body.add(declaration());
        if (_recover) {
          if (!_recoverTo(TokenKind.RBRACE, TokenKind.SEMICOLON)) break;
          _maybeEat(TokenKind.SEMICOLON);
        }
      }
    } else {
      _errorExpected('block starting with "{" or ";"');
    }
    return new TypeDefinition(kind == TokenKind.CLASS, name, typeParams,
      _extends, _implements, _native, defaultType, body, _makeSpan(start));
  }

  functionTypeAlias() {
    int start = _peekToken.start;
    _eat(TokenKind.TYPEDEF);

    var di = declaredIdentifier(false);
    var typeParams = null;
    if (_peekKind(TokenKind.LT)) {
      typeParams = typeParameters();
    }
    var formals = formalParameterList();
    _eatSemicolon();

    // TODO(jimhug): Validate that di.name is not a pseudo-keyword
    var func = new FunctionDefinition(null, di.type, di.name, formals,
        null, null, null, _makeSpan(start));

    return new FunctionTypeDefinition(func, typeParams, _makeSpan(start));
  }

  initializers() {
    _inhibitLambda = true;
    var ret = [];
    do {
      ret.add(expression());
    } while (_maybeEat(TokenKind.COMMA));
    _inhibitLambda = false;
    return ret;
  }

  functionBody(bool inExpression) {
    int start = _peekToken.start;
    if (_maybeEat(TokenKind.ARROW)) {
      var expr = expression();
      if (!inExpression) {
        _eatSemicolon();
      }
      return new ReturnStatement(expr, _makeSpan(start));
    } else if (_peekKind(TokenKind.LBRACE)) {
      if (diet) {
        _skipBlock();
        return new DietStatement(_makeSpan(start));
      } else {
        return block();
      }
    } else if (!inExpression) {
      if (_maybeEat(TokenKind.SEMICOLON)) {
        return null;
      }
    }

    _error('Expected function body (neither { nor => found)');
  }

  finishField(start, modifiers, type, name, value) {
    var names = [name];
    var values = [value];

    while (_maybeEat(TokenKind.COMMA)) {
      names.add(identifier());
      if (_maybeEat(TokenKind.ASSIGN)) {
        values.add(expression());
      } else {
        values.add(null);
      }
    }

    _eatSemicolon();
    return new VariableDefinition(modifiers, type, names, values,
                                   _makeSpan(start));
  }

  finishDefinition(int start, List<Token> modifiers, di) {
    switch(_peek()) {
      case TokenKind.LPAREN:
        var formals = formalParameterList();
        var inits = null, native = null;
        if (_maybeEat(TokenKind.COLON)) {
          inits = initializers();
        }
        if (_maybeEat(TokenKind.NATIVE)) {
          native = maybeStringLiteral();
          if (native == null) native = '';
        }
        var body = functionBody(/*inExpression:*/false);
        if (di.name == null) {
          // TODO(jimhug): Must be named constructor - verify how?
          di.name = di.type.name;
        }
        return new FunctionDefinition(modifiers, di.type, di.name, formals,
          inits, native, body, _makeSpan(start));

      case TokenKind.ASSIGN:
        _eat(TokenKind.ASSIGN);
        var value = expression();
        return finishField(start, modifiers, di.type, di.name, value);

      case TokenKind.COMMA:
      case TokenKind.SEMICOLON:
        return finishField(start, modifiers, di.type, di.name, null);

      default:
        // TODO(jimhug): This error message sucks.
        _errorExpected('declaration');

        return null;
    }
  }

  declaration([bool includeOperators=true]) {
    int start = _peekToken.start;
    if (_peekKind(TokenKind.FACTORY)) {
      return factoryConstructorDeclaration();
    }

    var modifiers = _readModifiers();
    return finishDefinition(start, modifiers,
        declaredIdentifier(includeOperators));
  }

  // TODO(jmesserly): do we still need this method?
  // I left it here for now to support old-style factories
  factoryConstructorDeclaration() {
    int start = _peekToken.start;
    var factoryToken = _next();

    var names = [identifier()];
    while (_maybeEat(TokenKind.DOT)) {
      names.add(identifier());
    }
    if (_peekKind(TokenKind.LT)) {
      var tp = typeParameters();
      world.warning('type parameters on factories are no longer supported, '
          + 'place them on the class instead', _makeSpan(tp[0].span.start));
    }

    var name = null;
    var type = null;
    if (_maybeEat(TokenKind.DOT)) {
      name = identifier();
    } else {
      if (names.length > 1) {
        name = names.removeLast();
      } else {
        name = new Identifier('', names[0].span);
      }
    }

    if (names.length > 1) {
      // TODO(jimhug): This is nasty to support and currently unused.
      _error('unsupported qualified name for factory', names[0].span);
    }
    type = new NameTypeReference(false, names[0], null, names[0].span);
    var di = new DeclaredIdentifier(type, name, false, _makeSpan(start));
    return finishDefinition(start, [factoryToken], di);
  }

  ///////////////////////////////////////////////////////////////////
  // Statement productions
  ///////////////////////////////////////////////////////////////////
  Statement statement() {
    switch (_peek()) {
      case TokenKind.BREAK:
        return breakStatement();
      case TokenKind.CONTINUE:
        return continueStatement();
      case TokenKind.RETURN:
        return returnStatement();
      case TokenKind.THROW:
        return throwStatement();
      case TokenKind.ASSERT:
        return assertStatement();

      case TokenKind.WHILE:
        return whileStatement();
      case TokenKind.DO:
        return doStatement();
      case TokenKind.FOR:
        return forStatement();

      case TokenKind.IF:
        return ifStatement();
      case TokenKind.SWITCH:
        return switchStatement();

      case TokenKind.TRY:
        return tryStatement();

      case TokenKind.LBRACE:
        return block();
      case TokenKind.SEMICOLON:
        return emptyStatement();

      case TokenKind.FINAL:
        return declaration(false);
      case TokenKind.VAR:
        return declaration(false);

      default:
        // Covers var decl, func decl, labeled stmt and real expressions.
        return finishExpressionAsStatement(expression());
    }
  }

  finishExpressionAsStatement(expr) {
    // TODO(jimhug): This method looks very inefficient - bundle tests.
    int start = expr.span.start;

    if (_maybeEat(TokenKind.COLON)) {
      var label = _makeLabel(expr);
      return new LabeledStatement(label, statement(), _makeSpan(start));
    }

    if (expr is LambdaExpression) {
      if (expr.func.body is! BlockStatement) {
        _eatSemicolon();
        expr.func.span = _makeSpan(start);
      }
      return expr.func;
    } else if (expr is DeclaredIdentifier) {
      var value = null;
      if (_maybeEat(TokenKind.ASSIGN)) {
        value = expression();
      }
      return finishField(start, null, expr.type, expr.name, value);
    } else if (_isBin(expr, TokenKind.ASSIGN) &&
               (expr.x is DeclaredIdentifier)) {
      DeclaredIdentifier di = expr.x; // TODO(jimhug): inference should handle!
      return finishField(start, null, di.type, di.name, expr.y);
    } else if (_isBin(expr, TokenKind.LT) && _maybeEat(TokenKind.COMMA)) {
      var baseType = _makeType(expr.x);
      var typeArgs = [_makeType(expr.y)];
      var gt = _finishTypeArguments(baseType, 0, typeArgs);
      var name = identifier();
      var value = null;
      if (_maybeEat(TokenKind.ASSIGN)) {
        value = expression();
      }
      return finishField(expr.span.start, null, gt, name, value);
    } else {
      _eatSemicolon();
      return new ExpressionStatement(expr, _makeSpan(expr.span.start));
    }
  }

  Expression testCondition() {
    _eatLeftParen();
    var ret = expression();
    _eat(TokenKind.RPAREN);
    return ret;
  }

  /** Parses a block. Also is an entry point when parsing [DietStatement]. */
  BlockStatement block() {
    int start = _peekToken.start;
    _eat(TokenKind.LBRACE);
    var stmts = [];
    while (!_maybeEat(TokenKind.RBRACE)) {
      stmts.add(statement());
      if (_recover && !_recoverTo(TokenKind.RBRACE, TokenKind.SEMICOLON)) break;
    }
    _recover = false;
    return new BlockStatement(stmts, _makeSpan(start));
  }

  EmptyStatement emptyStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.SEMICOLON);
    return new EmptyStatement(_makeSpan(start));
  }


  IfStatement ifStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.IF);
    var test = testCondition();
    var trueBranch = statement();
    var falseBranch = null;
    if (_maybeEat(TokenKind.ELSE)) {
      falseBranch = statement();
    }
    return new IfStatement(test, trueBranch, falseBranch, _makeSpan(start));
  }

  WhileStatement whileStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.WHILE);
    var test = testCondition();
    var body = statement();
    return new WhileStatement(test, body, _makeSpan(start));
  }

  DoStatement doStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.DO);
    var body = statement();
    _eat(TokenKind.WHILE);
    var test = testCondition();
    _eatSemicolon();
    return new DoStatement(body, test, _makeSpan(start));
  }

  forStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.FOR);
    _eatLeftParen();

    var init = forInitializerStatement(start);
    if (init is ForInStatement) {
      return init;
    }
    var test = null;
    if (!_maybeEat(TokenKind.SEMICOLON)) {
      test = expression();
      _eatSemicolon();
    }
    var step = [];
    if (!_maybeEat(TokenKind.RPAREN)) {
      step.add(expression());
      while (_maybeEat(TokenKind.COMMA)) {
        step.add(expression());
      }
      _eat(TokenKind.RPAREN);
    }

    var body = statement();

    return new ForStatement(init, test, step, body, _makeSpan(start));
  }

  forInitializerStatement(int start) {
    if (_maybeEat(TokenKind.SEMICOLON)) {
      return null;
    } else {
      var init = expression();
      // Weird code here is needed to handle generic type and for in
      // TODO(jmesserly): unify with block in finishExpressionAsStatement
      if (_peekKind(TokenKind.COMMA) && _isBin(init, TokenKind.LT)) {
        _eat(TokenKind.COMMA);
        var baseType = _makeType(init.x);
        var typeArgs = [_makeType(init.y)];
        var gt = _finishTypeArguments(baseType, 0, typeArgs);
        var name = identifier();
        init = new DeclaredIdentifier(gt, name, false, _makeSpan(init.span.start));
      }

      if (_maybeEat(TokenKind.IN)) {
        return _finishForIn(start, _makeDeclaredIdentifier(init));
      } else {
        return finishExpressionAsStatement(init);
      }
    }
  }

  _finishForIn(int start, DeclaredIdentifier di) {
    var expr = expression();
    _eat(TokenKind.RPAREN);
    var body = statement();
    return new ForInStatement(di, expr, body,
      _makeSpan(start));
  }

  tryStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.TRY);
    var body = block();
    var catches = [];

    while (_peekKind(TokenKind.CATCH)) {
      catches.add(catchNode());
    }

    var finallyBlock = null;
    if (_maybeEat(TokenKind.FINALLY)) {
      finallyBlock = block();
    }
    return new TryStatement(body, catches, finallyBlock, _makeSpan(start));
  }

  catchNode() {
    int start = _peekToken.start;
    _eat(TokenKind.CATCH);
    _eatLeftParen();
    var exc = declaredIdentifier();
    var trace = null;
    if (_maybeEat(TokenKind.COMMA)) {
      trace = declaredIdentifier();
    }
    _eat(TokenKind.RPAREN);
    var body = block();
    return new CatchNode(exc, trace, body, _makeSpan(start));
  }

  switchStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.SWITCH);
    var test = testCondition();
    var cases = [];
    _eat(TokenKind.LBRACE);
    while (!_maybeEat(TokenKind.RBRACE)) {
      cases.add(caseNode());
    }
    return new SwitchStatement(test, cases, _makeSpan(start));
  }

  _peekCaseEnd() {
    var kind = _peek();
    //TODO(efortuna): also if the first is an identifier followed by a colon, we
    //have a label for the case statement.
    return kind == TokenKind.RBRACE || kind == TokenKind.CASE ||
      kind == TokenKind.DEFAULT;
  }

  caseNode() {
    int start = _peekToken.start;
    var label = null;
    if (_peekIdentifier()) {
      label = identifier();
      _eat(TokenKind.COLON);
    }
    var cases = [];
    while (true) {
      if (_maybeEat(TokenKind.CASE)) {
        cases.add(expression());
        _eat(TokenKind.COLON);
      } else if (_maybeEat(TokenKind.DEFAULT)) {
        cases.add(null);
        _eat(TokenKind.COLON);
      } else {
        break;
      }
    }
    if (cases.length == 0) {
      _error('case or default');
    }
    var stmts = [];
    while (!_peekCaseEnd()) {
      stmts.add(statement());
      if (_recover && !_recoverTo(
          TokenKind.RBRACE, TokenKind.CASE, TokenKind.DEFAULT)) {
        break;
      }
    }
    return new CaseNode(label, cases, stmts, _makeSpan(start));
  }

  returnStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.RETURN);
    var expr;
    if (_maybeEat(TokenKind.SEMICOLON)) {
      expr = null;
    } else {
      expr = expression();
      _eatSemicolon();
    }
    return new ReturnStatement(expr, _makeSpan(start));
  }

  throwStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.THROW);
    var expr;
    if (_maybeEat(TokenKind.SEMICOLON)) {
      expr = null;
    } else {
      expr = expression();
      _eatSemicolon();
    }
    return new ThrowStatement(expr, _makeSpan(start));
  }

  assertStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.ASSERT);
    _eatLeftParen();
    var expr = expression();
    _eat(TokenKind.RPAREN);
    _eatSemicolon();
    return new AssertStatement(expr, _makeSpan(start));
  }

  breakStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.BREAK);
    var name = null;
    if (_peekIdentifier()) {
      name = identifier();
    }
    _eatSemicolon();
    return new BreakStatement(name, _makeSpan(start));
  }

  continueStatement() {
    int start = _peekToken.start;
    _eat(TokenKind.CONTINUE);
    var name = null;
    if (_peekIdentifier()) {
      name = identifier();
    }
    _eatSemicolon();
    return new ContinueStatement(name, _makeSpan(start));
  }


  ///////////////////////////////////////////////////////////////////
  // Expression productions
  ///////////////////////////////////////////////////////////////////
  expression() {
    return infixExpression(0);
  }

  _makeType(expr) {
    if (expr is VarExpression) {
      return new NameTypeReference(false, expr.name, null, expr.span);
    } else if (expr is DotExpression) {
      var type = _makeType(expr.self);
      if (type.names == null) {
        type.names = [expr.name];
      } else {
        type.names.add(expr.name);
      }
      type.span = expr.span;
      return type;
    } else {
      _error('expected type reference');
      return null;
    }
  }

  infixExpression(int precedence) {
    return finishInfixExpression(unaryExpression(), precedence);
  }

  _finishDeclaredId(type) {
    var name = identifier();
    return finishPostfixExpression(
      new DeclaredIdentifier(type, name, false, _makeSpan(type.span.start)));
  }

  /**
   * Takes an initial binary expression of A < B and turns it into a
   * declared identifier included the A < B piece in the type.
   */
  _fixAsType(BinaryExpression x) {
    assert(_isBin(x, TokenKind.LT));
    // TODO(jimhug): good errors when expectations are violated
    if (_maybeEat(TokenKind.GT)) {
      // The simple case of A < B > just becomes a generic type
      var base = _makeType(x.x);
      var typeParam = _makeType(x.y);
      var type = new GenericTypeReference(base, [typeParam], 0,
        _makeSpan(x.span.start));
      return _finishDeclaredId(type);
    } else {
      // The case of A < B < kicks off a lot more parsing.
      assert(_peekKind(TokenKind.LT));

      var base = _makeType(x.x);
      var paramBase = _makeType(x.y);
      var firstParam = addTypeArguments(paramBase, 1);

      var type;
      if (firstParam.depth <= 0) {
        type = new GenericTypeReference(base, [firstParam], 0,
          _makeSpan(x.span.start));
      } else if (_maybeEat(TokenKind.COMMA)) {
        type = _finishTypeArguments(base, 0, [firstParam]);
      } else {
        _eat(TokenKind.GT);
        type = new GenericTypeReference(base, [firstParam], 0,
          _makeSpan(x.span.start));
      }
      return _finishDeclaredId(type);
    }
  }

  finishInfixExpression(Expression x, int precedence) {
    while (true) {
      int kind = _peek();
      var prec = TokenKind.infixPrecedence(_peek());
      if (prec >= precedence) {
        if (kind == TokenKind.LT || kind == TokenKind.GT) {
          if (_isBin(x, TokenKind.LT)) {
            // This must be a generic type according the the Dart grammar.
            // This rule is in the grammar to forbid A < B < C and
            // A < B > C as expressions both because they don't make sense
            // and to make it easier to disambiguate the generic types.
            // There are a number of other comparison operators that are
            // also unallowed to nest in this way, but in the spirit of this
            // "friendly" parser, those will be allowed until a later phase.
            return _fixAsType(x);
          }
        }
        var op = _next();
        if (op.kind == TokenKind.IS) {
          var isTrue = !_maybeEat(TokenKind.NOT);
          var typeRef = type();
          x = new IsExpression(isTrue, x, typeRef, _makeSpan(x.span.start));
          continue;
        }
        // Using prec + 1 ensures that a - b - c will group correctly.
        // Using prec for ASSIGN ops ensures that a = b = c groups correctly.
        var y = infixExpression(prec == 2 ? prec: prec+1);
        if (op.kind == TokenKind.CONDITIONAL) {
          _eat(TokenKind.COLON);
          // Using prec for so "a ? b : c ? d : e" groups correctly as
          // "a ? b : (c ? d : e)"
          var z = infixExpression(prec);
          x = new ConditionalExpression(x, y, z, _makeSpan(x.span.start));
        } else {
          x = new BinaryExpression(op, x, y, _makeSpan(x.span.start));
        }
      } else {
        break;
      }
    }
    return x;
  }

  _isPrefixUnaryOperator(int kind) {
    switch(kind) {
      case TokenKind.ADD:
      case TokenKind.SUB:
      case TokenKind.NOT:
      case TokenKind.BIT_NOT:
      case TokenKind.INCR:
      case TokenKind.DECR:
        return true;
      default:
        return false;
    }
  }

  unaryExpression() {
    int start = _peekToken.start;
    // peek for prefixOperators and incrementOperators
    if (_isPrefixUnaryOperator(_peek())) {
      var tok = _next();
      var expr = unaryExpression();
      return new UnaryExpression(tok, expr, _makeSpan(start));
    } else if (enableAwait && _maybeEat(TokenKind.AWAIT)) {
      var expr = unaryExpression();
      return new AwaitExpression(expr, _makeSpan(start));
    }

    return finishPostfixExpression(primary());
  }

  argument() {
    int start = _peekToken.start;
    var expr;
    var label = null;
    if (_maybeEat(TokenKind.ELLIPSIS)) {
      label = new Identifier('...', _makeSpan(start));
    }
    expr = expression();
    if (label == null && _maybeEat(TokenKind.COLON)) {
      label = _makeLabel(expr);
      expr = expression();
    }
    return new ArgumentNode(label, expr, _makeSpan(start));
  }

  arguments() {
    var args = [];
    _eatLeftParen();
    var saved = _inhibitLambda;
    _inhibitLambda = false;
    if (!_maybeEat(TokenKind.RPAREN)) {
      do {
        args.add(argument());
      } while (_maybeEat(TokenKind.COMMA));
      _eat(TokenKind.RPAREN);
    }
     _inhibitLambda = saved;
    return args;
  }

  finishPostfixExpression(expr) {
    switch(_peek()) {
      case TokenKind.LPAREN:
        return finishCallOrLambdaExpression(expr);
      case TokenKind.LBRACK:
        _eat(TokenKind.LBRACK);
        var index = expression();
        _eat(TokenKind.RBRACK);
        return finishPostfixExpression(new IndexExpression(expr, index,
          _makeSpan(expr.span.start)));
      case TokenKind.DOT:
        _eat(TokenKind.DOT);
        var name = identifier();
        var ret = new DotExpression(expr, name, _makeSpan(expr.span.start));
        return finishPostfixExpression(ret);

      case TokenKind.INCR:
      case TokenKind.DECR:
        var tok = _next();
        return new PostfixExpression(expr, tok, _makeSpan(expr.span.start));

      // These are pseudo-expressions supported for cover grammar
      // must be forbidden when parsing initializers.
      // TODO(jmesserly): is this still needed?
      case TokenKind.ARROW:
      case TokenKind.LBRACE:
         return expr;

      default:
        if (_peekIdentifier()) {
          return finishPostfixExpression(
            new DeclaredIdentifier(_makeType(expr), identifier(),
              false, _makeSpan(expr.span.start)));
        } else {
          return expr;
        }
    }
  }

  finishCallOrLambdaExpression(expr) {
    if (_atClosureParameters()) {
      var formals = formalParameterList();
      var body = functionBody(true);
      return _makeFunction(expr, formals, body);
    } else {
      if (expr is DeclaredIdentifier) {
        _error('illegal target for call, did you mean to declare a function?',
          expr.span);
      }
      var args = arguments();
      return finishPostfixExpression(
          new CallExpression(expr, args, _makeSpan(expr.span.start)));
    }
  }

  /** Checks if the given expression is a binary op of the given kind. */
  _isBin(expr, kind) {
    return expr is BinaryExpression && expr.op.kind == kind;
  }

  _makeLiteral(Value value) {
    return new LiteralExpression(value, value.span);
  }

  primary() {
    int start = _peekToken.start;
    switch (_peek()) {
      case TokenKind.THIS:
        _eat(TokenKind.THIS);
        return new ThisExpression(_makeSpan(start));

      case TokenKind.SUPER:
        _eat(TokenKind.SUPER);
        return new SuperExpression(_makeSpan(start));

      case TokenKind.CONST:
        _eat(TokenKind.CONST);
        if (_peekKind(TokenKind.LBRACK) || _peekKind(TokenKind.INDEX)) {
          return finishListLiteral(start, true, null);
        } else if (_peekKind(TokenKind.LBRACE)) {
          return finishMapLiteral(start, true, null, null);
        } else if (_peekKind(TokenKind.LT)) {
          return finishTypedLiteral(start, true);
        } else {
          return finishNewExpression(start, true);
        }

      case TokenKind.NEW:
        _eat(TokenKind.NEW);
        return finishNewExpression(start, false);

      case TokenKind.LPAREN:
        return _parenOrLambda();

      case TokenKind.LBRACK:
      case TokenKind.INDEX:
        return finishListLiteral(start, false, null);
      case TokenKind.LBRACE:
        return finishMapLiteral(start, false, null, null);

      // Literals
      case TokenKind.NULL:
        _eat(TokenKind.NULL);
        return _makeLiteral(Value.fromNull(_makeSpan(start)));

      // TODO(jimhug): Make Literal creation less wasteful - no dup span/text.
      case TokenKind.TRUE:
        _eat(TokenKind.TRUE);
        return _makeLiteral(Value.fromBool(true, _makeSpan(start)));

      case TokenKind.FALSE:
        _eat(TokenKind.FALSE);
        return _makeLiteral(Value.fromBool(false, _makeSpan(start)));

      case TokenKind.HEX_INTEGER:
        var t = _next();
        return _makeLiteral(Value.fromInt(t.value, t.span));

      case TokenKind.INTEGER:
        var t = _next();
        return _makeLiteral(Value.fromInt(Math.parseInt(t.text), t.span));

      case TokenKind.DOUBLE:
        var t = _next();
        return _makeLiteral(
          Value.fromDouble(Math.parseDouble(t.text), t.span));

      case TokenKind.STRING:
      case TokenKind.STRING_PART:
        return adjacentStrings();

      case TokenKind.LT:
        return finishTypedLiteral(start, false);

      case TokenKind.VOID:
      case TokenKind.VAR:
      case TokenKind.FINAL:
        return declaredIdentifier(false);

      default:
        if (!_peekIdentifier()) {
          // TODO(jimhug): Better error message.
          _errorExpected('expression');
        }
        return new VarExpression(identifier(), _makeSpan(start));
    }
  }

  adjacentStrings() {
    int start = _peekToken.start;
    List<Expression> strings = [];
    while (_peek() == TokenKind.STRING || _peek() == TokenKind.STRING_PART) {
      Expression part = null;
      if (_peek() == TokenKind.STRING) {
        var t = _next();
        part = _makeLiteral(Value.fromString(t.value, t.span));
      } else {
        part = stringInterpolation();
      }
      strings.add(part);
    }
    if (strings.length == 1) {
      return strings[0];
    } else {
      assert(!strings.isEmpty());
      return new StringConcatExpression(strings, _makeSpan(start));
    }
  }

  stringInterpolation() {
    int start = _peekToken.start;
    var pieces = new List<Expression>();
    var startQuote = null, endQuote = null;
    while(_peekKind(TokenKind.STRING_PART)) {
      var token = _next();
      pieces.add(_makeLiteral(Value.fromString(token.value, token.span)));
      if (_maybeEat(TokenKind.LBRACE)) {
        pieces.add(expression());
        _eat(TokenKind.RBRACE);
      } else if (_maybeEat(TokenKind.THIS)) {
        pieces.add(new ThisExpression(_previousToken.span));
      } else {
        var id = identifier();
        pieces.add(new VarExpression(id, id.span));
      }
    }
    var tok = _next();
    if (tok.kind != TokenKind.STRING) {
      _errorExpected('interpolated string');
    }
    pieces.add(_makeLiteral(Value.fromString(tok.value, tok.span)));
    var span = _makeSpan(start);
    return new StringInterpExpression(pieces, span);
  }

  String maybeStringLiteral() {
    var kind = _peek();
    if (kind == TokenKind.STRING) {
      var t = _next();
      return t.value;
    } else if (kind == TokenKind.STRING_PART) {
      _next();
      _errorExpected('string literal, but found interpolated string start');
    }
    return null;
  }

  _parenOrLambda() {
    int start = _peekToken.start;
    if (_atClosureParameters()) {
      var formals = formalParameterList();
      var body = functionBody(true);
      var func = new FunctionDefinition(null, null, null, formals, null, null,
        body, _makeSpan(start));
      return new LambdaExpression(func, func.span);
    } else {
      _eatLeftParen();
      var saved = _inhibitLambda;
      _inhibitLambda = false;
      var expr = expression();
      _eat(TokenKind.RPAREN);
      _inhibitLambda = saved;
      return new ParenExpression(expr, _makeSpan(start));
    }
  }

  bool _atClosureParameters() {
    if (_inhibitLambda) return false;
    Token after = _peekAfterCloseParen();
    return after.kind == TokenKind.ARROW || after.kind == TokenKind.LBRACE;
  }

  /** Eats an LPAREN, and advances our after-RPAREN lookahead. */
  _eatLeftParen() {
    _eat(TokenKind.LPAREN);
    _afterParensIndex++;
  }

  Token _peekAfterCloseParen() {
    if (_afterParensIndex < _afterParens.length) {
      return _afterParens[_afterParensIndex];
    }

    // Reset the queue
    _afterParensIndex = 0;
    _afterParens.clear();

    // Start copying tokens as we lookahead
    var tokens = <Token>[_next()]; // LPAREN
    _lookaheadAfterParens(tokens);

    // Put all the lookahead tokens back into the parser's token stream.
    var after = _peekToken;
    tokens.add(after);
    tokenizer = new DivertedTokenSource(tokens, this, tokenizer);
    _next();  // Re-synchronize parser lookahead state.
    return after;
  }

  /**
   * This scan for the matching RPAREN to the current LPAREN and saves this
   * result for all nested parentheses so we don't need to look-head again.
   */
  _lookaheadAfterParens(List<Token> tokens) {
    // Save a slot in the array. This will hold the token after the parens.
    int saved = _afterParens.length;
    _afterParens.add(null); // save a slot
    while (true) {
      Token token = _next();
      tokens.add(token);
      int kind = token.kind;
      if (kind == TokenKind.RPAREN || kind == TokenKind.END_OF_FILE) {
        _afterParens[saved] = _peekToken;
        return;
      } else if (kind == TokenKind.LPAREN) {
        // Scan anything inside these nested parenthesis
        _lookaheadAfterParens(tokens);
      }
    }
  }

  _typeAsIdentifier(type) {
    if (type.name.name == 'void') {
      _errorExpected('identifer, but found "${type.name.name}"');
    }

    // TODO(jimhug): lots of errors to check for
    return type.name;
  }

  _specialIdentifier(bool includeOperators) {
    int start = _peekToken.start;
    String name;

    switch (_peek()) {
      case TokenKind.ELLIPSIS:
        _eat(TokenKind.ELLIPSIS);
        _error('rest no longer supported', _previousToken.span);
        name = identifier().name;
        break;
      case TokenKind.THIS:
        _eat(TokenKind.THIS);
        _eat(TokenKind.DOT);
        name = 'this.${identifier().name}';
        break;
      case TokenKind.GET:
        if (!includeOperators) return null;
        _eat(TokenKind.GET);
        if (_peekIdentifier()) {
          name = 'get:${identifier().name}';
        } else {
          name = 'get';
        }
        break;
      case TokenKind.SET:
        if (!includeOperators) return null;
        _eat(TokenKind.SET);
        if (_peekIdentifier()) {
          name = 'set:${identifier().name}';
        } else {
          name = 'set';
        }
        break;
      case TokenKind.OPERATOR:
        if (!includeOperators) return null;
        _eat(TokenKind.OPERATOR);
        var kind = _peek();
        if (kind == TokenKind.NEGATE) {
          name = ':negate';
          _next();
        } else {
          name = TokenKind.binaryMethodName(kind);
          if (name == null) {
            // TODO(jimhug): This is a very useful error, but we have to
            //   lose it because operator is a pseudo-keyword...
            //_errorExpected('legal operator name, but found: ${tok}');
            name = 'operator';
          } else {
            _next();
          }
        }
        break;
      default:
        return null;
    }
    return new Identifier(name, _makeSpan(start));
  }

  // always includes this and ... as legal names to simplify other code.
  declaredIdentifier([bool includeOperators=false]) {
    int start = _peekToken.start;
    var myType = null;
    var name = _specialIdentifier(includeOperators);
    bool isFinal = false;
    if (name == null) {
      myType = type();
      name = _specialIdentifier(includeOperators);
      if (name == null) {
        if (_peekIdentifier()) {
          name = identifier();
        } else if (myType is NameTypeReference && myType.names == null) {
          name = _typeAsIdentifier(myType);
          isFinal = myType.isFinal;
          myType = null;
        } else {
          // TODO(jimhug): Where do these errors get handled?
        }
      }
    }
    return new DeclaredIdentifier(myType, name, isFinal, _makeSpan(start));
  }

  finishNewExpression(int start, bool isConst) {
    var type = type();
    var name = null;
    if (_maybeEat(TokenKind.DOT)) {
      name = identifier();
    }
    var args = arguments();
    return new NewExpression(isConst, type, name, args, _makeSpan(start));
  }

  finishListLiteral(int start, bool isConst, TypeReference itemType) {
    if (_maybeEat(TokenKind.INDEX)) {
      // This is an empty array.
      return new ListExpression(isConst, itemType, [], _makeSpan(start));
    }

    var values = [];
    _eat(TokenKind.LBRACK);
    while (!_maybeEat(TokenKind.RBRACK)) {
      values.add(expression());
      if (_recover && !_recoverTo(TokenKind.RBRACK, TokenKind.COMMA)) break;
      if (!_maybeEat(TokenKind.COMMA)) {
        _eat(TokenKind.RBRACK);
        break;
      }
    }
    return new ListExpression(isConst, itemType, values, _makeSpan(start));
  }

  finishMapLiteral(int start, bool isConst,
      TypeReference keyType, TypeReference valueType) {
    var items = [];
    _eat(TokenKind.LBRACE);
    while (!_maybeEat(TokenKind.RBRACE)) {
      // This is deliberately overly permissive - checked in later pass.
      items.add(expression());
      _eat(TokenKind.COLON);
      items.add(expression());
      if (_recover && !_recoverTo(TokenKind.RBRACE, TokenKind.COMMA)) break;
      if (!_maybeEat(TokenKind.COMMA)) {
        _eat(TokenKind.RBRACE);
        break;
      }
    }
    return new MapExpression(isConst, keyType, valueType, items,
      _makeSpan(start));
  }

  finishTypedLiteral(int start, bool isConst) {
    var span = _makeSpan(start);

    final typeToBeNamedLater = new NameTypeReference(false, null, null, span);
    final genericType = addTypeArguments(typeToBeNamedLater, 0);
    final typeArgs = genericType.typeArguments;

    if (_peekKind(TokenKind.LBRACK) || _peekKind(TokenKind.INDEX)) {
      if (typeArgs.length != 1) {
        world.error('exactly one type argument expected for list',
          genericType.span);
      }
      return finishListLiteral(start, isConst, typeArgs[0]);
    } else if (_peekKind(TokenKind.LBRACE)) {
      var keyType, valueType;
      if (typeArgs.length == 1) {
        keyType = null;
        valueType = typeArgs[0];
      } else if (typeArgs.length == 2) {
        keyType = typeArgs[0];
        // making key explicit is just a warning.
        world.warning(
            'a map literal takes one type argument specifying the value type',
            keyType.span);
        valueType = typeArgs[1];
      } // o.w. the type system will detect the mismatch in type arguments.
      return finishMapLiteral(start, isConst, keyType, valueType);
    } else {
      _errorExpected('array or map literal');
    }
  }

  ///////////////////////////////////////////////////////////////////
  // Some auxilary productions.
  ///////////////////////////////////////////////////////////////////
  _readModifiers() {
    var modifiers = null;
    while (true) {
      switch(_peek()) {
        case TokenKind.STATIC:
        case TokenKind.FINAL:
        case TokenKind.CONST:
        case TokenKind.ABSTRACT:
        case TokenKind.FACTORY:
          if (modifiers == null) modifiers = [];
          modifiers.add(_next());
          break;
        default:
          return modifiers;
      }
    }

    return null;
  }

  ParameterType typeParameter() {
    // non-recursive - so always starts from zero depth
    int start = _peekToken.start;
    var name = identifier();
    var myType = null;
    if (_maybeEat(TokenKind.EXTENDS)) {
      myType = type(1);
    }

    var tp = new TypeParameter(name, myType, _makeSpan(start));
    return new ParameterType(name.name, tp);
  }

  List<ParameterType> typeParameters() {
    // always starts from zero depth
    _eat(TokenKind.LT);

    bool closed = false;
    var ret = [];
    do {
      var tp = typeParameter();
      ret.add(tp);
      if (tp.typeParameter.extendsType is GenericTypeReference &&
          tp.typeParameter.extendsType.dynamic.depth == 0) {
        closed = true;
        break;
      }
    } while (_maybeEat(TokenKind.COMMA));
    if (!closed) {
      _eat(TokenKind.GT);
    }
    return ret;
  }

  int _eatClosingAngle(int depth) {
    if (_maybeEat(TokenKind.GT)) {
      return depth;
    } else if (depth > 0 && _maybeEat(TokenKind.SAR)) {
      return depth-1;
    } else if (depth > 1 && _maybeEat(TokenKind.SHR)) {
      return depth-2;
    } else {
      _errorExpected('>');
      return depth;
    }
  }

  addTypeArguments(TypeReference baseType, int depth) {
    _eat(TokenKind.LT);
    return _finishTypeArguments(baseType, depth, []);
  }

  _finishTypeArguments(TypeReference baseType, int depth, types) {
    var delta = -1;
    do {
      var myType = type(depth+1);
      types.add(myType);
      if (myType is GenericTypeReference && myType.depth <= depth) {
        // TODO(jimhug): Friendly error if peek(COMMA).
        delta = depth - myType.depth;
        break;
      }
    } while (_maybeEat(TokenKind.COMMA));
    if (delta >= 0) {
      depth -= delta;
    } else {
      depth = _eatClosingAngle(depth);
    }

    var span = _makeSpan(baseType.span.start);
    return new GenericTypeReference(baseType, types, depth, span);
  }

  typeList() {
    var types = [];
    do {
      types.add(type());
    } while (_maybeEat(TokenKind.COMMA));

    return types;
  }

  nameTypeReference() {
    int start = _peekToken.start;
    var name;
    var names = null;
    var typeArgs = null;
    var isFinal = false;

    switch (_peek()) {
      case TokenKind.VOID:
        return new SimpleTypeReference(world.voidType, _next().span);
      case TokenKind.VAR:
        return new SimpleTypeReference(world.varType, _next().span);
      case TokenKind.FINAL:
        _eat(TokenKind.FINAL);
        isFinal = true;
        name = identifier();
        break;
      default:
        name = identifier();
        break;
    }

    while (_maybeEat(TokenKind.DOT)) {
      if (names == null) names = [];
      names.add(identifier());
    }

    return new NameTypeReference(isFinal, name, names, _makeSpan(start));
  }

  type([int depth = 0]) {
    var typeRef = nameTypeReference();

    if (_peekKind(TokenKind.LT)) {
      return addTypeArguments(typeRef, depth);
    } else {
      return typeRef;
    }
  }

  formalParameter(bool inOptionalBlock) {
    int start = _peekToken.start;
    var isThis = false;
    var isRest = false;
    var di = declaredIdentifier(false);
    var type = di.type;
    var name = di.name;

    if (name == null) {
      _error('Formal parameter invalid', _makeSpan(start));
    }

    var value = null;
    if (_maybeEat(TokenKind.ASSIGN)) {
      if (!inOptionalBlock) {
        _error('default values only allowed inside [optional] section');
      }
      value = expression();
    } else if (_peekKind(TokenKind.LPAREN)) {
      var formals = formalParameterList();
      var func = new FunctionDefinition(null, type, name, formals,
          null, null, null, _makeSpan(start));
      type = new FunctionTypeReference(false, func, func.span);
    }
    if (inOptionalBlock && value == null) {
      value = _makeLiteral(Value.fromNull(_makeSpan(start)));
    }

    return new FormalNode(isThis, isRest, type, name, value, _makeSpan(start));
  }

  formalParameterList() {
    _eatLeftParen();
    var formals = [];
    var inOptionalBlock = false;
    if (!_maybeEat(TokenKind.RPAREN)) {
      if (_maybeEat(TokenKind.LBRACK)) {
        inOptionalBlock = true;
      }
      formals.add(formalParameter(inOptionalBlock));
      while (_maybeEat(TokenKind.COMMA)) {
        if (_maybeEat(TokenKind.LBRACK)) {
          if (inOptionalBlock) {
            _error('already inside an optional block', _previousToken.span);
          }
          inOptionalBlock = true;
        }
        formals.add(formalParameter(inOptionalBlock));
      }
      if (inOptionalBlock) {
        _eat(TokenKind.RBRACK);
      }
      _eat(TokenKind.RPAREN);
    }
    return formals;
  }

  // Type names are not allowed to use pseudo keywords
  identifierForType() {
    var tok = _next();
    if (!_isIdentifier(tok.kind)) {
      _error('expected identifier, but found $tok', tok.span);
    }
    if (tok.kind !== TokenKind.IDENTIFIER && tok.kind != TokenKind.NATIVE) {
      _error('$tok may not be used as a type name', tok.span);
    }
    return new Identifier(tok.text, _makeSpan(tok.start));
  }

  identifier() {
    var tok = _next();
    if (!_isIdentifier(tok.kind)) {
      _error('expected identifier, but found $tok', tok.span);
    }

    return new Identifier(tok.text, _makeSpan(tok.start));
  }

  ///////////////////////////////////////////////////////////////////
  // These last productions handle most ambiguities in grammar
  // They will convert expressions into other types.
  ///////////////////////////////////////////////////////////////////

  /**
   * Converts an [Expression], [Formals] and a [Statment] body into a
   * [FunctionDefinition].
   */
  _makeFunction(expr, formals, body) {
    var name, type;
    if (expr is VarExpression) {
      name = expr.name;
      type = null;
    } else if (expr is DeclaredIdentifier) {
      name = expr.name;
      type = expr.type;
      if (name == null) {
        _error('expected name and type', expr.span);
      }
    } else {
      _error('bad function body', expr.span);
    }
    var span = new SourceSpan(expr.span.file, expr.span.start, body.span.end);
    var func = new FunctionDefinition(null, type, name, formals, null, null,
                                      body, span);
    return new LambdaExpression(func, func.span);
  }

  /** Converts an expression to a [DeclaredIdentifier]. */
  _makeDeclaredIdentifier(e) {
    if (e is VarExpression) {
      return new DeclaredIdentifier(null, e.name, false, e.span);
    } else if (e is DeclaredIdentifier) {
      return e;
    } else {
      _error('expected declared identifier');
      return new DeclaredIdentifier(null, null, false, e.span);
    }
  }

  /** Converts an expression into a label. */
  _makeLabel(expr) {
    if (expr is VarExpression) {
      return expr.name;
    } else {
      _errorExpected('label');
      return null;
    }
  }
}

class IncompleteSourceException implements Exception {
  final Token token;

  IncompleteSourceException(this.token);

  String toString() {
    if (token.span == null) return 'Unexpected $token';
    return token.span.toMessageString('Unexpected $token');
  }
}

/**
 * Stores a token stream that will be used by the parser. Once the parser has
 * reached the end of this [TokenSource], it switches back to the
 * [previousTokenizer]
 */
class DivertedTokenSource implements TokenSource {
  final List<Token> tokens;
  final Parser parser;
  final TokenSource previousTokenizer;
  DivertedTokenSource(this.tokens, this.parser, this.previousTokenizer);

  int _pos = 0;
  next() {
    var token = tokens[_pos];
    ++_pos;
    if (_pos == tokens.length) {
      parser.tokenizer = previousTokenizer;
    }
    return token;
  }
}
