// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a

class TagStack {
  List<ASTNode> _stack;

  TagStack(var elem) : _stack = [] {
    _stack.add(elem);
  }

  void push(var elem) {
    _stack.add(elem);
  }

  ASTNode pop() {
    return _stack.removeLast();
  }

  top() {
    return _stack.last();
  }
}

// TODO(terry): Cleanup returning errors from CSS to common World error
//              handler.
class ErrorMsgRedirector {
  void displayError(String msg) {
    if (world.printHandler != null) {
      world.printHandler(msg);
    } else {
      print("Unhandler Error: ${msg}");
    }
    world.errors++;
  }
}

/**
 * A simple recursive descent parser for HTML.
 */
class Parser {
  Tokenizer tokenizer;

  var _fs;                        // If non-null filesystem to read files.

  final SourceFile source;

  Token _previousToken;
  Token _peekToken;

  PrintHandler printHandler;

  Parser(this.source, [int start = 0, this._fs = null]) {
    tokenizer = new Tokenizer(source, true, start);
    _peekToken = tokenizer.next();
    _previousToken = null;
  }

  // Main entry point for parsing an entire HTML file.
  List<Template> parse([PrintHandler handler = null]) {
    printHandler = handler;

    List<Template> productions = [];

    int start = _peekToken.start;
    while (!_maybeEat(TokenKind.END_OF_FILE)) {
      Template template = processTemplate();
      if (template != null) {
        productions.add(template);
      }
    }

    return productions;
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

  Token _next([bool inTag = true]) {
    _previousToken = _peekToken;
    _peekToken = tokenizer.next(inTag);
    return _previousToken;
  }

  bool _peekKind(int kind) {
    return _peekToken.kind == kind;
  }

  /* Is the next token a legal identifier?  This includes pseudo-keywords. */
  bool _peekIdentifier([String name = null]) {
    if (TokenKind.isIdentifier(_peekToken.kind)) {
      return (name != null) ? _peekToken.text == name : true;
    }

    return false;
  }

  bool _maybeEat(int kind) {
    if (_peekToken.kind == kind) {
      _previousToken = _peekToken;
      if (kind == TokenKind.GREATER_THAN) {
        _peekToken = tokenizer.next(false);
      } else {
        _peekToken = tokenizer.next();
      }
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

    if (printHandler == null) {
      world.fatal(message, location);    // syntax errors are fatal for now
    } else {
      // TODO(terry):  Need common World view for css and template parser.
      //               For now this is how we return errors from CSS - ugh.
      printHandler(message);
    }
  }

  void _warning(String message, [SourceSpan location=null]) {
    if (location === null) {
      location = _peekToken.span;
    }

    if (printHandler == null) {
      world.warning(message, location);
    } else {
      // TODO(terry):  Need common World view for css and template parser.
      //               For now this is how we return errors from CSS - ugh.
      printHandler(message);
    }
  }

  SourceSpan _makeSpan(int start) {
    return new SourceSpan(source, start, _previousToken.end);
  }

  ///////////////////////////////////////////////////////////////////
  // Top level productions
  ///////////////////////////////////////////////////////////////////

  Template processTemplate() {
    var template;

    int start = _peekToken.start;

    // Handle the template keyword followed by template signature.
    _eat(TokenKind.TEMPLATE_KEYWORD);

    if (_peekIdentifier()) {
      final templateName = identifier();

      List<Map<Identifier, Identifier>> params =
        new List<Map<Identifier, Identifier>>();

      _eat(TokenKind.LPAREN);

      start = _peekToken.start;
      while (true) {
        // TODO(terry): Need robust Dart argument parser (e.g.,
        //              List<String> arg1, etc).
        var type = processAsIdentifier();
        var paramName = processAsIdentifier();
        if (type != null && paramName != null) {
          params.add({'type': type, 'name' : paramName});

          if (!_maybeEat(TokenKind.COMMA)) {
            break;
          }
        } else {
          // No parameters we're done.
          break;
        }
      }

      _eat(TokenKind.RPAREN);

      TemplateSignature sig =
        new TemplateSignature(templateName.name, params, _makeSpan(start));

      TemplateContent content = processTemplateContent();

      template = new Template(sig, content, _makeSpan(start));
    }

    return template;
  }

  // All tokens are identifiers tokenizer is geared to HTML if identifiers are
  // HTML element or attribute names we need them as an identifier.  Used by
  // template signatures and expressions in ${...}
  Identifier processAsIdentifier() {
    int start = _peekToken.start;

    if (_peekIdentifier()) {
      return identifier();
    } else if (TokenKind.validTagName(_peek())) {
      var tok = _next();
      return new Identifier(TokenKind.tagNameFromTokenId(tok.kind),
        _makeSpan(start));
    }
  }

  css.Stylesheet processCSS() {
    // Is there a CSS block?
    if (_peekIdentifier('css')) {
      _next();

      int start = _peekToken.start;
      _eat(TokenKind.LBRACE);

      css.Stylesheet cssCtx = processCSSContent(source, tokenizer.startIndex);

      // TODO(terry): Hack, restart template parser where CSS parser stopped.
      tokenizer.index = lastCSSIndexParsed;
     _next(false);

      _eat(TokenKind.RBRACE);       // close } of css block

      return cssCtx;
    }
  }

  // TODO(terry): get should be able to use all template control flow but return
  //              a string instead of a node.  Maybe expose both html and get
  //              e.g.,
  //
  //              A.)
  //              html {
  //                <div>...</div>
  //              }
  //
  //              B.)
  //              html foo() {
  //                <div>..</div>
  //              }
  //
  //              C.)
  //              get {
  //                <div>...</div>
  //              }
  //
  //              D.)
  //              get foo() {
  //                <div>..</div>
  //              }
  //
  //              Only one default allower either A or C the constructor will
  //              generate a string or a node.
  //              Examples B and D would generate getters that either return
  //              a node for B or a String for D.
  //
  List<TemplateGetter> processGetters() {
    List<TemplateGetter> getters = [];

    while (true) {
      if (_peekIdentifier('get')) {
        _next();

        int start = _peekToken.start;
        if (_peekIdentifier()) {
          String getterName = identifier().name;

          List<Map<Identifier, Identifier>> params =
            new List<Map<Identifier, Identifier>>();

          _eat(TokenKind.LPAREN);

          start = _peekToken.start;
          while (true) {
            // TODO(terry): Need robust Dart argument parser (e.g.,
            //              List<String> arg1, etc).
            var type = processAsIdentifier();
            var paramName = processAsIdentifier();
            if (paramName == null && type != null) {
              paramName = type;
              type = "";
            }
            if (type != null && paramName != null) {
              params.add({'type': type, 'name' : paramName});

              if (!_maybeEat(TokenKind.COMMA)) {
                break;
              }
            } else {
              // No parameters we're done.
              break;
            }
          }

          _eat(TokenKind.RPAREN);

          _eat(TokenKind.LBRACE);

          var elems = new TemplateElement.fragment(_makeSpan(_peekToken.start));
          var templateDoc = processHTML(elems);

          _eat(TokenKind.RBRACE);       // close } of get block

          getters.add(new TemplateGetter(getterName, params, templateDoc,
            _makeSpan(_peekToken.start)));
        }
      } else {
        break;
      }
    }

    return getters;

/*
    get newTotal(value) {
      <div class="alignleft">${value}</div>
    }

    String get HTML_newTotal(value) {
      return '<div class="alignleft">${value}</div>
    }

*/
  }

  TemplateContent processTemplateContent() {
    css.Stylesheet ss;

    _eat(TokenKind.LBRACE);

    int start = _peekToken.start;

    ss = processCSS();

    // TODO(terry): getters should be allowed anywhere not just after CSS.
    List<TemplateGetter> getters = processGetters();

    var elems = new TemplateElement.fragment(_makeSpan(_peekToken.start));
    var templateDoc = processHTML(elems);

    // TODO(terry): Should allow css { } to be at beginning or end of the
    //              template's content.  Today css only allow at beginning
    //              because the css {...} is sucked in as a text node.  We'll
    //              need a special escape for css maybe:
    //
    //                  ${#css}
    //                  ${/css}
    //
    //              uggggly!


    _eat(TokenKind.RBRACE);

    return new TemplateContent(ss, templateDoc, getters, _makeSpan(start));
  }

  int lastCSSIndexParsed;       // TODO(terry): Hack, last good CSS parsed.

  css.Stylesheet processCSSContent(var cssSource, int start) {
    try {
      css.Parser parser = new css.Parser(new SourceFile(
          SourceFile.IN_MEMORY_FILE, cssSource.text), start);

      css.Stylesheet stylesheet = parser.parse(false, new ErrorMsgRedirector());

      var lastParsedChar = parser.tokenizer.startIndex;

      lastCSSIndexParsed = lastParsedChar;

      return stylesheet;
    } catch (cssParseException) {
      // TODO(terry): Need SourceSpan from CSS parser to pass onto _error.
      _error("Unexcepted CSS error: ${cssParseException.toString()}");
    }
  }

  /* TODO(terry): Assume template {   },  single close curley as a text node
   *              inside of the template would need to be escaped maybe \}
   */
  processHTML(TemplateElement root) {
    assert(root.isFragment);
    TagStack stack = new TagStack(root);

    int start = _peekToken.start;

    bool done = false;
    while (!done) {
      if (_maybeEat(TokenKind.LESS_THAN)) {
        // Open tag
        start = _peekToken.start;

        if (TokenKind.validTagName(_peek())) {
          Token tagToken = _next();

          Map<String, TemplateAttribute> attrs = processAttributes();

          String varName;
          if (attrs.containsKey('var')) {
            varName = attrs['var'].value;
            attrs.remove('var');
          }

          int scopeType;     // 1 implies scoped, 2 implies non-scoped element.
          if (_maybeEat(TokenKind.GREATER_THAN)) {
            // Scoped unless the tag is explicitly known as an unscoped tag
            // e.g., <br>.
            scopeType = TokenKind.unscopedTag(tagToken.kind) ? 2 : 1;
          } else if (_maybeEat(TokenKind.END_NO_SCOPE_TAG)) {
            scopeType = 2;
          }
          if (scopeType > 0) {
            var elem = new TemplateElement.attributes(tagToken.kind,
              attrs.getValues(), varName, _makeSpan(start));
            stack.top().add(elem);

            if (scopeType == 1) {
              // Maybe more nested tags/text?
              stack.push(elem);
            }
          }
        } else {
          // Close tag
          _eat(TokenKind.SLASH);
          if (TokenKind.validTagName(_peek())) {
            Token tagToken = _next();

            _eat(TokenKind.GREATER_THAN);

            var elem = stack.pop();
            if (elem is TemplateElement && !elem.isFragment) {
              if (elem.tagTokenId != tagToken.kind) {
                _error('Tag doesn\'t match expected </${elem.tagName}> got ' +
                  '</${TokenKind.tagNameFromTokenId(tagToken.kind)}>');
              }
            } else {
              // Too many end tags.
              _error('Too many end tags at ' +
                  '</${TokenKind.tagNameFromTokenId(tagToken.kind)}>');
            }
          }
        }
      } else if (_maybeEat(TokenKind.START_COMMAND)) {
        Identifier commandName = processAsIdentifier();
        if (commandName != null) {
          switch (commandName.name) {
            case "each":
            case "with":
              var listName = processAsIdentifier();
              if (listName != null) {
                var loopItem = processAsIdentifier();
                // Is the optional item name specified?
                //    #each lists [item]
                //    #with expression [item]

                _eat(TokenKind.RBRACE);

                var frag = new TemplateElement.fragment(
                    _makeSpan(_peekToken.start));
                TemplateDocument docFrag = processHTML(frag);

                if (docFrag != null) {
                  var span = _makeSpan(start);
                  var cmd;
                  if (commandName.name == "each") {
                    cmd = new TemplateEachCommand(listName, loopItem, docFrag,
                        span);
                  } else if (commandName.name == "with") {
                    cmd = new TemplateWithCommand(listName, loopItem, docFrag,
                        span);
                  }

                  stack.top().add(cmd);
                  stack.push(cmd);
                }

                // Process ${/commandName}
                _eat(TokenKind.END_COMMAND);

                // Close command ${/commandName}
                if (_peekIdentifier()) {
                  commandName = identifier();
                  switch (commandName.name) {
                    case "each":
                    case "with":
                    case "if":
                    case "else":
                      break;
                    default:
                      _error('Unknown command \${#${commandName}}');
                  }
                  var elem = stack.pop();
                  if (elem is TemplateEachCommand &&
                      commandName.name == "each") {

                  } else if (elem is TemplateWithCommand &&
                    commandName.name == "with") {

                  } /*else if (elem is TemplateIfCommand && commandName == "if") {

                  }
                  */else {
                    String expectedCmd;
                    if (elem is TemplateEachCommand) {
                      expectedCmd = "\${/each}";
                    } /* TODO(terry): else other commands as well */
                    _error('mismatched command expected ${expectedCmd} got...');
                    return;
                  }
                  _eat(TokenKind.RBRACE);
                } else {
                  _error('Missing command name \${/commandName}');
                }
              } else {
                _error("Missing listname for #each command");
              }
              break;
            case "if":
              break;
            case "else":
              break;
            default:
              // Calling another template.
              int startPos = this._previousToken.end;
              // Gobble up everything until we hit }
              while (_peek() != TokenKind.RBRACE &&
                     _peek() != TokenKind.END_OF_FILE) {
                _next(false);
              }

              if (_peek() == TokenKind.RBRACE) {
                int endPos = this._previousToken.end;
                TemplateCall callNode = new TemplateCall(commandName.name,
                    source.text.substring(startPos, endPos), _makeSpan(start));
                stack.top().add(callNode);

                _next(false);
              } else {
                _error("Unknown template command");
              }
          }  // End of switch/case
        }
      } else if (_peekKind(TokenKind.END_COMMAND)) {
        break;
      } else {
        // Any text or expression nodes?
        var nodes = processTextNodes();
        if (nodes.length > 0) {
          assert(stack.top() != null);
          for (var node in nodes) {
            stack.top().add(node);
          }
        } else {
          break;
        }
      }
    }
/*
    if (elems.children.length != 1) {
      print("ERROR: No closing end-tag for elems ${elems[elems.length - 1]}");
    }
*/
    var docChildren = new List<ASTNode>();
    docChildren.add(stack.pop());
    return new TemplateDocument(docChildren, _makeSpan(start));
  }

  /* Map is used so only last unique attribute name is remembered and to quickly
   * find the var attribute.
   */
  Map<String, TemplateAttribute> processAttributes() {
    Map<String, TemplateAttribute> attrs = new Map();

    int start = _peekToken.start;
    String elemName;
    while (_peekIdentifier() ||
           (elemName = TokenKind.tagNameFromTokenId(_peek())) != null) {
      var attrName;
      if (elemName == null) {
        attrName = identifier();
      } else {
        attrName = new Identifier(elemName, _makeSpan(start));
        _next();
      }

      var attrValue;

      // Attribute value?
      if (_peek() == TokenKind.ATTR_VALUE) {
        var tok = _next();
        attrValue = new StringValue(tok.value, _makeSpan(tok.start));
      }

      attrs[attrName.name] =
        new TemplateAttribute(attrName, attrValue, _makeSpan(start));

      start = _peekToken.start;
      elemName = null;
    }

    return attrs;
  }

  identifier() {
    var tok = _next();
    if (!TokenKind.isIdentifier(tok.kind)) {
      _error('expected identifier, but found $tok', tok.span);
    }

    return new Identifier(tok.text, _makeSpan(tok.start));
  }

  List<ASTNode> processTextNodes() {
    // May contain TemplateText and TemplateExpression.
    List<ASTNode> nodes = [];

    int start = _peekToken.start;
    bool inExpression = false;
    StringBuffer stringValue = new StringBuffer();

    // Any text chars between close of tag and text node?
    if (_previousToken.kind == TokenKind.GREATER_THAN) {
      // If the next token is } could be the close template token.  If user
      // needs } as token in text node use the entity &125;
      // TODO(terry): Probably need a &RCURLY entity instead of 125.
      if (_peek() == TokenKind.ERROR) {
        // Backup, just past previous token, & rescan we're outside of the tag.
        tokenizer.index = _previousToken.end;
        _next(false);
      } else if (_peek() != TokenKind.RBRACE) {
        // Yes, grab the chars after the >
        stringValue.add(_previousToken.source.text.substring(
            this._previousToken.end, this._peekToken.start));
      }
    }

    // Gobble up everything until we hit <
    while (_peek() != TokenKind.LESS_THAN &&
           _peek() != TokenKind.START_COMMAND &&
           _peek() != TokenKind.END_COMMAND &&
           (_peek() != TokenKind.RBRACE ||
            (_peek() == TokenKind.RBRACE && inExpression)) &&
           _peek() != TokenKind.END_OF_FILE) {

      // Beginning of expression?
      if (_peek() == TokenKind.START_EXPRESSION) {
        if (stringValue.length > 0) {
          // We have a real text node create the text node.
          nodes.add(new TemplateText(stringValue.toString(), _makeSpan(start)));
          stringValue = new StringBuffer();
          start = _peekToken.start;
        }
        inExpression = true;
      }

      var tok = _next(false);
      if (tok.kind == TokenKind.RBRACE && inExpression) {
        // We have an expression create the expression node, don't save the }
        inExpression = false;
        nodes.add(new TemplateExpression(stringValue.toString(),
          _makeSpan(start)));
        stringValue = new StringBuffer();
        start = _peekToken.start;
      } else if (tok.kind != TokenKind.START_EXPRESSION) {
        // Only save the the contents between ${ and }
        stringValue.add(tok.text);
      }
    }

    if (stringValue.length > 0) {
      nodes.add(new TemplateText(stringValue.toString(), _makeSpan(start)));
    }

    return nodes;
  }

}