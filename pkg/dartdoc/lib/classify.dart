// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('classify');

#import('../../../lib/compiler/implementation/scanner/scannerlib.dart');
// TODO(rnystrom): Use "package:" URL (#4968).
#import('markdown.dart', prefix: 'md');

/**
 * Kinds of tokens that we care to highlight differently. The values of the
 * fields here will be used as CSS class names for the generated spans.
 */
class Classification {
  static const NONE = null;
  static const ERROR = "e";
  static const COMMENT = "c";
  static const IDENTIFIER = "i";
  static const KEYWORD = "k";
  static const OPERATOR = "o";
  static const STRING = "s";
  static const NUMBER = "n";
  static const PUNCTUATION = "p";

  // A few things that are nice to make different:
  static const TYPE_IDENTIFIER = "t";

  // Between a keyword and an identifier
  static const SPECIAL_IDENTIFIER = "r";

  static const ARROW_OPERATOR = "a";

  static const STRING_INTERPOLATION = 'si';
}

String classifySource(String text) {
  var html = new StringBuffer();
  var tokenizer = new StringScanner(text, includeComments: true);

  var whitespaceOffset = 0;
  var token = tokenizer.tokenize();
  var inString = false;
  while (token.kind != EOF_TOKEN) {
    html.add(text.substring(whitespaceOffset, token.charOffset));
    whitespaceOffset = token.charOffset + token.slowCharCount;

    // Track whether or not we're in a string.
    switch (token.kind) {
      case STRING_TOKEN:
      case STRING_INTERPOLATION_TOKEN:
        inString = true;
        break;
    }

    final kind = classify(token);
    final escapedText = md.escapeHtml(token.slowToString());
    if (kind != null) {
      // Add a secondary class to tokens appearing within a string so that
      // we can highlight tokens in an interpolation specially.
      var stringClass = inString ? Classification.STRING_INTERPOLATION : '';
      html.add('<span class="$kind $stringClass">$escapedText</span>');
    } else {
      html.add(escapedText);
    }

    // Track whether or not we're in a string.
    if (token.kind == STRING_TOKEN) {
      inString = false;
    }
    token = token.next;
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
    case UNKNOWN_TOKEN:
      return Classification.ERROR;

    case IDENTIFIER_TOKEN:
      // Special case for names that look like types.
      final text = token.slowToString();
      if (_looksLikeType(text)
          || text == 'num'
          || text == 'bool'
          || text == 'int'
          || text == 'double') {
        return Classification.TYPE_IDENTIFIER;
      }
      return Classification.IDENTIFIER;

    case STRING_TOKEN:
    case STRING_INTERPOLATION_TOKEN:
      return Classification.STRING;

    case INT_TOKEN:
    case HEXADECIMAL_TOKEN:
    case DOUBLE_TOKEN:
      return Classification.NUMBER;

    case COMMENT_TOKEN:
      return Classification.COMMENT;

    // => is so awesome it is in a class of its own.
    case FUNCTION_TOKEN:
      return Classification.ARROW_OPERATOR;

    case OPEN_PAREN_TOKEN:
    case CLOSE_PAREN_TOKEN:
    case OPEN_SQUARE_BRACKET_TOKEN:
    case CLOSE_SQUARE_BRACKET_TOKEN:
    case OPEN_CURLY_BRACKET_TOKEN:
    case CLOSE_CURLY_BRACKET_TOKEN:
    case COLON_TOKEN:
    case SEMICOLON_TOKEN:
    case COMMA_TOKEN:
    case PERIOD_TOKEN:
    case PERIOD_PERIOD_TOKEN:
      return Classification.PUNCTUATION;

    case PLUS_PLUS_TOKEN:
    case MINUS_MINUS_TOKEN:
    case TILDE_TOKEN:
    case BANG_TOKEN:
    case EQ_TOKEN:
    case BAR_EQ_TOKEN:
    case CARET_EQ_TOKEN:
    case AMPERSAND_EQ_TOKEN:
    case LT_LT_EQ_TOKEN:
    case GT_GT_EQ_TOKEN:
    case PLUS_EQ_TOKEN:
    case MINUS_EQ_TOKEN:
    case STAR_EQ_TOKEN:
    case SLASH_EQ_TOKEN:
    case TILDE_SLASH_EQ_TOKEN:
    case PERCENT_EQ_TOKEN:
    case QUESTION_TOKEN:
    case BAR_BAR_TOKEN:
    case AMPERSAND_AMPERSAND_TOKEN:
    case BAR_TOKEN:
    case CARET_TOKEN:
    case AMPERSAND_TOKEN:
    case LT_LT_TOKEN:
    case GT_GT_TOKEN:
    case PLUS_TOKEN:
    case MINUS_TOKEN:
    case STAR_TOKEN:
    case SLASH_TOKEN:
    case TILDE_SLASH_TOKEN:
    case PERCENT_TOKEN:
    case EQ_EQ_TOKEN:
    case BANG_EQ_TOKEN:
    case EQ_EQ_EQ_TOKEN:
    case BANG_EQ_EQ_TOKEN:
    case LT_TOKEN:
    case GT_TOKEN:
    case LT_EQ_TOKEN:
    case GT_EQ_TOKEN:
    case INDEX_TOKEN:
    case INDEX_EQ_TOKEN:
      return Classification.OPERATOR;

    // Color keyword token. Most are colored as keywords.
    case HASH_TOKEN:
    case KEYWORD_TOKEN:
      if (token.stringValue === 'void') {
        // Color "void" as a type.
        return Classification.TYPE_IDENTIFIER;
      }
      if (token.stringValue === 'this' || token.stringValue === 'super') {
        // Color "this" and "super" as identifiers.
        return Classification.SPECIAL_IDENTIFIER;
      }
      return Classification.KEYWORD;

    case EOF_TOKEN:
      return Classification.NONE;

    default:
      return Classification.NONE;
  }
}
