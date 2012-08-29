// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a

/**
 * A simple recursive descent parser for CSS.
 */
class Parser {
  Tokenizer tokenizer;

  var _fs;                        // If non-null filesystem to read files.
  String _basePath;               // Base path of CSS file.

  final SourceFile source;

  Token _previousToken;
  Token _peekToken;

// Communicating errors back to template parser.
// TODO(terry): Need a better mechanism (e.g., common World).
  var _erroMsgRedirector;

  Parser(this.source, [int start = 0, this._fs = null, this._basePath = null]) {
    tokenizer = new Tokenizer(source, true, start);
    _peekToken = tokenizer.next();
    _previousToken = null;
  }

  // Main entry point for parsing an entire CSS file.
  // If nestedCSS is true when we're back at processing directives from top and
  // we encounter a } then stop we're inside of a template e.g.,
  //
  //       template ... {
  //          css {
  //            .item {
  //               left: 10px;
  //            }
  //          }
  //          <div>...</div>
  //       }
  // 
  Stylesheet parse([bool nestedCSS = false, var erroMsgRedirector = null]) {
    // TODO(terry): Hack for migrating CSS errors back to template errors.
    _erroMsgRedirector = erroMsgRedirector;

    List<ASTNode> productions = [];

    int start = _peekToken.start;
    while (!_maybeEat(TokenKind.END_OF_FILE) &&
           (!nestedCSS && !_peekKind(TokenKind.RBRACE))) {
      // TODO(terry): Need to handle charset, import, media and page.
      var directive = processDirective();
      if (directive != null) {
        productions.add(directive);
      } else {
        RuleSet ruleset = processRuleSet();
        if (ruleset != null) {
          productions.add(ruleset);
        } else {
          break;
        }
      }
    }

    return new Stylesheet(productions, _makeSpan(start));
  }

  /** Generate an error if [source] has not been completely consumed. */
  void checkEndOfFile() {
    _eat(TokenKind.END_OF_FILE);
  }

  /** Guard to break out of parser when an unexpected end of file is found. */
  // TODO(jimhug): Failure to call this method can lead to inifinite parser
  //   loops.  Consider embracing exceptions for more errors to reduce
  //   the danger here.
  bool isPrematureEndOfFile() {
    if (_maybeEat(TokenKind.END_OF_FILE)) {
      _error('unexpected end of file', _peekToken.span);
      return true;
    } else {
      return false;
    }
  }

  ///////////////////////////////////////////////////////////////////
  // Basic support methods
  ///////////////////////////////////////////////////////////////////
  int _peek() {
    return _peekToken.kind;
  }

  Token _next() {
    _previousToken = _peekToken;
    _peekToken = tokenizer.next();
    return _previousToken;
  }

  bool _peekKind(int kind) {
    return _peekToken.kind == kind;
  }

  /* Is the next token a legal identifier?  This includes pseudo-keywords. */
  bool _peekIdentifier() {
    return TokenKind.isIdentifier(_peekToken.kind);
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
    _eat(TokenKind.SEMICOLON);
  }

  void _errorExpected(String expected) {
    var tok = _next();
    var message;
    try {
      message = 'expected $expected, but found $tok';
    } catch (e) {
      message = 'parsing error expected $expected';
    }
    _error(message, tok.span);
  }

  void _error(String message, [SourceSpan location=null]) {
    if (location === null) {
      location = _peekToken.span;
    }

    if (_erroMsgRedirector == null) {
       world.fatal(message, location);    // syntax errors are fatal for now
    } else {
      String text = "";
      if (location != null) {
        text = location.toMessageString("");
      }
      _erroMsgRedirector.displayError("CSS error: \r${text}\r${message}");
    }
  }

  void _warning(String message, [SourceSpan location=null]) {
    if (location === null) {
      location = _peekToken.span;
    }

    world.warning(message, location);
  }

  SourceSpan _makeSpan(int start) {
    return new SourceSpan(source, start, _previousToken.end);
  }

  ///////////////////////////////////////////////////////////////////
  // Top level productions
  ///////////////////////////////////////////////////////////////////

  // Templates are @{selectors} single line nothing else.
  SelectorGroup parseTemplate() {
    SelectorGroup selectorGroup = null;
    if (!isPrematureEndOfFile()) {
      selectorGroup = templateExpression();
    }

    return selectorGroup;
  }

  /*
   * Expect @{css_expression}
   */
  templateExpression() {
    List<Selector> selectors = [];

    int start = _peekToken.start;

    _eat(TokenKind.AT);
    _eat(TokenKind.LBRACE);

    selectors.add(processSelector());
    SelectorGroup group = new SelectorGroup(selectors, _makeSpan(start));

    _eat(TokenKind.RBRACE);

    return group;
  }

  ///////////////////////////////////////////////////////////////////
  // Productions
  ///////////////////////////////////////////////////////////////////
  
  processMedia([bool oneRequired = false]) {
    List<String> media = [];

    while (_peekIdentifier()) {
      // We have some media types.
      var medium = identifier();   // Medium ident.
      media.add(medium);
      if (!_maybeEat(TokenKind.COMMA)) {
        // No more media types exit now.
        break;
      }
    }

    if (oneRequired && media.length == 0) {
      _error('at least one media type required', _peekToken.span);
    }

    return media;
  }

  //  Directive grammar:
  //
  //  import:       '@import' [string | URI] media_list?
  //  media:        '@media' media_list '{' ruleset '}'
  //  page:         '@page' [':' IDENT]? '{' declarations '}'
  //  include:      '@include' [string | URI]
  //  stylet:       '@stylet' IDENT '{' ruleset '}'
  //  media_list:   IDENT [',' IDENT]
  //  keyframes:    '@-webkit-keyframes ...' (see grammar below).
  //  font_face:    '@font-face' '{' declarations '}'
  //
  processDirective() {
    int start = _peekToken.start;

    if (_maybeEat(TokenKind.AT)) {
      switch (_peek()) {
      case TokenKind.DIRECTIVE_IMPORT:
        _next();

        String importStr;
        if (_peekIdentifier()) {
          var func = processFunction(identifier());
          if (func is UriTerm) {
            importStr = func.text;
          }
        } else {
          importStr = processQuotedString(false);
        }

        // Any medias?
        List<String> medias = processMedia();

        if (importStr == null) {
          _error('missing import string', _peekToken.span);
        }
        return new ImportDirective(importStr, medias, _makeSpan(start));
      case TokenKind.DIRECTIVE_MEDIA:
        _next();

        // Any medias?
        List<String> media = processMedia(true);
        RuleSet ruleset;

        if (_maybeEat(TokenKind.LBRACE)) {
          ruleset = processRuleSet();
          if (!_maybeEat(TokenKind.RBRACE)) {
            _error('expected } after ruleset for @media', _peekToken.span);
          }
        } else {
          _error('expected { after media before ruleset', _peekToken.span);
        }
        return new MediaDirective(media, ruleset, _makeSpan(start));
      case TokenKind.DIRECTIVE_PAGE:
        _next();

        // Any pseudo page?
        var pseudoPage;
        if (_maybeEat(TokenKind.COLON)) {
          if (_peekIdentifier()) {
            pseudoPage = identifier();
          }
        }
        return new PageDirective(pseudoPage, processDeclarations(),
            _makeSpan(start));
      case TokenKind.DIRECTIVE_KEYFRAMES:
        /*  Key frames grammar:
         *
         *  @-webkit-keyframes [IDENT|STRING] '{' keyframes-blocks '}';
         *
         *  keyframes-blocks:
         *    [keyframe-selectors '{' declarations '}']* ;
         *
         *  keyframe-selectors:
         *    ['from'|'to'|PERCENTAGE] [',' ['from'|'to'|PERCENTAGE] ]* ;
         */
        _next();

        var name;
        if (_peekIdentifier()) {
          name = identifier();
        }

        _eat(TokenKind.LBRACE);

        KeyFrameDirective kf = new KeyFrameDirective(name, _makeSpan(start));

        do {
          Expressions selectors = new Expressions(_makeSpan(start));

          do {
            var term = processTerm();

            // TODO(terry): Only allow from, to and PERCENTAGE ...

            selectors.add(term);
          } while (_maybeEat(TokenKind.COMMA));

          kf.add(new KeyFrameBlock(selectors, processDeclarations(),
              _makeSpan(start)));

        } while (!_maybeEat(TokenKind.RBRACE));

        return kf;
      case TokenKind.DIRECTIVE_FONTFACE:
        _next();

        List<Declaration> decls = [];

        // TODO(terry): To Be Implemented

        return new FontFaceDirective(decls, _makeSpan(start));
      case TokenKind.DIRECTIVE_INCLUDE:
        _next();
        String filename = processQuotedString(false);
        if (_fs != null) {
          // Does CSS file exist?
          if (_fs.fileExists('${_basePath}${filename}')) {
            String basePath = "";
            int idx = filename.lastIndexOf('/');
            if (idx >= 0) {
              basePath = filename.substring(0, idx + 1);
            }
            basePath = '${_basePath}${basePath}';
            // Yes, let's parse this file as well.
            String fullFN = '${basePath}${filename}';
            String contents = _fs.readAll(fullFN);
            Parser parser = new Parser(new SourceFile(fullFN, contents), 0,
                _fs, basePath);
            Stylesheet stylesheet = parser.parse();
            return new IncludeDirective(filename, stylesheet, _makeSpan(start));
          }

          _error('file doesn\'t exist ${filename}', _peekToken.span);
        }

        print("WARNING: @include doesn't work for uitest");
        return new IncludeDirective(filename, null, _makeSpan(start));
      case TokenKind.DIRECTIVE_STYLET:
        /* Stylet grammar:
        *
        *  @stylet IDENT '{'
        *    ruleset
        *  '}'
        */
        _next();

        var name;
        if (_peekIdentifier()) {
          name = identifier();
        }

        _eat(TokenKind.LBRACE);

        List<ASTNode> productions = [];

        start = _peekToken.start;
        while (!_maybeEat(TokenKind.END_OF_FILE)) {
          RuleSet ruleset = processRuleSet();
          if (ruleset == null) {
            break;
          }
          productions.add(ruleset);
        }

        _eat(TokenKind.RBRACE);

        return new StyletDirective(name, productions, _makeSpan(start));
      default:
        _error('unknown directive, found $_peekToken', _peekToken.span);
      }
    }
  }

  RuleSet processRuleSet() {
    int start = _peekToken.start;

    SelectorGroup selGroup = processSelectorGroup();
    if (selGroup != null) {
      return new RuleSet(selGroup, processDeclarations(), _makeSpan(start));
    }
  }

  DeclarationGroup processDeclarations() {
    int start = _peekToken.start;

    _eat(TokenKind.LBRACE);

    List<Declaration> decls = [];
    do {
      Declaration decl = processDeclaration();
      if (decl != null) {
        decls.add(decl);
      }
    } while (_maybeEat(TokenKind.SEMICOLON));

    _eat(TokenKind.RBRACE);

    return new DeclarationGroup(decls, _makeSpan(start));
  }

  SelectorGroup processSelectorGroup() {
    List<Selector> selectors = [];
    int start = _peekToken.start;
    do {
      Selector selector = processSelector();
      if (selector != null) {
        selectors.add(selector);
      }
    } while (_maybeEat(TokenKind.COMMA));

    if (selectors.length > 0) {
      return new SelectorGroup(selectors, _makeSpan(start));
    }
  }

  /* Return list of selectors
   *
   */
  processSelector() {
    List<SimpleSelectorSequence> simpleSequences = [];
    int start = _peekToken.start;
    while (true) {
      // First item is never descendant make sure it's COMBINATOR_NONE.
      var selectorItem = simpleSelectorSequence(simpleSequences.length == 0);
      if (selectorItem != null) {
        simpleSequences.add(selectorItem);
      } else {
        break;
      }
    }

    if (simpleSequences.length > 0) {
      return new Selector(simpleSequences, _makeSpan(start));
    }
  }

  simpleSelectorSequence(bool forceCombinatorNone) {
    int start = _peekToken.start;
    int combinatorType = TokenKind.COMBINATOR_NONE;

    switch (_peek()) {
      case TokenKind.PLUS:
        _eat(TokenKind.PLUS);
        combinatorType = TokenKind.COMBINATOR_PLUS;
        break;
      case TokenKind.GREATER:
        _eat(TokenKind.GREATER);
        combinatorType = TokenKind.COMBINATOR_GREATER;
        break;
      case TokenKind.TILDE:
        _eat(TokenKind.TILDE);
        combinatorType = TokenKind.COMBINATOR_TILDE;
        break;
    }

    // Check if WHITESPACE existed between tokens if so we're descendent.
    if (combinatorType == TokenKind.COMBINATOR_NONE && !forceCombinatorNone) {
      if (this._previousToken != null &&
          this._previousToken.end != this._peekToken.start) {
        combinatorType = TokenKind.COMBINATOR_DESCENDANT;
      }
    }

    var simpleSel = simpleSelector();
    if (simpleSel != null) {
      return new SimpleSelectorSequence(simpleSel, _makeSpan(start),
          combinatorType);
    }
  }

  /**
   * Simple selector grammar:
   *
   *    simple_selector_sequence
   *       : [ type_selector | universal ]
   *         [ HASH | class | attrib | pseudo | negation ]*
   *       | [ HASH | class | attrib | pseudo | negation ]+
   *    type_selector
   *       : [ namespace_prefix ]? element_name
   *    namespace_prefix
   *       : [ IDENT | '*' ]? '|'
   *    element_name
   *       : IDENT
   *    universal
   *       : [ namespace_prefix ]? '*'
   *    class
   *       : '.' IDENT
   */
  simpleSelector() {
    // TODO(terry): Nathan makes a good point parsing of namespace and element
    //              are essentially the same (asterisk or identifier) other
    //              than the error message for element.  Should consolidate the
    //              code.
    // TODO(terry): Need to handle attribute namespace too.
    var first;
    int start = _peekToken.start;
    switch (_peek()) {
      case TokenKind.ASTERISK:
        // Mark as universal namespace.
        var tok = _next();
        first = new Wildcard(_makeSpan(tok.start));
        break;
      case TokenKind.IDENTIFIER:
        int startIdent = _peekToken.start;
        first = identifier();
        break;
    }

    if (_maybeEat(TokenKind.NAMESPACE)) {
      var element;
      switch (_peek()) {
        case TokenKind.ASTERISK:
          // Mark as universal element
          var tok = _next();
          element = new Wildcard(_makeSpan(tok.start));
          break;
        case TokenKind.IDENTIFIER:
          element = identifier();
          break;
        default:
          _error('expected element name or universal(*), but found $_peekToken',
              _peekToken.span);
      }

      return new NamespaceSelector(first,
          new ElementSelector(element, element.span), _makeSpan(start));
    } else if (first != null) {
      return new ElementSelector(first, _makeSpan(start));
    } else {
      // Check for HASH | class | attrib | pseudo | negation
      return simpleSelectorTail();
    }
  }

  simpleSelectorTail() {
    // Check for HASH | class | attrib | pseudo | negation
    int start = _peekToken.start;
    switch (_peek()) {
      case TokenKind.HASH:
        _eat(TokenKind.HASH);
        return new IdSelector(identifier(), _makeSpan(start));
      case TokenKind.DOT:
        _eat(TokenKind.DOT);
        return new ClassSelector(identifier(), _makeSpan(start));
      case TokenKind.COLON:
        // :pseudo-class ::pseudo-element
        // TODO(terry): '::' should be token.
        _eat(TokenKind.COLON);
        bool pseudoElement = _maybeEat(TokenKind.COLON);
        var name = identifier();
        // TODO(terry): Need to handle specific pseudo class/element name and
        // backward compatible names that are : as well as :: as well as
        // parameters.
        return pseudoElement ?
            new PseudoElementSelector(name, _makeSpan(start)) :
            new PseudoClassSelector(name, _makeSpan(start));
      case TokenKind.LBRACK:
        return processAttribute();
    }
  }

  //  Attribute grammar:
  //
  //  attributes :
  //    '[' S* IDENT S* [ ATTRIB_MATCHES S* [ IDENT | STRING ] S* ]? ']'
  //
  //  ATTRIB_MATCHES :
  //    [ '=' | INCLUDES | DASHMATCH | PREFIXMATCH | SUFFIXMATCH | SUBSTRMATCH ]
  //
  //  INCLUDES:         '~='
  //
  //  DASHMATCH:        '|='
  //
  //  PREFIXMATCH:      '^='
  //
  //  SUFFIXMATCH:      '$='
  //
  //  SUBSTRMATCH:      '*='
  //
  //
  processAttribute() {
    int start = _peekToken.start;

    if (_maybeEat(TokenKind.LBRACK)) {
      var attrName = identifier();

      int op = TokenKind.NO_MATCH;
      switch (_peek()) {
      case TokenKind.EQUALS:
      case TokenKind.INCLUDES:        // ~=
      case TokenKind.DASH_MATCH:      // |=
      case TokenKind.PREFIX_MATCH:    // ^=
      case TokenKind.SUFFIX_MATCH:    // $=
      case TokenKind.SUBSTRING_MATCH: // *=
        op = _peek();
        _next();
        break;
      }

      String value;
      if (op != TokenKind.NO_MATCH) {
        // Operator hit so we require a value too.
        if (_peekIdentifier()) {
          value = identifier();
        } else {
          value = processQuotedString(false);
        }

        if (value == null) {
          _error('expected attribute value string or ident', _peekToken.span);
        }
      }

      _eat(TokenKind.RBRACK);

      return new AttributeSelector(attrName, op, value, _makeSpan(start));
    }
  }

  //  Declaration grammar:
  //
  //  declaration:  property ':' expr prio?
  //
  //  property:  IDENT
  //  prio:      !important
  //  expr:      (see processExpr)
  //
  processDeclaration() {
    Declaration decl;

    int start = _peekToken.start;

    // IDENT ':' expr '!important'?
    if (TokenKind.isIdentifier(_peekToken.kind)) {
      var propertyIdent = identifier();
      _eat(TokenKind.COLON);
  
      decl = new Declaration(propertyIdent, processExpr(), _makeSpan(start));

      // Handle !important (prio)
      decl.important = _maybeEat(TokenKind.IMPORTANT);
    }

    return decl;
  }

  //  Expression grammar:
  //
  //  expression:   term [ operator? term]*
  //
  //  operator:     '/' | ','
  //  term:         (see processTerm)
  //
  processExpr() {
    int start = _peekToken.start;
    Expressions expressions = new Expressions(_makeSpan(start));

    bool keepGoing = true;
    var expr;
    while (keepGoing && (expr = processTerm()) != null) {
      var op;

      int opStart = _peekToken.start;

      switch (_peek()) {
      case TokenKind.SLASH:
        op = new OperatorSlash(_makeSpan(opStart));
        break;
      case TokenKind.COMMA:
        op = new OperatorComma(_makeSpan(opStart));
        break;
      }

      if (expr != null) {
        expressions.add(expr);
      } else {
        keepGoing = false;
      }

      if (op != null) {
        expressions.add(op);
        _next();
      }
    }

    return expressions;
  }

  //  Term grammar:
  //
  //  term:
  //    unary_operator?
  //    [ term_value ]
  //    | STRING S* | IDENT S* | URI S* | UNICODERANGE S* | hexcolor
  //
  //  term_value:
  //    NUMBER S* | PERCENTAGE S* | LENGTH S* | EMS S* | EXS S* | ANGLE S* |
  //    TIME S* | FREQ S* | function
  //
  //  NUMBER:       {num}
  //  PERCENTAGE:   {num}%
  //  LENGTH:       {num}['px' | 'cm' | 'mm' | 'in' | 'pt' | 'pc']
  //  EMS:          {num}'em'
  //  EXS:          {num}'ex'
  //  ANGLE:        {num}['deg' | 'rad' | 'grad']
  //  TIME:         {num}['ms' | 's']
  //  FREQ:         {num}['hz' | 'khz']
  //  function:     IDENT '(' expr ')'
  //
  processTerm() {
    int start = _peekToken.start;
    Token t;             // token for term's value
    var value;                // value of term (numeric values)

    var unary = "";

    switch (_peek()) {
    case TokenKind.HASH:
      this._eat(TokenKind.HASH);
      String hexText;
      if (_peekKind(TokenKind.INTEGER)) {
        String hexText1 = _peekToken.text;
        _next();
        if (_peekIdentifier()) {
          hexText = '${hexText1}${identifier().name}';
        } else {
          hexText = hexText1;
        }
      } else if (_peekIdentifier()) {
        hexText = identifier().name;
      } else {
        _errorExpected("hex number");
      }

      try {
        int hexValue = parseHex(hexText);
        return new HexColorTerm(hexValue, hexText, _makeSpan(start));
      } on HexNumberException catch (hne) {
        _error('Bad hex number', _makeSpan(start));
      }
      break;
    case TokenKind.INTEGER:
      t = _next();
      value = Math.parseInt("${unary}${t.text}");
      break;
    case TokenKind.DOUBLE:
      t = _next();
      value = Math.parseDouble("${unary}${t.text}");
      break;
    case TokenKind.SINGLE_QUOTE:
    case TokenKind.DOUBLE_QUOTE:
      value = processQuotedString(false);
      value = '"${value}"';
      return new LiteralTerm(value, value, _makeSpan(start));
    case TokenKind.LPAREN:
      _next();

      GroupTerm group = new GroupTerm(_makeSpan(start));

      do {
        var term = processTerm();
        if (term != null && term is LiteralTerm) {
          group.add(term);
        }
      } while (!_maybeEat(TokenKind.RPAREN));

      return group;
    case TokenKind.LBRACK:
      _next();

      var term = processTerm();
      if (!(term is NumberTerm)) {
        _error('Expecting a positive number', _makeSpan(start));
      }

      _eat(TokenKind.RBRACK);

      return new ItemTerm(term.value, term.text, _makeSpan(start));
    case TokenKind.IDENTIFIER:
      var nameValue = identifier();   // Snarf up the ident we'll remap, maybe.

      if (_maybeEat(TokenKind.LPAREN)) {
        // FUNCTION
        return processFunction(nameValue);
      } else {
        // TODO(terry): Need to have a list of known identifiers today only
        //              'from' is special.
        if (nameValue.name == 'from') {
          return new LiteralTerm(nameValue, nameValue.name, _makeSpan(start));
        }

        // What kind of identifier is it?
        try {
          // Named color?
          int colorValue = TokenKind.matchColorName(nameValue.name);

          // Yes, process the color as an RGB value.
          String rgbColor = TokenKind.decimalToHex(colorValue, 3);
          try {
            colorValue = parseHex(rgbColor);
          } on HexNumberException catch (hne) {
            _error('Bad hex number', _makeSpan(start));
          }
          return new HexColorTerm(colorValue, rgbColor, _makeSpan(start));
        } catch (error) {
          if (error is NoColorMatchException) {
            // TODO(terry): Other named things to match with validator?

            // TODO(terry): Disable call to _warning need one World class for
            //              both CSS parser and other parser (e.g., template)
            //              so all warnings, errors, options, etc. are driven
            //              from the one World.
//          _warning('Unknown property value ${error.name}', _makeSpan(start));
            return new LiteralTerm(nameValue, nameValue.name, _makeSpan(start));
          }
        }
      }
    }

    var term;
    var unitType = this._peek();

    switch (unitType) {
    case TokenKind.UNIT_EM:
      term = new EmTerm(value, t.text, _makeSpan(start));
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_EX:
      term = new ExTerm(value, t.text, _makeSpan(start));
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_LENGTH_PX:
    case TokenKind.UNIT_LENGTH_CM:
    case TokenKind.UNIT_LENGTH_MM:
    case TokenKind.UNIT_LENGTH_IN:
    case TokenKind.UNIT_LENGTH_PT:
    case TokenKind.UNIT_LENGTH_PC:
      term = new LengthTerm(value, t.text, _makeSpan(start), unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_ANGLE_DEG:
    case TokenKind.UNIT_ANGLE_RAD:
    case TokenKind.UNIT_ANGLE_GRAD:
      term = new AngleTerm(value, t.text, _makeSpan(start), unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_TIME_MS:
    case TokenKind.UNIT_TIME_S:
      term = new TimeTerm(value, t.text, _makeSpan(start), unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_FREQ_HZ:
    case TokenKind.UNIT_FREQ_KHZ:
      term = new FreqTerm(value, t.text, _makeSpan(start), unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.PERCENT:
      term = new PercentageTerm(value, t.text, _makeSpan(start));
      _next();    // Skip the %
      break;
    case TokenKind.UNIT_FRACTION:
      term = new FractionTerm(value, t.text, _makeSpan(start));
      _next();     // Skip the unit
      break;
    default:
      if (value != null) {
        term = new NumberTerm(value, t.text, _makeSpan(start));
      }
    }

    return term;
  }

  processQuotedString([bool urlString = false]) {
    int start = _peekToken.start;

    // URI term sucks up everything inside of quotes(' or ") or between parens
    int stopToken = urlString ? TokenKind.RPAREN : -1;
    switch (_peek()) {
    case TokenKind.SINGLE_QUOTE:
      stopToken = TokenKind.SINGLE_QUOTE;
      _next();    // Skip the SINGLE_QUOTE.
      break;
    case TokenKind.DOUBLE_QUOTE:
      stopToken = TokenKind.DOUBLE_QUOTE;
      _next();    // Skip the DOUBLE_QUOTE.
      break;
    default:
      if (urlString) {
        if (_peek() == TokenKind.LPAREN) {
          _next();    // Skip the LPAREN.
        }
        stopToken = TokenKind.RPAREN;
      } else {
        _error('unexpected string', _makeSpan(start));
      }
    }

    StringBuffer stringValue = new StringBuffer();

    // Gobble up everything until we hit our stop token.
    int runningStart = _peekToken.start;
    while (_peek() != stopToken && _peek() != TokenKind.END_OF_FILE) {
      var tok = _next();
      stringValue.add(tok.text);
    }

    if (stopToken != TokenKind.RPAREN) {
      _next();    // Skip the SINGLE_QUOTE or DOUBLE_QUOTE;
    }

    return stringValue.toString();
  }

  //  Function grammar:
  //
  //  function:     IDENT '(' expr ')'
  //
  processFunction(Identifier func) {
    int start = _peekToken.start;

    String name = func.name;

    switch (name) {
    case 'url':
      // URI term sucks up everything inside of quotes(' or ") or between parens
      String urlParam = processQuotedString(true);

      // TODO(terry): Better error messge and checking for mismatched quotes.
      if (_peek() == TokenKind.END_OF_FILE) {
        _error("problem parsing URI", _peekToken.span);
      }

      if (_peek() == TokenKind.RPAREN) {
        _next();
      }

      return new UriTerm(urlParam, _makeSpan(start));
    case 'calc':
      // TODO(terry): Implement expression handling...
      break;
    default:
      var expr = processExpr();
      if (!_maybeEat(TokenKind.RPAREN)) {
        _error("problem parsing function expected ), ", _peekToken.span);
      }

      return new FunctionTerm(name, name, expr, _makeSpan(start));
    }

    return null;
  }

  identifier() {
    var tok = _next();
    if (!TokenKind.isIdentifier(tok.kind)) {
      _error('expected identifier, but found $tok', tok.span);
    }
  
    return new Identifier(tok.text, _makeSpan(tok.start));
  }

  // TODO(terry): Move this to base <= 36 and into shared code.
  static int _hexDigit(int c) {
    if(c >= 48/*0*/ && c <= 57/*9*/) {
      return c - 48;
    } else if (c >= 97/*a*/ && c <= 102/*f*/) {
      return c - 87;
    } else if (c >= 65/*A*/ && c <= 70/*F*/) {
      return c - 55;
    } else {
      return -1;
    }
  }

  static int parseHex(String hex) {
    var result = 0;

    for (int i = 0; i < hex.length; i++) {
      var digit = _hexDigit(hex.charCodeAt(i));
      if (digit < 0) {
        throw new HexNumberException();
      }
      result = (result << 4) + digit;
    }

    return result;
  }
}

/** Not a hex number. */
class HexNumberException implements Exception {
  HexNumberException();
}

