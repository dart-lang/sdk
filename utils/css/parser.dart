// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple recursive descent parser for CSS.
 */
class Parser {
  Tokenizer tokenizer;

  final lang.SourceFile source;

  lang.Token _previousToken;
  lang.Token _peekToken;
  
  Parser(this.source, [int startOffset = 0]) {
    tokenizer = new Tokenizer(source, true, startOffset);
    _peekToken = tokenizer.next();
    _previousToken = null;
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

  lang.Token _next() {
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
    } catch (var e) {
      message = 'parsing error expected $expected';
    }
    _error(message, tok.span);
  }

  void _error(String message, [lang.SourceSpan location=null]) {
    if (location === null) {
      location = _peekToken.span;
    }

    lang.world.fatal(message, location);    // syntax errors are fatal for now
  }

  lang.SourceSpan _makeSpan(int start) {
    return new lang.SourceSpan(source, start, _previousToken.end);
  }

  ///////////////////////////////////////////////////////////////////
  // Top level productions
  ///////////////////////////////////////////////////////////////////

  List<SelectorGroup> preprocess() {
    List<SelectorGroup> groups = [];
    while (!_maybeEat(TokenKind.END_OF_FILE)) {
      do {
        int start = _peekToken.start;
        groups.add(new SelectorGroup(selector(),
            _makeSpan(start)));
      } while (_maybeEat(TokenKind.COMMA));
    }

    return groups;
  }

  // Templates are @{selectors} single line nothing else.
  SelectorGroup template() {
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
    int start = _peekToken.start;

    _eat(TokenKind.AT);
    _eat(TokenKind.LBRACE);

    SelectorGroup group = new SelectorGroup(selector(),
        _makeSpan(start));

    _eat(TokenKind.RBRACE);

    return group;
  }

  int classNameCheck(var selector, int matches) {
    if (selector.isCombinatorDescendant() ||
        (selector.isCombinatorNone() && matches == 0)) {
      if (matches < 0) {
        String tooMany = selector.toString();
        throw new CssSelectorException(
            'Can not mix Id selector with class selector(s). Id ' +
            'selector must be singleton too many starting at $tooMany');
      }
  
      return matches + 1;
    } else {
      String error = selector.toString();
      throw new CssSelectorException(
          'Selectors can not have combinators (>, +, or ~) before $error');
    }
  }

  int elementIdCheck(var selector, int matches) {
    if (selector.isCombinatorNone() && matches == 0) {
      // Perfect just one element id returns matches of -1.
      return -1;
    } else if (selector.isCombinatorDescendant()) {
        String tooMany = selector.toString();
        throw new CssSelectorException(
            'Use of Id selector must be singleton starting at $tooMany');
    } else {
      String error = selector.toString();
      throw new CssSelectorException(
          'Selectors can not have combinators (>, +, or ~) before $error');
    }
  }

  // Validate the @{css expression} only .class and #elementId are valid inside
  // of @{...}.
  validateTemplate(List<lang.Node> selectors, CssWorld cssWorld) {
    var errorSelector;                  // signal which selector didn't match.
    bool found = false;                 // signal if a selector is matched.

    int matches = 0;                    // < 0 IdSelectors, > 0 ClassSelector
    for (selector in selectors) {
      found = false;
      if (selector is ClassSelector) {
        // Any class name starting with an underscore is a private class name
        // that doesn't have to match the world of known classes.
        if (!selector.name.startsWith('_')) {
          // TODO(terry): For now iterate through all classes look for faster
          //              mechanism hash map, etc.
          for (className in cssWorld.classes) {
            if (selector.name == className) {
              matches = classNameCheck(selector, matches);
              found = true;             // .class found.
              break;
            }
          }
        } else {
          // Don't check any class name that is prefixed with an underscore.
          // However, signal as found and bump up matches; it's a valid class
          // name.
          matches = classNameCheck(selector, matches);
          found = true;                 // ._class are always okay.
        }
      } else if (selector is IdSelector) {
        // Any element id starting with an underscore is a private element id
        // that doesn't have to match the world of known elemtn ids.
        if (!selector.name.startsWith('_')) {
          for (id in cssWorld.ids) {
            if (selector.name == id) {
              matches = elementIdCheck(selector, matches);
              found = true;             // #id found.
              break;
            }
          }
        } else {
          // Don't check any element ID that is prefixed with an underscore.
          // However, signal as found and bump up matches; it's a valid element
          // ID.
          matches = elementIdCheck(selector, matches);
          found = true;                 // #_id are always okay
        }
      } else {
        String badSelector = selector.toString();
        throw new CssSelectorException(
            'Invalid template selector $badSelector');
      }

      if (!found) {
        String unknownName = selector.toString();
        throw new CssSelectorException('Unknown selector name $unknownName');
      }
    }

    // Every selector must match.
    assert((matches >= 0 ? matches : -matches) == selectors.length);
  }

  ///////////////////////////////////////////////////////////////////
  // Productions
  ///////////////////////////////////////////////////////////////////

  selector() {
    List<SimpleSelector> simpleSelectors = [];
    while (true) {
      // First item is never descendant make sure it's COMBINATOR_NONE.
      var selectorItem = simpleSelectorSequence(simpleSelectors.length == 0);
      if (selectorItem != null) {
        simpleSelectors.add(selectorItem);
      } else {
        break;
      }
    }

    return simpleSelectors;
  }

  simpleSelectorSequence(bool forceCombinatorNone) {
    int combinatorType = TokenKind.COMBINATOR_NONE;
    switch (_peek()) {
      case TokenKind.COMBINATOR_PLUS:
        _eat(TokenKind.COMBINATOR_PLUS);
        combinatorType = TokenKind.COMBINATOR_PLUS;
        break;
      case TokenKind.COMBINATOR_GREATER:
        _eat(TokenKind.COMBINATOR_GREATER);
        combinatorType = TokenKind.COMBINATOR_GREATER;
        break;
      case TokenKind.COMBINATOR_TILDE:
        _eat(TokenKind.COMBINATOR_TILDE);
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

    return simpleSelector(combinatorType);
  }

  /**
   * Simple selector grammar:
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
  simpleSelector(int combinator) {
    // TODO(terry): Nathan makes a good point parsing of namespace and element
    //              are essentially the same (asterisk or identifier) other
    //              than the error message for element.  Should consolidate the
    //              code.
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

    if (first == null) {
      // Check for HASH | class | attrib | pseudo | negation
      return simpleSelectorTail(combinator);
    }

    // Could be a namespace?
    var isNamespace = _maybeEat(TokenKind.NAMESPACE);
    if (isNamespace) {
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
          new ElementSelector(element, element.span),
          _makeSpan(start), combinator);
    } else {
      return new ElementSelector(first, _makeSpan(start), combinator);
    }
  }

  simpleSelectorTail(int combinator) {
    // Check for HASH | class | attrib | pseudo | negation
    int start = _peekToken.start;
    switch (_peek()) {
      case TokenKind.HASH:
        _eat(TokenKind.HASH);
        return new IdSelector(identifier(), _makeSpan(start), combinator);
      case TokenKind.DOT:
        _eat(TokenKind.DOT);
        return new ClassSelector(identifier(), _makeSpan(start), combinator);
      case TokenKind.PSEUDO:
        // :pseudo-class ::pseudo-element
        // TODO(terry): '::' should be token.
        _eat(TokenKind.PSEUDO);
        bool pseudoClass = _peek() != TokenKind.PSEUDO;
        var name = identifier();
        // TODO(terry): Need to handle specific pseudo class/element name and
        // backward compatible names that are : as well as :: as well as
        // parameters.
        return pseudoClass ?
            new PseudoClassSelector(name, _makeSpan(start), combinator) :
            new PseudoElementSelector(name, _makeSpan(start), combinator);

      // TODO(terry): attrib, negation.
    }
  }

  identifier() {
    var tok = _next();
    if (!TokenKind.isIdentifier(tok.kind)) {
      _error('expected identifier, but found $tok', tok.span);
    }
  
    return new Identifier(tok.text, _makeSpan(tok.start));
  }
}
