// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void checkType<T>(thing) {
  assert(thing is T);
  var type = thing.runtimeType;
  if (type == T) return;
  Expect.fail("""
Type print string does not match expectation
  Expected: '$T'
  Actual: '$type'
""");
}

void checkFunctionTypeString<T>(
  Type returnType,
  List<Type> positional,
  List<Type> positionalOptional,
  Map<Symbol, Type> named,
) {
  final sb = StringBuffer();
  sb.write('(');
  bool began = false;
  for (final p in positional) {
    if (began) sb.write(', ');
    sb.write('$p');
    began = true;
  }
  for (final p in positionalOptional) {
    if (began) sb.write(', ');
    sb.write('$p');
    began = true;
  }
  named.forEach((Symbol s, Type t) {
    if (began) sb.write(', ');
    sb.write('$t $s');
    began = true;
  });
  sb.write(')');
  sb.write('=> ');
  sb.write('$returnType');
}
