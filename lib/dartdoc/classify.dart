// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('classify');

#import('frog/lang.dart');
#import('markdown.dart', prefix: 'md');

/**
 * Kinds of tokens that we care to highlight differently. The values of the
 * fields here will be used as CSS class names for the generated spans.
 */
class Classification {
  static final NONE = null;
  static final ERROR = "e";
  static final COMMENT = "c";
  static final IDENTIFIER = "i";
  static final KEYWORD = "k";
  static final OPERATOR = "o";
  static final STRING = "s";
  static final NUMBER = "n";
  static final PUNCTUATION = "p";

  // A few things that are nice to make different:
  static final TYPE_IDENTIFIER = "t";

  // Between a keyword and an identifier
  static final SPECIAL_IDENTIFIER = "r";

  static final ARROW_OPERATOR = "a";

  static final STRING_INTERPOLATION = 'si';
}

String classifySource(SourceFile src) {
  var html = new StringBuffer();
  var tokenizer = new Tokenizer(src, /*skipWhitespace:*/false);

  var token;
  var inString = false;
  while ((token = tokenizer.next()).kind != TokenKind.END_OF_FILE) {

    // Track whether or not we're in a string.
    switch (token.kind) {
      case TokenKind.STRING:
      case TokenKind.STRING_PART:
      case TokenKind.INCOMPLETE_STRING:
      case TokenKind.INCOMPLETE_MULTILINE_STRING_DQ:
      case TokenKind.INCOMPLETE_MULTILINE_STRING_SQ:
        inString = true;
        break;
    }

    final kind = classify(token);
    final text = md.escapeHtml(token.text);
    if (kind != null) {
      // Add a secondary class to tokens appearing within a string so that
      // we can highlight tokens in an interpolation specially.
      var stringClass = inString ? Classification.STRING_INTERPOLATION : '';
      html.add('<span class="$kind $stringClass">$text</span>');
    } else {
      html.add('<span>$text</span>');
    }

    // Track whether or not we're in a string.
    if (token.kind == TokenKind.STRING) {
      inString = false;
    }
  }
  return html.toString();
}

bool _looksLikeType(String name) {
  // If the name looks like an UppercaseName, assume it's a type.
  return _looksLikePublicType(name) || _looksLikePrivateType(name);
}

bool _looksLikePublicType(String name) {
  // If the name looks like an UppercaseName, assume it's a type.
  return name.length >= 2 && isUpper(name[0]) && isLower(name[1]);
}

bool _looksLikePrivateType(String name) {
  // If the name looks like an _UppercaseName, assume it's a type.
  return (name.length >= 3 && name[0] == '_' && isUpper(name[1])
    && isLower(name[2]));
}

// These ensure that they don't return "true" if the string only has symbols.
bool isUpper(String s) => s.toLowerCase() != s;
bool isLower(String s) => s.toUpperCase() != s;

String classify(Token token) {
  switch (token.kind) {
    case TokenKind.ERROR:
      return Classification.ERROR;

    case TokenKind.IDENTIFIER:
      // Special case for names that look like types.
      if (_looksLikeType(token.text)
          || token.text == 'num'
          || token.text == 'bool'
          || token.text == 'int'
          || token.text == 'double') {
        return Classification.TYPE_IDENTIFIER;
      }
      return Classification.IDENTIFIER;

    // Even though it's a reserved word, let's try coloring it like a type.
    case TokenKind.VOID:
      return Classification.TYPE_IDENTIFIER;

    case TokenKind.THIS:
    case TokenKind.SUPER:
      return Classification.SPECIAL_IDENTIFIER;

    case TokenKind.STRING:
    case TokenKind.STRING_PART:
    case TokenKind.INCOMPLETE_STRING:
    case TokenKind.INCOMPLETE_MULTILINE_STRING_DQ:
    case TokenKind.INCOMPLETE_MULTILINE_STRING_SQ:
      return Classification.STRING;

    case TokenKind.INTEGER:
    case TokenKind.HEX_INTEGER:
    case TokenKind.DOUBLE:
      return Classification.NUMBER;

    case TokenKind.COMMENT:
    case TokenKind.INCOMPLETE_COMMENT:
      return Classification.COMMENT;

    // => is so awesome it is in a class of its own.
    case TokenKind.ARROW:
      return Classification.ARROW_OPERATOR;

    case TokenKind.HASHBANG:
    case TokenKind.LPAREN:
    case TokenKind.RPAREN:
    case TokenKind.LBRACK:
    case TokenKind.RBRACK:
    case TokenKind.LBRACE:
    case TokenKind.RBRACE:
    case TokenKind.COLON:
    case TokenKind.SEMICOLON:
    case TokenKind.COMMA:
    case TokenKind.DOT:
    case TokenKind.ELLIPSIS:
      return Classification.PUNCTUATION;

    case TokenKind.INCR:
    case TokenKind.DECR:
    case TokenKind.BIT_NOT:
    case TokenKind.NOT:
    case TokenKind.ASSIGN:
    case TokenKind.ASSIGN_OR:
    case TokenKind.ASSIGN_XOR:
    case TokenKind.ASSIGN_AND:
    case TokenKind.ASSIGN_SHL:
    case TokenKind.ASSIGN_SAR:
    case TokenKind.ASSIGN_SHR:
    case TokenKind.ASSIGN_ADD:
    case TokenKind.ASSIGN_SUB:
    case TokenKind.ASSIGN_MUL:
    case TokenKind.ASSIGN_DIV:
    case TokenKind.ASSIGN_TRUNCDIV:
    case TokenKind.ASSIGN_MOD:
    case TokenKind.CONDITIONAL:
    case TokenKind.OR:
    case TokenKind.AND:
    case TokenKind.BIT_OR:
    case TokenKind.BIT_XOR:
    case TokenKind.BIT_AND:
    case TokenKind.SHL:
    case TokenKind.SAR:
    case TokenKind.SHR:
    case TokenKind.ADD:
    case TokenKind.SUB:
    case TokenKind.MUL:
    case TokenKind.DIV:
    case TokenKind.TRUNCDIV:
    case TokenKind.MOD:
    case TokenKind.EQ:
    case TokenKind.NE:
    case TokenKind.EQ_STRICT:
    case TokenKind.NE_STRICT:
    case TokenKind.LT:
    case TokenKind.GT:
    case TokenKind.LTE:
    case TokenKind.GTE:
    case TokenKind.INDEX:
    case TokenKind.SETINDEX:
      return Classification.OPERATOR;

    // Color this like a keyword
    case TokenKind.HASH:

    case TokenKind.ABSTRACT:
    case TokenKind.ASSERT:
    case TokenKind.CLASS:
    case TokenKind.EXTENDS:
    case TokenKind.FACTORY:
    case TokenKind.GET:
    case TokenKind.IMPLEMENTS:
    case TokenKind.IMPORT:
    case TokenKind.INTERFACE:
    case TokenKind.LIBRARY:
    case TokenKind.NATIVE:
    case TokenKind.NEGATE:
    case TokenKind.OPERATOR:
    case TokenKind.SET:
    case TokenKind.SOURCE:
    case TokenKind.STATIC:
    case TokenKind.TYPEDEF:
    case TokenKind.BREAK:
    case TokenKind.CASE:
    case TokenKind.CATCH:
    case TokenKind.CONST:
    case TokenKind.CONTINUE:
    case TokenKind.DEFAULT:
    case TokenKind.DO:
    case TokenKind.ELSE:
    case TokenKind.FALSE:
    case TokenKind.FINALLY:
    case TokenKind.FOR:
    case TokenKind.IF:
    case TokenKind.IN:
    case TokenKind.IS:
    case TokenKind.NEW:
    case TokenKind.NULL:
    case TokenKind.RETURN:
    case TokenKind.SWITCH:
    case TokenKind.THROW:
    case TokenKind.TRUE:
    case TokenKind.TRY:
    case TokenKind.WHILE:
    case TokenKind.VAR:
    case TokenKind.FINAL:
      return Classification.KEYWORD;

    case TokenKind.WHITESPACE:
    case TokenKind.END_OF_FILE:
      return Classification.NONE;

    default:
      return Classification.NONE;
  }
}