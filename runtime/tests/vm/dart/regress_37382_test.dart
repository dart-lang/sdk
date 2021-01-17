// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void expectType(Type type, Pattern text) {
  var typeString = "$type";
  if (typeString.contains("minified:")) {
    return; // No checks for minimized types.
  }
  var match = text.matchAsPrefix(typeString);
  if (match != null && match.end == typeString.length) return;
  Expect.fail(
      "$typeString was not matched by $text${match == null ? "" : ", match: ${match[0]}"}");
}

class A<X, Y> {
  R f<R>(R Function<S, T>(A<S, T>) t) => t<X, Y>(this);
}

main() {
  A<num, num> a = A<int, int>();
  expectType(a.f.runtimeType,
      RegExp(r"<(\w+)>\(<(\w+), (\w+)>\(A<\2, \3>\) => \1\) => \1$"));
}
