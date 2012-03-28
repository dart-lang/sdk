// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("characters");

final int $EOF = 0;
final int $STX = 2;
final int $BS  = 8;
final int $TAB = 9;
final int $LF = 10;
final int $VTAB = 11;
final int $FF = 12;
final int $CR = 13;
final int $SPACE = 32;
final int $BANG = 33;
final int $DQ = 34;
final int $HASH = 35;
final int $$ = 36;
final int $PERCENT = 37;
final int $AMPERSAND = 38;
final int $SQ = 39;
final int $OPEN_PAREN = 40;
final int $CLOSE_PAREN = 41;
final int $STAR = 42;
final int $PLUS = 43;
final int $COMMA = 44;
final int $MINUS = 45;
final int $PERIOD = 46;
final int $SLASH = 47;
final int $0 = 48;
final int $1 = 49;
final int $2 = 50;
final int $3 = 51;
final int $4 = 52;
final int $5 = 53;
final int $6 = 54;
final int $7 = 55;
final int $8 = 56;
final int $9 = 57;
final int $COLON = 58;
final int $SEMICOLON = 59;
final int $LT = 60;
final int $EQ = 61;
final int $GT = 62;
final int $QUESTION = 63;
final int $AT = 64;
final int $A = 65;
final int $B = 66;
final int $C = 67;
final int $D = 68;
final int $E = 69;
final int $F = 70;
final int $G = 71;
final int $H = 72;
final int $I = 73;
final int $J = 74;
final int $K = 75;
final int $L = 76;
final int $M = 77;
final int $N = 78;
final int $O = 79;
final int $P = 80;
final int $Q = 81;
final int $R = 82;
final int $S = 83;
final int $T = 84;
final int $U = 85;
final int $V = 86;
final int $W = 87;
final int $X = 88;
final int $Y = 89;
final int $Z = 90;
final int $OPEN_SQUARE_BRACKET = 91;
final int $BACKSLASH = 92;
final int $CLOSE_SQUARE_BRACKET = 93;
final int $CARET = 94;
final int $_ = 95;
final int $BACKPING = 96;
final int $a = 97;
final int $b = 98;
final int $c = 99;
final int $d = 100;
final int $e = 101;
final int $f = 102;
final int $g = 103;
final int $h = 104;
final int $i = 105;
final int $j = 106;
final int $k = 107;
final int $l = 108;
final int $m = 109;
final int $n = 110;
final int $o = 111;
final int $p = 112;
final int $q = 113;
final int $r = 114;
final int $s = 115;
final int $t = 116;
final int $u = 117;
final int $v = 118;
final int $w = 119;
final int $x = 120;
final int $y = 121;
final int $z = 122;
final int $OPEN_CURLY_BRACKET = 123;
final int $BAR = 124;
final int $CLOSE_CURLY_BRACKET = 125;
final int $TILDE = 126;
final int $DEL = 127;
final int $NBSP = 160;
final int $LS = 0x2028;
final int $PS = 0x2029;

final int $FIRST_SURROGATE = 0xd800;
final int $LAST_SURROGATE = 0xdfff;
final int $LAST_CODE_POINT = 0x10ffff;

bool isHexDigit(int characterCode) {
  if (characterCode <= $9) return $0 <= characterCode;
  characterCode |= $a ^ $A;
  return ($a <= characterCode && characterCode <= $f);
}

int hexDigitValue(int hexDigit) {
  assert(isHexDigit(hexDigit));
  // hexDigit is one of '0'..'9', 'A'..'F' and 'a'..'f'.
  if (hexDigit <= $9) return hexDigit - $0;
  return (hexDigit | ($a ^ $A)) - ($a - 10);
}

bool isUnicodeScalarValue(int value) {
  return value < $FIRST_SURROGATE ||
      (value > $LAST_SURROGATE && value <= $LAST_CODE_POINT);
}
