// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library csslib.parser;

import 'dart:math' as math;

import 'package:source_span/source_span.dart';

import "visitor.dart";
import 'src/messages.dart';
import 'src/options.dart';

part 'src/analyzer.dart';
part 'src/polyfill.dart';
part 'src/property.dart';
part 'src/token.dart';
part 'src/tokenizer_base.dart';
part 'src/tokenizer.dart';
part 'src/tokenkind.dart';


/** Used for parser lookup ahead (used for nested selectors Less support). */
class ParserState extends TokenizerState {
  final Token peekToken;
  final Token previousToken;

  ParserState(this.peekToken, this.previousToken, Tokenizer tokenizer)
      : super(tokenizer);
}

// TODO(jmesserly): this should not be global
void _createMessages({List<Message> errors, List<String> options}) {
  if (errors == null) errors = [];

  if (options == null) {
    options = ['--no-colors', 'memory'];
  }
  var opt = PreprocessorOptions.parse(options);
  messages = new Messages(options: opt, printHandler: errors.add);
}

/** CSS checked mode enabled. */
bool get isChecked => messages.options.checked;

// TODO(terry): Remove nested name parameter.
/** Parse and analyze the CSS file. */
StyleSheet compile(input, {List<Message> errors, List<String> options,
    bool nested: true,
    bool polyfill: false,
    List<StyleSheet> includes: null}) {

  if (includes == null) {
    includes = [];
  }

  var source = _inputAsString(input);

  _createMessages(errors: errors, options: options);

  var file = new SourceFile(source);

  var tree = new _Parser(file, source).parse();

  analyze([tree], errors: errors, options: options);

  if (polyfill) {
    var processCss = new PolyFill(messages, true);
    processCss.process(tree, includes: includes);
  }

  return tree;
}

/** Analyze the CSS file. */
void analyze(List<StyleSheet> styleSheets,
    {List<Message> errors, List<String> options}) {

  _createMessages(errors: errors, options: options);
  new Analyzer(styleSheets, messages).run();
}

/**
 * Parse the [input] CSS stylesheet into a tree. The [input] can be a [String],
 * or [List<int>] of bytes and returns a [StyleSheet] AST.  The optional
 * [errors] list will contain each error/warning as a [Message].
 */
StyleSheet parse(input, {List<Message> errors, List<String> options}) {
  var source = _inputAsString(input);

  _createMessages(errors: errors, options: options);

  var file = new SourceFile(source);
  return new _Parser(file, source).parse();
}

/**
 * Parse the [input] CSS selector into a tree. The [input] can be a [String],
 * or [List<int>] of bytes and returns a [StyleSheet] AST.  The optional
 * [errors] list will contain each error/warning as a [Message].
 */
// TODO(jmesserly): should rename "parseSelector" and return Selector
StyleSheet selector(input, {List<Message> errors}) {
  var source = _inputAsString(input);

  _createMessages(errors: errors);

  var file = new SourceFile(source);
  return (new _Parser(file, source)
      ..tokenizer.inSelector = true)
      .parseSelector();
}

SelectorGroup parseSelectorGroup(input, {List<Message> errors}) {
  var source = _inputAsString(input);

  _createMessages(errors: errors);

  var file = new SourceFile(source);
  return (new _Parser(file, source)
      // TODO(jmesserly): this fix should be applied to the parser. It's tricky
      // because by the time the flag is set one token has already been fetched.
      ..tokenizer.inSelector = true)
      .processSelectorGroup();
}

String _inputAsString(input) {
  String source;

  if (input is String) {
    source = input;
  } else if (input is List<int>) {
    // TODO(terry): The parse function needs an "encoding" argument and will
    //              default to whatever encoding CSS defaults to.
    //
    // Here's some info about CSS encodings:
    // http://www.w3.org/International/questions/qa-css-charset.en.php
    //
    // As JMesserly suggests it will probably need a "preparser" html5lib
    // (encoding_parser.dart) that interprets the bytes as ASCII and scans for
    // @charset. But for now an "encoding" argument would work.  Often the
    // HTTP header will indicate the correct encoding.
    //
    // See encoding helpers at: package:html5lib/lib/src/char_encodings.dart
    // These helpers can decode in different formats given an encoding name
    // (mostly unicode, ascii, windows-1252 which is html5 default encoding).
    source = new String.fromCharCodes(input);
  } else {
    // TODO(terry): Support RandomAccessFile using console.
    throw new ArgumentError("'source' must be a String or "
        "List<int> (of bytes). RandomAccessFile not supported from this "
        "simple interface");
  }

  return source;
}

// TODO(terry): Consider removing this class when all usages can be eliminated
//               or replaced with compile API.
/** Public parsing interface for csslib. */
class Parser {
  final _Parser _parser;

  // TODO(jmesserly): having file and text is redundant.
  Parser(SourceFile file, String text, {int start: 0, String baseUrl}) :
    _parser = new _Parser(file, text, start: start, baseUrl: baseUrl);

  StyleSheet parse() => _parser.parse();
}

/** A simple recursive descent parser for CSS. */
class _Parser {
  final Tokenizer tokenizer;

  /** Base url of CSS file. */
  final String _baseUrl;

  /**
   * File containing the source being parsed, used to report errors with
   * source-span locations.
   */
  final SourceFile file;

  Token _previousToken;
  Token _peekToken;

  _Parser(SourceFile file, String text, {int start: 0, String baseUrl})
      : this.file = file,
        _baseUrl = baseUrl,
        tokenizer = new Tokenizer(file, text, true, start) {
    _peekToken = tokenizer.next();
  }

  /** Main entry point for parsing an entire CSS file. */
  StyleSheet parse() {
    List<TreeNode> productions = [];

    int start = _peekToken.start;
    while (!_maybeEat(TokenKind.END_OF_FILE) && !_peekKind(TokenKind.RBRACE)) {
      // TODO(terry): Need to handle charset.
      var directive = processDirective();
      if (directive != null) {
        productions.add(directive);
        _maybeEat(TokenKind.SEMICOLON);
      } else {
        RuleSet ruleset = processRuleSet();
        if (ruleset != null) {
          productions.add(ruleset);
        } else {
          break;
        }
      }
    }

    checkEndOfFile();

    return new StyleSheet(productions, _makeSpan(start));
  }

  /** Main entry point for parsing a simple selector sequence. */
  StyleSheet parseSelector() {
    List<TreeNode> productions = [];

    int start = _peekToken.start;
    while (!_maybeEat(TokenKind.END_OF_FILE) && !_peekKind(TokenKind.RBRACE)) {
      var selector = processSelector();
      if (selector != null) {
        productions.add(selector);
      }
    }

    checkEndOfFile();

    return new StyleSheet.selector(productions, _makeSpan(start));
  }

  /** Generate an error if [file] has not been completely consumed. */
  void checkEndOfFile() {
    if (!(_peekKind(TokenKind.END_OF_FILE) ||
        _peekKind(TokenKind.INCOMPLETE_COMMENT))) {
      _error('premature end of file unknown CSS', _peekToken.span);
    }
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

  Token _next({unicodeRange : false}) {
    _previousToken = _peekToken;
    _peekToken = tokenizer.next(unicodeRange: unicodeRange);
    return _previousToken;
  }

  bool _peekKind(int kind) {
    return _peekToken.kind == kind;
  }

  /* Is the next token a legal identifier?  This includes pseudo-keywords. */
  bool _peekIdentifier() {
    return TokenKind.isIdentifier(_peekToken.kind);
  }

  /** Marks the parser/tokenizer look ahead to support Less nested selectors. */
  ParserState get _mark =>
      new ParserState(_peekToken, _previousToken, tokenizer);

  /** Restores the parser/tokenizer state to state remembered by _mark. */
  void _restore(ParserState markedData) {
    tokenizer.restore(markedData);
    _peekToken = markedData.peekToken;
    _previousToken = markedData.previousToken;
  }

  bool _maybeEat(int kind, {unicodeRange : false}) {
    if (_peekToken.kind == kind) {
      _previousToken = _peekToken;
      _peekToken = tokenizer.next(unicodeRange: unicodeRange);
      return true;
    } else {
      return false;
    }
  }

  void _eat(int kind, {unicodeRange : false}) {
    if (!_maybeEat(kind, unicodeRange: unicodeRange)) {
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

  void _error(String message, SourceSpan location) {
    if (location == null) {
      location = _peekToken.span;
    }
    messages.error(message, location);
  }

  void _warning(String message, SourceSpan location) {
    if (location == null) {
      location = _peekToken.span;
    }
    messages.warning(message, location);
  }

  SourceSpan _makeSpan(int start) {
    // TODO(terry): there are places where we are creating spans before we eat
    // the tokens, so using _previousToken.end is not always valid.
    var end = _previousToken != null && _previousToken.end >= start
        ? _previousToken.end : _peekToken.end;
    return file.span(start, end);
  }

  ///////////////////////////////////////////////////////////////////
  // Top level productions
  ///////////////////////////////////////////////////////////////////

  /**
   * The media_query_list production below replaces the media_list production
   * from CSS2 the new grammar is:
   *
   *   media_query_list
   *    : S* [media_query [ ',' S* media_query ]* ]?
   *   media_query
   *    : [ONLY | NOT]? S* media_type S* [ AND S* expression ]*
   *    | expression [ AND S* expression ]*
   *   media_type
   *    : IDENT
   *   expression
   *    : '(' S* media_feature S* [ ':' S* expr ]? ')' S*
   *   media_feature
   *    : IDENT
   */
  List<MediaQuery> processMediaQueryList() {
    var mediaQueries = [];

    bool firstTime = true;
    var mediaQuery;
    do {
      mediaQuery = processMediaQuery(firstTime == true);
      if (mediaQuery != null) {
        mediaQueries.add(mediaQuery);
        firstTime = false;
        continue;
      }

      // Any more more media types separated by comma.
      if (!_maybeEat(TokenKind.COMMA)) break;

      // Yep more media types start again.
      firstTime = true;
    } while ((!firstTime && mediaQuery != null) || firstTime);

    return mediaQueries;
  }

  MediaQuery processMediaQuery([bool startQuery = true]) {
    // Grammar: [ONLY | NOT]? S* media_type S*
    //          [ AND S* MediaExpr ]* | MediaExpr [ AND S* MediaExpr ]*

    int start = _peekToken.start;

    // Is it a unary media operator?
    var op = _peekToken.text;
    var opLen = op.length;
    var unaryOp = TokenKind.matchMediaOperator(op, 0, opLen);
    if (unaryOp != -1) {
      if (isChecked) {
        if (startQuery &&
            unaryOp != TokenKind.MEDIA_OP_NOT ||
            unaryOp != TokenKind.MEDIA_OP_ONLY) {
          _warning("Only the unary operators NOT and ONLY allowed",
              _makeSpan(start));
        }
        if (!startQuery && unaryOp != TokenKind.MEDIA_OP_AND) {
          _warning("Only the binary AND operator allowed", _makeSpan(start));
        }
      }
      _next();
      start = _peekToken.start;
    }

    var type;
    if (startQuery && unaryOp != TokenKind.MEDIA_OP_AND) {
      // Get the media type.
      if (_peekIdentifier()) type = identifier();
    }

    var exprs = [];

    if (unaryOp == -1 || unaryOp == TokenKind.MEDIA_OP_AND) {
      var andOp = false;
      while (true) {
        var expr = processMediaExpression(andOp);
        if (expr == null) break;

        exprs.add(expr);
        op = _peekToken.text;
        opLen = op.length;
        andOp = TokenKind.matchMediaOperator(op, 0, opLen) ==
            TokenKind.MEDIA_OP_AND;
        if (!andOp) break;
        _next();
      }
    }

    if (unaryOp != -1 || type != null || exprs.length > 0) {
      return new MediaQuery(unaryOp, type, exprs, _makeSpan(start));
    }
  }

  MediaExpression processMediaExpression([bool andOperator = false]) {
    int start = _peekToken.start;

    // Grammar: '(' S* media_feature S* [ ':' S* expr ]? ')' S*
    if (_maybeEat(TokenKind.LPAREN)) {
      if (_peekIdentifier()) {
        var feature = identifier();           // Media feature.
        while (_maybeEat(TokenKind.COLON)) {
          int startExpr = _peekToken.start;
          var exprs = processExpr();
          if (_maybeEat(TokenKind.RPAREN)) {
            return new MediaExpression(andOperator, feature, exprs,
                _makeSpan(startExpr));
          } else if (isChecked) {
            _warning("Missing parenthesis around media expression",
                _makeSpan(start));
            return null;
          }
        }
      } else if (isChecked) {
        _warning("Missing media feature in media expression", _makeSpan(start));
        return null;
      }
    }
  }

  /**
   * Directive grammar:
   *
   *  import:             '@import' [string | URI] media_list?
   *  media:              '@media' media_query_list '{' ruleset '}'
   *  page:               '@page' [':' IDENT]? '{' declarations '}'
   *  stylet:             '@stylet' IDENT '{' ruleset '}'
   *  media_query_list:   IDENT [',' IDENT]
   *  keyframes:          '@-webkit-keyframes ...' (see grammar below).
   *  font_face:          '@font-face' '{' declarations '}'
   *  namespace:          '@namespace name url("xmlns")
   *  host:               '@host '{' ruleset '}'
   *  mixin:              '@mixin name [(args,...)] '{' declarations/ruleset '}'
   *  include:            '@include name [(@arg,@arg1)]
   *                      '@include name [(@arg...)]
   *  content             '@content'
   */
  processDirective() {
    int start = _peekToken.start;

    var tokId = processVariableOrDirective();
    if (tokId is VarDefinitionDirective) return tokId;
    switch (tokId) {
      case TokenKind.DIRECTIVE_IMPORT:
        _next();

        // @import "uri_string" or @import url("uri_string") are identical; only
        // a url can follow an @import.
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
        var medias = processMediaQueryList();

        if (importStr == null) {
          _error('missing import string', _peekToken.span);
        }

        return new ImportDirective(importStr.trim(), medias, _makeSpan(start));

      case TokenKind.DIRECTIVE_MEDIA:
        _next();

        // Any medias?
        var media = processMediaQueryList();

        List<TreeNode> rulesets = [];
        if (_maybeEat(TokenKind.LBRACE)) {
          while (!_maybeEat(TokenKind.END_OF_FILE)) {
            RuleSet ruleset = processRuleSet();
            if (ruleset == null) break;
            rulesets.add(ruleset);
          }

          if (!_maybeEat(TokenKind.RBRACE)) {
            _error('expected } after ruleset for @media', _peekToken.span);
          }
        } else {
          _error('expected { after media before ruleset', _peekToken.span);
        }
        return new MediaDirective(media, rulesets, _makeSpan(start));

      case TokenKind.DIRECTIVE_HOST:
        _next();

        List<TreeNode> rulesets = [];
        if (_maybeEat(TokenKind.LBRACE)) {
          while (!_maybeEat(TokenKind.END_OF_FILE)) {
            RuleSet ruleset = processRuleSet();
            if (ruleset == null) break;
            rulesets.add(ruleset);
          }

          if (!_maybeEat(TokenKind.RBRACE)) {
            _error('expected } after ruleset for @host', _peekToken.span);
          }
        } else {
          _error('expected { after host before ruleset', _peekToken.span);
        }
        return new HostDirective(rulesets, _makeSpan(start));

      case TokenKind.DIRECTIVE_PAGE:
        /*
         * @page S* IDENT? pseudo_page?
         *      S* '{' S*
         *      [ declaration | margin ]?
         *      [ ';' S* [ declaration | margin ]? ]* '}' S*
         *
         * pseudo_page :
         *      ':' [ "left" | "right" | "first" ]
         *
         * margin :
         *      margin_sym S* '{' declaration [ ';' S* declaration? ]* '}' S*
         *
         * margin_sym : @top-left-corner, @top-left, @bottom-left, etc.
         *
         * See http://www.w3.org/TR/css3-page/#CSS21
         */
        _next();

        // Page name
        var name;
        if (_peekIdentifier()) {
          name = identifier();
        }

        // Any pseudo page?
        var pseudoPage;
        if (_maybeEat(TokenKind.COLON)) {
          if (_peekIdentifier()) {
            pseudoPage = identifier();
            // TODO(terry): Normalize pseudoPage to lowercase.
            if (isChecked &&
                !(pseudoPage.name == 'left' ||
                  pseudoPage.name == 'right' ||
                  pseudoPage.name == 'first')) {
              _warning("Pseudo page must be left, top or first",
                  pseudoPage.span);
              return null;
            }
          }
        }

        String pseudoName = pseudoPage is Identifier ? pseudoPage.name : '';
        String ident = name is Identifier ? name.name : '';
        return new PageDirective(ident, pseudoName,
            processMarginsDeclarations(), _makeSpan(start));

      case TokenKind.DIRECTIVE_CHARSET:
        // @charset S* STRING S* ';'
        _next();

        var charEncoding = processQuotedString(false);
        if (isChecked && charEncoding == null) {
          // Missing character encoding.
          _warning('missing character encoding string', _makeSpan(start));
        }

        return new CharsetDirective(charEncoding, _makeSpan(start));

      // TODO(terry): Workaround Dart2js bug continue not implemented in switch
      //              see https://code.google.com/p/dart/issues/detail?id=8270
      /*
      case TokenKind.DIRECTIVE_MS_KEYFRAMES:
        // TODO(terry): For now only IE 10 (are base level) supports @keyframes,
        // -moz- has only been optional since Oct 2012 release of Firefox, not
        // all versions of webkit support @keyframes and opera doesn't yet
        // support w/o -o- prefix.  Add more warnings for other prefixes when
        // they become optional.
        if (isChecked) {
          _warning('@-ms-keyframes should be @keyframes', _makeSpan(start));
        }
        continue keyframeDirective;

      keyframeDirective:
      */
      case TokenKind.DIRECTIVE_KEYFRAMES:
      case TokenKind.DIRECTIVE_WEB_KIT_KEYFRAMES:
      case TokenKind.DIRECTIVE_MOZ_KEYFRAMES:
      case TokenKind.DIRECTIVE_O_KEYFRAMES:
      // TODO(terry): Remove workaround when bug 8270 is fixed.
      case TokenKind.DIRECTIVE_MS_KEYFRAMES:
        if (tokId == TokenKind.DIRECTIVE_MS_KEYFRAMES && isChecked) {
          _warning('@-ms-keyframes should be @keyframes', _makeSpan(start));
        }
      // TODO(terry): End of workaround.

        /*  Key frames grammar:
         *
         *  @[browser]? keyframes [IDENT|STRING] '{' keyframes-blocks '}';
         *
         *  browser: [-webkit-, -moz-, -ms-, -o-]
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

        var keyframe = new KeyFrameDirective(tokId, name, _makeSpan(start));

        do {
          Expressions selectors = new Expressions(_makeSpan(start));

          do {
            var term = processTerm();

            // TODO(terry): Only allow from, to and PERCENTAGE ...

            selectors.add(term);
          } while (_maybeEat(TokenKind.COMMA));

          keyframe.add(new KeyFrameBlock(selectors, processDeclarations(),
              _makeSpan(start)));

        } while (!_maybeEat(TokenKind.RBRACE) && !isPrematureEndOfFile());

        return keyframe;

      case TokenKind.DIRECTIVE_FONTFACE:
        _next();
        return new FontFaceDirective(processDeclarations(), _makeSpan(start));

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

        List<TreeNode> productions = [];

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

      case TokenKind.DIRECTIVE_NAMESPACE:
        /* Namespace grammar:
         *
         * @namespace S* [namespace_prefix S*]? [STRING|URI] S* ';' S*
         * namespace_prefix : IDENT
         *
         */
        _next();

        var prefix;
        if (_peekIdentifier()) {
          prefix = identifier();
        }

        // The namespace URI can be either a quoted string url("uri_string")
        // are identical.
        String namespaceUri;
        if (_peekIdentifier()) {
          var func = processFunction(identifier());
          if (func is UriTerm) {
            namespaceUri = func.text;
          }
        } else {
          if (prefix != null && prefix.name == 'url') {
            var func = processFunction(prefix);
            if (func is UriTerm) {
              // @namespace url("");
              namespaceUri = func.text;
              prefix = null;
            }
          } else {
            namespaceUri = processQuotedString(false);
          }
        }

        return new NamespaceDirective(prefix != null ? prefix.name : '',
            namespaceUri, _makeSpan(start));

      case TokenKind.DIRECTIVE_MIXIN:
        return processMixin(start);

      case TokenKind.DIRECTIVE_INCLUDE:
        return processInclude( _makeSpan(start));

      case TokenKind.DIRECTIVE_CONTENT:
        // TODO(terry): TBD
        _warning("@content not implemented.", _makeSpan(start));
        return null;
    }
    return null;
  }

  /**
   * Parse the mixin beginning token offset [start]. Returns a [MixinDefinition]
   * node.
   *
   * Mixin grammar:
   *
   *  @mixin IDENT [(args,...)] '{'
   *    [ruleset | property | directive]*
   *  '}'
   */
  MixinDefinition processMixin(int start) {
    _next();

    var name = identifier();

    List<VarDefinitionDirective> params = [];
    // Any parameters?
    if (_maybeEat(TokenKind.LPAREN)) {
      var mustHaveParam = false;
      var keepGoing = true;
      while (keepGoing) {
        var varDef = processVariableOrDirective(mixinParameter: true);
        if (varDef is VarDefinitionDirective || varDef is VarDefinition) {
          params.add(varDef);
        } else if (mustHaveParam) {
          _warning("Expecting parameter", _makeSpan(_peekToken.start));
          keepGoing = false;
        }
        if (_maybeEat(TokenKind.COMMA)) {
          mustHaveParam = true;
          continue;
        }
        keepGoing = !_maybeEat(TokenKind.RPAREN);
      }
    }

    _eat(TokenKind.LBRACE);

    List<TreeNode> productions = [];
    List<TreeNode> declarations = [];
    var mixinDirective;

    start = _peekToken.start;
    while (!_maybeEat(TokenKind.END_OF_FILE)) {
      var directive = processDirective();
      if (directive != null) {
        productions.add(directive);
        continue;
      }

      var declGroup = processDeclarations(checkBrace: false);
      var decls = [];
      if (declGroup.declarations.any((decl) {
        return decl is Declaration &&
            decl is! IncludeMixinAtDeclaration;
      })) {
        var newDecls = [];
        productions.forEach((include) {
          // If declGroup has items that are declarations then we assume
          // this mixin is a declaration mixin not a top-level mixin.
          if (include is IncludeDirective) {
            newDecls.add(new IncludeMixinAtDeclaration(include,
                include.span));
          } else {
            _warning("Error mixing of top-level vs declarations mixins",
                _makeSpan(include));
          }
        });
        declGroup.declarations.insertAll(0, newDecls);
        productions = [];
      } else {
        // Declarations are just @includes make it a list of productions
        // not a declaration group (anything else is a ruleset).  Make it a
        // list of productions, not a declaration group.
        for (var decl in declGroup.declarations) {
          productions.add(decl is IncludeMixinAtDeclaration ?
              decl.include : decl);
        };
        declGroup.declarations.clear();
      }

      if (declGroup.declarations.isNotEmpty) {
        if (productions.isEmpty) {
          mixinDirective = new MixinDeclarationDirective(name.name, params,
              false, declGroup, _makeSpan(start));
          break;
        } else {
          for (var decl in declGroup.declarations) {
            productions.add(decl is IncludeMixinAtDeclaration ?
                decl.include : decl);
          }
        }
      } else {
        mixinDirective = new MixinRulesetDirective(name.name, params,
            false, productions, _makeSpan(start));
        break;
      }
    }

    if (productions.isNotEmpty) {
      mixinDirective = new MixinRulesetDirective(name.name, params,
          false, productions, _makeSpan(start));
    }

    _eat(TokenKind.RBRACE);

    return mixinDirective;
  }

  /**
   * Returns a VarDefinitionDirective or VarDefinition if a varaible otherwise
   * return the token id of a directive or -1 if neither.
   */
  processVariableOrDirective({bool mixinParameter: false}) {
    int start = _peekToken.start;

    var tokId = _peek();
    // Handle case for @ directive (where there's a whitespace between the @
    // sign and the directive name.  Technically, it's not valid grammar but
    // a number of CSS tests test for whitespace between @ and name.
    if (tokId == TokenKind.AT) {
      Token tok = _next();
      tokId = _peek();
      if (_peekIdentifier()) {
        // Is it a directive?
        var directive = _peekToken.text;
        var directiveLen = directive.length;
        tokId = TokenKind.matchDirectives(directive, 0, directiveLen);
        if (tokId == -1) {
          tokId = TokenKind.matchMarginDirectives(directive, 0, directiveLen);
        }
      }

      if (tokId == -1) {
        if (messages.options.lessSupport) {
          // Less compatibility:
          //    @name: value;      =>    var-name: value;       (VarDefinition)
          //    property: @name;   =>    property: var(name);   (VarUsage)
          var name;
          if (_peekIdentifier()) {
            name = identifier();
          }

          Expressions exprs;
          if (mixinParameter && _maybeEat(TokenKind.COLON)) {
            exprs = processExpr();
          } else if (!mixinParameter) {
            _eat(TokenKind.COLON);
            exprs = processExpr();
          }

          var span = _makeSpan(start);
          return new VarDefinitionDirective(
              new VarDefinition(name, exprs, span), span);
        } else if (isChecked) {
          _error('unexpected directive @$_peekToken', _peekToken.span);
        }
      }
    } else if (mixinParameter && _peekToken.kind == TokenKind.VAR_DEFINITION) {
      _next();
      var definedName;
      if (_peekIdentifier()) definedName = identifier();

      Expressions exprs;
      if (_maybeEat(TokenKind.COLON)) {
        exprs = processExpr();
      }

      return new VarDefinition(definedName, exprs, _makeSpan(start));
    }

    return tokId;
  }

  IncludeDirective processInclude(SourceSpan span, {bool eatSemiColon: true}) {
    /* Stylet grammar:
    *
     *  @include IDENT [(args,...)];
     */
    _next();

    var name;
    if (_peekIdentifier()) {
      name = identifier();
    }

    var params = [];

    // Any parameters?  Parameters can be multiple terms per argument e.g.,
    // 3px solid yellow, green is two parameters:
    //    1. 3px solid yellow
    //    2. green
    // the first has 3 terms and the second has 1 term.
    if (_maybeEat(TokenKind.LPAREN)) {
      var terms = [];
      var expr;
      var keepGoing = true;
      while (keepGoing && (expr = processTerm()) != null) {
        // VarUsage is returns as a list
        terms.add(expr is List ? expr[0] : expr);
        keepGoing = !_peekKind(TokenKind.RPAREN);
        if (keepGoing) {
          if (_maybeEat(TokenKind.COMMA)) {
            params.add(terms);
            terms = [];
          }
        }
      }
      params.add(terms);
      _maybeEat(TokenKind.RPAREN);
    }

    if (eatSemiColon) {
      _eat(TokenKind.SEMICOLON);
    }

    return new IncludeDirective(name.name, params, span);
  }

  RuleSet processRuleSet([SelectorGroup selectorGroup]) {
    if (selectorGroup == null) {
      selectorGroup = processSelectorGroup();
    }
    if (selectorGroup != null) {
      return new RuleSet(selectorGroup, processDeclarations(),
          selectorGroup.span);
    }
  }

  /**
   * Look ahead to see if what should be a declaration is really a selector.
   * If it's a selector than it's a nested selector.  This support's Less'
   * nested selector syntax (requires a look ahead). E.g.,
   *
   *    div {
   *      width : 20px;
   *      span {
   *        color: red;
   *      }
   *    }
   *
   * Two tag name selectors div and span equivalent to:
   *
   *    div {
   *      width: 20px;
   *    }
   *    div span {
   *      color: red;
   *    }
   *
   * Return [:null:] if no selector or [SelectorGroup] if a selector was parsed.
   */
  SelectorGroup _nestedSelector() {
    Messages oldMessages = messages;
    _createMessages();

    var markedData = _mark;

    // Look a head do we have a nested selector instead of a declaration?
    SelectorGroup selGroup = processSelectorGroup();

    var nestedSelector = selGroup != null && _peekKind(TokenKind.LBRACE) &&
        messages.messages.isEmpty;

    if (!nestedSelector) {
      // Not a selector so restore the world.
      _restore(markedData);
      messages = oldMessages;
      return null;
    } else {
      // Remember any messages from look ahead.
      oldMessages.mergeMessages(messages);
      messages = oldMessages;
      return selGroup;
    }
  }

  DeclarationGroup processDeclarations({bool checkBrace: true}) {
    int start = _peekToken.start;

    if (checkBrace) _eat(TokenKind.LBRACE);

    List decls = [];
    List dartStyles = [];             // List of latest styles exposed to Dart.

    do {
      var selectorGroup = _nestedSelector();
      while (selectorGroup != null) {
        // Nested selector so process as a ruleset.
        var ruleset = processRuleSet(selectorGroup);
        decls.add(ruleset);
        selectorGroup = _nestedSelector();
      }

      Declaration decl = processDeclaration(dartStyles);
      if (decl != null) {
        if (decl.hasDartStyle) {
          var newDartStyle = decl.dartStyle;

          // Replace or add latest Dart style.
          bool replaced = false;
          for (var i = 0; i < dartStyles.length; i++) {
            var dartStyle = dartStyles[i];
            if (dartStyle.isSame(newDartStyle)) {
              dartStyles[i] = newDartStyle;
              replaced = true;
              break;
            }
          }
          if (!replaced) {
            dartStyles.add(newDartStyle);
          }
        }
        decls.add(decl);
      }
    } while (_maybeEat(TokenKind.SEMICOLON));

    if (checkBrace) _eat(TokenKind.RBRACE);

    // Fixup declaration to only have dartStyle that are live for this set of
    // declarations.
    for (var decl in decls) {
      if (decl is Declaration) {
        if (decl.hasDartStyle && dartStyles.indexOf(decl.dartStyle) < 0) {
          // Dart style not live, ignore these styles in this Declarations.
          decl.dartStyle = null;
        }
      }
    }

    return new DeclarationGroup(decls, _makeSpan(start));
  }

  List<DeclarationGroup> processMarginsDeclarations() {
    List groups = [];

    int start = _peekToken.start;

    _eat(TokenKind.LBRACE);

    List<Declaration> decls = [];
    List dartStyles = [];             // List of latest styles exposed to Dart.

    do {
      switch (_peek()) {
        case TokenKind.MARGIN_DIRECTIVE_TOPLEFTCORNER:
        case TokenKind.MARGIN_DIRECTIVE_TOPLEFT:
        case TokenKind.MARGIN_DIRECTIVE_TOPCENTER:
        case TokenKind.MARGIN_DIRECTIVE_TOPRIGHT:
        case TokenKind.MARGIN_DIRECTIVE_TOPRIGHTCORNER:
        case TokenKind.MARGIN_DIRECTIVE_BOTTOMLEFTCORNER:
        case TokenKind.MARGIN_DIRECTIVE_BOTTOMLEFT:
        case TokenKind.MARGIN_DIRECTIVE_BOTTOMCENTER:
        case TokenKind.MARGIN_DIRECTIVE_BOTTOMRIGHT:
        case TokenKind.MARGIN_DIRECTIVE_BOTTOMRIGHTCORNER:
        case TokenKind.MARGIN_DIRECTIVE_LEFTTOP:
        case TokenKind.MARGIN_DIRECTIVE_LEFTMIDDLE:
        case TokenKind.MARGIN_DIRECTIVE_LEFTBOTTOM:
        case TokenKind.MARGIN_DIRECTIVE_RIGHTTOP:
        case TokenKind.MARGIN_DIRECTIVE_RIGHTMIDDLE:
        case TokenKind.MARGIN_DIRECTIVE_RIGHTBOTTOM:
          // Margin syms processed.
          //   margin :
          //      margin_sym S* '{' declaration [ ';' S* declaration? ]* '}' S*
          //
          //      margin_sym : @top-left-corner, @top-left, @bottom-left, etc.
          var marginSym = _peek();

          _next();

          var declGroup = processDeclarations();
          if (declGroup != null) {
            groups.add(new MarginGroup(marginSym, declGroup.declarations,
                _makeSpan(start)));
          }
          break;
        default:
          Declaration decl = processDeclaration(dartStyles);
          if (decl != null) {
            if (decl.hasDartStyle) {
              var newDartStyle = decl.dartStyle;

              // Replace or add latest Dart style.
              bool replaced = false;
              for (var i = 0; i < dartStyles.length; i++) {
                var dartStyle = dartStyles[i];
                if (dartStyle.isSame(newDartStyle)) {
                  dartStyles[i] = newDartStyle;
                  replaced = true;
                  break;
                }
              }
              if (!replaced) {
                dartStyles.add(newDartStyle);
              }
            }
            decls.add(decl);
          }
          _maybeEat(TokenKind.SEMICOLON);
          break;
      }
    } while (!_maybeEat(TokenKind.RBRACE) && !isPrematureEndOfFile());

    // Fixup declaration to only have dartStyle that are live for this set of
    // declarations.
    for (var decl in decls) {
      if (decl.hasDartStyle && dartStyles.indexOf(decl.dartStyle) < 0) {
        // Dart style not live, ignore these styles in this Declarations.
        decl.dartStyle = null;
      }
    }

    if (decls.length > 0) {
      groups.add(new DeclarationGroup(decls, _makeSpan(start)));
    }

    return groups;
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

  /**
   * Return list of selectors
   */
  Selector processSelector() {
    var simpleSequences = <SimpleSelectorSequence>[];
    var start = _peekToken.start;
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
    var start = _peekToken.start;
    var combinatorType = TokenKind.COMBINATOR_NONE;
    var thisOperator = false;

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
      case TokenKind.AMPERSAND:
        _eat(TokenKind.AMPERSAND);
        thisOperator = true;
        break;
      }

    // Check if WHITESPACE existed between tokens if so we're descendent.
    if (combinatorType == TokenKind.COMBINATOR_NONE && !forceCombinatorNone) {
      if (this._previousToken != null &&
          this._previousToken.end != this._peekToken.start) {
        combinatorType = TokenKind.COMBINATOR_DESCENDANT;
      }
    }

    var span = _makeSpan(start);
    var simpleSel = thisOperator ?
        new ElementSelector(new ThisOperator(span), span) : simpleSelector();
    if (simpleSel == null &&
        (combinatorType == TokenKind.COMBINATOR_PLUS ||
        combinatorType == TokenKind.COMBINATOR_GREATER ||
        combinatorType == TokenKind.COMBINATOR_TILDE)) {
      // For "+ &", "~ &" or "> &" a selector sequence with no name is needed
      // so that the & will have a combinator too.  This is needed to
      // disambiguate selector expressions:
      //    .foo&:hover     combinator before & is NONE
      //    .foo &          combinator before & is DESCDENDANT
      //    .foo > &        combinator before & is GREATER
      simpleSel =  new ElementSelector(new Identifier("", span), span);
    }
    if (simpleSel != null) {
      return new SimpleSelectorSequence(simpleSel, span, combinatorType);
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
        first = identifier();
        break;
      default:
        // Expecting simple selector.
        // TODO(terry): Could be a synthesized token like value, etc.
        if (TokenKind.isKindIdentifier(_peek())) {
          first = identifier();
        } else if (_peekKind(TokenKind.SEMICOLON)) {
          // Can't be a selector if we found a semi-colon.
          return null;
        }
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
          break;
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

  bool _anyWhiteSpaceBeforePeekToken(int kind) {
    if (_previousToken != null && _peekToken != null &&
        _previousToken.kind == kind) {
      // If end of previous token isn't same as the start of peek token then
      // there's something between these tokens probably whitespace.
      return _previousToken.end != _peekToken.start;
    }

    return false;
  }

  /**
   * type_selector | universal | HASH | class | attrib | pseudo
   */
  simpleSelectorTail() {
    // Check for HASH | class | attrib | pseudo | negation
    var start = _peekToken.start;
    switch (_peek()) {
      case TokenKind.HASH:
        _eat(TokenKind.HASH);

        var hasWhiteSpace = false;
        if (_anyWhiteSpaceBeforePeekToken(TokenKind.HASH)) {
          _warning("Not a valid ID selector expected #id", _makeSpan(start));
          hasWhiteSpace = true;
        }
        if (_peekIdentifier()) {
          var id = identifier();
          if (hasWhiteSpace) {
            // Generate bad selector id (normalized).
            id.name = " ${id.name}";
          }
          return new IdSelector(id, _makeSpan(start));
        }
        return null;
      case TokenKind.DOT:
        _eat(TokenKind.DOT);

        bool hasWhiteSpace = false;
        if (_anyWhiteSpaceBeforePeekToken(TokenKind.DOT)) {
          _warning("Not a valid class selector expected .className",
              _makeSpan(start));
          hasWhiteSpace = true;
        }
        var id = identifier();
        if (hasWhiteSpace) {
          // Generate bad selector class (normalized).
          id.name = " ${id.name}";
        }
        return new ClassSelector(id, _makeSpan(start));
      case TokenKind.COLON:
        // :pseudo-class ::pseudo-element
        return processPseudoSelector(start);
      case TokenKind.LBRACK:
        return processAttribute();
      case TokenKind.DOUBLE:
        _error('name must start with a alpha character, but found a number',
            _peekToken.span);
        _next();
        break;
    }
  }

  processPseudoSelector(int start) {
    // :pseudo-class ::pseudo-element
    // TODO(terry): '::' should be token.
    _eat(TokenKind.COLON);
    var pseudoElement = _maybeEat(TokenKind.COLON);

    // TODO(terry): If no identifier specified consider optimizing out the
    //              : or :: and making this a normal selector.  For now,
    //              create an empty pseudoName.
    var pseudoName;
    if (_peekIdentifier()) {
      pseudoName = identifier();
    } else {
      return null;
    }

    // Functional pseudo?

    if (_peekToken.kind == TokenKind.LPAREN) {

      if (!pseudoElement && pseudoName.name.toLowerCase() == 'not') {
        _eat(TokenKind.LPAREN);

        // Negation :   ':NOT(' S* negation_arg S* ')'
        var negArg = simpleSelector();

        _eat(TokenKind.RPAREN);
        return new NegationSelector(negArg, _makeSpan(start));
      } else {
        // Special parsing for expressions in pseudo functions.  Minus is used
        // as operator not identifier.
        // TODO(jmesserly): we need to flip this before we eat the "(" as the
        // next token will be fetched when we do that. I think we should try to
        // refactor so we don't need this boolean; it seems fragile.
        tokenizer.inSelectorExpression = true;
        _eat(TokenKind.LPAREN);

        // Handle function expression.
        var span = _makeSpan(start);
        var expr = processSelectorExpression();

        tokenizer.inSelectorExpression = false;

        // Used during selector look-a-head if not a SelectorExpression is
        // bad.
        if (expr is! SelectorExpression) {
          _errorExpected("CSS expression");
          return null;
        }

        _eat(TokenKind.RPAREN);
        return (pseudoElement) ?
            new PseudoElementFunctionSelector(pseudoName, expr, span) :
              new PseudoClassFunctionSelector(pseudoName, expr, span);
      }
    }

    // TODO(terry): Need to handle specific pseudo class/element name and
    // backward compatible names that are : as well as :: as well as
    // parameters.  Current, spec uses :: for pseudo-element and : for
    // pseudo-class.  However, CSS2.1 allows for : to specify old
    // pseudo-elements (:first-line, :first-letter, :before and :after) any
    // new pseudo-elements defined would require a ::.
    return pseudoElement ?
        new PseudoElementSelector(pseudoName, _makeSpan(start)) :
          new PseudoClassSelector(pseudoName, _makeSpan(start));
  }

  /**
   *  In CSS3, the expressions are identifiers, strings, or of the form "an+b".
   *
   *    : [ [ PLUS | '-' | DIMENSION | NUMBER | STRING | IDENT ] S* ]+
   *
   *    num               [0-9]+|[0-9]*\.[0-9]+
   *    PLUS              '+'
   *    DIMENSION         {num}{ident}
   *    NUMBER            {num}
   */
  processSelectorExpression() {
    var start = _peekToken.start;

    var expressions = [];

    Token termToken;
    var value;

    var keepParsing = true;
    while (keepParsing) {
      switch (_peek()) {
        case TokenKind.PLUS:
          start = _peekToken.start;
          termToken = _next();
          expressions.add(new OperatorPlus(_makeSpan(start)));
          break;
        case TokenKind.MINUS:
          start = _peekToken.start;
          termToken = _next();
          expressions.add(new OperatorMinus(_makeSpan(start)));
          break;
        case TokenKind.INTEGER:
          termToken = _next();
          value = int.parse(termToken.text);
          break;
        case TokenKind.DOUBLE:
          termToken = _next();
          value = double.parse(termToken.text);
          break;
        case TokenKind.SINGLE_QUOTE:
          value = processQuotedString(false);
          value = "'${_escapeString(value, single: true)}'";
          return new LiteralTerm(value, value, _makeSpan(start));
        case TokenKind.DOUBLE_QUOTE:
          value = processQuotedString(false);
          value = '"${_escapeString(value)}"';
          return new LiteralTerm(value, value, _makeSpan(start));
        case TokenKind.IDENTIFIER:
          value = identifier();   // Snarf up the ident we'll remap, maybe.
          break;
        default:
          keepParsing = false;
      }

      if (keepParsing && value != null) {
        var unitTerm;
        // Don't process the dimension if MINUS or PLUS is next.
        if (_peek() != TokenKind.MINUS && _peek() != TokenKind.PLUS) {
          unitTerm = processDimension(termToken, value, _makeSpan(start));
        }
        if (unitTerm == null) {
          unitTerm = new LiteralTerm(value, value.name, _makeSpan(start));
        }
        expressions.add(unitTerm);

        value = null;
      }
    }

    return new SelectorExpression(expressions, _makeSpan(start));
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
  AttributeSelector processAttribute() {
    var start = _peekToken.start;

    if (_maybeEat(TokenKind.LBRACK)) {
      var attrName = identifier();

      int op;
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
      default:
        op = TokenKind.NO_MATCH;
      }

      var value;
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
  //  property:  IDENT [or IE hacks]
  //  prio:      !important
  //  expr:      (see processExpr)
  //
  // Here are the ugly IE hacks we need to support:
  //   property: expr prio? \9; - IE8 and below property, /9 before semi-colon
  //   *IDENT                   - IE7 or below
  //   _IDENT                   - IE6 property (automatically a valid ident)
  //
  Declaration processDeclaration(List dartStyles) {
    Declaration decl;

    int start = _peekToken.start;

    // IE7 hack of * before property name if so the property is IE7 or below.
    var ie7 = _peekKind(TokenKind.ASTERISK);
    if (ie7) {
      _next();
    }

    // IDENT ':' expr '!important'?
    if (TokenKind.isIdentifier(_peekToken.kind)) {
      var propertyIdent = identifier();

      var ieFilterProperty = propertyIdent.name.toLowerCase() == 'filter';

      _eat(TokenKind.COLON);

      Expressions exprs = processExpr(ieFilterProperty);

      var dartComposite = _styleForDart(propertyIdent, exprs, dartStyles);

      // Handle !important (prio)
      var importantPriority = _maybeEat(TokenKind.IMPORTANT);

      decl = new Declaration(propertyIdent, exprs, dartComposite,
          _makeSpan(start), important: importantPriority, ie7: ie7);
    } else if (_peekToken.kind == TokenKind.VAR_DEFINITION) {
      _next();
      var definedName;
      if (_peekIdentifier()) definedName = identifier();

      _eat(TokenKind.COLON);

      Expressions exprs = processExpr();

      decl = new VarDefinition(definedName, exprs, _makeSpan(start));
    } else if (_peekToken.kind == TokenKind.DIRECTIVE_INCLUDE) {
      // @include mixinName in the declaration area.
      var span = _makeSpan(start);
      var include = processInclude(span, eatSemiColon: false);
      decl = new IncludeMixinAtDeclaration(include, span);
    } else if (_peekToken.kind == TokenKind.DIRECTIVE_EXTEND) {
      var simpleSequences = <TreeNode>[];

      _next();
      var span = _makeSpan(start);
      var selector = simpleSelector();
      if (selector == null) {
        _warning("@extends expecting simple selector name", span);
      } else {
        simpleSequences.add(selector);
      }
      if (_peekKind(TokenKind.COLON)) {
        var pseudoSelector = processPseudoSelector(_peekToken.start);
        if (pseudoSelector is PseudoElementSelector ||
            pseudoSelector is PseudoClassSelector) {
          simpleSequences.add(pseudoSelector);
        } else {
          _warning("not a valid selector", span);
        }
      }
      decl = new ExtendDeclaration(simpleSequences, span);
    }

    return decl;
  }

  /** List of styles exposed to the Dart UI framework. */
  static const int _fontPartFont= 0;
  static const int _fontPartVariant = 1;
  static const int _fontPartWeight = 2;
  static const int _fontPartSize = 3;
  static const int _fontPartFamily = 4;
  static const int _fontPartStyle = 5;
  static const int _marginPartMargin = 6;
  static const int _marginPartLeft = 7;
  static const int _marginPartTop = 8;
  static const int _marginPartRight = 9;
  static const int _marginPartBottom = 10;
  static const int _lineHeightPart = 11;
  static const int _borderPartBorder = 12;
  static const int _borderPartLeft = 13;
  static const int _borderPartTop = 14;
  static const int _borderPartRight = 15;
  static const int _borderPartBottom = 16;
  static const int _borderPartWidth = 17;
  static const int _borderPartLeftWidth = 18;
  static const int _borderPartTopWidth = 19;
  static const int _borderPartRightWidth = 20;
  static const int _borderPartBottomWidth = 21;
  static const int _heightPart = 22;
  static const int _widthPart = 23;
  static const int _paddingPartPadding = 24;
  static const int _paddingPartLeft = 25;
  static const int _paddingPartTop = 26;
  static const int _paddingPartRight = 27;
  static const int _paddingPartBottom = 28;

  static const Map<String, int> _stylesToDart = const {
    'font':                 _fontPartFont,
    'font-family':          _fontPartFamily,
    'font-size':            _fontPartSize,
    'font-style':           _fontPartStyle,
    'font-variant':         _fontPartVariant,
    'font-weight':          _fontPartWeight,
    'line-height':          _lineHeightPart,
    'margin':               _marginPartMargin,
    'margin-left':          _marginPartLeft,
    'margin-right':         _marginPartRight,
    'margin-top':           _marginPartTop,
    'margin-bottom':        _marginPartBottom,
    'border':               _borderPartBorder,
    'border-left':          _borderPartLeft,
    'border-right':         _borderPartRight,
    'border-top':           _borderPartTop,
    'border-bottom':        _borderPartBottom,
    'border-width':         _borderPartWidth,
    'border-left-width':    _borderPartLeftWidth,
    'border-top-width':     _borderPartTopWidth,
    'border-right-width':   _borderPartRightWidth,
    'border-bottom-width':  _borderPartBottomWidth,
    'height':               _heightPart,
    'width':                _widthPart,
    'padding':              _paddingPartPadding,
    'padding-left':         _paddingPartLeft,
    'padding-top':          _paddingPartTop,
    'padding-right':        _paddingPartRight,
    'padding-bottom':       _paddingPartBottom
  };

  static const Map<String, int> _nameToFontWeight = const {
    'bold' : FontWeight.bold,
    'normal' : FontWeight.normal
  };

  static int _findStyle(String styleName) => _stylesToDart[styleName];

  DartStyleExpression _styleForDart(Identifier property, Expressions exprs,
      List dartStyles) {
    var styleType = _findStyle(property.name.toLowerCase());
    if (styleType != null) {
      return buildDartStyleNode(styleType, exprs, dartStyles);
    }
  }

  FontExpression _mergeFontStyles(FontExpression fontExpr, List dartStyles) {
    // Merge all font styles for this class selector.
    for (var dartStyle in dartStyles) {
      if (dartStyle.isFont) {
        fontExpr = new FontExpression.merge(dartStyle, fontExpr);
      }
    }

    return fontExpr;
  }

  DartStyleExpression buildDartStyleNode(int styleType, Expressions exprs,
      List dartStyles) {

    switch (styleType) {
      /*
       * Properties in order:
       *
       *   font-style font-variant font-weight font-size/line-height font-family
       *
       * The font-size and font-family values are required. If other values are
       * missing; a default, if it exist, will be used.
       */
       case _fontPartFont:
         var processor = new ExpressionsProcessor(exprs);
         return _mergeFontStyles(processor.processFont(), dartStyles);
      case _fontPartFamily:
        var processor = new ExpressionsProcessor(exprs);

        try {
          return _mergeFontStyles(processor.processFontFamily(), dartStyles);
        } catch (fontException) {
          _error(fontException, _peekToken.span);
        }
        break;
      case _fontPartSize:
        var processor = new ExpressionsProcessor(exprs);
        return _mergeFontStyles(processor.processFontSize(), dartStyles);
      case _fontPartStyle:
        /* Possible style values:
         *   normal [default]
         *   italic
         *   oblique
         *   inherit
         */
        // TODO(terry): TBD
        break;
      case _fontPartVariant:
        /* Possible variant values:
         *   normal  [default]
         *   small-caps
         *   inherit
         */
        // TODO(terry): TBD
        break;
      case _fontPartWeight:
        /* Possible weight values:
         *   normal [default]
         *   bold
         *   bolder
         *   lighter
         *   100 - 900
         *   inherit
         */
        // TODO(terry): Only 'normal', 'bold', or values of 100-900 supoorted
        //              need to handle bolder, lighter, and inherit.  See
        //              https://github.com/dart-lang/csslib/issues/1
        var expr = exprs.expressions[0];
        if (expr is NumberTerm) {
          var fontExpr = new FontExpression(expr.span,
              weight: expr.value);
          return _mergeFontStyles(fontExpr, dartStyles);
        } else if (expr is LiteralTerm) {
          int weight = _nameToFontWeight[expr.value.toString()];
          if (weight != null) {
            var fontExpr = new FontExpression(expr.span, weight: weight);
            return _mergeFontStyles(fontExpr, dartStyles);
          }
        }
        break;
      case _lineHeightPart:
        num lineHeight;
        if (exprs.expressions.length == 1) {
          var expr = exprs.expressions[0];
          if (expr is UnitTerm) {
            UnitTerm unitTerm = expr;
            // TODO(terry): Need to handle other units and LiteralTerm normal
            //              See https://github.com/dart-lang/csslib/issues/2.
            if (unitTerm.unit == TokenKind.UNIT_LENGTH_PX ||
                   unitTerm.unit == TokenKind.UNIT_LENGTH_PT) {
              var fontExpr = new FontExpression(expr.span,
                  lineHeight: new LineHeight(expr.value, inPixels: true));
              return _mergeFontStyles(fontExpr, dartStyles);
            } else if (isChecked) {
              _warning("Unexpected unit for line-height", expr.span);
            }
          } else if (expr is NumberTerm) {
            var fontExpr = new FontExpression(expr.span,
                lineHeight: new LineHeight(expr.value, inPixels: false));
            return _mergeFontStyles(fontExpr, dartStyles);
          } else if (isChecked) {
            _warning("Unexpected value for line-height", expr.span);
          }
        }
        break;
      case _marginPartMargin:
        return new MarginExpression.boxEdge(exprs.span, processFourNums(exprs));
      case _borderPartBorder:
        for (var expr in exprs.expressions) {
          var v = marginValue(expr);
          if (v != null) {
            final box = new BoxEdge.uniform(v);
            return new BorderExpression.boxEdge(exprs.span, box);
          }
        }
        break;
      case _borderPartWidth:
        var v = marginValue(exprs.expressions[0]);
        if (v != null) {
          final box = new BoxEdge.uniform(v);
          return new BorderExpression.boxEdge(exprs.span, box);
        }
        break;
      case _paddingPartPadding:
        return new PaddingExpression.boxEdge(exprs.span,
            processFourNums(exprs));
      case _marginPartLeft:
      case _marginPartTop:
      case _marginPartRight:
      case _marginPartBottom:
      case _borderPartLeft:
      case _borderPartTop:
      case _borderPartRight:
      case _borderPartBottom:
      case _borderPartLeftWidth:
      case _borderPartTopWidth:
      case _borderPartRightWidth:
      case _borderPartBottomWidth:
      case _heightPart:
      case _widthPart:
      case _paddingPartLeft:
      case _paddingPartTop:
      case _paddingPartRight:
      case _paddingPartBottom:
        if (exprs.expressions.length > 0) {
          return processOneNumber(exprs, styleType);
        }
        break;
      default:
        // Don't handle it.
        return null;
    }
  }

  // TODO(terry): Look at handling width of thin, thick, etc. any none numbers
  //              to convert to a number.
  DartStyleExpression processOneNumber(Expressions exprs, int part) {
    var value = marginValue(exprs.expressions[0]);
    if (value != null) {
      switch (part) {
        case _marginPartLeft:
          return new MarginExpression(exprs.span, left: value);
        case _marginPartTop:
          return new MarginExpression(exprs.span, top: value);
        case _marginPartRight:
          return new MarginExpression(exprs.span, right: value);
        case _marginPartBottom:
          return new MarginExpression(exprs.span, bottom: value);
        case _borderPartLeft:
        case _borderPartLeftWidth:
          return new BorderExpression(exprs.span, left: value);
        case _borderPartTop:
        case _borderPartTopWidth:
          return new BorderExpression(exprs.span, top: value);
        case _borderPartRight:
        case _borderPartRightWidth:
          return new BorderExpression(exprs.span, right: value);
        case _borderPartBottom:
        case _borderPartBottomWidth:
          return new BorderExpression(exprs.span, bottom: value);
        case _heightPart:
          return new HeightExpression(exprs.span, value);
        case _widthPart:
          return new WidthExpression(exprs.span, value);
        case _paddingPartLeft:
          return new PaddingExpression(exprs.span, left: value);
        case _paddingPartTop:
          return new PaddingExpression(exprs.span, top: value);
        case _paddingPartRight:
          return new PaddingExpression(exprs.span, right: value);
        case _paddingPartBottom:
          return new PaddingExpression(exprs.span, bottom: value);
      }
    }
  }

  /**
   * Margins are of the format:
   *
   *   top,right,bottom,left      (4 parameters)
   *   top,right/left, bottom     (3 parameters)
   *   top/bottom,right/left      (2 parameters)
   *   top/right/bottom/left      (1 parameter)
   *
   * The values of the margins can be a unit or unitless or auto.
   */
  BoxEdge processFourNums(Expressions exprs) {
    num top;
    num right;
    num bottom;
    num left;

    int totalExprs = exprs.expressions.length;
    switch (totalExprs) {
      case 1:
        top = marginValue(exprs.expressions[0]);
        right = top;
        bottom = top;
        left = top;
        break;
      case 2:
        top = marginValue(exprs.expressions[0]);
        bottom = top;
        right = marginValue(exprs.expressions[1]);
        left = right;
       break;
      case 3:
        top = marginValue(exprs.expressions[0]);
        right = marginValue(exprs.expressions[1]);
        left = right;
        bottom = marginValue(exprs.expressions[2]);
        break;
      case 4:
        top = marginValue(exprs.expressions[0]);
        right = marginValue(exprs.expressions[1]);
        bottom = marginValue(exprs.expressions[2]);
        left = marginValue(exprs.expressions[3]);
        break;
      default:
        return null;
    }

    return new BoxEdge.clockwiseFromTop(top, right, bottom, left);
  }

  // TODO(terry): Need to handle auto.
  marginValue(var exprTerm) {
    if (exprTerm is UnitTerm || exprTerm is NumberTerm) {
      return exprTerm.value;
    }
  }

  //  Expression grammar:
  //
  //  expression:   term [ operator? term]*
  //
  //  operator:     '/' | ','
  //  term:         (see processTerm)
  //
  Expressions processExpr([bool ieFilter = false]) {
    var start = _peekToken.start;
    var expressions = new Expressions(_makeSpan(start));

    var keepGoing = true;
    var expr;
    while (keepGoing && (expr = processTerm(ieFilter)) != null) {
      var op;

      var opStart = _peekToken.start;

      switch (_peek()) {
      case TokenKind.SLASH:
        op = new OperatorSlash(_makeSpan(opStart));
        break;
      case TokenKind.COMMA:
        op = new OperatorComma(_makeSpan(opStart));
        break;
      case TokenKind.BACKSLASH:
        // Backslash outside of string; detected IE8 or older signaled by \9 at
        // end of an expression.
        var ie8Start = _peekToken.start;

        _next();
        if (_peekKind(TokenKind.INTEGER)) {
          var numToken = _next();
          var value = int.parse(numToken.text);
          if (value == 9) {
            op = new IE8Term(_makeSpan(ie8Start));
          } else if (isChecked) {
            _warning("\$value is not valid in an expression", _makeSpan(start));
          }
        }
        break;
      }

      if (expr != null) {
        if (expr is List) {
          expr.forEach((exprItem) {
            expressions.add(exprItem);
          });
        } else {
          expressions.add(expr);
        }
      } else {
        keepGoing = false;
      }

      if (op != null) {
        expressions.add(op);
        if (op is IE8Term) {
          keepGoing = false;
        } else {
          _next();
        }
      }
    }

    return expressions;
  }

  static final int MAX_UNICODE = int.parse('0x10FFFF');

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
  processTerm([bool ieFilter = false]) {
    var start = _peekToken.start;
    Token t;                          // token for term's value
    var value;                        // value of term (numeric values)

    var unary = "";
    switch (_peek()) {
    case TokenKind.HASH:
      this._eat(TokenKind.HASH);
      if (!_anyWhiteSpaceBeforePeekToken(TokenKind.HASH)) {
        String hexText;
        if (_peekKind(TokenKind.INTEGER)) {
          String hexText1 = _peekToken.text;
          _next();
          if (_peekIdentifier()) {
            hexText = '$hexText1${identifier().name}';
          } else {
            hexText = hexText1;
          }
        } else if (_peekIdentifier()) {
          hexText = identifier().name;
        }
        if (hexText != null) {
          return _parseHex(hexText, _makeSpan(start));
        }
      }

      if (isChecked) {
        _warning("Expected hex number", _makeSpan(start));
      }
      // Construct the bad hex value with a #<space>number.
      return _parseHex(" ${processTerm().text}", _makeSpan(start));
    case TokenKind.INTEGER:
      t = _next();
      value = int.parse("${unary}${t.text}");
      break;
    case TokenKind.DOUBLE:
      t = _next();
      value = double.parse("${unary}${t.text}");
      break;
    case TokenKind.SINGLE_QUOTE:
      value = processQuotedString(false);
      value = "'${_escapeString(value, single: true)}'";
      return new LiteralTerm(value, value, _makeSpan(start));
    case TokenKind.DOUBLE_QUOTE:
      value = processQuotedString(false);
      value = '"${_escapeString(value)}"';
      return new LiteralTerm(value, value, _makeSpan(start));
    case TokenKind.LPAREN:
      _next();

      GroupTerm group = new GroupTerm(_makeSpan(start));

      var term;
      do {
        term = processTerm();
        if (term != null && term is LiteralTerm) {
          group.add(term);
        }
      } while (term != null && !_maybeEat(TokenKind.RPAREN) &&
          !isPrematureEndOfFile());

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

      if (!ieFilter && _maybeEat(TokenKind.LPAREN)) {
        // FUNCTION
        return processFunction(nameValue);
      } if (ieFilter) {
         if (_maybeEat(TokenKind.COLON) &&
           nameValue.name.toLowerCase() == 'progid') {
           // IE filter:progid:
           return processIEFilter(start);
         } else {
           // Handle filter:<name> where name is any filter e.g., alpha, chroma,
           // Wave, blur, etc.
           return processIEFilter(start);
         }
      }

      // TODO(terry): Need to have a list of known identifiers today only
      //              'from' is special.
      if (nameValue.name == 'from') {
        return new LiteralTerm(nameValue, nameValue.name, _makeSpan(start));
      }

      // What kind of identifier is it, named color?
      var colorEntry = TokenKind.matchColorName(nameValue.name);
      if (colorEntry == null) {
        if (isChecked) {
          var propName = nameValue.name;
          var errMsg = TokenKind.isPredefinedName(propName) ?
              "Improper use of property value ${propName}" :
              "Unknown property value ${propName}";
          _warning(errMsg, _makeSpan(start));
        }
        return new LiteralTerm(nameValue, nameValue.name, _makeSpan(start));
      }

      // Yes, process the color as an RGB value.
      var rgbColor =
          TokenKind.decimalToHex(TokenKind.colorValue(colorEntry), 6);
      return _parseHex(rgbColor, _makeSpan(start));
    case TokenKind.UNICODE_RANGE:
      var first;
      var second;
      var firstNumber;
      var secondNumber;
      _eat(TokenKind.UNICODE_RANGE, unicodeRange: true);
      if (_maybeEat(TokenKind.HEX_INTEGER, unicodeRange: true)) {
        first = _previousToken.text;
        firstNumber = int.parse('0x$first');
        if (firstNumber > MAX_UNICODE) {
          _error("unicode range must be less than 10FFFF", _makeSpan(start));
        }
        if (_maybeEat(TokenKind.MINUS, unicodeRange: true)) {
          if (_maybeEat(TokenKind.HEX_INTEGER, unicodeRange: true)) {
            second = _previousToken.text;
            secondNumber = int.parse('0x$second');
            if (secondNumber > MAX_UNICODE) {
              _error("unicode range must be less than 10FFFF",
                  _makeSpan(start));
            }
            if (firstNumber > secondNumber) {
              _error("unicode first range can not be greater than last",
                  _makeSpan(start));
            }
          }
        }
      } else if (_maybeEat(TokenKind.HEX_RANGE, unicodeRange: true)) {
        first = _previousToken.text;
      }

      return new UnicodeRangeTerm(first, second, _makeSpan(start));
    case TokenKind.AT:
      if (messages.options.lessSupport) {
        _next();

        var expr = processExpr();
        if (isChecked && expr.expressions.length > 1) {
          _error("only @name for Less syntax", _peekToken.span);
        }

        var param = expr.expressions[0];
        var varUsage = new VarUsage(param.text, [], _makeSpan(start));
        expr.expressions[0] = varUsage;
        return expr.expressions;
      }
      break;
    }

    return processDimension(t, value, _makeSpan(start));
  }

  /** Process all dimension units. */
  LiteralTerm processDimension(Token t, var value, SourceSpan span) {
    LiteralTerm term;
    var unitType = this._peek();

    switch (unitType) {
    case TokenKind.UNIT_EM:
      term = new EmTerm(value, t.text, span);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_EX:
      term = new ExTerm(value, t.text, span);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_LENGTH_PX:
    case TokenKind.UNIT_LENGTH_CM:
    case TokenKind.UNIT_LENGTH_MM:
    case TokenKind.UNIT_LENGTH_IN:
    case TokenKind.UNIT_LENGTH_PT:
    case TokenKind.UNIT_LENGTH_PC:
      term = new LengthTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_ANGLE_DEG:
    case TokenKind.UNIT_ANGLE_RAD:
    case TokenKind.UNIT_ANGLE_GRAD:
    case TokenKind.UNIT_ANGLE_TURN:
      term = new AngleTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_TIME_MS:
    case TokenKind.UNIT_TIME_S:
      term = new TimeTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_FREQ_HZ:
    case TokenKind.UNIT_FREQ_KHZ:
      term = new FreqTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.PERCENT:
      term = new PercentageTerm(value, t.text, span);
      _next();    // Skip the %
      break;
    case TokenKind.UNIT_FRACTION:
      term = new FractionTerm(value, t.text, span);
      _next();     // Skip the unit
      break;
    case TokenKind.UNIT_RESOLUTION_DPI:
    case TokenKind.UNIT_RESOLUTION_DPCM:
    case TokenKind.UNIT_RESOLUTION_DPPX:
      term = new ResolutionTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_CH:
      term = new ChTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_REM:
      term = new RemTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    case TokenKind.UNIT_VIEWPORT_VW:
    case TokenKind.UNIT_VIEWPORT_VH:
    case TokenKind.UNIT_VIEWPORT_VMIN:
    case TokenKind.UNIT_VIEWPORT_VMAX:
      term = new ViewportTerm(value, t.text, span, unitType);
      _next();    // Skip the unit
      break;
    default:
      if (value != null && t != null) {
        term = (value is Identifier)
            ? new LiteralTerm(value, value.name, span)
            : new NumberTerm(value, t.text, span);
      }
      break;
    }

    return term;
  }

  String processQuotedString([bool urlString = false]) {
    var start = _peekToken.start;

    // URI term sucks up everything inside of quotes(' or ") or between parens
    var stopToken = urlString ? TokenKind.RPAREN : -1;

    // Note: disable skipping whitespace tokens inside a string.
    // TODO(jmesserly): the layering here feels wrong.
    var skipWhitespace = tokenizer._skipWhitespace;
    tokenizer._skipWhitespace = false;

    switch (_peek()) {
    case TokenKind.SINGLE_QUOTE:
      stopToken = TokenKind.SINGLE_QUOTE;
      start = _peekToken.start + 1;   // Skip the quote might have whitespace.
      _next();    // Skip the SINGLE_QUOTE.
      break;
    case TokenKind.DOUBLE_QUOTE:
      stopToken = TokenKind.DOUBLE_QUOTE;
      start = _peekToken.start + 1;   // Skip the quote might have whitespace.
      _next();    // Skip the DOUBLE_QUOTE.
      break;
    default:
      if (urlString) {
        if (_peek() == TokenKind.LPAREN) {
          _next();    // Skip the LPAREN.
          start = _peekToken.start;
        }
        stopToken = TokenKind.RPAREN;
      } else {
        _error('unexpected string', _makeSpan(start));
      }
      break;
    }

    // Gobble up everything until we hit our stop token.
    var runningStart = _peekToken.start;

    var stringValue = new StringBuffer();
    while (_peek() != stopToken && _peek() != TokenKind.END_OF_FILE) {
      stringValue.write(_next().text);
    }

    tokenizer._skipWhitespace = skipWhitespace;

    // All characters between quotes is the string.
    if (stopToken != TokenKind.RPAREN) {
      _next();    // Skip the SINGLE_QUOTE or DOUBLE_QUOTE;
    }

    return stringValue.toString();
  }

  // TODO(terry): Should probably understand IE's non-standard filter syntax to
  //              fully support calc, var(), etc.
  /**
   * IE's filter property breaks CSS value parsing.  IE's format can be:
   *
   *    filter: progid:DXImageTransform.MS.gradient(Type=0, Color='#9d8b83');
   *
   * We'll just parse everything after the 'progid:' look for the left paren
   * then parse to the right paren ignoring everything in between.
   */
  processIEFilter(int startAfterProgidColon) {
    var parens = 0;

    while (_peek() != TokenKind.END_OF_FILE) {
      switch (_peek()) {
        case TokenKind.LPAREN:
          _eat(TokenKind.LPAREN);
          parens++;
          break;
        case TokenKind.RPAREN:
          _eat(TokenKind.RPAREN);
          if (--parens == 0) {
            var tok = tokenizer.makeIEFilter(startAfterProgidColon,
                _peekToken.start);
            return new LiteralTerm(tok.text, tok.text, tok.span);
          }
          break;
        default:
          _eat(_peek());
      }
    }
  }

  //  Function grammar:
  //
  //  function:     IDENT '(' expr ')'
  //
  processFunction(Identifier func) {
    var start = _peekToken.start;

    var name = func.name;

    switch (name) {
    case 'url':
      // URI term sucks up everything inside of quotes(' or ") or between parens
      var urlParam = processQuotedString(true);

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
    case 'var':
      // TODO(terry): Consider handling var in IE specific filter/progid.  This
      //              will require parsing entire IE specific syntax e.g.,
      //              param = value or progid:com_id, etc. for example:
      //
      //    var-blur: Blur(Add = 0, Direction = 225, Strength = 10);
      //    var-gradient: progid:DXImageTransform.Microsoft.gradient"
      //      (GradientType=0,StartColorStr='#9d8b83', EndColorStr='#847670');
      var expr = processExpr();
      if (!_maybeEat(TokenKind.RPAREN)) {
        _error("problem parsing var expected ), ", _peekToken.span);
      }
      if (isChecked &&
          expr.expressions.where((e) => e is OperatorComma).length > 1) {
        _error("too many parameters to var()", _peekToken.span);
      }

      var paramName = expr.expressions[0].text;

      // [0] - var name, [1] - OperatorComma, [2] - default value.
      var defaultValues = expr.expressions.length >= 3
          ? expr.expressions.sublist(2) : [];
      return new VarUsage(paramName, defaultValues, _makeSpan(start));
    default:
      var expr = processExpr();
      if (!_maybeEat(TokenKind.RPAREN)) {
        _error("problem parsing function expected ), ", _peekToken.span);
      }

      return new FunctionTerm(name, name, expr, _makeSpan(start));
    }

    return null;
  }

  Identifier identifier() {
    var tok = _next();

    if (!TokenKind.isIdentifier(tok.kind) &&
        !TokenKind.isKindIdentifier(tok.kind)) {
      if (isChecked) {
        _warning('expected identifier, but found $tok', tok.span);
      }
      return new Identifier("", _makeSpan(tok.start));
    }

    return new Identifier(tok.text, _makeSpan(tok.start));
  }

  // TODO(terry): Move this to base <= 36 and into shared code.
  static int _hexDigit(int c) {
    if (c >= 48/*0*/ && c <= 57/*9*/) {
      return c - 48;
    } else if (c >= 97/*a*/ && c <= 102/*f*/) {
      return c - 87;
    } else if (c >= 65/*A*/ && c <= 70/*F*/) {
      return c - 55;
    } else {
      return -1;
    }
  }

  HexColorTerm _parseHex(String hexText, SourceSpan span) {
    var hexValue = 0;

     for (var i = 0; i < hexText.length; i++) {
      var digit = _hexDigit(hexText.codeUnitAt(i));
      if (digit < 0) {
        _warning('Bad hex number', span);
        return new HexColorTerm(new BAD_HEX_VALUE(), hexText, span);
      }
      hexValue = (hexValue << 4) + digit;
    }

    // Make 3 character hex value #RRGGBB => #RGB iff:
    // high/low nibble of RR is the same, high/low nibble of GG is the same and
    // high/low nibble of BB is the same.
    if (hexText.length == 6 &&
        hexText[0] == hexText[1] &&
        hexText[2] == hexText[3] &&
        hexText[4] == hexText[5]) {
      hexText = '${hexText[0]}${hexText[2]}${hexText[4]}';
    } else if (hexText.length == 4 &&
        hexText[0] == hexText[1] &&
        hexText[2] == hexText[3]) {
      hexText = '${hexText[0]}${hexText[2]}';
    } else if (hexText.length == 2 && hexText[0] == hexText[1]) {
      hexText = '${hexText[0]}';
    }
    return new HexColorTerm(hexValue, hexText, span);
  }
}

class ExpressionsProcessor {
  final Expressions _exprs;
  int _index = 0;

  ExpressionsProcessor(this._exprs);

  // TODO(terry): Only handles ##px unit.
  FontExpression processFontSize() {
    /* font-size[/line-height]
     *
     * Possible size values:
     *   xx-small
     *   small
     *   medium [default]
     *   large
     *   x-large
     *   xx-large
     *   smaller
     *   larger
     *   ##length in px, pt, etc.
     *   ##%, percent of parent elem's font-size
     *   inherit
     */
    LengthTerm size;
    LineHeight lineHt;
    var nextIsLineHeight = false;
    for (; _index < _exprs.expressions.length; _index++) {
      var expr = _exprs.expressions[_index];
      if (size == null && expr is LengthTerm) {
        // font-size part.
        size = expr;
      } else if (size != null) {
        if (expr is OperatorSlash) {
          // LineHeight could follow?
          nextIsLineHeight = true;
        } else if (nextIsLineHeight && expr is LengthTerm) {
          assert(expr.unit == TokenKind.UNIT_LENGTH_PX);
          lineHt = new LineHeight(expr.value, inPixels: true);
          nextIsLineHeight = false;
          _index++;
          break;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return new FontExpression(_exprs.span, size: size, lineHeight: lineHt);
  }

  FontExpression processFontFamily() {
    var family = <String>[];

    /* Possible family values:
     * font-family: arial, Times new roman ,Lucida Sans Unicode,Courier;
     * font-family: "Times New Roman", arial, Lucida Sans Unicode, Courier;
     */
    var moreFamilies = false;

    for (; _index < _exprs.expressions.length; _index++) {
      Expression expr = _exprs.expressions[_index];
      if (expr is LiteralTerm) {
        if (family.length == 0 || moreFamilies) {
          // It's font-family now.
          family.add(expr.toString());
          moreFamilies = false;
        } else if (isChecked) {
          messages.warning('Only font-family can be a list', _exprs.span);
        }
      } else if (expr is OperatorComma && family.length > 0) {
        moreFamilies = true;
      } else {
        break;
      }
    }

    return new FontExpression(_exprs.span, family: family);
  }

  FontExpression processFont() {
    List<String> family;

    // Process all parts of the font expression.
    FontExpression fontSize;
    FontExpression fontFamily;
    for (; _index < _exprs.expressions.length; _index++) {
      var expr = _exprs.expressions[_index];
      // Order is font-size font-family
      if (fontSize == null) {
        fontSize = processFontSize();
      }
      if (fontFamily == null) {
        fontFamily = processFontFamily();
      }
      //TODO(terry): Handle font-weight, font-style, and font-variant. See
      //               https://github.com/dart-lang/csslib/issues/3
      //               https://github.com/dart-lang/csslib/issues/4
      //               https://github.com/dart-lang/csslib/issues/5
    }

    return new FontExpression(_exprs.span,
        size: fontSize.font.size,
        lineHeight: fontSize.font.lineHeight,
        family: fontFamily.font.family);
  }
}

/**
 * Escapes [text] for use in a CSS string.
 * [single] specifies single quote `'` vs double quote `"`.
 */
String _escapeString(String text, {bool single: false}) {
  StringBuffer result = null;

  for (int i = 0; i < text.length; i++) {
    var code = text.codeUnitAt(i);
    String replace = null;
    switch (code) {
      case 34/*'"'*/:  if (!single) replace = r'\"'; break;
      case 39/*"'"*/:  if (single) replace = r"\'"; break;
    }

    if (replace != null && result == null) {
      result = new StringBuffer(text.substring(0, i));
    }

    if (result != null) result.write(replace != null ? replace : text[i]);
  }

  return result == null ? text : result.toString();
}
