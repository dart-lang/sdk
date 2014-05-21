// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of csslib.parser;

// TODO(terry): Need to be consistent with tokens either they're ASCII tokens
//              e.g., ASTERISK or they're CSS e.g., PSEUDO, COMBINATOR_*.
class TokenKind {
  // Common shared tokens used in TokenizerBase.
  static const int UNUSED = 0;                  // Unused place holder...
  static const int END_OF_FILE = 1;             // EOF
  static const int LPAREN = 2;                  // (
  static const int RPAREN = 3;                  // )
  static const int LBRACK = 4;                  // [
  static const int RBRACK = 5;                  // ]
  static const int LBRACE = 6;                  // {
  static const int RBRACE = 7;                  // }
  static const int DOT = 8;                     // .
  static const int SEMICOLON = 9;               // ;

  // Unique tokens for CSS.
  static const int AT = 10;                     // @
  static const int HASH = 11;                   // #
  static const int PLUS = 12;                   // +
  static const int GREATER = 13;                // >
  static const int TILDE = 14;                  // ~
  static const int ASTERISK = 15;               // *
  static const int NAMESPACE = 16;              // |
  static const int COLON = 17;                  // :
  static const int PRIVATE_NAME = 18;           // _ prefix private class or id
  static const int COMMA = 19;                  // ,
  static const int SPACE = 20;
  static const int TAB = 21;                    // /t
  static const int NEWLINE = 22;                // /n
  static const int RETURN = 23;                 // /r
  static const int PERCENT = 24;                // %
  static const int SINGLE_QUOTE = 25;           // '
  static const int DOUBLE_QUOTE = 26;           // "
  static const int SLASH = 27;                  // /
  static const int EQUALS = 28;                 // =
  static const int CARET = 30;                  // ^
  static const int DOLLAR = 31;                 // $
  static const int LESS = 32;                   // <
  static const int BANG = 33;                   // !
  static const int MINUS = 34;                  // -
  static const int BACKSLASH = 35;              // \
  static const int AMPERSAND = 36;              // &

  // WARNING: Tokens from this point and above must have the corresponding ASCII
  //          character in the TokenChar list at the bottom of this file.  The
  //          order of the above tokens should be the same order as TokenChar.

  /** [TokenKind] representing integer tokens. */
  static const int INTEGER = 60;

  /** [TokenKind] representing hex integer tokens. */
  static const int HEX_INTEGER = 61;

  /** [TokenKind] representing double tokens. */
  static const int DOUBLE = 62;

  /** [TokenKind] representing whitespace tokens. */
  static const int WHITESPACE = 63;

  /** [TokenKind] representing comment tokens. */
  static const int COMMENT = 64;

  /** [TokenKind] representing error tokens. */
  static const int ERROR = 65;

  /** [TokenKind] representing incomplete string tokens. */
  static const int INCOMPLETE_STRING = 66;

  /** [TokenKind] representing incomplete comment tokens. */
  static const int INCOMPLETE_COMMENT = 67;

  static const int VAR_DEFINITION = 400;        // var-NNN-NNN
  static const int VAR_USAGE = 401;             // var(NNN-NNN [,default])

  // Synthesized Tokens (no character associated with TOKEN).
  static const int STRING = 500;
  static const int STRING_PART = 501;
  static const int NUMBER = 502;
  static const int HEX_NUMBER = 503;
  static const int HTML_COMMENT = 504;          // <!--
  static const int IMPORTANT = 505;             // !important
  static const int CDATA_START = 506;           // <![CDATA[
  static const int CDATA_END = 507;             // ]]>
  // U+uNumber[-U+uNumber]
  // uNumber = 0..10FFFF | ?[?]*
  static const int UNICODE_RANGE = 508;
  static const int HEX_RANGE = 509;             // ? in the hex range
  static const int IDENTIFIER = 511;

  // Uniquely synthesized tokens for CSS.
  static const int SELECTOR_EXPRESSION = 512;
  static const int COMBINATOR_NONE = 513;
  static const int COMBINATOR_DESCENDANT = 514; // Space combinator
  static const int COMBINATOR_PLUS = 515;       // + combinator
  static const int COMBINATOR_GREATER = 516;    // > combinator
  static const int COMBINATOR_TILDE = 517;      // ~ combinator

  static const int UNARY_OP_NONE = 518;         // No unary operator present.

  // Attribute match types:
  static const int INCLUDES = 530;              // '~='
  static const int DASH_MATCH = 531;            // '|='
  static const int PREFIX_MATCH = 532;          // '^='
  static const int SUFFIX_MATCH = 533;          // '$='
  static const int SUBSTRING_MATCH = 534;       // '*='
  static const int NO_MATCH = 535;              // No operator.

  // Unit types:
  static const int UNIT_EM = 600;
  static const int UNIT_EX = 601;
  static const int UNIT_LENGTH_PX = 602;
  static const int UNIT_LENGTH_CM = 603;
  static const int UNIT_LENGTH_MM = 604;
  static const int UNIT_LENGTH_IN = 605;
  static const int UNIT_LENGTH_PT = 606;
  static const int UNIT_LENGTH_PC = 607;
  static const int UNIT_ANGLE_DEG = 608;
  static const int UNIT_ANGLE_RAD = 609;
  static const int UNIT_ANGLE_GRAD = 610;
  static const int UNIT_ANGLE_TURN = 611;
  static const int UNIT_TIME_MS = 612;
  static const int UNIT_TIME_S = 613;
  static const int UNIT_FREQ_HZ = 614;
  static const int UNIT_FREQ_KHZ = 615;
  static const int UNIT_PERCENT = 616;
  static const int UNIT_FRACTION = 617;
  static const int UNIT_RESOLUTION_DPI = 618;
  static const int UNIT_RESOLUTION_DPCM = 619;
  static const int UNIT_RESOLUTION_DPPX = 620;
  static const int UNIT_CH = 621;   // Measure of "0" U+0030 glyph.
  static const int UNIT_REM = 622;  // computed value ‘font-size’ on root elem.
  static const int UNIT_VIEWPORT_VW = 623;
  static const int UNIT_VIEWPORT_VH = 624;
  static const int UNIT_VIEWPORT_VMIN = 625;
  static const int UNIT_VIEWPORT_VMAX = 626;

  // Directives (@nnnn)
  static const int DIRECTIVE_NONE = 640;
  static const int DIRECTIVE_IMPORT = 641;
  static const int DIRECTIVE_MEDIA = 642;
  static const int DIRECTIVE_PAGE = 643;
  static const int DIRECTIVE_CHARSET = 644;
  static const int DIRECTIVE_STYLET = 645;
  static const int DIRECTIVE_KEYFRAMES = 646;
  static const int DIRECTIVE_WEB_KIT_KEYFRAMES = 647;
  static const int DIRECTIVE_MOZ_KEYFRAMES = 648;
  static const int DIRECTIVE_MS_KEYFRAMES = 649;
  static const int DIRECTIVE_O_KEYFRAMES = 650;
  static const int DIRECTIVE_FONTFACE = 651;
  static const int DIRECTIVE_NAMESPACE = 652;
  static const int DIRECTIVE_HOST = 653;
  static const int DIRECTIVE_MIXIN = 654;
  static const int DIRECTIVE_INCLUDE = 655;
  static const int DIRECTIVE_CONTENT = 656;
  static const int DIRECTIVE_EXTEND = 657;

  // Media query operators
  static const int MEDIA_OP_ONLY = 665;     // Unary.
  static const int MEDIA_OP_NOT = 666;      // Unary.
  static const int MEDIA_OP_AND = 667;      // Binary.

  // Directives inside of a @page (margin sym).
  static const int MARGIN_DIRECTIVE_TOPLEFTCORNER = 670;
  static const int MARGIN_DIRECTIVE_TOPLEFT = 671;
  static const int MARGIN_DIRECTIVE_TOPCENTER = 672;
  static const int MARGIN_DIRECTIVE_TOPRIGHT = 673;
  static const int MARGIN_DIRECTIVE_TOPRIGHTCORNER = 674;
  static const int MARGIN_DIRECTIVE_BOTTOMLEFTCORNER = 675;
  static const int MARGIN_DIRECTIVE_BOTTOMLEFT = 676;
  static const int MARGIN_DIRECTIVE_BOTTOMCENTER = 677;
  static const int MARGIN_DIRECTIVE_BOTTOMRIGHT = 678;
  static const int MARGIN_DIRECTIVE_BOTTOMRIGHTCORNER = 679;
  static const int MARGIN_DIRECTIVE_LEFTTOP = 680;
  static const int MARGIN_DIRECTIVE_LEFTMIDDLE = 681;
  static const int MARGIN_DIRECTIVE_LEFTBOTTOM = 682;
  static const int MARGIN_DIRECTIVE_RIGHTTOP = 683;
  static const int MARGIN_DIRECTIVE_RIGHTMIDDLE = 684;
  static const int MARGIN_DIRECTIVE_RIGHTBOTTOM = 685;

  // Simple selector type.
  static const int CLASS_NAME = 700;            // .class
  static const int ELEMENT_NAME = 701;          // tagName
  static const int HASH_NAME = 702;             // #elementId
  static const int ATTRIBUTE_NAME = 703;        // [attrib]
  static const int PSEUDO_ELEMENT_NAME = 704;   // ::pseudoElement
  static const int PSEUDO_CLASS_NAME = 705;     // :pseudoClass
  static const int NEGATION = 706;              // NOT

  static const List<Map<int, String>> _DIRECTIVES = const [
    const {'type': TokenKind.DIRECTIVE_IMPORT, 'value' : 'import'},
    const {'type': TokenKind.DIRECTIVE_MEDIA, 'value' : 'media'},
    const {'type': TokenKind.DIRECTIVE_PAGE, 'value' : 'page'},
    const {'type': TokenKind.DIRECTIVE_CHARSET, 'value' : 'charset'},
    const {'type': TokenKind.DIRECTIVE_STYLET, 'value' : 'stylet'},
    const {'type': TokenKind.DIRECTIVE_KEYFRAMES, 'value' : 'keyframes'},
    const {'type': TokenKind.DIRECTIVE_WEB_KIT_KEYFRAMES,
        'value' : '-webkit-keyframes'},
    const {'type': TokenKind.DIRECTIVE_MOZ_KEYFRAMES,
          'value' : '-moz-keyframes'},
    const {'type': TokenKind.DIRECTIVE_MS_KEYFRAMES, 'value' : '-ms-keyframes'},
    const {'type': TokenKind.DIRECTIVE_O_KEYFRAMES, 'value' : '-o-keyframes'},
    const {'type': TokenKind.DIRECTIVE_FONTFACE, 'value' : 'font-face'},
    const {'type': TokenKind.DIRECTIVE_NAMESPACE, 'value' : 'namespace'},
    const {'type': TokenKind.DIRECTIVE_HOST, 'value' : 'host'},
    const {'type': TokenKind.DIRECTIVE_MIXIN, 'value' : 'mixin'},
    const {'type': TokenKind.DIRECTIVE_INCLUDE, 'value' : 'include'},
    const {'type': TokenKind.DIRECTIVE_CONTENT, 'value' : 'content'},
    const {'type': TokenKind.DIRECTIVE_EXTEND, 'value' : 'extend'},
  ];

  static const List<Map<int, String>> MEDIA_OPERATORS = const [
    const {'type': TokenKind.MEDIA_OP_ONLY, 'value' : 'only'},
    const {'type': TokenKind.MEDIA_OP_NOT, 'value' : 'not'},
    const {'type': TokenKind.MEDIA_OP_AND, 'value' : 'and'},
];

  static const List<Map<int, String>> MARGIN_DIRECTIVES = const [
    const {'type': TokenKind.MARGIN_DIRECTIVE_TOPLEFTCORNER,
        'value' : 'top-left-corner'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_TOPLEFT,
        'value' : 'top-left'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_TOPCENTER,
        'value' : 'top-center'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_TOPRIGHT,
        'value' : 'top-right'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_TOPRIGHTCORNER,
        'value' : 'top-right-corner'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMLEFTCORNER,
        'value' : 'bottom-left-corner'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMLEFT,
        'value' : 'bottom-left'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMCENTER,
        'value' : 'bottom-center'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMRIGHT,
        'value' : 'bottom-right'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMRIGHTCORNER,
        'value' : 'bottom-right-corner'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_LEFTTOP,
        'value' : 'left-top'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_LEFTMIDDLE,
        'value' : 'left-middle'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_LEFTBOTTOM,
        'value' : 'right-bottom'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_RIGHTTOP,
        'value' : 'right-top'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_RIGHTMIDDLE,
        'value' : 'right-middle'},
    const {'type': TokenKind.MARGIN_DIRECTIVE_RIGHTBOTTOM,
        'value' : 'right-bottom'},
  ];

  static const List<Map> _UNITS = const [
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
    const {'unit': TokenKind.UNIT_ANGLE_TURN, 'value' : 'turn'},
    const {'unit': TokenKind.UNIT_TIME_MS, 'value' : 'ms'},
    const {'unit': TokenKind.UNIT_TIME_S, 'value' : 's'},
    const {'unit': TokenKind.UNIT_FREQ_HZ, 'value' : 'hz'},
    const {'unit': TokenKind.UNIT_FREQ_KHZ, 'value' : 'khz'},
    const {'unit': TokenKind.UNIT_FRACTION, 'value' : 'fr'},
    const {'unit': TokenKind.UNIT_RESOLUTION_DPI, 'value' : 'dpi'},
    const {'unit': TokenKind.UNIT_RESOLUTION_DPCM, 'value' : 'dpcm'},
    const {'unit': TokenKind.UNIT_RESOLUTION_DPPX, 'value' : 'dppx'},
    const {'unit': TokenKind.UNIT_CH, 'value' : 'ch'},
    const {'unit': TokenKind.UNIT_REM, 'value' : 'rem'},
    const {'unit': TokenKind.UNIT_VIEWPORT_VW, 'value' : 'vw'},
    const {'unit': TokenKind.UNIT_VIEWPORT_VH, 'value' : 'vh'},
    const {'unit': TokenKind.UNIT_VIEWPORT_VMIN, 'value' : 'vmin'},
    const {'unit': TokenKind.UNIT_VIEWPORT_VMAX, 'value' : 'vmax'},
    ];

  // Some more constants:
  static const int ASCII_UPPER_A = 65;    // ASCII value for uppercase A
  static const int ASCII_UPPER_Z = 90;    // ASCII value for uppercase Z

  // Extended color keywords:
  static const List<Map> _EXTENDED_COLOR_NAMES = const [
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
  static const List<Map<String, Object>> _FUNCTIONS = const [
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

  /**
   * Check if name is a pre-defined CSS name.  Used by error handler to report
   * if name is unknown or used improperly.
   */
  static bool isPredefinedName(String name) {
    var nameLen = name.length;
    // TODO(terry): Add more pre-defined names (hidden, bolder, inherit, etc.).
    if (matchUnits(name, 0, nameLen) == -1 ||
        matchDirectives(name, 0, nameLen) == -1 ||
        matchMarginDirectives(name, 0, nameLen) == -1 ||
        matchColorName(name) == null) {
      return false;
    }

    return true;
  }

  /** Return the token that matches the unit ident found. */
  static int matchList(var identList, String tokenField, String text,
                       int offset, int length) {
    for (final entry in identList) {
      String ident = entry['value'];

      if (length == ident.length) {
        int idx = offset;
        bool match = true;
        for (int i = 0; i < ident.length; i++) {
          int identChar = ident.codeUnitAt(i);
          int char = text.codeUnitAt(idx++);
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

  /** Return the token that matches the unit ident found. */
  static int matchUnits(String text, int offset, int length) {
    return matchList(_UNITS, 'unit', text, offset, length);
  }

  /** Return the token that matches the directive name found. */
  static int matchDirectives(String text, int offset, int length) {
    return matchList(_DIRECTIVES, 'type', text, offset, length);
  }

  /** Return the token that matches the margin directive name found. */
  static int matchMarginDirectives(String text, int offset, int length) {
    return matchList(MARGIN_DIRECTIVES, 'type', text, offset, length);
  }

  /** Return the token that matches the media operator found. */
  static int matchMediaOperator(String text, int offset, int length) {
    return matchList(MEDIA_OPERATORS, 'type', text, offset, length);
  }

  static String idToValue(var identList, int tokenId) {
    for (var entry in identList) {
      if (tokenId == entry['type']) {
        return entry['value'];
      }
    }

    return null;
  }


  /** Return the unit token as its pretty name. */
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

  /**
   * Match color name, case insensitive match and return the associated color
   * entry from _EXTENDED_COLOR_NAMES list, return [:null:] if not found.
   */
  static Map matchColorName(String text) {
    var name = text.toLowerCase();
    return _EXTENDED_COLOR_NAMES.
        firstWhere((e) => e['name'] == name, orElse: () => null);
  }

  /** Return RGB value as [int] from a color entry in _EXTENDED_COLOR_NAMES. */
  static int colorValue(Map entry) {
    assert(entry != null);
    return entry['value'];
  }

  static String hexToColorName(hexValue) {
    for (final entry in _EXTENDED_COLOR_NAMES) {
      if (entry['value'] == hexValue) {
        return entry['name'];
      }
    }

    return null;
  }

  static String decimalToHex(int number, [int minDigits = 1]) {
    final String _HEX_DIGITS = '0123456789abcdef';

    List<String> result = new List<String>();

    int dividend = number >> 4;
    int remain = number % 16;
    result.add(_HEX_DIGITS[remain]);
    while (dividend != 0) {
      remain = dividend % 16;
      dividend >>= 4;
      result.add(_HEX_DIGITS[remain]);
    }

    StringBuffer invertResult = new StringBuffer();
    int paddings = minDigits - result.length;
    while (paddings-- > 0) {
      invertResult.write('0');
    }
    for (int i = result.length - 1; i >= 0; i--) {
      invertResult.write(result[i]);
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
      case TokenKind.CARET: return '^';
      case TokenKind.DOLLAR: return '\$';
      case TokenKind.LESS: return '<';
      case TokenKind.BANG: return '!';
      case TokenKind.MINUS: return '-';
      case TokenKind.BACKSLASH: return '\\';
      default:
        throw "Unknown TOKEN";
    }
  }

  static bool isKindIdentifier(int kind) {
    switch(kind) {
      // Synthesized tokens.
      case TokenKind.DIRECTIVE_IMPORT:
      case TokenKind.DIRECTIVE_MEDIA:
      case TokenKind.DIRECTIVE_PAGE:
      case TokenKind.DIRECTIVE_CHARSET:
      case TokenKind.DIRECTIVE_STYLET:
      case TokenKind.DIRECTIVE_KEYFRAMES:
      case TokenKind.DIRECTIVE_WEB_KIT_KEYFRAMES:
      case TokenKind.DIRECTIVE_MOZ_KEYFRAMES:
      case TokenKind.DIRECTIVE_MS_KEYFRAMES:
      case TokenKind.DIRECTIVE_O_KEYFRAMES:
      case TokenKind.DIRECTIVE_FONTFACE:
      case TokenKind.DIRECTIVE_NAMESPACE:
      case TokenKind.DIRECTIVE_HOST:
      case TokenKind.DIRECTIVE_MIXIN:
      case TokenKind.DIRECTIVE_INCLUDE:
      case TokenKind.DIRECTIVE_CONTENT:
      case TokenKind.UNIT_EM:
      case TokenKind.UNIT_EX:
      case TokenKind.UNIT_LENGTH_PX:
      case TokenKind.UNIT_LENGTH_CM:
      case TokenKind.UNIT_LENGTH_MM:
      case TokenKind.UNIT_LENGTH_IN:
      case TokenKind.UNIT_LENGTH_PT:
      case TokenKind.UNIT_LENGTH_PC:
      case TokenKind.UNIT_ANGLE_DEG:
      case TokenKind.UNIT_ANGLE_RAD:
      case TokenKind.UNIT_ANGLE_GRAD:
      case TokenKind.UNIT_TIME_MS:
      case TokenKind.UNIT_TIME_S:
      case TokenKind.UNIT_FREQ_HZ:
      case TokenKind.UNIT_FREQ_KHZ:
      case TokenKind.UNIT_FRACTION:
        return true;
      default:
        return false;
    }
  }

  static bool isIdentifier(int kind) {
    return kind == IDENTIFIER ;
  }
}

// Note: these names should match TokenKind names
class TokenChar {
  static const int UNUSED = -1;
  static const int END_OF_FILE = 0;
  static const int LPAREN = 0x28; // "(".codeUnitAt(0)
  static const int RPAREN = 0x29; // ")".codeUnitAt(0)
  static const int LBRACK = 0x5b; // "[".codeUnitAt(0)
  static const int RBRACK = 0x5d; // "]".codeUnitAt(0)
  static const int LBRACE = 0x7b; // "{".codeUnitAt(0)
  static const int RBRACE = 0x7d; // "}".codeUnitAt(0)
  static const int DOT = 0x2e; // ".".codeUnitAt(0)
  static const int SEMICOLON = 0x3b; // ";".codeUnitAt(0)
  static const int AT = 0x40; // "@".codeUnitAt(0)
  static const int HASH = 0x23; // "#".codeUnitAt(0)
  static const int PLUS = 0x2b; // "+".codeUnitAt(0)
  static const int GREATER = 0x3e; // ">".codeUnitAt(0)
  static const int TILDE = 0x7e; // "~".codeUnitAt(0)
  static const int ASTERISK = 0x2a; // "*".codeUnitAt(0)
  static const int NAMESPACE = 0x7c; // "|".codeUnitAt(0)
  static const int COLON = 0x3a; // ":".codeUnitAt(0)
  static const int PRIVATE_NAME = 0x5f; // "_".codeUnitAt(0)
  static const int COMMA = 0x2c; // ",".codeUnitAt(0)
  static const int SPACE = 0x20; // " ".codeUnitAt(0)
  static const int TAB = 0x9; // "\t".codeUnitAt(0)
  static const int NEWLINE = 0xa; // "\n".codeUnitAt(0)
  static const int RETURN = 0xd; // "\r".codeUnitAt(0)
  static const int BACKSPACE = 0x8; // "/b".codeUnitAt(0)
  static const int FF = 0xc; // "/f".codeUnitAt(0)
  static const int VT = 0xb; // "/v".codeUnitAt(0)
  static const int PERCENT = 0x25; // "%".codeUnitAt(0)
  static const int SINGLE_QUOTE = 0x27; // "'".codeUnitAt(0)
  static const int DOUBLE_QUOTE = 0x22; // '"'.codeUnitAt(0)
  static const int SLASH = 0x2f; // "/".codeUnitAt(0)
  static const int EQUALS = 0x3d; // "=".codeUnitAt(0)
  static const int OR = 0x7c; // "|".codeUnitAt(0)
  static const int CARET = 0x5e; // "^".codeUnitAt(0)
  static const int DOLLAR = 0x24; // "\$".codeUnitAt(0)
  static const int LESS = 0x3c; // "<".codeUnitAt(0)
  static const int BANG = 0x21; // "!".codeUnitAt(0)
  static const int MINUS = 0x2d; // "-".codeUnitAt(0)
  static const int BACKSLASH = 0x5c; // "\".codeUnitAt(0)
  static const int AMPERSAND = 0x26; // "&".codeUnitAt(0)
}
