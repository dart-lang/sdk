// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of Symbol class for operators..

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
  testSymbol(#==, new Symbol("=="), "=="); // Can't hit noSuchMethod.
  testSymbol(#[], $[$], "[]");
  testSymbol(#[]=, ($[$] = $).lastMember, "[]=");
  testSymbol(const Symbol("unary-"), -$, "unary-");

  testSymbolThrows(">>>"); // //# 03: ok
  testSymbolThrows("!"); //   //# 03: continued
  testSymbolThrows("&&"); //  //# 03: continued
  testSymbolThrows("||"); //  //# 03: continued
  testSymbolThrows("?"); //   //# 03: continued
  testSymbolThrows("?:"); //  //# 03: continued
  testSymbolThrows("#"); //   //# 03: continued
  testSymbolThrows("//"); //  //# 03: continued
}

void testSymbol(Symbol constSymbol, var mirrorSymbol, String name) {
  Symbol dynamicSymbol = new Symbol(name);
  if (constSymbol != mirrorSymbol) {
    throw "Not equal #$name, \$$name: $constSymbol, $mirrorSymbol";
  }
  if (constSymbol != dynamicSymbol) {
    throw "Not equal #$name, new Symbol('$name'): $constSymbol, $dynamicSymbol";
  }
  if (mirrorSymbol != dynamicSymbol) {
    throw "Not equal \$$name, new Symbol('$name'): "
        "$mirrorSymbol, $dynamicSymbol";
  }
  if (constSymbol.hashCode != mirrorSymbol.hashCode) {
    throw "HashCode not equal #$name, \$$name: $constSymbol, $mirrorSymbol";
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

void testSymbolThrows(name) {
  bool fails = false;
  try {
    new Symbol(name);
  } catch (e) {
    fails = true;
  }
  if (!fails) {
    throw "Didn't throw: $name";
  }
}

class Symbolize {
  Symbol lastMember;
  noSuchMethod(m) => lastMember = m.memberName;
}
