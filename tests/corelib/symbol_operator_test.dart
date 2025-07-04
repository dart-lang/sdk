// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of Symbol class for operators..

import 'package:expect/variations.dart';

dynamic $ = new Symbolize();

main() {
  testSymbol(#+, $ + $, "+");
  testSymbol(#-, $ - $, "-");
  testSymbol(#*, $ * $, "*");
  testSymbol(#/, $ / $, "/");
  testSymbol(#~/, $ ~/ $, "~/");
  testSymbol(#%, $ % $, "%");
  testSymbol(#<<, $ << $, "<<");
  testSymbol(#>>, $ >> $, ">>");
  testSymbol(#~, ~$, "~");
  testSymbol(#|, $ | $, "|");
  testSymbol(#&, $ & $, "&");
  testSymbol(#^, $ ^ $, "^");
  testSymbol(#<, $ < $, "<");
  testSymbol(#<=, $ <= $, "<=");
  testSymbol(#>, $ > $, ">");
  testSymbol(#>=, $ >= $, ">=");
  testSymbol(#==, #==, "=="); // Can't hit noSuchMethod.
  testSymbol(#[], $[$], "[]");
  testSymbol(#[]=, ($[$] = $).lastMember, "[]=");
  testSymbol(Symbol.unaryMinus, -$, "unary-");

  testSymbolNotInstanceOperator(">>>");
  testSymbolNotInstanceOperator("!");
  testSymbolNotInstanceOperator("&&");
  testSymbolNotInstanceOperator("||");
  testSymbolNotInstanceOperator("?");
  testSymbolNotInstanceOperator("?:");
  testSymbolNotInstanceOperator("#");
  testSymbolNotInstanceOperator("//");
}

void testSymbol(Symbol constSymbol, var mirrorSymbol, String name) {
  if (constSymbol != mirrorSymbol) {
    throw "Not equal #$name, \$$name: $constSymbol, $mirrorSymbol";
  }
  if (constSymbol.hashCode != mirrorSymbol.hashCode) {
    throw "HashCode not equal #$name, \$$name: $constSymbol, $mirrorSymbol";
  }
  if (!minifiedSymbols) {
    final dynamicSymbol = new Symbol(name);
    if (constSymbol != dynamicSymbol) {
      throw "Not equal #$name, new Symbol('$name'): $constSymbol, $dynamicSymbol";
    }
    if (mirrorSymbol != dynamicSymbol) {
      throw "Not equal \$$name, new Symbol('$name'): "
          "$mirrorSymbol, $dynamicSymbol";
    }
    if (constSymbol.hashCode != dynamicSymbol.hashCode) {
      throw "HashCode not equal #$name, new Symbol('$name'): "
          "$constSymbol, $dynamicSymbol";
    }
    if (mirrorSymbol.hashCode != dynamicSymbol.hashCode) {
      throw "HashCode not equal \$$name, new Symbol('$name'): "
          "$mirrorSymbol, $dynamicSymbol";
    }
  }
}

void testSymbolNotInstanceOperator(name) {
  new Symbol(name);
}

class Symbolize {
  Symbol? lastMember;
  noSuchMethod(m) => lastMember = m.memberName;
}
