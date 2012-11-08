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
  static final int WIN_KEY_FF_LINUX = 0;
  static final int MAC_ENTER = 3;
  static final int BACKSPACE = 8;
  static final int TAB = 9;
  /** NUM_CENTER is also NUMLOCK for FF and Safari on Mac. */
  static final int NUM_CENTER = 12;
  static final int ENTER = 13;
  static final int SHIFT = 16;
  static final int CTRL = 17;
  static final int ALT = 18;
  static final int PAUSE = 19;
  static final int CAPS_LOCK = 20;
  static final int ESC = 27;
  static final int SPACE = 32;
  static final int PAGE_UP = 33;
  static final int PAGE_DOWN = 34;
  static final int END = 35;
  static final int HOME = 36;
  static final int LEFT = 37;
  static final int UP = 38;
  static final int RIGHT = 39;
  static final int DOWN = 40;
  static final int NUM_NORTH_EAST = 33;
  static final int NUM_SOUTH_EAST = 34;
  static final int NUM_SOUTH_WEST = 35;
  static final int NUM_NORTH_WEST = 36;
  static final int NUM_WEST = 37;
  static final int NUM_NORTH = 38;
  static final int NUM_EAST = 39;
  static final int NUM_SOUTH = 40;
  static final int PRINT_SCREEN = 44;
  static final int INSERT = 45;
  static final int NUM_INSERT = 45;
  static final int DELETE = 46;
  static final int NUM_DELETE = 46;
  static final int ZERO = 48;
  static final int ONE = 49;
  static final int TWO = 50;
  static final int THREE = 51;
  static final int FOUR = 52;
  static final int FIVE = 53;
  static final int SIX = 54;
  static final int SEVEN = 55;
  static final int EIGHT = 56;
  static final int NINE = 57;
  static final int FF_SEMICOLON = 59;
  static final int FF_EQUALS = 61;
  /**
   * CAUTION: The question mark is for US-keyboard layouts. It varies
   * for other locales and keyboard layouts.
   */
  static final int QUESTION_MARK = 63;
  static final int A = 65;
  static final int B = 66;
  static final int C = 67;
  static final int D = 68;
  static final int E = 69;
  static final int F = 70;
  static final int G = 71;
  static final int H = 72;
  static final int I = 73;
  static final int J = 74;
  static final int K = 75;
  static final int L = 76;
  static final int M = 77;
  static final int N = 78;
  static final int O = 79;
  static final int P = 80;
  static final int Q = 81;
  static final int R = 82;
  static final int S = 83;
  static final int T = 84;
  static final int U = 85;
  static final int V = 86;
  static final int W = 87;
  static final int X = 88;
  static final int Y = 89;
  static final int Z = 90;
  static final int META = 91;
  static final int WIN_KEY_LEFT = 91;
  static final int WIN_KEY_RIGHT = 92;
  static final int CONTEXT_MENU = 93;
  static final int NUM_ZERO = 96;
  static final int NUM_ONE = 97;
  static final int NUM_TWO = 98;
  static final int NUM_THREE = 99;
  static final int NUM_FOUR = 100;
  static final int NUM_FIVE = 101;
  static final int NUM_SIX = 102;
  static final int NUM_SEVEN = 103;
  static final int NUM_EIGHT = 104;
  static final int NUM_NINE = 105;
  static final int NUM_MULTIPLY = 106;
  static final int NUM_PLUS = 107;
  static final int NUM_MINUS = 109;
  static final int NUM_PERIOD = 110;
  static final int NUM_DIVISION = 111;
  static final int F1 = 112;
  static final int F2 = 113;
  static final int F3 = 114;
  static final int F4 = 115;
  static final int F5 = 116;
  static final int F6 = 117;
  static final int F7 = 118;
  static final int F8 = 119;
  static final int F9 = 120;
  static final int F10 = 121;
  static final int F11 = 122;
  static final int F12 = 123;
  static final int NUMLOCK = 144;
  static final int SCROLL_LOCK = 145;

  // OS-specific media keys like volume controls and browser controls.
  static final int FIRST_MEDIA_KEY = 166;
  static final int LAST_MEDIA_KEY = 183;

  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int SEMICOLON = 186;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int DASH = 189;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int EQUALS = 187;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int COMMA = 188;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int PERIOD = 190;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int SLASH = 191;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int APOSTROPHE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int TILDE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int SINGLE_QUOTE = 222;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int OPEN_SQUARE_BRACKET = 219;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int BACKSLASH = 220;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static final int CLOSE_SQUARE_BRACKET = 221;
  static final int WIN_KEY = 224;
  static final int MAC_FF_META = 224;
  static final int WIN_IME = 229;
}
