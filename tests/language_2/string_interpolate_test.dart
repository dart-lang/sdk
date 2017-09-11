// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing string interpolation.

import "package:expect/expect.dart";

class WhatchamaCallIt {
  WhatchamaCallIt() {}

  String foo() {
    // Test $this is defined in subclass.
    return "$this";
  }
}

class ThingamaBob extends WhatchamaCallIt {
  ThingamaBob(String s)
      : super(),
        name = s {}
  String name;
  toString() => "Hansel and $name";
}

const String A = "svin";
const String B = "hest";
const int N = 1 + 1;
String Printers;
String AAR_Printers;

main() {
  Printers = "Printers: $A and $B";
  AAR_Printers = "AAR has $N $Printers.";

  var x = 1;
  var s = "eins und \$x macht zwei.";
  print(s);
  Expect.equals(r"eins und $x macht zwei.", s);

  s = "eins und $x macht zwei.";
  print(s);
  Expect.equals(r"eins und 1 macht zwei.", s);

  print(AAR_Printers);
  Expect.equals(r"AAR has 2 Printers: svin and hest.", AAR_Printers);

  var s$eins = "eins";
  var $1 = 1;
  var zw = "zw";
  var ei = "ei";
  var zw$ei = "\"Martini, dry? Nai zwai.\"";
  s = "${s$eins} und ${$1} macht $zw$ei.";
  print(s);
  Expect.equals(r"eins und 1 macht zwei.", s);

  var t = new ThingamaBob("Gretel");
  print(t.foo());
  Expect.equals(t.foo(), "Hansel and Gretel");

  testStringVariants();
}

class Stringable {
  final String value;
  Stringable(this.value);
  String toString() => value;
  operator *(int count) => new Stringable(value * count);
}

void testStringVariants() {
  String latin = "ab\x00\xff";
  String nonLatin = "\u2000\u{10000}\ufeff";
  var oLatin = new Stringable(latin);
  var oNonLatin = new Stringable(nonLatin);

  // ASCII.
  Expect.equals(latin * 3, "$latin$latin$latin");
  Expect.equals(
      latin * 64,
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin");
  Expect.equals(
      latin * 64,
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}");
  // Non-ASCII.
  Expect.equals(nonLatin * 3, "$nonLatin$nonLatin$nonLatin");
  Expect.equals(
      nonLatin * 64,
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$nonLatin$nonLatin$nonLatin$nonLatin");
  Expect.equals(
      nonLatin * 64,
      "${nonLatin * 4}${nonLatin * 4}"
      "${nonLatin * 4}${nonLatin * 4}"
      "${nonLatin * 4}${nonLatin * 4}"
      "${nonLatin * 4}${nonLatin * 4}"
      "${nonLatin * 4}${nonLatin * 4}"
      "${nonLatin * 4}${nonLatin * 4}"
      "${nonLatin * 4}${nonLatin * 4}"
      "${nonLatin * 4}${nonLatin * 4}");
  // Mixed.
  Expect.equals(latin * 3 + nonLatin, "$latin$latin$latin$nonLatin");
  Expect.equals(nonLatin + latin * 3, "$nonLatin$latin$latin$latin");
  Expect.equals(
      latin * 60 + nonLatin * 4,
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin"
      "$nonLatin$nonLatin$nonLatin$nonLatin");
  Expect.equals(
      nonLatin * 4 + latin * 60,
      "$nonLatin$nonLatin$nonLatin$nonLatin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin$latin$latin$latin$latin"
      "$latin$latin$latin$latin");
  Expect.equals(
      latin * 60 + nonLatin * 4,
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${nonLatin * 4}");
  Expect.equals(
      nonLatin * 4 + latin * 60,
      "${nonLatin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${latin * 4}");
  // With objects.
  Expect.equals(latin * 3, "$latin$oLatin$latin");
  Expect.equals(
      latin * 64,
      "$latin$latin$latin$latin$latin$latin$latin$oLatin"
      "$latin$latin$latin$latin$latin$latin$latin$oLatin"
      "$latin$latin$latin$latin$latin$latin$latin$oLatin"
      "$latin$latin$latin$latin$latin$latin$latin$oLatin"
      "$latin$latin$latin$latin$latin$latin$latin$oLatin"
      "$latin$latin$latin$latin$latin$latin$latin$oLatin"
      "$latin$latin$latin$latin$latin$latin$latin$oLatin"
      "$latin$latin$latin$latin$latin$latin$latin$oLatin");
  Expect.equals(
      latin * 64,
      "${latin * 4}${latin * 4}${latin * 4}${oLatin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${oLatin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${oLatin * 4}"
      "${latin * 4}${latin * 4}${latin * 4}${oLatin * 4}");
  // Non-ASCII.
  Expect.equals(nonLatin * 3, "$nonLatin$oNonLatin$nonLatin");
  Expect.equals(
      nonLatin * 64,
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin"
      "$nonLatin$nonLatin$nonLatin$oNonLatin");
  Expect.equals(
      nonLatin * 64,
      "${nonLatin * 4}${oNonLatin * 4}"
      "${nonLatin * 4}${oNonLatin * 4}"
      "${nonLatin * 4}${oNonLatin * 4}"
      "${nonLatin * 4}${oNonLatin * 4}"
      "${nonLatin * 4}${oNonLatin * 4}"
      "${nonLatin * 4}${oNonLatin * 4}"
      "${nonLatin * 4}${oNonLatin * 4}"
      "${nonLatin * 4}${oNonLatin * 4}");
  // Mixed.
  Expect.equals(latin * 2 + nonLatin * 2, "$latin$oLatin$nonLatin$oNonLatin");
  Expect.equals(nonLatin * 2 + latin * 2, "$nonLatin$oNonLatin$latin$oLatin");
  Expect.equals(
      (latin * 2 + nonLatin * 2) * 8,
      "$latin$oLatin$nonLatin$oNonLatin"
      "$latin$oLatin$nonLatin$oNonLatin"
      "$latin$oLatin$nonLatin$oNonLatin"
      "$latin$oLatin$nonLatin$oNonLatin"
      "$latin$oLatin$nonLatin$oNonLatin"
      "$latin$oLatin$nonLatin$oNonLatin"
      "$latin$oLatin$nonLatin$oNonLatin"
      "$latin$oLatin$nonLatin$oNonLatin");
  Expect.equals(
      (nonLatin * 2 + latin * 2) * 8,
      "$nonLatin$oNonLatin$latin$oLatin"
      "$nonLatin$oNonLatin$latin$oLatin"
      "$nonLatin$oNonLatin$latin$oLatin"
      "$nonLatin$oNonLatin$latin$oLatin"
      "$nonLatin$oNonLatin$latin$oLatin"
      "$nonLatin$oNonLatin$latin$oLatin"
      "$nonLatin$oNonLatin$latin$oLatin"
      "$nonLatin$oNonLatin$latin$oLatin");

  // All combinations
  var o1 = new Stringable("x");
  var o2 = new Stringable("\ufeff");

  Expect.equals("a\u2000x\ufeff", "${"a"}${"\u2000"}${o1}${o2}");
  Expect.equals("a\u2000\ufeffx", "${"a"}${"\u2000"}${o2}${o1}");
  Expect.equals("ax\u2000\ufeff", "${"a"}${o1}${"\u2000"}${o2}");
  Expect.equals("ax\ufeff\u2000", "${"a"}${o1}${o2}${"\u2000"}");
  Expect.equals("a\ufeffx\u2000", "${"a"}${o2}${o1}${"\u2000"}");
  Expect.equals("a\ufeff\u2000x", "${"a"}${o2}${"\u2000"}${o1}");

  Expect.equals("\u2000ax\ufeff", "${"\u2000"}${"a"}${o1}${o2}");
  Expect.equals("\u2000a\ufeffx", "${"\u2000"}${"a"}${o2}${o1}");
  Expect.equals("xa\u2000\ufeff", "${o1}${"a"}${"\u2000"}${o2}");
  Expect.equals("xa\ufeff\u2000", "${o1}${"a"}${o2}${"\u2000"}");
  Expect.equals("\ufeffax\u2000", "${o2}${"a"}${o1}${"\u2000"}");
  Expect.equals("\ufeffa\u2000x", "${o2}${"a"}${"\u2000"}${o1}");

  Expect.equals("\u2000xa\ufeff", "${"\u2000"}${o1}${"a"}${o2}");
  Expect.equals("\u2000\ufeffax", "${"\u2000"}${o2}${"a"}${o1}");
  Expect.equals("x\u2000a\ufeff", "${o1}${"\u2000"}${"a"}${o2}");
  Expect.equals("x\ufeffa\u2000", "${o1}${o2}${"a"}${"\u2000"}");
  Expect.equals("\ufeffxa\u2000", "${o2}${o1}${"a"}${"\u2000"}");
  Expect.equals("\ufeff\u2000ax", "${o2}${"\u2000"}${"a"}${o1}");

  Expect.equals("\u2000x\ufeffa", "${"\u2000"}${o1}${o2}${"a"}");
  Expect.equals("\u2000\ufeffxa", "${"\u2000"}${o2}${o1}${"a"}");
  Expect.equals("x\u2000\ufeffa", "${o1}${"\u2000"}${o2}${"a"}");
  Expect.equals("x\ufeff\u2000a", "${o1}${o2}${"\u2000"}${"a"}");
  Expect.equals("\ufeffx\u2000a", "${o2}${o1}${"\u2000"}${"a"}");
  Expect.equals("\ufeff\u2000xa", "${o2}${"\u2000"}${o1}${"a"}");
}
