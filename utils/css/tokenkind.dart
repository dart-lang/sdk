// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Need to be consistent with tokens either they're ASCII tokens
//              e.g., ASTERISK or they're CSS e.g., PSEUDO, COMBINATOR_*.
class TokenKind {
  // Common shared tokens used in TokenizerBase.
  static final int UNUSED = 0;                  // Unused place holder...
  static final int END_OF_FILE = 1;             // TODO(terry): Must match base
  static final int LPAREN = 2;                  // (
  static final int RPAREN = 3;                  // )
  static final int LBRACK = 4;                  // [
  static final int RBRACK = 5;                  // ]
  static final int LBRACE = 6;                  // {
  static final int RBRACE = 7;                  // }
  static final int DOT = 8;                     // .
  static final int SEMICOLON = 9;               // ;

  // Unique tokens for CSS.
  static final int AT = 10;                     // @
  static final int HASH = 11;                   // #
  static final int PLUS = 12;                   // +
  static final int GREATER = 13;                // >
  static final int TILDE = 14;                  // ~
  static final int ASTERISK = 15;               // *
  static final int NAMESPACE = 16;              // |
  static final int COLON = 17;                  // :
  static final int PRIVATE_NAME = 18;           // _ prefix private class or id
  static final int COMMA = 19;                  // ,
  static final int SPACE = 20;
  static final int TAB = 21;                    // /t
  static final int NEWLINE = 22;                // /n
  static final int RETURN = 23;                 // /r
  static final int PERCENT = 24;                // %
  static final int SINGLE_QUOTE = 25;           // '
  static final int DOUBLE_QUOTE = 26;           // "
  static final int SLASH = 27;                  // /
  static final int EQUALS = 28;                 // =
  static final int OR = 29;                     // |
  static final int CARET = 30;                  // ^
  static final int DOLLAR = 31;                 // $
  static final int LESS = 32;                   // <
  static final int BANG = 33;                   // !
  static final int MINUS = 34;                  // -

  // WARNING: END_TOKENS must be 1 greater than the last token above (last
  //          character in our list).  Also add to kindToString function and the
  //          constructor for TokenKind.

  static final int END_TOKENS = 35;             // Marker for last token in list

  /** [TokenKind] representing integer tokens. */
  static final int INTEGER = 60;                // TODO(terry): must match base

  /** [TokenKind] representing hex integer tokens. */
//  static final int HEX_INTEGER = 61;            // TODO(terry): must match base

  /** [TokenKind] representing double tokens. */
  static final int DOUBLE = 62;                 // TODO(terry): must match base

  /** [TokenKind] representing whitespace tokens. */
  static final int WHITESPACE = 63;             // TODO(terry): must match base

  /** [TokenKind] representing comment tokens. */
  static final int COMMENT = 64;                // TODO(terry): must match base

  /** [TokenKind] representing error tokens. */
  static final int ERROR = 65;                  // TODO(terry): must match base

  /** [TokenKind] representing incomplete string tokens. */
  static final int INCOMPLETE_STRING = 66;      // TODO(terry): must match base

  /** [TokenKind] representing incomplete comment tokens. */
  static final int INCOMPLETE_COMMENT = 67;     // TODO(terry): must match base

  // Synthesized Tokens (no character associated with TOKEN).
  // TODO(terry): Possible common names used by both Dart and CSS tokenizers.
  static final int STRING = 500;
  static final int STRING_PART = 501;
  static final int NUMBER = 502;
  static final int HEX_NUMBER = 503;
  static final int HTML_COMMENT = 504;          // <!--
  static final int IMPORTANT = 505;             // !important
  static final int IDENTIFIER = 511;

  // Uniquely synthesized tokens for CSS.
  static final int SELECTOR_EXPRESSION = 512;
  static final int COMBINATOR_NONE = 513;
  static final int COMBINATOR_DESCENDANT = 514; // Space combinator
  static final int COMBINATOR_PLUS = 515;       // + combinator
  static final int COMBINATOR_GREATER = 516;    // > combinator
  static final int COMBINATOR_TILDE = 517;      // ~ combinator

  static final int UNARY_OP_NONE = 518;         // No unary operator present.
  
  // Attribute match types:
  static final int INCLUDES = 530;              // '~='
  static final int DASH_MATCH = 531;            // '|='
  static final int PREFIX_MATCH = 532;          // '^='
  static final int SUFFIX_MATCH = 533;          // '$='
  static final int SUBSTRING_MATCH = 534;       // '*='
  static final int NO_MATCH = 535;              // No operator.

  // Unit types:
  static final int UNIT_EM = 600;
  static final int UNIT_EX = 601;
  static final int UNIT_LENGTH_PX = 602;
  static final int UNIT_LENGTH_CM = 603;
  static final int UNIT_LENGTH_MM = 604;
  static final int UNIT_LENGTH_IN = 605;
  static final int UNIT_LENGTH_PT = 606;
  static final int UNIT_LENGTH_PC = 607;
  static final int UNIT_ANGLE_DEG = 608;
  static final int UNIT_ANGLE_RAD = 609;
  static final int UNIT_ANGLE_GRAD = 610;
  static final int UNIT_TIME_MS = 611;
  static final int UNIT_TIME_S = 612;
  static final int UNIT_FREQ_HZ = 613;
  static final int UNIT_FREQ_KHZ = 614;
  static final int UNIT_PERCENT = 615;
  static final int UNIT_FRACTION = 616;

  // Directives (@nnnn)
  static final int DIRECTIVE_NONE = 650;
  static final int DIRECTIVE_IMPORT = 651;
  static final int DIRECTIVE_MEDIA = 652;
  static final int DIRECTIVE_PAGE = 653;
  static final int DIRECTIVE_INCLUDE = 654;
  static final int DIRECTIVE_STYLET = 655;
  static final int DIRECTIVE_KEYFRAMES = 656;
  static final int DIRECTIVE_FONTFACE = 657;

  // Simple selector type.
  static final int CLASS_NAME = 700;            // .class
  static final int ELEMENT_NAME = 701;          // tagName
  static final int HASH_NAME = 702;             // #elementId
  static final int ATTRIBUTE_NAME = 703;        // [attrib]
  static final int PSEUDO_ELEMENT_NAME = 704;   // ::pseudoElement
  static final int PSEUDO_CLASS_NAME = 705;     // :pseudoClass
  static final int NEGATION = 706;              // NOT

  static final List<Map<int, String>> _DIRECTIVES = const [
    const {'type': TokenKind.DIRECTIVE_IMPORT, 'value' : 'import'},
    const {'type': TokenKind.DIRECTIVE_MEDIA, 'value' : 'media'},
    const {'type': TokenKind.DIRECTIVE_PAGE, 'value' : 'page'},
    const {'type': TokenKind.DIRECTIVE_INCLUDE, 'value' : 'include'},
    const {'type': TokenKind.DIRECTIVE_STYLET, 'value' : 'stylet'},
    const {'type': TokenKind.DIRECTIVE_KEYFRAMES, 'value' : '-webkit-keyframes'},
    const {'type': TokenKind.DIRECTIVE_FONTFACE, 'value' : 'font-face'},
  ];

  static final List<Map<int, String>> _UNITS = const [
    const {'unit': TokenKind.UNIT_EM, 'value' : 'em'},
    const {'unit': TokenKind.UNIT_EX, 'value' : 'ex'},
    const {'unit': TokenKind.UNIT_LENGTH_PX, 'value' : 'px'},
    const {'unit': TokenKind.UNIT_LENGTH_CM, 'value' : 'cm'},
    const {'unit': TokenKind.UNIT_LENGTH_MM, 'value' : 'mm'},
    const {'unit': TokenKind.UNIT_LENGTH_IN, 'value' : 'in'},
    const {'unit': TokenKind.UNIT_LENGTH_PT, 'value' : 'pt'},
    const {'unit': TokenKind.UNIT_LENGTH_PC, 'value' : 'pc'},
    const {'unit': TokenKind.UNIT_ANGLE_DEG, 'value' : 'deg'},
    const {'unit': TokenKind.UNIT_ANGLE_RAD, 'value' : 'rad'},
    const {'unit': TokenKind.UNIT_ANGLE_GRAD, 'value' : 'grad'},
    const {'unit': TokenKind.UNIT_TIME_MS, 'value' : 'ms'},
    const {'unit': TokenKind.UNIT_TIME_S, 'value' : 's'},
    const {'unit': TokenKind.UNIT_FREQ_HZ, 'value' : 'hz'},
    const {'unit': TokenKind.UNIT_FREQ_KHZ, 'value' : 'khz'},
    const {'unit': TokenKind.UNIT_FRACTION, 'value' : 'fr'},
  ];

  // Some more constants:
  static final int ASCII_UPPER_A = 65;    // ASCII value for uppercase A
  static final int ASCII_UPPER_Z = 90;    // ASCII value for uppercase Z

  // Extended color keywords:
  static final List<Map<String, int>> _EXTENDED_COLOR_NAMES = const [
    const {'name' : 'aliceblue', 'value' : 0xF08FF},
    const {'name' : 'antiquewhite', 'value' : 0xFAEBD7},
    const {'name' : 'aqua', 'value' : 0x00FFFF},
    const {'name' : 'aquamarine', 'value' : 0x7FFFD4},
    const {'name' : 'azure', 'value' : 0xF0FFFF},
    const {'name' : 'beige', 'value' : 0xF5F5DC},
    const {'name' : 'bisque', 'value' : 0xFFE4C4},
    const {'name' : 'black', 'value' : 0x000000},
    const {'name' : 'blanchedalmond', 'value' : 0xFFEBCD},
    const {'name' : 'blue', 'value' : 0x0000FF},
    const {'name' : 'blueviolet', 'value' : 0x8A2BE2},
    const {'name' : 'brown', 'value' : 0xA52A2A},
    const {'name' : 'burlywood', 'value' : 0xDEB887},
    const {'name' : 'cadetblue', 'value' : 0x5F9EA0},
    const {'name' : 'chartreuse', 'value' : 0x7FFF00},
    const {'name' : 'chocolate', 'value' : 0xD2691E},
    const {'name' : 'coral', 'value' : 0xFF7F50},
    const {'name' : 'cornflowerblue', 'value' : 0x6495ED},
    const {'name' : 'cornsilk', 'value' : 0xFFF8DC},
    const {'name' : 'crimson', 'value' : 0xDC143C},
    const {'name' : 'cyan', 'value' : 0x00FFFF},
    const {'name' : 'darkblue', 'value' : 0x00008B},
    const {'name' : 'darkcyan', 'value' : 0x008B8B},
    const {'name' : 'darkgoldenrod', 'value' : 0xB8860B},
    const {'name' : 'darkgray', 'value' : 0xA9A9A9},
    const {'name' : 'darkgreen', 'value' : 0x006400},
    const {'name' : 'darkgrey', 'value' : 0xA9A9A9},
    const {'name' : 'darkkhaki', 'value' : 0xBDB76B},
    const {'name' : 'darkmagenta', 'value' : 0x8B008B},
    const {'name' : 'darkolivegreen', 'value' : 0x556B2F},
    const {'name' : 'darkorange', 'value' : 0xFF8C00},
    const {'name' : 'darkorchid', 'value' : 0x9932CC},
    const {'name' : 'darkred', 'value' : 0x8B0000},
    const {'name' : 'darksalmon', 'value' : 0xE9967A},
    const {'name' : 'darkseagreen', 'value' : 0x8FBC8F},
    const {'name' : 'darkslateblue', 'value' : 0x483D8B},
    const {'name' : 'darkslategray', 'value' : 0x2F4F4F},
    const {'name' : 'darkslategrey', 'value' : 0x2F4F4F},
    const {'name' : 'darkturquoise', 'value' : 0x00CED1},
    const {'name' : 'darkviolet', 'value' : 0x9400D3},
    const {'name' : 'deeppink', 'value' : 0xFF1493},
    const {'name' : 'deepskyblue', 'value' : 0x00BFFF},
    const {'name' : 'dimgray', 'value' : 0x696969},
    const {'name' : 'dimgrey', 'value' : 0x696969},
    const {'name' : 'dodgerblue', 'value' : 0x1E90FF},
    const {'name' : 'firebrick', 'value' : 0xB22222},
    const {'name' : 'floralwhite', 'value' : 0xFFFAF0},
    const {'name' : 'forestgreen', 'value' : 0x228B22},
    const {'name' : 'fuchsia', 'value' : 0xFF00FF},
    const {'name' : 'gainsboro', 'value' : 0xDCDCDC},
    const {'name' : 'ghostwhite', 'value' : 0xF8F8FF},
    const {'name' : 'gold', 'value' : 0xFFD700},
    const {'name' : 'goldenrod', 'value' : 0xDAA520},
    const {'name' : 'gray', 'value' : 0x808080},
    const {'name' : 'green', 'value' : 0x008000},
    const {'name' : 'greenyellow', 'value' : 0xADFF2F},
    const {'name' : 'grey', 'value' : 0x808080},
    const {'name' : 'honeydew', 'value' : 0xF0FFF0},
    const {'name' : 'hotpink', 'value' : 0xFF69B4},
    const {'name' : 'indianred', 'value' : 0xCD5C5C},
    const {'name' : 'indigo', 'value' : 0x4B0082},
    const {'name' : 'ivory', 'value' : 0xFFFFF0},
    const {'name' : 'khaki', 'value' : 0xF0E68C},
    const {'name' : 'lavender', 'value' : 0xE6E6FA},
    const {'name' : 'lavenderblush', 'value' : 0xFFF0F5},
    const {'name' : 'lawngreen', 'value' : 0x7CFC00},
    const {'name' : 'lemonchiffon', 'value' : 0xFFFACD},
    const {'name' : 'lightblue', 'value' : 0xADD8E6},
    const {'name' : 'lightcoral', 'value' : 0xF08080},
    const {'name' : 'lightcyan', 'value' : 0xE0FFFF},
    const {'name' : 'lightgoldenrodyellow', 'value' : 0xFAFAD2},
    const {'name' : 'lightgray', 'value' : 0xD3D3D3},
    const {'name' : 'lightgreen', 'value' : 0x90EE90},
    const {'name' : 'lightgrey', 'value' : 0xD3D3D3},
    const {'name' : 'lightpink', 'value' : 0xFFB6C1},
    const {'name' : 'lightsalmon', 'value' : 0xFFA07A},
    const {'name' : 'lightseagreen', 'value' : 0x20B2AA},
    const {'name' : 'lightskyblue', 'value' : 0x87CEFA},
    const {'name' : 'lightslategray', 'value' : 0x778899},
    const {'name' : 'lightslategrey', 'value' : 0x778899},
    const {'name' : 'lightsteelblue', 'value' : 0xB0C4DE},
    const {'name' : 'lightyellow', 'value' : 0xFFFFE0},
    const {'name' : 'lime', 'value' : 0x00FF00},
    const {'name' : 'limegreen', 'value' : 0x32CD32},
    const {'name' : 'linen', 'value' : 0xFAF0E6},
    const {'name' : 'magenta', 'value' : 0xFF00FF},
    const {'name' : 'maroon', 'value' : 0x800000},
    const {'name' : 'mediumaquamarine', 'value' : 0x66CDAA},
    const {'name' : 'mediumblue', 'value' : 0x0000CD},
    const {'name' : 'mediumorchid', 'value' : 0xBA55D3},
    const {'name' : 'mediumpurple', 'value' : 0x9370DB},
    const {'name' : 'mediumseagreen', 'value' : 0x3CB371},
    const {'name' : 'mediumslateblue', 'value' : 0x7B68EE},
    const {'name' : 'mediumspringgreen', 'value' : 0x00FA9A},
    const {'name' : 'mediumturquoise', 'value' : 0x48D1CC},
    const {'name' : 'mediumvioletred', 'value' : 0xC71585},
    const {'name' : 'midnightblue', 'value' : 0x191970},
    const {'name' : 'mintcream', 'value' : 0xF5FFFA},
    const {'name' : 'mistyrose', 'value' : 0xFFE4E1},
    const {'name' : 'moccasin', 'value' : 0xFFE4B5},
    const {'name' : 'navajowhite', 'value' : 0xFFDEAD},
    const {'name' : 'navy', 'value' : 0x000080},
    const {'name' : 'oldlace', 'value' : 0xFDF5E6},
    const {'name' : 'olive', 'value' : 0x808000},
    const {'name' : 'olivedrab', 'value' : 0x6B8E23},
    const {'name' : 'orange', 'value' : 0xFFA500},
    const {'name' : 'orangered', 'value' : 0xFF4500},
    const {'name' : 'orchid', 'value' : 0xDA70D6},
    const {'name' : 'palegoldenrod', 'value' : 0xEEE8AA},
    const {'name' : 'palegreen', 'value' : 0x98FB98},
    const {'name' : 'paleturquoise', 'value' : 0xAFEEEE},
    const {'name' : 'palevioletred', 'value' : 0xDB7093},
    const {'name' : 'papayawhip', 'value' : 0xFFEFD5},
    const {'name' : 'peachpuff', 'value' : 0xFFDAB9},
    const {'name' : 'peru', 'value' : 0xCD853F},
    const {'name' : 'pink', 'value' : 0xFFC0CB},
    const {'name' : 'plum', 'value' : 0xDDA0DD},
    const {'name' : 'powderblue', 'value' : 0xB0E0E6},
    const {'name' : 'purple', 'value' : 0x800080},
    const {'name' : 'red', 'value' : 0xFF0000},
    const {'name' : 'rosybrown', 'value' : 0xBC8F8F},
    const {'name' : 'royalblue', 'value' : 0x4169E1},
    const {'name' : 'saddlebrown', 'value' : 0x8B4513},
    const {'name' : 'salmon', 'value' : 0xFA8072},
    const {'name' : 'sandybrown', 'value' : 0xF4A460},
    const {'name' : 'seagreen', 'value' : 0x2E8B57},
    const {'name' : 'seashell', 'value' : 0xFFF5EE},
    const {'name' : 'sienna', 'value' : 0xA0522D},
    const {'name' : 'silver', 'value' : 0xC0C0C0},
    const {'name' : 'skyblue', 'value' : 0x87CEEB},
    const {'name' : 'slateblue', 'value' : 0x6A5ACD},
    const {'name' : 'slategray', 'value' : 0x708090},
    const {'name' : 'slategrey', 'value' : 0x708090},
    const {'name' : 'snow', 'value' : 0xFFFAFA},
    const {'name' : 'springgreen', 'value' : 0x00FF7F},
    const {'name' : 'steelblue', 'value' : 0x4682B4},
    const {'name' : 'tan', 'value' : 0xD2B48C},
    const {'name' : 'teal', 'value' : 0x008080},
    const {'name' : 'thistle', 'value' : 0xD8BFD8},
    const {'name' : 'tomato', 'value' : 0xFF6347},
    const {'name' : 'turquoise', 'value' : 0x40E0D0},
    const {'name' : 'violet', 'value' : 0xEE82EE},
    const {'name' : 'wheat', 'value' : 0xF5DEB3},
    const {'name' : 'white', 'value' : 0xFFFFFF},
    const {'name' : 'whitesmoke', 'value' : 0xF5F5F5},
    const {'name' : 'yellow', 'value' : 0xFFFF00},
    const {'name' : 'yellowgreen', 'value' : 0x9ACD32},
  ];

  // TODO(terry): Should used Dart mirroring for parameter values and types
  //              especially for enumeration (e.g., counter's second parameter
  //              is list-style-type which is an enumerated list for ordering
  //              of a list 'circle', 'decimal', 'lower-roman', 'square', etc.
  //              see http://www.w3schools.com/cssref/pr_list-style-type.asp
  //              for list of possible values.

  // List of valid CSS functions:
  static final List<Map<String, Object>> _FUNCTIONS = const [
    const {'name' : 'counter', 'info' : const {'params' : 2, 'expr' : false}},
    const {'name' : 'attr', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'calc', 'info' : const {'params' : 1, 'expr' : true}},
    const {'name' : 'min', 'info' : const {'params' : 2, 'expr' : true}},
    const {'name' : 'max', 'info' : const {'params' : 2, 'expr' : true}},

    // 2D functions:
    const {'name' : 'translateX',
        'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'translateY',
        'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'translate', 'info' : const {'params' : 2, 'expr' : false}},
    const {'name' : 'rotate', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'scaleX', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'scaleY', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'scale', 'info' : const {'params' : 2, 'expr' : false}},
    const {'name' : 'skewX', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'skewY', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'skew', 'info' : const {'params' : 2, 'expr' : false}},
    const {'name' : 'matrix', 'info' : const {'params' : 6, 'expr' : false}},

    // 3D functions:
    const {'name' : 'matrix3d', 'info' : const {'params' : 16, 'expr' : false}},
    const {'name' : 'translate3d',
        'info' : const {'params' : 3, 'expr' : false}},
    const {'name' : 'translateZ',
        'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'scale3d', 'info' : const {'params' : 3, 'expr' : false}},
    const {'name' : 'scaleZ', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'rotate3d', 'info' : const {'params' : 3, 'expr' : false}},
    const {'name' : 'rotateX', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'rotateY', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'rotateZ', 'info' : const {'params' : 1, 'expr' : false}},
    const {'name' : 'perspective',
        'info' : const {'params' : 1, 'expr' : false}},
  ];

  List<int> tokens;

  /*
   * Return the token that matches the unit ident found.
   */
  static int matchList(var identList, String tokenField, String text,
                       int offset, int length) {
    for (final entry in identList) {
      String ident = entry['value'];
      if (length == ident.length) {
        int idx = offset;
        bool match = true;
        for (int identIdx = 0; identIdx < ident.length; identIdx++) {
          int identChar = ident.charCodeAt(identIdx);
          int char = text.charCodeAt(idx++);
          // Compare lowercase to lowercase then check if char is uppercase.
          match = match && (char == identChar ||
              ((char >= ASCII_UPPER_A && char <= ASCII_UPPER_Z) &&
               (char + 32) == identChar));
          if (!match) {
            break;
          }
        }

        if (match) {
          // Completely matched; return the token for this unit.
          return entry[tokenField];
        }
      }
    }

    return -1;  // Not a unit token.
  }

  /*
   * Return the token that matches the unit ident found.
   */
  static int matchUnits(String text, int offset, int length) {
    return matchList(_UNITS, 'unit', text, offset, length);
  }

  /*
   * Return the token that matches the directive ident found.
   */
  static int matchDirectives(String text, int offset, int length) {
    return matchList(_DIRECTIVES, 'type', text, offset, length);
  }

  /*
   * Return the unit token as its pretty name.
   */
  static String unitToString(int unitTokenToFind) {
    if (unitTokenToFind == TokenKind.PERCENT) {
      return '%';
    } else {
      for (final entry in _UNITS) {
        int unit = entry['unit'];
        if (unit == unitTokenToFind) {
          return entry['value'];
        }
      }
    }

    return '<BAD UNIT>';  // Not a unit token.
  }

  /*
   * Match color name, case insensitive match and return the associated RGB
   * value as decimal number.
   */
  static int matchColorName(String text) {
    int length = text.length;
    for (final entry in _EXTENDED_COLOR_NAMES) {
      String ident = entry['name'];
      if (length == ident.length) {
        int idx = 0;
        bool match = true;
        for (int identIdx = 0; identIdx < ident.length; identIdx++) {
          int identChar = ident.charCodeAt(identIdx);
          int char = text.charCodeAt(idx++);
          // Compare lowercase to lowercase then check if char is uppercase.
          match = match && (char == identChar ||
              ((char >= ASCII_UPPER_A && char <= ASCII_UPPER_Z) &&
               (char + 32) == identChar));
          if (!match) {
            break;
          }
        }

        if (match) {
          // Completely matched; return the token for this unit.
          return entry['value'];
        }
      }
    }

    // No match.
    throw new NoColorMatchException(text);
  }

  static String decimalToHex(int num, [int minDigits = 1]) {
    final String _HEX_DIGITS = '0123456789abcdef';

    List<String> result = new List<String>();

    int dividend = num >> 4;
    int remain = num % 16;
    result.add(_HEX_DIGITS[remain]);
    while (dividend != 0) {
      remain = dividend % 16;
      dividend >>= 4;
      result.add(_HEX_DIGITS[remain]);
    }

    StringBuffer invertResult = new StringBuffer();
    int paddings = minDigits - result.length;
    while (paddings-- > 0) {
      invertResult.add('0');
    }
    for (int idx = result.length - 1; idx >= 0; idx--) {
      invertResult.add(result[idx]);
    }

    return invertResult.toString();
  }

  static String kindToString(int kind) {
    switch(kind) {
      case TokenKind.UNUSED: return "ERROR";
      case TokenKind.END_OF_FILE: return "end of file";
      case TokenKind.LPAREN: return "(";
      case TokenKind.RPAREN: return ")";
      case TokenKind.LBRACK: return "[";
      case TokenKind.RBRACK: return "]";
      case TokenKind.LBRACE: return "{";
      case TokenKind.RBRACE: return "}";
      case TokenKind.DOT: return ".";
      case TokenKind.SEMICOLON: return ";";
      case TokenKind.AT: return "@";
      case TokenKind.HASH: return "#";
      case TokenKind.PLUS: return "+";
      case TokenKind.GREATER: return ">";
      case TokenKind.TILDE: return "~";
      case TokenKind.ASTERISK: return "*";
      case TokenKind.NAMESPACE: return "|";
      case TokenKind.COLON: return ":";
      case TokenKind.PRIVATE_NAME: return "_";
      case TokenKind.COMMA: return ",";
      case TokenKind.SPACE: return " ";
      case TokenKind.TAB: return "\t";
      case TokenKind.NEWLINE: return "\n";
      case TokenKind.RETURN: return "\r";
      case TokenKind.PERCENT: return "%";
      case TokenKind.SINGLE_QUOTE: return "'";
      case TokenKind.DOUBLE_QUOTE: return "\"";
      case TokenKind.SLASH: return "/";
      case TokenKind.EQUALS: return '=';
      case TokenKind.OR: return '|';
      case TokenKind.CARET: return '^';
      case TokenKind.DOLLAR: return '\$';
      case TokenKind.LESS: return '<';
      case TokenKind.BANG: return '!';
      case TokenKind.MINUS: return '-';

      default:
        throw "Unknown TOKEN";
    }
  }

  TokenKind() {
    tokens = [];

    // All tokens must be in TokenKind order.
    tokens.add(-1);                 // TokenKind.UNUSED
    tokens.add(0);                  // TokenKind.END_OF_FILE match base
    tokens.add(TokenKind.kindToString(TokenKind.LPAREN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RPAREN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.LBRACK).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RBRACK).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.LBRACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RBRACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.DOT).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.SEMICOLON).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.AT).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.HASH).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.PLUS).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.GREATER).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.TILDE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.ASTERISK).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.NAMESPACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.COLON).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.PRIVATE_NAME).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.COMMA).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.SPACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.TAB).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.NEWLINE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RETURN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.PERCENT).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.SINGLE_QUOTE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.DOUBLE_QUOTE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.SLASH).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.EQUALS).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.OR).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.CARET).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.DOLLAR).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.LESS).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.BANG).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.MINUS).charCodeAt(0));

    assert(tokens.length == TokenKind.END_TOKENS);
  }

  static bool isIdentifier(int kind) {
    return kind == IDENTIFIER ;
  }

}

class NoColorMatchException implements Exception {
  String _colorName;
  NoColorMatchException(this._colorName);

  String get name() => _colorName;
}
