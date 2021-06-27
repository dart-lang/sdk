// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import "package:expect/expect.dart";

class C {
  static int ctr = 0;
  final Object? _text;
  C([Object? text]) : _text = text ?? "${++ctr}";

  // It's possible to declare a `>>>` operator.
  C operator >>>(arg) => C("(${++ctr}:$_text>>>$arg)");

  // + binds more strongly than `>>`, `>>>` and `<<`.
  C operator +(arg) => C("(${++ctr}:$_text+$arg)");
  // Both `>>` and `<<` binds exactly as strongly as `>>>`.
  C operator >>(arg) => C("(${++ctr}:$_text>>$arg)");
  C operator <<(arg) => C("(${++ctr}:$_text<<$arg)");
  // & binds less strongly than `>>`, `>>>` and `<<`.
  C operator &(arg) =>  C("(${++ctr}:$_text&$arg)");

  String toString() => "${_text}";
}

class NSM {
  noSuchMethod(i) => i.memberName;
}

// Valid in extensions too.
extension ShiftIt<T> on T {
  List<T> operator >>>(int count) => List<T>.filled(count, this);
}

main() {
  // It's possible to use the `>>>` operator.
  // Evaluation is left-to-right.
  Expect.equals("(3:1>>>2)", "${C() >>> C()}");

  var c = C();
  Expect.equals("4", "$c");
  c >>>= C();
  Expect.equals("(6:4>>>5)", "$c");

  // Precedence is as expected.
  // Different precedence than + (which binds stronger) and & (which doesn't).
  Expect.equals("(11:(9:7+8)>>>10)", "${C() + C() >>> C()}");
  Expect.equals("(16:12>>>(15:13+14))", "${C() >>> C() + C()}");
  Expect.equals("(23:(19:17+18)>>>(22:20+21))", "${C() + C() >>> C() + C()}");
  Expect.equals("(28:(26:24>>>25)&27)", "${C() >>> C() & C()}");
  Expect.equals("(33:29&(32:30>>>31))", "${C() & C() >>> C()}");
  Expect.equals("(40:(38:34&(37:35>>>36))&39)", "${C() & C() >>> C() & C()}");

  // Same precedence as `>>` and `<<`, left associative.
  Expect.equals("(45:(43:41>>>42)>>44)", "${C() >>> C() >> C()}");
  Expect.equals("(50:(48:46>>47)>>>49)", "${C() >> C() >>> C()}");
  Expect.equals("(55:(53:51>>>52)<<54)", "${C() >>> C() << C()}");
  Expect.equals("(60:(58:56<<57)>>>59)", "${C() << C() >>> C()}");
  Expect.equals("(67:(65:(63:61<<62)>>>64)>>66)",
      "${C() << C() >>> C() >> C()}");

  /// The `>>>` Symbol works.
  var literalSymbol = #>>>;
  var constSymbol = const Symbol(">>>");
  var newSymbol = new Symbol(">>>");
  Expect.identical(literalSymbol, constSymbol);
  Expect.equals(literalSymbol, newSymbol);

  dynamic n = NSM();
  var nsmSymbol = n >>> 42;
  Expect.equals(nsmSymbol, literalSymbol);

  var o = Object();
  Expect.listEquals([o, o, o, o, o], o >>> 5);
}
