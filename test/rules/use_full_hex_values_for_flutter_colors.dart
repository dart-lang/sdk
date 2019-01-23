// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_full_hex_values_for_flutter_colors`

library dart.ui;

class Color {
  Color(int v);
  Color.fromARGB(int a, int r, int g, int b);
  Color.fromRGBO(int r, int g, int b, double opacity);
}

m() {
  var a;
  Color(1); // LINT
  Color(0x000000); // LINT
  Color(0x00000000); // OK
  Color(a); // OK
}
