// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

main() {
  print(new W().native);
  print(new X().native());
  print(new Y2().native);
  print((new Z()..native = "setter").f);
}

class W {
  String native;
  W() : native = "field";
}

class X {
  String native() => "method";
}

abstract class Y1 {
  String get native;
}

class Y2 extends Y1 {
  @override
  String get native => "getter";
}

class Z {
  set native(String s) => f = s;
  String f;
}
