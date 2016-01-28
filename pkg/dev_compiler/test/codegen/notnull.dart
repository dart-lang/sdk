// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library notnull;

void intAssignments() {
  var i = 0;
  i &= 1;
  i |= 1;
  i ^= 1;
  i >>= 1;
  i <<= 1;
  i -= 1;
  i %= 1;
  i += 1;
  i ??= 1;
  i *= 1;
  i ~/= 1;
  i++;
  --i;
  print(i + 1);

  int j = 1;
  j = i < 10 ? 1 : 2;
  print(j + 1);
}

void doubleAssignments() {
  var d = 0.0;
  d /= 1;
  print(d + 1);
}

void boolAssignments() {
  var b = true;
  b != b;
  print(b);
}

void increments() {
  int i = 1;
  print(++i);
  print(i++);
  print(--i);
  print(i--);

  int j;
  j = 1;
  print(++j);
  print(j++);
  print(--j);
  print(j--);
}

void conditionals([bool cond]) {
  int nullable;
  nullable = 1;
  int nonNullable = 1;
  int a = cond ? nullable : nullable;
  int b = cond ? nullable : nonNullable;
  int c = cond ? nonNullable : nonNullable;
  int d = cond ? nonNullable : nullable;
  print(a + b + c + d);
}

void nullAwareOps() {
  int nullable;
  int nonNullable = 1;
  int a = nullable ?? nullable;
  int b = nullable ?? nonNullable;
  int c = nonNullable ?? nonNullable;
  int d = nonNullable ?? nullable;
  print(a + b + c + d);

  var s = "";
  print(s?.length + 1);
}

void nullableLocals(int param) {
  print(param + 1);

  int i;
  // We could detect that i is effectively non-nullable with flow analysis.
  i = 1;
  print(i + 1);

  int j = 1;
  j = i == 1 ? 1 : null;
  print(j + 1);
}

void optParams([int x, int y = 1]) {
  print(x + y);
}

void namedParams({int x, int y : 1}) {
  print(x + y);
}

void forLoops(int length()) {
  for (int i = 0; i < 10; i++) {
    print(i + 1);
  }
  for (int i = 0; i < length(); i++) {
    print(i + 1);
  }
  for (int i = 0, n = length(); i < n; i++) {
    print(i + 1);
  }
  // TODO(ochafik): Special-case `int + 0` to provide a cheap way to coerce
  // ints to notnull in the SDK (like asm.js's `x|0` pattern).
  for (int i = 0, n = length() + 0; i < n; i++) {
    print(i + 1);
  }
}

void nullableCycle() {
  int x = 1;
  int y = 2;
  int z;
  x = y;
  y = z;
  z = x;
  print(x + y + z);

  int s;
  s = s;
  print(s + 1);
}

void nonNullableCycle() {
  int x = 1;
  int y = 2;
  int z = 3;
  x = y;
  y = z;
  z = x;
  print(x + y + z);

  int s = 1;
  s = s;
  print(s + 1);
}

class Foo {
  int intField;
  var varField;
  f(Foo o) {
    print(1 + varField + 2);
    while (varField < 10) varField++;
    while (varField < 10) varField = varField + 1;

    print(1 + intField + 2);
    while (intField < 10) intField++;
    while (intField < 10) intField = intField + 1;

    print(1 + o.intField + 2);
    while (o.intField < 10) o.intField++;
    while (o.intField < 10) o.intField = o.intField + 1;
  }
}

int _foo() => 1;
calls() {
  int a = 1;
  int b = 1;
  b = ((x) => x)(a);
  print(b + 1);

  int c = _foo();
  print(c + 1);
}

localEscapes() {
  int a = 1;
  var f = (x) => a = x;

  int b = 1;
  g(x) => b = x;

  f(1);
  g(1);

  print(a + b);
}

controlFlow() {
  for (int i, j;;) {
    i = j = 1;
    print(i + j + 1);
    break;
  }
  try {
    throw 1;
  } catch (e) {
    print(e + 1);
  }
  try {
    (null as dynamic).foo();
  } catch (e, trace) {
    print('${(e is String) ? e : e.toString()} at $trace');
  }
}

main() {
  intAssignments();
  doubleAssignments();
  boolAssignments();
  nullableLocals(1);
  optParams(1, 2);
  namedParams(x: 1, y: 2);
  forLoops(() => 10);
  increments();
  conditionals(true);
  calls();
  localEscapes();
  controlFlow();

  nullableCycle();
  nonNullableCycle();
}
