// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Need to be consistent with tokens either they're ASCII tokens
//              e.g., ASTERISK or they're CSS e.g., PSEUDO, COMBINATOR_*.
class TokenKind {
  // Common shared tokens used in TokenizerBase.
  static final int END_OF_FILE = 0;
  static final int LPAREN = 1;
  static final int RPAREN = 2;
  static final int LBRACK = 3;
  static final int RBRACK = 4;
  static final int LBRACE = 5;
  static final int RBRACE = 6;
  static final int DOT = 7;

  // Unique tokens for CSS.
  static final int AT = 8;
  static final int HASH = 9;
  static final int COMBINATOR_PLUS = 10;
  static final int COMBINATOR_GREATER = 11;
  static final int COMBINATOR_TILDE = 12;
  static final int ASTERISK = 13;
  static final int NAMESPACE = 14;
  static final int PSEUDO = 15;
  static final int PRIVATE_NAME = 16;           // _ prefix private class or id
  static final int COMMA = 17;
  static final int SPACE = 18;
  static final int TAB = 19;
  static final int NEWLINE = 20;
  static final int RETURN = 21;

  // WARNING: END_TOKENS must be 1 greater than the last token above (last
  //          character in our list).  Also add to kindToString function and the
  //          constructor for TokenKind.

  static final int END_TOKENS = 22;             // Marker for last token in list

  // Synthesized Tokens (no character associated with TOKEN).
  // TODO(terry): Possible common names used by both Dart and CSS tokenizers.
  static final int STRING = 500;
  static final int STRING_PART = 501;
  static final int NUMBER = 502;
  static final int HEX_NUMBER = 503;
  static final int WHITESPACE = 504;
  static final int COMMENT = 505;
  static final int ERROR = 506;
  static final int INCOMPLETE_STRING = 507;
  static final int INCOMPLETE_COMMENT = 508;
  static final int INCOMPLETE_MULTILINE_STRING_DQ = 509;
  static final int INCOMPLETE_MULTILINE_STRING_SQ = 510;
  static final int IDENTIFIER = 511;

  // Uniquely synthesized tokens for CSS.
  static final int SELECTOR_EXPRESSION = 512;
  static final int COMBINATOR_NONE = 513;
  static final int COMBINATOR_DESCENDANT = 514; // Space combinator

  // Attribute match:
  static final int INCLUDES_MATCH = 515;        // ~=
  static final int DASH_MATCH = 516;            // |=
  static final int PREFIX_MATCH = 517;          // ^=
  static final int SUFFIX_MATCH = 518;          // $=
  static final int STRING_MATCH = 519;          // *=
  static final int EQUAL_MATCH = 520;           // =

  // Simple selector type.
  static final int CLASS_NAME = 700;            // .class
  static final int ELEMENT_NAME = 701;          // tagName
  static final int HASH_NAME = 702;             // #elementId
  static final int ATTRIBUTE_NAME = 703;        // [attrib]
  static final int PSEUDO_ELEMENT_NAME = 704;   // ::pseudoElement
  static final int PSEUDO_CLASS_NAME = 705;     // :pseudoClass
  static final int NEGATION = 706;              // NOT

  List<int> tokens;

  static String kindToString(int kind) {
    switch(kind) {
      case TokenKind.END_OF_FILE: return "end of file";
      case TokenKind.LPAREN: return "(";
      case TokenKind.RPAREN: return ")";
      case TokenKind.LBRACK: return "[";
      case TokenKind.RBRACK: return "[";
      case TokenKind.LBRACE: return "{";
      case TokenKind.RBRACE: return "}";
      case TokenKind.DOT: return ".";
      case TokenKind.AT: return "@";
      case TokenKind.HASH: return "#";
      case TokenKind.COMBINATOR_PLUS: return "+";
      case TokenKind.COMBINATOR_GREATER: return ">";
      case TokenKind.COMBINATOR_TILDE: return "~";
      case TokenKind.ASTERISK: return "*";
      case TokenKind.NAMESPACE: return "|";
      case TokenKind.PSEUDO: return ":";
      case TokenKind.PRIVATE_NAME: return "_";
      case TokenKind.COMMA: return ",";
      case TokenKind.SPACE: return " ";
      case TokenKind.TAB: return "\t";
      case TokenKind.NEWLINE: return "\n";
      case TokenKind.RETURN: return "\r";

      default:
        throw "Unknown TOKEN";
    }
  }

  TokenKind() {
    tokens = [];

    // All tokens must be in TokenKind order.
    tokens.add(0);                                      // TokenKind.END_OF_FILE
    tokens.add(TokenKind.kindToString(TokenKind.LPAREN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RPAREN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.LBRACK).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RBRACK).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.LBRACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RBRACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.DOT).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.AT).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.HASH).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.COMBINATOR_PLUS).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.COMBINATOR_GREATER).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.COMBINATOR_TILDE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.ASTERISK).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.NAMESPACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.PSEUDO).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.PRIVATE_NAME).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.COMMA).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.SPACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.TAB).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.NEWLINE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RETURN).charCodeAt(0));

    assert(tokens.length == TokenKind.END_TOKENS);
  }

  static bool isIdentifier(int kind) {
    return kind == IDENTIFIER ;
  }
}
