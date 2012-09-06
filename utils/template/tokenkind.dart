// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Need to be consistent with tokens either they're ASCII tokens
//              e.g., ASTERISK or they're CSS e.g., PSEUDO, COMBINATOR_*.
class TokenKind {
  // Common shared tokens used in TokenizerBase.
  static const int UNUSED = 0;                  // Unused place holder...
  static const int END_OF_FILE = 1;
  static const int LPAREN = 2;                  // (
  static const int RPAREN = 3;                  // )
  static const int LBRACK = 4;                  // [
  static const int RBRACK = 5;                  // ]
  static const int LBRACE = 6;                  // {
  static const int RBRACE = 7;                  // }
  static const int DOT = 8;                     // .
  static const int SEMICOLON = 9;               // ;
  static const int SPACE = 10;                  // space character
  static const int TAB = 11;                    // \t
  static const int NEWLINE = 12;                // \n
  static const int RETURN = 13;                 // \r
  static const int COMMA = 14;                  // ,

  // Unique tokens.
  static const int LESS_THAN = 15;              // <
  static const int GREATER_THAN = 16;           // >
  static const int SLASH = 17;                  // /
  static const int DOLLAR = 18;                 // $
  static const int HASH = 19;                   // #
  static const int MINUS = 20;                  // -
  static const int EQUAL = 21;                  // =
  static const int DOUBLE_QUOTE = 22;           // "
  static const int SINGLE_QUOTE = 23;           // '
  static const int ASTERISK = 24;               // *

  // WARNING: END_TOKENS must be 1 greater than the last token above (last
  //          character in our list).  Also add to kindToString function and the
  //          constructor for TokenKind.

  static const int END_TOKENS = 25;             // Marker for last token in list

  // Synthesized tokens:

  static const int END_NO_SCOPE_TAG = 50;       // />
  static const int START_EXPRESSION = 51;       // ${
  static const int START_COMMAND = 52;          // ${#
  static const int END_COMMAND = 53;            // ${/
  static const int EACH_COMMAND = 53;           // ${#each list}
  static const int WITH_COMMAND = 54;           // ${#with object}
  static const int IF_COMMAND = 55;             // ${#if (expression)}
  static const int ELSE_COMMAND = 56;           // ${#else}

  /** [TokenKind] representing integer tokens. */
  static const int INTEGER = 60;                // TODO(terry): must match base

  /** [TokenKind] representing hex integer tokens. */
//  static const int HEX_INTEGER = 61;          // TODO(terry): must match base

  /** [TokenKind] representing double tokens. */
  static const int DOUBLE = 62;                 // TODO(terry): must match base

  /** [TokenKind] representing whitespace tokens. */
  static const int WHITESPACE = 63;             // TODO(terry): must match base

  /** [TokenKind] representing comment tokens. */
  static const int COMMENT = 64;                // TODO(terry): must match base

  /** [TokenKind] representing error tokens. */
  static const int ERROR = 65;                  // TODO(terry): must match base

  /** [TokenKind] representing incomplete string tokens. */
  static const int INCOMPLETE_STRING = 66;      // TODO(terry): must match base

  /** [TokenKind] representing incomplete comment tokens. */
  static const int INCOMPLETE_COMMENT = 67;     // TODO(terry): must match base

  // Synthesized Tokens (no character associated with TOKEN).
  // TODO(terry): Possible common names used by both Dart and CSS tokenizers.
  static const int ATTR_VALUE = 500;
  static const int NUMBER = 502;
  static const int HEX_NUMBER = 503;
  static const int HTML_COMMENT = 504;          // <!--
  static const int IDENTIFIER = 511;
  static const int STRING = 512;
  static const int STRING_PART = 513;

  static const int TEMPLATE_KEYWORD = 595;      // template keyword

  // Elements
  /* START_HTML_ELEMENT is first valid element tag name
   * END_HTML_ELEMENT is the last valid element tag name
   *
   */
  static const int START_HTML_ELEMENT = 600;      // First valid tag name.
  static const int A_ELEMENT = 600;
  static const int ABBR_ELEMENT = 601;
  static const int ACRONYM_ELEMENT = 602;
  static const int ADDRESS_ELEMENT = 603;
  static const int APPLET_ELEMENT = 604;
  static const int AREA_ELEMENT = 605;
  static const int B_ELEMENT = 606;
  static const int BASE_ELEMENT = 607;
  static const int BASEFONT_ELEMENT = 608;
  static const int BDO_ELEMENT = 609;
  static const int BIG_ELEMENT = 610;
  static const int BLOCKQUOTE_ELEMENT = 611;
  static const int BODY_ELEMENT = 612;
  static const int BR_ELEMENT = 613;
  static const int BUTTON_ELEMENT = 614;
  static const int CAPTION_ELEMENT = 615;
  static const int CENTER_ELEMENT = 616;
  static const int CITE_ELEMENT = 617;
  static const int CODE_ELEMENT = 618;
  static const int COL_ELEMENT = 619;
  static const int COLGROUP_ELEMENT = 620;
  static const int DD_ELEMENT = 621;
  static const int DEL_ELEMENT = 622;
  static const int DFN_ELEMENT = 623;
  static const int DIR_ELEMENT = 624;
  static const int DIV_ELEMENT = 625;
  static const int DL_ELEMENT = 626;
  static const int DT_ELEMENT = 627;
  static const int EM_ELEMENT = 628;
  static const int FIELDSET_ELEMENT = 629;
  static const int FONT_ELEMENT = 630;
  static const int FORM_ELEMENT = 631;
  static const int FRAME_ELEMENT = 632;
  static const int FRAMESET_ELEMENT = 633;
  static const int H1_ELEMENT = 634;
  static const int H2_ELEMENT = 635;
  static const int H3_ELEMENT = 636;
  static const int H4_ELEMENT = 637;
  static const int H5_ELEMENT = 638;
  static const int H6_ELEMENT = 639;
  static const int HEAD_ELEMENT = 640;
  static const int HR_ELEMENT = 641;
  static const int HTML_ELEMENT = 642;
  static const int I_ELEMENT = 643;
  static const int IFRAME_ELEMENT = 644;
  static const int IMG_ELEMENT = 645;
  static const int INPUT_ELEMENT = 646;
  static const int INS_ELEMENT = 647;
  static const int ISINDEX_ELEMENT = 648;
  static const int KBD_ELEMENT = 649;
  static const int LABEL_ELEMENT = 650;
  static const int LEGEND_ELEMENT = 651;
  static const int LI_ELEMENT = 652;
  static const int LINK_ELEMENT = 653;
  static const int MAP_ELEMENT = 654;
  static const int MENU_ELEMENT = 645;
  static const int META_ELEMENT = 656;
  static const int NOFRAMES_ELEMENT = 657;
  static const int NOSCRIPT_ELEMENT = 658;
  static const int OBJECT_ELEMENT = 659;
  static const int OL_ELEMENT = 660;
  static const int OPTGROUP_ELEMENT = 661;
  static const int OPTION_ELEMENT = 662;
  static const int P_ELEMENT = 663;
  static const int PARAM_ELEMENT = 664;
  static const int PRE_ELEMENT = 665;
  static const int Q_ELEMENT = 666;
  static const int S_ELEMENT = 667;
  static const int SAMP_ELEMENT = 668;
  static const int SCRIPT_ELEMENT = 669;
  static const int SELECT_ELEMENT = 670;
  static const int SMALL_ELEMENT = 671;
  static const int SPAN_ELEMENT = 672;
  static const int STRIKE_ELEMENT = 673;
  static const int STRONG_ELEMENT = 674;
  static const int STYLE_ELEMENT = 675;
  static const int SUB_ELEMENT = 676;
  static const int SUP_ELEMENT = 677;
  static const int TABLE_ELEMENT = 678;
  static const int TBODY_ELEMENT = 679;
  static const int TD_ELEMENT = 680;
  static const int TEXTAREA_ELEMENT = 681;
  static const int TFOOT_ELEMENT = 682;
  static const int TH_ELEMENT = 683;
  static const int THEAD_ELEMENT = 684;
  static const int TITLE_ELEMENT = 685;
  static const int TR_ELEMENT = 686;
  static const int TT_ELEMENT = 687;
  static const int U_ELEMENT = 688;
  static const int UL_ELEMENT = 689;
  static const int VAR_ELEMENT = 690;
  static const int END_HTML_ELEMENT = VAR_ELEMENT;    // Last valid tag name.

  static bool validTagName(int tokId) {
    return tokId >= TokenKind.START_HTML_ELEMENT &&
      tokId <= TokenKind.END_HTML_ELEMENT;
  }

  static const List<Map<int, String>> _KEYWORDS = const [
    const {'type': TokenKind.TEMPLATE_KEYWORD, 'value' : 'template'},
  ];

  static const List<int> _NON_SCOPED_ELEMENTS = const [
    BR_ELEMENT,
  ];

  // tag values starting with a minus sign implies tag can be unscoped e.g.,
  // <br> is valid without <br></br> or <br/>
  static const List<Map<int, String>> _ELEMENTS = const [
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
  static const int ASCII_UPPER_A = 65;    // ASCII value for uppercase A
  static const int ASCII_UPPER_Z = 90;    // ASCII value for uppercase Z

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
