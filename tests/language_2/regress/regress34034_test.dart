// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

dynamic bar(int Function(int) f) => f;
T foo<T>(T a) => a;

void main() {
  final closure = bar(foo);
  String s = closure.toString();
  print(s);
  Expect.isTrue(s.contains("(int) => int") || s.contains("with <int>"));
}
