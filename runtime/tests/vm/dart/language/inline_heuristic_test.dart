// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=10

// Test on specialized vs non-specialized inlining.

import 'dart:core';
import "package:expect/expect.dart";

// To inline or not to inline, that is the question?
int foo(int k) {
  switch (k) {
    case 0:
      return 1;
    case 1:
      return 2;
    case 2:
      return 3;
    case 3:
      return 4;
    case 4:
      return 5;
    case 5:
      return 6;
    case 6:
      return 7;
    case 7:
      return 8;
    case 8:
      return 9;
    case 9:
      return 10;
    case 10:
      return 11;
    case 11:
      return 12;
    case 12:
      return 13;
    case 13:
      return 14;
    case 14:
      return 15;
    case 15:
      return 16;
    case 16:
      return 17;
    case 17:
      return 18;
    case 18:
      return 19;
    case 19:
      return 20;
    case 20:
      return 21;
    case 21:
      return 22;
    case 22:
      return 23;
    case 23:
      return 24;
    case 24:
      return 25;
    case 25:
      return 26;
    case 26:
      return 27;
    case 27:
      return 28;
    case 28:
      return 29;
    case 29:
      return 30;
    case 30:
      return 31;
    case 31:
      return 32;
    case 32:
      return 33;
    case 33:
      return 34;
    case 34:
      return 35;
    case 35:
      return 36;
    case 36:
      return 37;
    case 37:
      return 38;
    case 38:
      return 39;
    case 39:
      return 40;
    case 40:
      return 41;
    case 41:
      return 42;
    case 42:
      return 43;
    case 43:
      return 44;
    case 44:
      return 45;
    case 45:
      return 46;
    case 46:
      return 47;
    case 47:
      return 48;
    case 48:
      return 49;
    case 49:
      return 50;
    case 50:
      return 51;
    case 51:
      return 52;
    case 52:
      return 53;
    case 53:
      return 54;
    case 54:
      return 55;
    case 55:
      return 56;
    case 56:
      return 57;
    case 57:
      return 58;
    case 58:
      return 59;
    case 59:
      return 60;
    case 60:
      return 61;
    case 61:
      return 62;
    case 62:
      return 63;
    case 63:
      return 64;
    case 64:
      return 65;
    case 65:
      return 66;
    case 66:
      return 67;
    case 67:
      return 68;
    case 68:
      return 69;
    case 69:
      return 70;
    case 70:
      return 71;
    case 71:
      return 72;
    case 72:
      return 73;
    case 73:
      return 74;
    case 74:
      return 75;
    case 75:
      return 76;
    case 76:
      return 77;
    case 77:
      return 78;
    case 78:
      return 79;
    case 79:
      return 80;
    case 80:
      return 81;
    case 81:
      return 82;
    case 82:
      return 83;
    case 83:
      return 84;
    case 84:
      return 85;
    case 85:
      return 86;
    case 86:
      return 87;
    case 87:
      return 88;
    case 88:
      return 89;
    case 89:
      return 90;
    case 90:
      return 91;
    case 91:
      return 92;
    case 92:
      return 93;
    case 93:
      return 94;
    case 94:
      return 95;
    case 95:
      return 96;
    case 96:
      return 97;
    case 97:
      return 98;
    case 98:
      return 99;
    case 99:
      return 100;
    case 100:
      return 101;
    case 101:
      return 102;
    case 102:
      return 103;
    case 103:
      return 104;
    case 104:
      return 105;
    case 105:
      return 106;
    case 106:
      return 107;
    case 107:
      return 108;
    case 108:
      return 109;
    case 109:
      return 110;
    case 110:
      return 111;
    case 111:
      return 112;
    case 112:
      return 113;
    case 113:
      return 114;
    case 114:
      return 115;
    case 115:
      return 116;
    case 116:
      return 117;
    case 117:
      return 118;
    case 118:
      return 119;
    case 119:
      return 120;
    case 120:
      return 121;
    case 121:
      return 122;
    case 122:
      return 123;
    case 123:
      return 124;
    case 124:
      return 125;
    case 125:
      return 126;
    case 126:
      return 127;
    case 127:
      return 128;
    default:
      return -1;
  }
}

@pragma('vm:never-inline')
int bar() {
  // Here we should inline! The inlined size is very small
  // after specialization for the constant arguments.
  return foo(1) + foo(12);
}

@pragma('vm:never-inline')
int baz(int i) {
  // Here we should not inline! The inlined size is too large,
  // just keep the original method. In fact, we can use the cached
  // estimate of foo()'s size from the previous compilation at this
  // point, which enables the "early" bail heuristic!
  return foo(i);
}

main() {
  // Repeat tests to enter JIT (when applicable).
  for (int i = 0; i < 20; i++) {
    Expect.equals(15, bar());
    for (int i = -150; i <= 150; i++) {
      int e = (i < 0 || i > 127) ? -1 : i + 1;
      Expect.equals(e, baz(i));
    }
  }
}
