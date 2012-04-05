// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Need to be consistent with tokens either they're ASCII tokens
//              e.g., ASTERISK or they're CSS e.g., PSEUDO, COMBINATOR_*.
class TokenKind {
  // Common shared tokens used in TokenizerBase.
  static final int UNUSED = 0;                  // Unused place holder...
  static final int END_OF_FILE = 1;
  static final int LPAREN = 2;                  // (
  static final int RPAREN = 3;                  // )
  static final int LBRACK = 4;                  // [
  static final int RBRACK = 5;                  // ]
  static final int LBRACE = 6;                  // {
  static final int RBRACE = 7;                  // }
  static final int DOT = 8;                     // .
  static final int SEMICOLON = 9;               // ;
  static final int SPACE = 10;                  // space character
  static final int TAB = 11;                    // \t
  static final int NEWLINE = 12;                // \n
  static final int RETURN = 13;                 // \r
  static final int COMMA = 14;                  // ,

  // Unique tokens.
  static final int LESS_THAN = 15;              // <
  static final int GREATER_THAN = 16;           // >
  static final int SLASH = 17;                  // /
  static final int DOLLAR = 18;                 // $
  static final int HASH = 19;                   // #
  static final int MINUS = 20;                  // -
  static final int EQUAL = 21;                  // =
  static final int DOUBLE_QUOTE = 22;           // "
  static final int SINGLE_QUOTE = 23;           // '
  static final int ASTERISK = 24;               // *

  // WARNING: END_TOKENS must be 1 greater than the last token above (last
  //          character in our list).  Also add to kindToString function and the
  //          constructor for TokenKind.

  static final int END_TOKENS = 25;             // Marker for last token in list

  // Synthesized tokens:

  static final int END_NO_SCOPE_TAG = 50;       // />
  static final int START_EXPRESSION = 51;       // ${
  static final int START_COMMAND = 52;          // ${#
  static final int END_COMMAND = 53;            // ${/
  static final int EACH_COMMAND = 53;           // ${#each list}
  static final int WITH_COMMAND = 54;           // ${#with object}
  static final int IF_COMMAND = 55;             // ${#if (expression)}
  static final int ELSE_COMMAND = 56;           // ${#else}

  /** [TokenKind] representing integer tokens. */
  static final int INTEGER = 60;                // TODO(terry): must match base

  /** [TokenKind] representing hex integer tokens. */
//  static final int HEX_INTEGER = 61;          // TODO(terry): must match base

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
  static final int ATTR_VALUE = 500;
  static final int NUMBER = 502;
  static final int HEX_NUMBER = 503;
  static final int HTML_COMMENT = 504;          // <!--
  static final int IDENTIFIER = 511;
  static final int STRING = 512;
  static final int STRING_PART = 513;

  static final int TEMPLATE_KEYWORD = 595;      // template keyword

  // Elements
  /* START_HTML_ELEMENT is first valid element tag name
   * END_HTML_ELEMENT is the last valid element tag name
   *
   */
  static final int START_HTML_ELEMENT = 600;      // First valid tag name.
  static final int A_ELEMENT = 600;
  static final int ABBR_ELEMENT = 601;
  static final int ACRONYM_ELEMENT = 602;
  static final int ADDRESS_ELEMENT = 603;
  static final int APPLET_ELEMENT = 604;
  static final int AREA_ELEMENT = 605;
  static final int B_ELEMENT = 606;
  static final int BASE_ELEMENT = 607;
  static final int BASEFONT_ELEMENT = 608;
  static final int BDO_ELEMENT = 609;
  static final int BIG_ELEMENT = 610;
  static final int BLOCKQUOTE_ELEMENT = 611;
  static final int BODY_ELEMENT = 612;
  static final int BR_ELEMENT = 613;
  static final int BUTTON_ELEMENT = 614;
  static final int CAPTION_ELEMENT = 615;
  static final int CENTER_ELEMENT = 616;
  static final int CITE_ELEMENT = 617;
  static final int CODE_ELEMENT = 618;
  static final int COL_ELEMENT = 619;
  static final int COLGROUP_ELEMENT = 620;
  static final int DD_ELEMENT = 621;
  static final int DEL_ELEMENT = 622;
  static final int DFN_ELEMENT = 623;
  static final int DIR_ELEMENT = 624;
  static final int DIV_ELEMENT = 625;
  static final int DL_ELEMENT = 626;
  static final int DT_ELEMENT = 627;
  static final int EM_ELEMENT = 628;
  static final int FIELDSET_ELEMENT = 629;
  static final int FONT_ELEMENT = 630;
  static final int FORM_ELEMENT = 631;
  static final int FRAME_ELEMENT = 632;
  static final int FRAMESET_ELEMENT = 633;
  static final int H1_ELEMENT = 634;
  static final int H2_ELEMENT = 635;
  static final int H3_ELEMENT = 636;
  static final int H4_ELEMENT = 637;
  static final int H5_ELEMENT = 638;
  static final int H6_ELEMENT = 639;
  static final int HEAD_ELEMENT = 640;
  static final int HR_ELEMENT = 641;
  static final int HTML_ELEMENT = 642;
  static final int I_ELEMENT = 643;
  static final int IFRAME_ELEMENT = 644;
  static final int IMG_ELEMENT = 645;
  static final int INPUT_ELEMENT = 646;
  static final int INS_ELEMENT = 647;
  static final int ISINDEX_ELEMENT = 648;
  static final int KBD_ELEMENT = 649;
  static final int LABEL_ELEMENT = 650;
  static final int LEGEND_ELEMENT = 651;
  static final int LI_ELEMENT = 652;
  static final int LINK_ELEMENT = 653;
  static final int MAP_ELEMENT = 654;
  static final int MENU_ELEMENT = 645;
  static final int META_ELEMENT = 656;
  static final int NOFRAMES_ELEMENT = 657;
  static final int NOSCRIPT_ELEMENT = 658;
  static final int OBJECT_ELEMENT = 659;
  static final int OL_ELEMENT = 660;
  static final int OPTGROUP_ELEMENT = 661;
  static final int OPTION_ELEMENT = 662;
  static final int P_ELEMENT = 663;
  static final int PARAM_ELEMENT = 664;
  static final int PRE_ELEMENT = 665;
  static final int Q_ELEMENT = 666;
  static final int S_ELEMENT = 667;
  static final int SAMP_ELEMENT = 668;
  static final int SCRIPT_ELEMENT = 669;
  static final int SELECT_ELEMENT = 670;
  static final int SMALL_ELEMENT = 671;
  static final int SPAN_ELEMENT = 672;
  static final int STRIKE_ELEMENT = 673;
  static final int STRONG_ELEMENT = 674;
  static final int STYLE_ELEMENT = 675;
  static final int SUB_ELEMENT = 676;
  static final int SUP_ELEMENT = 677;
  static final int TABLE_ELEMENT = 678;
  static final int TBODY_ELEMENT = 679;
  static final int TD_ELEMENT = 680;
  static final int TEXTAREA_ELEMENT = 681;
  static final int TFOOT_ELEMENT = 682;
  static final int TH_ELEMENT = 683;
  static final int THEAD_ELEMENT = 684;
  static final int TITLE_ELEMENT = 685;
  static final int TR_ELEMENT = 686;
  static final int TT_ELEMENT = 687;
  static final int U_ELEMENT = 688;
  static final int UL_ELEMENT = 689;
  static final int VAR_ELEMENT = 690;
  static final int END_HTML_ELEMENT = VAR_ELEMENT;    // Last valid tag name.

  static bool validTagName(int tokId) {
    return tokId >= TokenKind.START_HTML_ELEMENT &&
      tokId <= TokenKind.END_HTML_ELEMENT;
  }

  static final List<Map<int, String>> _KEYWORDS = const [
    const {'type': TokenKind.TEMPLATE_KEYWORD, 'value' : 'template'},
  ];

  static final List<int> _NON_SCOPED_ELEMENTS = const [
    BR_ELEMENT,
  ];

  // tag values starting with a minus sign implies tag can be unscoped e.g.,
  // <br> is valid without <br></br> or <br/>
  static final List<Map<int, String>> _ELEMENTS = const [
    const {'type': TokenKind.A_ELEMENT, 'value' : 'a'},
    const {'type': TokenKind.ABBR_ELEMENT, 'value' : 'abbr'},
    const {'type': TokenKind.ACRONYM_ELEMENT, 'value' : 'acronym'},
    const {'type': TokenKind.ADDRESS_ELEMENT, 'value' : 'address'},
    const {'type': TokenKind.APPLET_ELEMENT, 'value' : 'applet'},
    const {'type': TokenKind.AREA_ELEMENT, 'value' : 'area'},
    const {'type': TokenKind.B_ELEMENT, 'value' : 'b'},
    const {'type': TokenKind.BASE_ELEMENT, 'value' : 'base'},
    const {'type': TokenKind.BASEFONT_ELEMENT, 'value' : 'basefont'},
    const {'type': TokenKind.BDO_ELEMENT, 'value' : 'bdo'},
    const {'type': TokenKind.BIG_ELEMENT, 'value' : 'big'},
    const {'type': TokenKind.BLOCKQUOTE_ELEMENT, 'value' : 'blockquote'},
    const {'type': TokenKind.BODY_ELEMENT, 'value' : 'body'},
    const {'type': TokenKind.BR_ELEMENT, 'value' : 'br'},
    const {'type': TokenKind.BUTTON_ELEMENT, 'value' : 'button'},
    const {'type': TokenKind.CAPTION_ELEMENT, 'value' : 'caption'},
    const {'type': TokenKind.CENTER_ELEMENT, 'value' : 'center'},
    const {'type': TokenKind.CITE_ELEMENT, 'value' : 'cite'},
    const {'type': TokenKind.CODE_ELEMENT, 'value' : 'code'},
    const {'type': TokenKind.COL_ELEMENT, 'value' : 'col'},
    const {'type': TokenKind.COLGROUP_ELEMENT, 'value' : 'colgroup'},
    const {'type': TokenKind.DD_ELEMENT, 'value' : 'dd'},
    const {'type': TokenKind.DEL_ELEMENT, 'value' : 'del'},
    const {'type': TokenKind.DFN_ELEMENT, 'value' : 'dfn'},
    const {'type': TokenKind.DIR_ELEMENT, 'value' : 'dir'},
    const {'type': TokenKind.DIV_ELEMENT, 'value' : 'div'},
    const {'type': TokenKind.DL_ELEMENT, 'value' : 'dl'},
    const {'type': TokenKind.DT_ELEMENT, 'value' : 'dt'},
    const {'type': TokenKind.EM_ELEMENT, 'value' : 'em'},
    const {'type': TokenKind.FIELDSET_ELEMENT, 'value' : 'fieldset'},
    const {'type': TokenKind.FONT_ELEMENT, 'value' : 'font'},
    const {'type': TokenKind.FORM_ELEMENT, 'value' : 'form'},
    const {'type': TokenKind.FRAME_ELEMENT, 'value' : 'frame'},
    const {'type': TokenKind.FRAMESET_ELEMENT, 'value' : 'frameset'},
    const {'type': TokenKind.H1_ELEMENT, 'value' : 'h1'},
    const {'type': TokenKind.H2_ELEMENT, 'value' : 'h2'},
    const {'type': TokenKind.H3_ELEMENT, 'value' : 'h3'},
    const {'type': TokenKind.H4_ELEMENT, 'value' : 'h4'},
    const {'type': TokenKind.H5_ELEMENT, 'value' : 'h5'},
    const {'type': TokenKind.H6_ELEMENT, 'value' : 'h6'},
    const {'type': TokenKind.HEAD_ELEMENT, 'value' : 'head'},
    const {'type': TokenKind.HR_ELEMENT, 'value' : 'hr'},
    const {'type': TokenKind.HTML_ELEMENT, 'value' : 'html'},
    const {'type': TokenKind.I_ELEMENT, 'value' : 'i'},
    const {'type': TokenKind.IFRAME_ELEMENT, 'value' : 'iframe'},
    const {'type': TokenKind.IMG_ELEMENT, 'value' : 'img'},
    const {'type': TokenKind.INPUT_ELEMENT, 'value' : 'input'},
    const {'type': TokenKind.INS_ELEMENT, 'value' : 'ins'},
    const {'type': TokenKind.ISINDEX_ELEMENT, 'value' : 'isindex'},
    const {'type': TokenKind.KBD_ELEMENT, 'value' : 'kbd'},
    const {'type': TokenKind.LABEL_ELEMENT, 'value' : 'label'},
    const {'type': TokenKind.LEGEND_ELEMENT, 'value' : 'legend'},
    const {'type': TokenKind.LI_ELEMENT, 'value' : 'li'},
    const {'type': TokenKind.LINK_ELEMENT, 'value' : 'link'},
    const {'type': TokenKind.MAP_ELEMENT, 'value' : 'map'},
    const {'type': TokenKind.MENU_ELEMENT, 'value' : 'menu'},
    const {'type': TokenKind.META_ELEMENT, 'value' : 'meta'},
    const {'type': TokenKind.NOFRAMES_ELEMENT, 'value' : 'noframes'},
    const {'type': TokenKind.NOSCRIPT_ELEMENT, 'value' : 'noscript'},
    const {'type': TokenKind.OBJECT_ELEMENT, 'value' : 'object'},
    const {'type': TokenKind.OL_ELEMENT, 'value' : 'ol'},
    const {'type': TokenKind.OPTGROUP_ELEMENT, 'value' : 'optgroup'},
    const {'type': TokenKind.OPTION_ELEMENT, 'value' : 'option'},
    const {'type': TokenKind.P_ELEMENT, 'value' : 'p'},
    const {'type': TokenKind.PARAM_ELEMENT, 'value' : 'param'},
    const {'type': TokenKind.PRE_ELEMENT, 'value' : 'pre'},
    const {'type': TokenKind.Q_ELEMENT, 'value' : 'q'},
    const {'type': TokenKind.S_ELEMENT, 'value' : 's'},
    const {'type': TokenKind.SAMP_ELEMENT, 'value' : 'samp'},
    const {'type': TokenKind.SCRIPT_ELEMENT, 'value' : 'script'},
    const {'type': TokenKind.SELECT_ELEMENT, 'value' : 'select'},
    const {'type': TokenKind.SMALL_ELEMENT, 'value' : 'small'},
    const {'type': TokenKind.SPAN_ELEMENT, 'value' : 'span'},
    const {'type': TokenKind.STRIKE_ELEMENT, 'value' : 'strike'},
    const {'type': TokenKind.STRONG_ELEMENT, 'value' : 'strong'},
    const {'type': TokenKind.STYLE_ELEMENT, 'value' : 'style'},
    const {'type': TokenKind.SUB_ELEMENT, 'value' : 'sub'},
    const {'type': TokenKind.SUP_ELEMENT, 'value' : 'sup'},
    const {'type': TokenKind.TABLE_ELEMENT, 'value' : 'table'},
    const {'type': TokenKind.TBODY_ELEMENT, 'value' : 'tbody'},
    const {'type': TokenKind.TD_ELEMENT, 'value' : 'td'},
    const {'type': TokenKind.TEXTAREA_ELEMENT, 'value' : 'textarea'},
    const {'type': TokenKind.TFOOT_ELEMENT, 'value' : 'tfoot'},
    const {'type': TokenKind.TH_ELEMENT, 'value' : 'th'},
    const {'type': TokenKind.THEAD_ELEMENT, 'value' : 'thead'},
    const {'type': TokenKind.TITLE_ELEMENT, 'value' : 'title'},
    const {'type': TokenKind.TR_ELEMENT, 'value' : 'tr'},
    const {'type': TokenKind.TT_ELEMENT, 'value' : 'tt'},
    const {'type': TokenKind.U_ELEMENT, 'value' : 'u'},
    const {'type': TokenKind.UL_ELEMENT, 'value' : 'ul'},
    const {'type': TokenKind.VAR_ELEMENT, 'value' : 'var'},
  ];

  // Some more constants:
  static final int ASCII_UPPER_A = 65;    // ASCII value for uppercase A
  static final int ASCII_UPPER_Z = 90;    // ASCII value for uppercase Z

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
   * Return the token that matches the element ident found.
   */
  static int matchElements(String text, int offset, int length) {
    return matchList(_ELEMENTS, 'type', text, offset, length);
  }

  static String tagNameFromTokenId(int tagTokenId) {
    if (TokenKind.validTagName(tagTokenId)) {
      for (final tag in TokenKind._ELEMENTS) {
        if (tag['type'] == tagTokenId) {
          return tag['value'];
        }
      }
    }
  }

  static bool unscopedTag(int tagTokenId) {
    for (final tagId in TokenKind._NON_SCOPED_ELEMENTS) {
      if (tagId == tagTokenId) {
        return true;
      }
    }

    return false;
  }

  static int matchKeywords(String text, int offset, int length) {
    return matchList(_KEYWORDS, 'type', text, offset, length);
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
      case TokenKind.SPACE: return " ";
      case TokenKind.TAB: return "\t";
      case TokenKind.NEWLINE: return "\n";
      case TokenKind.RETURN: return "\r";
      case TokenKind.COMMA: return ",";
      case TokenKind.LESS_THAN: return "<";
      case TokenKind.GREATER_THAN: return ">";
      case TokenKind.SLASH: return "/";
      case TokenKind.DOLLAR: return "\$";
      case TokenKind.HASH: return "#";
      case TokenKind.MINUS: return '-';
      case TokenKind.EQUAL: return '=';
      case TokenKind.DOUBLE_QUOTE: return '"';
      case TokenKind.SINGLE_QUOTE: return "'";
      case TokenKind.ASTERISK: return "*";
      case TokenKind.END_NO_SCOPE_TAG: return '/>';
      case TokenKind.START_EXPRESSION: return '\${';
      case TokenKind.START_COMMAND: return '\${#';
      case TokenKind.END_COMMAND: return '\${/';
      case TokenKind.EACH_COMMAND: return '\${#each list}';
      case TokenKind.WITH_COMMAND: return '\${with object}';
      case TokenKind.IF_COMMAND: return '\${#if (expression)}';
      case TokenKind.ELSE_COMMAND: return '\${#end}';
      case TokenKind.INTEGER: return 'integer';
      case TokenKind.DOUBLE: return 'double';
      case TokenKind.WHITESPACE: return 'whitespace';
      case TokenKind.COMMENT: return 'comment';
      case TokenKind.ERROR: return 'error';
      case TokenKind.INCOMPLETE_STRING : return 'incomplete string';
      case TokenKind.INCOMPLETE_COMMENT: return 'incomplete comment';
      case TokenKind.ATTR_VALUE: return 'attribute value';
      case TokenKind.NUMBER: return 'number';
      case TokenKind.HEX_NUMBER: return 'hex number';
      case TokenKind.HTML_COMMENT: return 'HTML comment <!-- -->';
      case TokenKind.IDENTIFIER: return 'identifier';
      case TokenKind.STRING: return 'string';
      case TokenKind.STRING_PART: return 'string part';
      case TokenKind.TEMPLATE_KEYWORD: return 'template';
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
    tokens.add(TokenKind.kindToString(TokenKind.SPACE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.TAB).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.NEWLINE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.RETURN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.COMMA).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.LESS_THAN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.GREATER_THAN).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.SLASH).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.DOLLAR).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.HASH).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.MINUS).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.EQUAL).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.DOUBLE_QUOTE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.SINGLE_QUOTE).charCodeAt(0));
    tokens.add(TokenKind.kindToString(TokenKind.ASTERISK).charCodeAt(0));

    assert(tokens.length == TokenKind.END_TOKENS);
  }

  static bool isIdentifier(int kind) {
    return kind == IDENTIFIER;
  }
}

class NoElementMatchException implements Exception {
  String _tagName;
  NoElementMatchException(this._tagName);

  String get name() => _tagName;
}
