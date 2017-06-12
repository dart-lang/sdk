// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * Defines the keycode values for keys that are returned by
 * KeyboardEvent.keyCode.
 *
 * Important note: There is substantial divergence in how different browsers
 * handle keycodes and their variants in different locales/keyboard layouts. We
 * provide these constants to help make code processing keys more readable.
 */
abstract class KeyCode {
  // These constant names were borrowed from Closure's Keycode enumeration
  // class.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keycodes.js.source.html
  static const int WIN_KEY_FF_LINUX = 0;
  static const int MAC_ENTER = 3;
  static const int BACKSPACE = 8;
  static const int TAB = 9;
  /** NUM_CENTER is also NUMLOCK for FF and Safari on Mac. */
  static const int NUM_CENTER = 12;
  static const int ENTER = 13;
  static const int SHIFT = 16;
  static const int CTRL = 17;
  static const int ALT = 18;
  static const int PAUSE = 19;
  static const int CAPS_LOCK = 20;
  static const int ESC = 27;
  static const int SPACE = 32;
  static const int PAGE_UP = 33;
  static const int PAGE_DOWN = 34;
  static const int END = 35;
  static const int HOME = 36;
  static const int LEFT = 37;
  static const int UP = 38;
  static const int RIGHT = 39;
  static const int DOWN = 40;
  static const int NUM_NORTH_EAST = 33;
  static const int NUM_SOUTH_EAST = 34;
  static const int NUM_SOUTH_WEST = 35;
  static const int NUM_NORTH_WEST = 36;
  static const int NUM_WEST = 37;
  static const int NUM_NORTH = 38;
  static const int NUM_EAST = 39;
  static const int NUM_SOUTH = 40;
  static const int PRINT_SCREEN = 44;
  static const int INSERT = 45;
  static const int NUM_INSERT = 45;
  static const int DELETE = 46;
  static const int NUM_DELETE = 46;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int TWO = 50;
  static const int THREE = 51;
  static const int FOUR = 52;
  static const int FIVE = 53;
  static const int SIX = 54;
  static const int SEVEN = 55;
  static const int EIGHT = 56;
  static const int NINE = 57;
  static const int FF_SEMICOLON = 59;
  static const int FF_EQUALS = 61;
  /**
   * CAUTION: The question mark is for US-keyboard layouts. It varies
   * for other locales and keyboard layouts.
   */
  static const int QUESTION_MARK = 63;
  static const int A = 65;
  static const int B = 66;
  static const int C = 67;
  static const int D = 68;
  static const int E = 69;
  static const int F = 70;
  static const int G = 71;
  static const int H = 72;
  static const int I = 73;
  static const int J = 74;
  static const int K = 75;
  static const int L = 76;
  static const int M = 77;
  static const int N = 78;
  static const int O = 79;
  static const int P = 80;
  static const int Q = 81;
  static const int R = 82;
  static const int S = 83;
  static const int T = 84;
  static const int U = 85;
  static const int V = 86;
  static const int W = 87;
  static const int X = 88;
  static const int Y = 89;
  static const int Z = 90;
  static const int META = 91;
  static const int WIN_KEY_LEFT = 91;
  static const int WIN_KEY_RIGHT = 92;
  static const int CONTEXT_MENU = 93;
  static const int NUM_ZERO = 96;
  static const int NUM_ONE = 97;
  static const int NUM_TWO = 98;
  static const int NUM_THREE = 99;
  static const int NUM_FOUR = 100;
  static const int NUM_FIVE = 101;
  static const int NUM_SIX = 102;
  static const int NUM_SEVEN = 103;
  static const int NUM_EIGHT = 104;
  static const int NUM_NINE = 105;
  static const int NUM_MULTIPLY = 106;
  static const int NUM_PLUS = 107;
  static const int NUM_MINUS = 109;
  static const int NUM_PERIOD = 110;
  static const int NUM_DIVISION = 111;
  static const int F1 = 112;
  static const int F2 = 113;
  static const int F3 = 114;
  static const int F4 = 115;
  static const int F5 = 116;
  static const int F6 = 117;
  static const int F7 = 118;
  static const int F8 = 119;
  static const int F9 = 120;
  static const int F10 = 121;
  static const int F11 = 122;
  static const int F12 = 123;
  static const int NUMLOCK = 144;
  static const int SCROLL_LOCK = 145;

  // OS-specific media keys like volume controls and browser controls.
  static const int FIRST_MEDIA_KEY = 166;
  static const int LAST_MEDIA_KEY = 183;

  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SEMICOLON = 186;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int DASH = 189;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int EQUALS = 187;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int COMMA = 188;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int PERIOD = 190;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SLASH = 191;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int APOSTROPHE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int TILDE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SINGLE_QUOTE = 222;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int OPEN_SQUARE_BRACKET = 219;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int BACKSLASH = 220;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int CLOSE_SQUARE_BRACKET = 221;
  static const int WIN_KEY = 224;
  static const int MAC_FF_META = 224;
  static const int WIN_IME = 229;

  /** A sentinel value if the keycode could not be determined. */
  static const int UNKNOWN = -1;

  /**
   * Returns true if the keyCode produces a (US keyboard) character.
   * Note: This does not (yet) cover characters on non-US keyboards (Russian,
   * Hebrew, etc.).
   */
  static bool isCharacterKey(int keyCode) {
    if ((keyCode >= ZERO && keyCode <= NINE) ||
        (keyCode >= NUM_ZERO && keyCode <= NUM_MULTIPLY) ||
        (keyCode >= A && keyCode <= Z)) {
      return true;
    }

    // Safari sends zero key code for non-latin characters.
    if (Device.isWebKit && keyCode == 0) {
      return true;
    }

    return (keyCode == SPACE ||
        keyCode == QUESTION_MARK ||
        keyCode == NUM_PLUS ||
        keyCode == NUM_MINUS ||
        keyCode == NUM_PERIOD ||
        keyCode == NUM_DIVISION ||
        keyCode == SEMICOLON ||
        keyCode == FF_SEMICOLON ||
        keyCode == DASH ||
        keyCode == EQUALS ||
        keyCode == FF_EQUALS ||
        keyCode == COMMA ||
        keyCode == PERIOD ||
        keyCode == SLASH ||
        keyCode == APOSTROPHE ||
        keyCode == SINGLE_QUOTE ||
        keyCode == OPEN_SQUARE_BRACKET ||
        keyCode == BACKSLASH ||
        keyCode == CLOSE_SQUARE_BRACKET);
  }

  /**
   * Experimental helper function for converting keyCodes to keyNames for the
   * keyIdentifier attribute still used in browsers not updated with current
   * spec. This is an imperfect conversion! It will need to be refined, but
   * hopefully it can just completely go away once all the browsers update to
   * follow the DOM3 spec.
   */
  static String _convertKeyCodeToKeyName(int keyCode) {
    switch (keyCode) {
      case KeyCode.ALT:
        return _KeyName.ALT;
      case KeyCode.BACKSPACE:
        return _KeyName.BACKSPACE;
      case KeyCode.CAPS_LOCK:
        return _KeyName.CAPS_LOCK;
      case KeyCode.CTRL:
        return _KeyName.CONTROL;
      case KeyCode.DELETE:
        return _KeyName.DEL;
      case KeyCode.DOWN:
        return _KeyName.DOWN;
      case KeyCode.END:
        return _KeyName.END;
      case KeyCode.ENTER:
        return _KeyName.ENTER;
      case KeyCode.ESC:
        return _KeyName.ESC;
      case KeyCode.F1:
        return _KeyName.F1;
      case KeyCode.F2:
        return _KeyName.F2;
      case KeyCode.F3:
        return _KeyName.F3;
      case KeyCode.F4:
        return _KeyName.F4;
      case KeyCode.F5:
        return _KeyName.F5;
      case KeyCode.F6:
        return _KeyName.F6;
      case KeyCode.F7:
        return _KeyName.F7;
      case KeyCode.F8:
        return _KeyName.F8;
      case KeyCode.F9:
        return _KeyName.F9;
      case KeyCode.F10:
        return _KeyName.F10;
      case KeyCode.F11:
        return _KeyName.F11;
      case KeyCode.F12:
        return _KeyName.F12;
      case KeyCode.HOME:
        return _KeyName.HOME;
      case KeyCode.INSERT:
        return _KeyName.INSERT;
      case KeyCode.LEFT:
        return _KeyName.LEFT;
      case KeyCode.META:
        return _KeyName.META;
      case KeyCode.NUMLOCK:
        return _KeyName.NUM_LOCK;
      case KeyCode.PAGE_DOWN:
        return _KeyName.PAGE_DOWN;
      case KeyCode.PAGE_UP:
        return _KeyName.PAGE_UP;
      case KeyCode.PAUSE:
        return _KeyName.PAUSE;
      case KeyCode.PRINT_SCREEN:
        return _KeyName.PRINT_SCREEN;
      case KeyCode.RIGHT:
        return _KeyName.RIGHT;
      case KeyCode.SCROLL_LOCK:
        return _KeyName.SCROLL;
      case KeyCode.SHIFT:
        return _KeyName.SHIFT;
      case KeyCode.SPACE:
        return _KeyName.SPACEBAR;
      case KeyCode.TAB:
        return _KeyName.TAB;
      case KeyCode.UP:
        return _KeyName.UP;
      case KeyCode.WIN_IME:
      case KeyCode.WIN_KEY:
      case KeyCode.WIN_KEY_LEFT:
      case KeyCode.WIN_KEY_RIGHT:
        return _KeyName.WIN;
      default:
        return _KeyName.UNIDENTIFIED;
    }
    return _KeyName.UNIDENTIFIED;
  }
}
